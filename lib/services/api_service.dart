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

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login. Check credentials.');
    }
  }

  static Future<Map<String, dynamic>> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to register. Email may already be in use.');
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

  static Future<List<dynamic>> getProviders(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/junction/providers/$userId'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['providers'] != null) {
        return body['providers'] as List<dynamic>;
      }
      return [];
    } else {
      throw Exception('Failed to get connected providers');
    }
  }

  static Future<void> disconnectProvider(String userId, String provider) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/junction/providers/$userId/$provider'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to disconnect provider');
    }
  }

  static Future<Map<String, dynamic>> updateUserName(String userId, String name) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update name');
    }
  }

  static Future<Map<String, dynamic>> getHealthMetrics(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sync/junction/$userId'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch health metrics');
    }
  }
}
