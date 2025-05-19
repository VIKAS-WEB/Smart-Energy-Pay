import 'package:dio/dio.dart';
import 'package:smart_energy_pay/Screens/InvoicesScreen/ProductsScreen/ProductScreen/productDetailsModel/productDetailModel.dart';
import 'package:smart_energy_pay/util/auth_manager.dart';

import '../../../../../util/apiConstants.dart';

class ProductDetailsApi {
  final Dio _dio = Dio();

  ProductDetailsApi() {
    _dio.options.baseUrl = ApiConstants.baseUrl;

    /*_dio.interceptors.add(LogInterceptor(
      request: true,
      requestBody: true,
      responseBody: true,
      responseHeader: true,
    ));*/
  }

  Future<ProductDetailsResponse> productDetailsApi(String? productID) async {
    try {
      final response = await _dio.get(
        '/product/$productID',
        options: Options(headers: {
          'Authorization': 'Bearer ${AuthManager.getToken()}',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ProductDetailsResponse.fromJson(response.data);
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
