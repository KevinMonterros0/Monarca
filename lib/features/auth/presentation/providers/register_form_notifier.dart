import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';
import 'package:monarca/features/shared/infrastucture/inputs/confirm_password.dart';
import 'package:monarca/features/shared/infrastucture/inputs/passwords.dart';
import 'package:monarca/features/shared/infrastucture/inputs/usuario.dart';
import 'register_form_state.dart';


class RegisterFormNotifier extends StateNotifier<RegisterFormState> {
  final Function(String, String, int) registerUserCallback;

  RegisterFormNotifier({required this.registerUserCallback})
      : super(RegisterFormState());

  void onUsernameChange(String value) {
    final newUsername = Username.dirty(value);
    final newConfirmPassword = ConfirmPassword.dirty(password: state.password.value, value: state.confirmPassword.value);
    state = state.copyWith(
      username: newUsername,
      isValid: Formz.validate([newUsername, state.password, newConfirmPassword]),
    );
  }

  void onPasswordChange(String value) {
    final newPassword = Passwords.dirty(value);
    final newConfirmPassword = ConfirmPassword.dirty(password: newPassword.value, value: state.confirmPassword.value);
    state = state.copyWith(
      password: newPassword,
      confirmPassword: newConfirmPassword,
      isValid: Formz.validate([state.username, newPassword, newConfirmPassword]),
    );
  }

  void onConfirmPasswordChange(String value) {
    final newConfirmPassword = ConfirmPassword.dirty(password: state.password.value, value: value);
    state = state.copyWith(
      confirmPassword: newConfirmPassword,
      isValid: Formz.validate([state.username, state.password, newConfirmPassword]),
    );
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(isConfirmPasswordVisible: !state.isConfirmPasswordVisible);
  }

  Future<void> onFormSubmit(int employeeId) async {
    _touchEveryField();

    if (!state.isValid) return;

    state = state.copyWith(isPosting: true);

    await registerUserCallback(state.username.value, state.password.value, employeeId);

    state = state.copyWith(isPosting: false);
  }

  void _touchEveryField() {
    final username = Username.dirty(state.username.value);
    final password = Passwords.dirty(state.password.value);
    final confirmPassword = ConfirmPassword.dirty(password: state.password.value, value: state.confirmPassword.value);

    state = state.copyWith(
      isFormPosted: true,
      username: username,
      password: password,
      confirmPassword: confirmPassword,
      isValid: Formz.validate([username, password, confirmPassword]),
    );
  }
}
