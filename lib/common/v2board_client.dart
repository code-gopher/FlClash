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
    return Options(headers: {'Authorization': '$_token'});
  }

  Future<dynamic> login(String email, String password) async {
    final response = await dio.post(
      '$_baseUrl/api/v1/passport/auth/login',
      data: {'email': email, 'password': password},
    );
    return response.data;
  }

  Future<dynamic> register(
    String email,
    String password,
    String emailCode,
  ) async {
    final response = await dio.post(
      '$_baseUrl/api/v1/passport/auth/register',
      data: {'email': email, 'password': password, 'email_code': emailCode},
    );
    return response.data;
  }

  Future<dynamic> sendEmailVerify(String email) async {
    final response = await dio.post(
      '$_baseUrl/api/v1/passport/comm/sendEmailVerify',
      data: {'email': email},
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

  Future<dynamic> getPaymentMethod() async {
    final response = await dio.get(
      '$_baseUrl/api/v1/user/order/getPaymentMethod',
      options: _authOptions,
    );
    return response.data;
  }

  Future<dynamic> createOrder({
    required int planId,
    required String period,
    String couponCode = '',
  }) async {
    try {
      final response = await dio.post(
        '$_baseUrl/api/v1/user/order/save?plan_id=$planId&period=$period&coupon_code=$couponCode',
        options: _authOptions,
      );
      print('[V2Board] createOrder response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('[V2Board] createOrder error: ${e.response?.data}');
      print('[V2Board] createOrder statusCode: ${e.response?.statusCode}');
      rethrow;
    }
  }

  Future<String?> checkoutOrder({
    required String tradeNo,
    required int method,
  }) async {
    try {
      final response = await dio.post(
        '$_baseUrl/api/v1/user/order/checkout?trade_no=$tradeNo&method=$method',
        options: _authOptions,
      );
      print('[V2Board] checkoutOrder response: ${response.data}');
      final data = response.data;
      if (data['type'] == 1 || data['type'] == -1) {
        return data['data'];
      }
      return null;
    } on DioException catch (e) {
      print('[V2Board] checkoutOrder error: ${e.response?.data}');
      print('[V2Board] checkoutOrder statusCode: ${e.response?.statusCode}');
      rethrow;
    }
  }

  Future<dynamic> getOrderList() async {
    final response = await dio.get(
      '$_baseUrl/api/v1/user/order/fetch',
      options: _authOptions,
    );
    return response.data;
  }

  Future<dynamic> cancelOrder(String tradeNo) async {
    try {
      final response = await dio.post(
        '$_baseUrl/api/v1/user/order/cancel?trade_no=$tradeNo',
        options: _authOptions,
      );
      return response.data;
    } on DioException catch (e) {
      print('[V2Board] cancelOrder error: ${e.response?.data}');
      print('[V2Board] cancelOrder statusCode: ${e.response?.statusCode}');
      rethrow;
    }
  }

  // 工单相关接口
  Future<dynamic> getTicketList() async {
    final response = await dio.get(
      '$_baseUrl/api/v1/user/ticket/fetch',
      options: _authOptions,
    );
    return response.data;
  }

  Future<dynamic> getTicketDetail(int id) async {
    final response = await dio.get(
      '$_baseUrl/api/v1/user/ticket/fetch?id=$id',
      options: _authOptions,
    );
    return response.data;
  }

  Future<dynamic> createTicket({
    required String subject,
    required int level,
    required String message,
  }) async {
    try {
      final response = await dio.post(
        '$_baseUrl/api/v1/user/ticket/save?subject=${Uri.encodeComponent(subject)}&level=$level&message=${Uri.encodeComponent(message)}',
        options: _authOptions,
      );
      print('[V2Board] createTicket response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('[V2Board] createTicket error: ${e.response?.data}');
      print('[V2Board] createTicket statusCode: ${e.response?.statusCode}');
      print('[V2Board] createTicket message: ${e.message}');
      rethrow;
    }
  }

  Future<dynamic> replyTicket({
    required int id,
    required String message,
  }) async {
    final response = await dio.post(
      '$_baseUrl/api/v1/user/ticket/reply',
      data: {'id': id, 'message': message},
      options: _authOptions,
    );
    return response.data;
  }

  Future<dynamic> closeTicket({required int id}) async {
    final response = await dio.get(
      '$_baseUrl/api/v1/user/ticket/close?id=$id',
      options: _authOptions,
    );
    return response.data;
  }
}
