import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decode/jwt_decode.dart';

class AuthManager {
  static final ValueNotifier<String?> authChangeNotifier = ValueNotifier(null);
  static late SharedPreferences _sharedPref;
  static bool _isFreshLogin = false;

  static Future<void> init() async {
    _sharedPref = await SharedPreferences.getInstance();
  }

  // Save and Get Token
  static Future<void> saveToken(String token) async {
    await _sharedPref.setString('access_token', token);
    authChangeNotifier.value = token; // Notify listeners about token change
  }

  static String getToken() {
    return _sharedPref.getString('access_token') ?? '';
  }

  static String readAuth() {
    return _sharedPref.getString('access_token') ?? '';
  }

  // Check if token is expired
  static bool isTokenExpired(String token) {
    try {
      final payload = Jwt.parseJwt(token);
      final exp = payload['exp'] as int?;
      if (exp == null) return true; // No expiration claim, assume expired
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return exp < now; // Token expired if exp < current time
    } catch (e) {
      print("Error decoding token: $e");
      return true; // If decoding fails, assume token is invalid
    }
  }

  // Get a valid token (checks expiration, no refresh since no endpoint exists)
  static Future<String?> getValidToken() async {
    final token = getToken();
    if (token.isEmpty) {
      await logout(); // Log out if no token exists
      return null;
    }

    if (isTokenExpired(token)) {
      await logout(); // Log out if token is expired
      return null;
    }
    return token;
  }

  // Login: Save token and mark as fresh login
  static Future<void> login(String token) async {
    await saveToken(token);
    _isFreshLogin = true; // Set flag to indicate a fresh login
    print("Login: _isFreshLogin set to true"); // Debug
  }

  // Logout: Clear all stored data
  static Future<void> logout() async {
    await _sharedPref.clear(); // Clear all SharedPreferences data
    authChangeNotifier.value = null; // Notify listeners about logout
    _isFreshLogin = false; // Reset fresh login flag
    print("Logout: _isFreshLogin set to false"); // Debug
  }

  static bool isLoggedIn() {
    String token = readAuth();
    return token.isNotEmpty;
  }

  // Fresh Login Flag Management
  static bool isFreshLogin() => _isFreshLogin;

  static void clearFreshLogin() {
    _isFreshLogin = false;
    print("clearFreshLogin: _isFreshLogin set to false"); // Debug
  }

  // Existing methods for user data
  static Future<void> saveUserId(String id) async {
    await _sharedPref.setString('user_id', id);
  }

  static String getUserId() {
    return _sharedPref.getString('user_id') ?? '';
  }

  static Future<void> saveKycStatus(String status) async {
    await _sharedPref.setString('kyc_status', status);
  }

  static String getKycStatus() {
    return _sharedPref.getString('kyc_status') ?? '';
  }

  static Future<void> saveKycId(String id) async {
    await _sharedPref.setString('kyc_id', id);
  }

  static String getKycId() {
    return _sharedPref.getString('kyc_id') ?? '';
  }

  static Future<void> saveKycDocFront(String status) async {
    await _sharedPref.setString('kyc_doc_front', status);
  }

  static String getKycDocFront() {
    return _sharedPref.getString('kyc_doc_front') ?? '';
  }

  static Future<void> saveUserName(String name) async {
    await _sharedPref.setString('user_name', name);
  }

  static String getUserName() {
    return _sharedPref.getString('user_name') ?? '';
  }

  static Future<void> saveUserEmail(String email) async {
    await _sharedPref.setString('user_email', email);
  }

  static String getUserEmail() {
    return _sharedPref.getString('user_email') ?? '';
  }

  static Future<void> saveUserImage(String image) async {
    await _sharedPref.setString('user_image', image);
  }

  static String getUserImage() {
    return _sharedPref.getString('user_image') ?? '';
  }

  static Future<void> saveOTP(String otp) async {
    await _sharedPref.setString('otp', otp);
  }

  static String getOtp() {
    return _sharedPref.getString('otp') ?? '';
  }

  static Future<void> saveCurrency(String currency) async {
    await _sharedPref.setString('currency', currency);
  }

  static String getCurrency() {
    return _sharedPref.getString('currency') ?? '';
  }

  static Future<void> saveAccountBalance(String balance) async {
    await _sharedPref.setString('balance', balance);
  }

  static String getBalance() {
    return _sharedPref.getString('balance') ?? '';
  }

  static Future<void> saveSelectedAccountId(String accountId) async {
    await _sharedPref.setString('selected_account_id', accountId);
  }

  static String getSelectedAccountId() {
    return _sharedPref.getString('selected_account_id') ?? '';
  }
}