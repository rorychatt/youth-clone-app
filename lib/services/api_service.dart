import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api';
    } else {
      return 'http://127.0.0.1:8080/api';
    }
  }

  static Future<Map<String, dynamic>> login(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login/register');
    }
  }

  static Future<Map<String, dynamic>> getLinkToken(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/junction/link-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get link token');
    }
  }

  static Future<Map<String, dynamic>> syncJunction(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sync/junction'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to sync junction data');
    }
  }
}
