import 'package:dio/dio.dart';
import 'package:smart_energy_pay/util/auth_manager.dart';
import '../../../../../../util/apiConstants.dart';
import 'cryptoTransactionGetDetailsModel.dart';

class CryptoTransactionGetDetailsApi {
  final Dio _dio = Dio();

  CryptoTransactionGetDetailsApi() {
    _dio.options.baseUrl = ApiConstants.baseUrl;


    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestBody: true,
      responseBody: true,
      responseHeader: true,
    ));
  }

  Future<CryptoTransactionGetDetailsResponse> cryptoTransactionGetDetailsApiApi(String transactionId) async {
    try {
      final response = await _dio.get(
        '/crypto/getdetails/$transactionId',
        options: Options(headers: {
          'Authorization': 'Bearer ${AuthManager.getToken()}',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CryptoTransactionGetDetailsResponse.fromJson(response.data);
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
