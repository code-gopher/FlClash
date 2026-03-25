import 'package:dio/dio.dart';

class V2boardClient {
  final Dio dio;

  V2boardClient({required this.dio});

  String _baseUrl = '';

  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Options get _authOptions {
    if (_token == null) return Options();
    return Options(headers: {
      'Authorization': '$_token',
    });
  }

  Future<dynamic> login(String email, String password) async {
    final response = await dio.post(
      '$_baseUrl/api/v1/passport/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    return response.data;
  }

  Future<dynamic> register(String email, String password, String emailCode) async {
    final response = await dio.post(
      '$_baseUrl/api/v1/passport/auth/register',
      data: {
        'email': email,
        'password': password,
        'email_code': emailCode,
      },
    );
    return response.data;
  }

  Future<dynamic> sendEmailVerify(String email) async {
    final response = await dio.post(
      '$_baseUrl/api/v1/passport/comm/sendEmailVerify',
      data: {
        'email': email,
      },
    );
    return response.data;
  }

  Future<dynamic> getUserInfo() async {
    final response = await dio.get(
      '$_baseUrl/api/v1/user/info',
      options: _authOptions,
    );
    return response.data;
  }

  Future<dynamic> getSubscribe() async {
    final response = await dio.get(
      '$_baseUrl/api/v1/user/getSubscribe',
      options: _authOptions,
    );
    return response.data;
  }

  Future<dynamic> getPlanFetch() async {
    final response = await dio.get(
      '$_baseUrl/api/v1/user/plan/fetch',
      options: _authOptions,
    );
    return response.data;
  }
}
