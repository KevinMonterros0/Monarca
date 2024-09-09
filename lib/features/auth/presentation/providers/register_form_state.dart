import 'package:monarca/features/shared/infrastucture/inputs/confirm_password.dart';
import 'package:monarca/features/shared/infrastucture/inputs/passwords.dart';
import 'package:monarca/features/shared/infrastucture/inputs/usuario.dart';


class RegisterFormState {
  final bool isPosting;
  final bool isFormPosted;
  final bool isValid;
  final bool isPasswordVisible; 
  final bool isConfirmPasswordVisible;
  final Username username;
  final Passwords password;
  final ConfirmPassword confirmPassword;

  RegisterFormState({
    this.isPosting = false,
    this.isFormPosted = false,
    this.isValid = false,
    this.isPasswordVisible = false, 
    this.isConfirmPasswordVisible = false,
    this.username = const Username.pure(),
    this.password = const Passwords.pure(),
    this.confirmPassword = const ConfirmPassword.pure(password: ''),
  });

  RegisterFormState copyWith({
    bool? isPosting,
    bool? isFormPosted,
    bool? isValid,
    bool? isPasswordVisible,
    bool? isConfirmPasswordVisible, 
    Username? username,
    Passwords? password,
    ConfirmPassword? confirmPassword,
  }) {
    return RegisterFormState(
      isPosting: isPosting ?? this.isPosting,
      isFormPosted: isFormPosted ?? this.isFormPosted,
      isValid: isValid ?? this.isValid,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible, 
      isConfirmPasswordVisible: isConfirmPasswordVisible ?? this.isConfirmPasswordVisible, 
      username: username ?? this.username,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
    );
  }

  @override
  String toString() {
    return '''
    RegisterFormState:
    isPosting: $isPosting,
    isFormPosted: $isFormPosted,
    isValid: $isValid,
    isPasswordVisible: $isPasswordVisible, // Incluir en toString
    isConfirmPasswordVisible: $isConfirmPasswordVisible, // Incluir en toString
    username: $username,
    password: $password,
    confirmPassword: $confirmPassword,
    ''';
  }
}
