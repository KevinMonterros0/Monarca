import 'package:formz/formz.dart';

enum PasswordValidationError { empty, tooShort }

class Passwords extends FormzInput<String, PasswordValidationError> {
  const Passwords.pure() : super.pure('');
  const Passwords.dirty([String value = '']) : super.dirty(value);

  @override
  PasswordValidationError? validator(String value) {
    if (value.isEmpty) {
      return PasswordValidationError.empty;
    } else if (value.length < 6) {
      return PasswordValidationError.tooShort;
    }
    return null;
  }
}
