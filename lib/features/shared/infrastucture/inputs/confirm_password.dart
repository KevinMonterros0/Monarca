import 'package:formz/formz.dart';

enum ConfirmPasswordValidationError { empty, notMatching }

class ConfirmPassword extends FormzInput<String, ConfirmPasswordValidationError> {
  final String password;

  const ConfirmPassword.pure({this.password = ''}) : super.pure('');
  const ConfirmPassword.dirty({required this.password, String value = ''}) : super.dirty(value);

  @override
  ConfirmPasswordValidationError? validator(String value) {
    if (value.isEmpty) {
      return ConfirmPasswordValidationError.empty;
    } else if (value != password) {
      return ConfirmPasswordValidationError.notMatching;
    }
    return null;
  }
}
