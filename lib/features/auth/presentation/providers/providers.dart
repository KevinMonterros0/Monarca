import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teslo_shop/features/shared/shared.dart';
import 'package:formz/formz.dart';

class LoginFormState{

  final bool isPosting;
  final bool isFormPosted;
  final bool isValid;
  final Username username;
  final Password password;

  LoginFormState({this.isPosting =false,
  this.isFormPosted = false,
    this.isValid = false,
    this.username = const Username.pure(), 
    this.password = const Password.pure()
    });

    LoginFormState copyWith({
      bool? isPosting,
      bool? isFormPosted,
      bool? isValid,
      Username? username,
      Password? password,  
    }) => LoginFormState( 
    isPosting: isPosting ?? this.isPosting,
    isFormPosted: isFormPosted ?? this.isFormPosted,
    isValid: isValid ?? this.isValid,
    username: username ?? this.username,
    password: password ?? this.password
    );

@override
  String toString() {
    
    return '''
    LoginFormState:
    isPosting : $isPosting
    isFormPosted  : $isFormPosted
    isValid : $isValid
    username  : $username
    password  : $password
      ''';
  }
}

  class LoginFormNotifier extends StateNotifier<LoginFormState> {
    LoginFormNotifier(): super(LoginFormState());

    onUsernameChange(String value){
      final newUsername = Username.dirty(value);
      state = state.copyWith(
        username: newUsername,
        isValid: Formz.validate([newUsername,state.password])
      );
    }
    
    onPasswordChange(String value){
      final newPassword = Password.dirty(value);
      state = state.copyWith(
        password: newPassword,
        isValid: Formz.validate([newPassword,state.username])
      );
    }

    onFormSubmit(){
      _touchEveryField();

      if(!state.isValid) return;
      print(state);
    }

    _touchEveryField(){
      final username = Username.dirty(state.username.value);
      final password = Password.dirty(state.password.value);

      state = state.copyWith(
        isFormPosted: true,
        username: username,
        password: password,
        isValid: Formz.validate([username, password])
      );
    }
    
  }

final loginFormProvider = StateNotifierProvider.autoDispose<LoginFormNotifier,LoginFormState>((ref) {
  return LoginFormNotifier();
});