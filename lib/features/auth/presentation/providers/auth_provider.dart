
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monarca/features/auth/domain/domain.dart';
import 'package:monarca/features/auth/infrastructure/infrastructure.dart';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service.dart';
import 'package:monarca/features/shared/infrastucture/services/key_value_storage_service_impl.dart';


final authProvider = StateNotifierProvider<AuthNotifier,AuthState>((ref) {
  final authRepository = AuthRepositoryImpl();
  final keyValueStorageService = KeyValueStorageServiceImpl();

  return AuthNotifier(
    authRepository : authRepository,
    keyValueStorageService: keyValueStorageService
  );
});

class AuthNotifier extends StateNotifier<AuthState> {

  final AuthRepository  authRepository;
  final KeyValueStorageService keyValueStorageService;
  AuthNotifier({required this.authRepository, required this.keyValueStorageService}): super(AuthState()){
    checkAuthStatus();
  }

  Future<void> loginUser(String username, String password) async{
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final user = await authRepository.login(username, password);
    _setLoggedUser(user);
    } on  WrongCredentianls{
      logout('Credenciales no son correctas');
    }on ConnectionTimeout{
      logout('Timeout');
    }
    catch(e){
      logout('Error no controlado');
    }
    // final user = await authRepository.login(username, password);
    // state = state.copyWith(user: user, Au);
  }

  void checkAuthStatus() async{
  final token  = await keyValueStorageService.getValue<String>('token');
  if(token == null) return logout();

  try {
    final user = await authRepository.checkAuthStatus(token);
    _setLoggedUser(user);
  } catch (e) {
    logout();
  }
  }

  void _setLoggedUser(User user){
    keyValueStorageService.setKeyValue('token',user.token);
    state = state.copyWith(
      user:user,
      authStatus: AuthStatus.authenticated,
      errorMessage: ''
    );
  }

  Future<void> logout([String ? errorMessage]) async{
    keyValueStorageService.removeKey('token');
    state = state.copyWith(
      authStatus: AuthStatus.noAuthenticated,
      user: null,
      errorMessage: errorMessage
    );

  }
  
}

enum AuthStatus {checking,authenticated,noAuthenticated}
class AuthState{

  final AuthStatus authStatus;
  final User ? user;
  final String errorMessage;

  AuthState({this.authStatus = AuthStatus.checking, 
  this.user,
  this.errorMessage = ''
  });

  AuthState copyWith({
    AuthStatus ? authStatus,
    User ? user,
    String? errorMessage,
  }) => AuthState(
    authStatus: authStatus ?? this.authStatus,
    user: user ?? this.user,
    errorMessage: errorMessage ?? this.errorMessage
  );
}