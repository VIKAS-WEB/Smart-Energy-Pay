import 'package:dio/dio.dart';
import 'package:smart_energy_pay/Screens/CryptoScreen/BuyAndSell/CryptoBuyAndSellScreen/cryptoBuyModel/walletAddressModel/walletAddressModel.dart';
import 'package:smart_energy_pay/util/auth_manager.dart';
import '../../../../../../util/apiConstants.dart';

class CryptoBuyWalletAddressApi {
  final Dio _dio = Dio();

  CryptoBuyWalletAddressApi() {
    _dio.options.baseUrl = ApiConstants.baseUrl;


    /*_dio.interceptors.add(LogInterceptor(
      request: true,
      requestBody: true,
      responseBody: true,
      responseHeader: true,
    ));*/
  }

  Future<CryptoBuyWalletAddressResponse> cryptoBuyWalletAddressApi(String coinType, String userEmailId) async {
    try {
      final response = await _dio.get(
        '/crypto/getWalletAddress/$coinType/$userEmailId',
        options: Options(headers: {
          'Authorization': 'Bearer ${AuthManager.getToken()}',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CryptoBuyWalletAddressResponse.fromJson(response.data);
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
