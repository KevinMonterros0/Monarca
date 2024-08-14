import 'package:teslo_shop/features/shared/shared.dart';

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
    this.password = const Password.pure()});

}