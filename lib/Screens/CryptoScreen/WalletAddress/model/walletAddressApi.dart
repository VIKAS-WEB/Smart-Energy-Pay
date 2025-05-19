import 'package:dio/dio.dart';
import 'package:smart_energy_pay/Screens/CryptoScreen/WalletAddress/model/walletAddressModel.dart';
import 'package:smart_energy_pay/util/auth_manager.dart';
import '../../../../util/apiConstants.dart';

class WalletAddressApi {
  final Dio _dio = Dio();

  WalletAddressApi() {
    _dio.options.baseUrl = ApiConstants.baseUrl;


    /*_dio.interceptors.add(LogInterceptor(
      request: true,
      requestBody: true,
      responseBody: true,
      responseHeader: true,
    ));*/
  }

  Future<WalletAddressResponse> walletAddressApi() async {
    try {
      final response = await _dio.get(
        '/walletaddressrequest/list/${AuthManager.getUserId()}',
        options: Options(headers: {
          'Authorization': 'Bearer ${AuthManager.getToken()}',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return WalletAddressResponse.fromJson(response.data);
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
