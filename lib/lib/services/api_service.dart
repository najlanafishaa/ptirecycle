import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Ganti dengan URL server Anda
  // Untuk localhost di emulator: 10.0.2.2 (Android) atau localhost (iOS)
  static const String baseUrl = 'http://10.0.2.2/recycle-connect-api';
  static String? _token;

  static Future<void> initToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    _token = token;
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _token = null;
  }

  static Map<String, String> get _headers {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // ==================== AUTH APIs ====================
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ==================== TRANSACTION APIs ====================
  static Future<Map<String, dynamic>> createTransaction(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getTransactions({String? status}) async {
    String url = '$baseUrl/transactions';
    if (status != null) {
      url += '?status=$status';
    }
    final response = await http.get(Uri.parse(url), headers: _headers);
    return _handleResponse(response)['data'] ?? [];
  }

  static Future<Map<String, dynamic>> getTransactionDetail(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ==================== WASTE PRICES APIs ====================
  static Future<List<dynamic>> getWastePrices() async {
    final response = await http.get(
      Uri.parse('$baseUrl/waste-prices'),
      headers: _headers,
    );
    return _handleResponse(response)['data'] ?? [];
  }

  static Future<List<dynamic>> getTrendingWastePrices() async {
    final response = await http.get(
      Uri.parse('$baseUrl/waste-prices/trending'),
      headers: _headers,
    );
    return _handleResponse(response)['data'] ?? [];
  }

  // ==================== WITHDRAWAL APIs ====================
  static Future<Map<String, dynamic>> createWithdrawal(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/withdrawals'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getWithdrawals() async {
    final response = await http.get(
      Uri.parse('$baseUrl/withdrawals'),
      headers: _headers,
    );
    return _handleResponse(response)['data'] ?? [];
  }

  // ==================== STATISTICS APIs ====================
  static Future<Map<String, dynamic>> getTransactionStatistics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/statistics'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getWithdrawalStatistics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/withdrawals/stats'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ==================== HELPER METHOD ====================
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      // Token expired, redirect to login
      removeToken();
      throw Exception('Session expired. Please login again.');
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ?? 'Failed to load data: ${response.statusCode}',
      );
    }
  }
}
