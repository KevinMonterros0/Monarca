import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monarca/features/auth/presentation/providers/register_form_provider.dart';
import 'package:monarca/features/shared/infrastucture/inputs/passwords.dart';
import 'package:monarca/features/shared/infrastucture/inputs/confirm_password.dart';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';
import 'package:monarca/features/shared/shared.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textStyles = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: GeometricalBackground(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => context.push('/'),
                      icon: const Icon(Icons.arrow_back_rounded, size: 40, color: Colors.white),
                    ),
                    const Spacer(flex: 1),
                    Text('Crear usuario', style: textStyles.titleLarge?.copyWith(color: Colors.white)),
                    const Spacer(flex: 2),
                  ],
                ),
                const SizedBox(height: 50),
                Container(
                  height: size.height - 260,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(100)),
                  ),
                  child: const _RegisterForm(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterForm extends ConsumerStatefulWidget {
  const _RegisterForm();

  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<_RegisterForm> {
  List<MyItem> items = [];
  MyItem? selectedItem;
  final keyValueStorageService = KeyValueStorageServiceImpl();

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    final token = await keyValueStorageService.getValue<String>('token');
    final response = await http.get(
      Uri.parse('https://apiproyectomonarca.fly.dev/api/empleados/obtener'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        items = data.map((item) => MyItem.fromJson(item)).toList();
      });
    } else {
      throw Exception('Failed to load items');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;
    final formState = ref.watch(registerFormProvider);
    final notifier = ref.read(registerFormProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        children: [
          const SizedBox(height: 50),
          Text('Nuevo usuario', style: textStyles.titleMedium),
          const SizedBox(height: 50),

          CustomTextFormField(
            label: 'Username',
            keyboardType: TextInputType.emailAddress,
            errorMessage: formState.username.error == UsernameError.empty
                ? 'El nombre de usuario es obligatorio'
                : null,
            onChanged: notifier.onUsernameChange,
          ),
          const SizedBox(height: 60),

          CustomTextFormField(
            label: 'Contraseña',
            obscureText: !formState.isPasswordVisible,
            errorMessage: formState.password.error == PasswordValidationError.tooShort
                ? 'La contraseña debe tener al menos 6 caracteres'
                : null,
            onChanged: notifier.onPasswordChange,
            suffixIcon: IconButton(
              icon: Icon(
                formState.isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: notifier.togglePasswordVisibility,
            ),
          ),
          const SizedBox(height: 60),

          CustomTextFormField(
            label: 'Repita la contraseña',
            obscureText: !formState.isConfirmPasswordVisible,
            errorMessage: formState.confirmPassword.error == ConfirmPasswordValidationError.notMatching
                ? 'Las contraseñas no coinciden'
                : null,
            onChanged: notifier.onConfirmPasswordChange,
            suffixIcon: IconButton(
              icon: Icon(
                formState.isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: notifier.toggleConfirmPasswordVisibility,
            ),
          ),
          const SizedBox(height: 60),

          items.isEmpty
              ? CircularProgressIndicator()
              : DropdownButton<MyItem>(
                  hint: Text('Empleado'),
                  value: selectedItem,
                  onChanged: (MyItem? newValue) {
                    setState(() {
                      selectedItem = newValue;
                    });
                  },
                  items: items.map((MyItem item) {
                    return DropdownMenuItem<MyItem>(
                      value: item,
                      child: Text(item.name),
                    );
                  }).toList(),
                ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: CustomFilledButton(
              text: 'Crear',
              buttonColor: const Color(0xFF283B71),
              onPressed: () async {
                if (selectedItem != null) {
                  final success = await notifier.onFormSubmit(selectedItem!.id);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Usuario creado exitosamente')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al crear usuario')),
                    );
                  }
                } else {
                  notifier.onFormSubmit(0);
                }
              },
            ),
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }

  void saveItem(int id) {
  }
}

class MyItem {
  final int id;
  final String name;

  MyItem({required this.id, required this.name});

  factory MyItem.fromJson(Map<String, dynamic> json) {
    return MyItem(
      id: json['id_empleado'],
      name: json['nombre'],
    );
  }
}
