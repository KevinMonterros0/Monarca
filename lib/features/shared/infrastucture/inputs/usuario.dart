import 'package:formz/formz.dart';

enum UsernameError { empty, tooShort }

class Username extends FormzInput<String, UsernameError> {

  static const int minLength = 3;

  const Username.pure() : super.pure('');

  const Username.dirty(String value) : super.dirty(value);

  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == UsernameError.empty) return 'El nombre de usuario es requerido';
    if (displayError == UsernameError.tooShort) return 'El nombre de usuario debe tener al menos $minLength caracteres';

    return null;
  }

  @override
  UsernameError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return UsernameError.empty;
    if (value.length < minLength) return UsernameError.tooShort;

    return null;
  }
}
