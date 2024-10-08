import 'package:dio/dio.dart';
import 'package:monarca/config/config.dart';
import 'package:monarca/features/auth/domain/datasources/auth_datasource.dart';
import 'package:monarca/features/auth/domain/entities/user.dart';
import 'package:monarca/features/auth/infrastructure/infrastructure.dart';
import 'package:monarca/features/auth/infrastructure/mappers/user_sesion.dart';

class AuthDatasourceImpl extends AuthDatasource{

  final dio = Dio();

  @override
  Future<User> checkAuthStatus(String token) async {
    try {
      final response = await dio.post('https://apiproyectomonarca.fly.dev/api/usuarios/verify',
      data: {
          'token': token
        }
      );
      
      final user = UserMapper.userJsonToEntity(response.data);
      return user;
    } on DioException catch (e) {
      if(e.response?.statusCode == 401 || e.response?.statusCode == 404) throw WrongCredentianls();
      if(e.type == DioExceptionType.connectionTimeout) throw ConnectionTimeout();
      throw CustomError('Something wrong happend: $e');
    } catch (e) {
      throw CustomError('Something wrong happend $e');
    }
  }

  @override
  Future<User> login(String username, String password) async {
    try {
      final response = await dio.post('https://apiproyectomonarca.fly.dev/api/usuarios/login', data: {
        'username':username,
        'password':password
      });

      final user = UserMapper.userJsonToEntity(response.data);

      await UserSession().setUsername(username); 
      await UserSession().setUserId(user.idUsuario); 
      final response2 = await Dio().post(
      'https://apiproyectomonarca.fly.dev/api/sesiones/crear',
      data: {
        'Id_usuario': user.idUsuario,
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

      return user;
    } on DioException catch (e) {
      if(e.response?.statusCode == 401 || e.response?.statusCode == 404) throw WrongCredentianls();
      if(e.type == DioExceptionType.connectionTimeout) throw ConnectionTimeout();
      throw CustomError('Something wrong happend: $e');
    } catch (e) {
      throw CustomError('Something wrong happend $e');
    }
  }

}
