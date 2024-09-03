import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monarca/features/auth/presentation/providers/auth_provider.dart';
import 'package:monarca/features/auth/presentation/providers/providers.dart';
import 'package:monarca/features/shared/shared.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: GeometricalBackground( 
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox( height: 80 ),
                // Icon Banner
                const Icon( 
                  Icons.water_drop, 
                  color: Colors.white,
                  size: 100,
                ),
                const SizedBox( height: 80 ),
    
                Container(
                  height: size.height - 260, // 80 los dos sizebox y 100 el ícono
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(100)),
                  ),
                  child: const _LoginForm(),
                )
              ],
            ),
          )
        )
      ),
    );
  }
}

class _LoginForm extends ConsumerWidget {
  const _LoginForm();

  void showSnackbar(BuildContext context, String message){
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message))
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final loginForm = ref.watch(loginFormProvider);
    final isPasswordVisible = ref.watch(loginPasswordVisibilityProvider);

    ref.listen(authProvider, (previous,next){
      if(next.errorMessage.isEmpty) return;
      showSnackbar(context, next.errorMessage);
    });

    final textStyles = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        children: [
          const SizedBox( height: 50 ),
          Text('Inicio de sesión', style: textStyles.titleLarge ),
          const SizedBox( height: 90 ),

          CustomTextFormField(
            label: 'Usuario',
            keyboardType: TextInputType.text,
            onChanged: (value) => ref.read(loginFormProvider.notifier).onUsernameChange(value),
            errorMessage: loginForm.isFormPosted ? loginForm.username.errorMessage : null,
          ),
          const SizedBox( height: 30 ),

          CustomTextFormField(
            label: 'Contraseña',
            obscureText: !isPasswordVisible,
            keyboardType: TextInputType.text,
            onChanged: (value) => ref.read(loginFormProvider.notifier).onPasswordChange(value),
            errorMessage: loginForm.isFormPosted ? loginForm.password.errorMessage: null,
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () => ref.read(loginPasswordVisibilityProvider.notifier).state = !isPasswordVisible,
            ),
          ),
    
          const SizedBox( height: 30 ),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: CustomFilledButton(
              text: 'Ingresar',
              buttonColor: const Color(0xFF283B71),
              onPressed: loginForm.isPosting ? null
              : ref.read(loginFormProvider.notifier).onFormSubmit
            )
          ),

          const Spacer( flex: 2 ),

          const Spacer( flex: 1),
        ],
      ),
    );
  }
}

final loginPasswordVisibilityProvider = StateProvider<bool>((ref) => false);
