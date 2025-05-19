import 'package:dio/dio.dart';
import 'package:smart_energy_pay/util/auth_manager.dart';
import '../../../../../util/apiConstants.dart';
import 'cryptoBuyModel.dart';

class CryptoBuyApi {
  final Dio _dio = Dio();

  CryptoBuyApi() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.headers['Authorization'] = 'Bearer ${AuthManager.getToken()}';


   /* _dio.interceptors.add(LogInterceptor(
      request: true,
      requestBody: true,
      responseBody: true,
      responseHeader: true,
    ));*/
  }


  Future<CryptoBuyResponse> cryptoBuyApi(CryptoBuyRequest request) async {
    try {
      final response = await _dio.post(
        '/crypto/fetch-calculation',
        data: request.toJson(),
      );

      // Check for a successful response
      if (response.statusCode == 200 || response.statusCode == 201) {
        return CryptoBuyResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch data: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Dio error: ${e.response?.data ?? e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
