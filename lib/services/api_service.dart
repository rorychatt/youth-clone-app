import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api';
    } else {
      return 'http://127.0.0.1:8080/api';
    }
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
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

  static Future<Map<String, dynamic>> register(
    String email,
    String password,
  ) async {
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
    try {
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
    } on SocketException {
      throw Exception('Cannot sync devices while offline.');
    } catch (e) {
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('ClientException')) {
        throw Exception('Cannot sync devices while offline.');
      }
      rethrow;
    }
  }

  static Future<List<dynamic>> getProviders(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'providers_$userId';

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/junction/providers/$userId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['providers'] != null) {
          final providersList = body['providers'] as List<dynamic>;
          await prefs.setString(cacheKey, jsonEncode(providersList));
          return providersList;
        }
        return [];
      } else {
        throw Exception('Failed to get connected providers');
      }
    } catch (e) {
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        return jsonDecode(cachedData) as List<dynamic>;
      }
      throw Exception('Failed to get connected providers. You are offline.');
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

  static Future<Map<String, dynamic>> updateUserName(
    String userId,
    String name,
  ) async {
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
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'healthMetrics_$userId';

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sync/junction/$userId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        await prefs.setString(cacheKey, jsonEncode(body));
        return body;
      } else {
        throw Exception('Failed to fetch health metrics');
      }
    } catch (e) {
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        return jsonDecode(cachedData);
      }
      throw Exception('Failed to fetch health metrics. You are offline.');
    }
  }

  static Future<List<dynamic>> getHealthHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'healthHistory_$userId';

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sync/junction/$userId/history'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final history = data['history'] ?? [];
        await prefs.setString(cacheKey, jsonEncode(history));
        return history;
      } else {
        throw Exception('Failed to fetch health history');
      }
    } catch (e) {
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        return jsonDecode(cachedData) as List<dynamic>;
      }
      throw Exception('Failed to fetch health history. You are offline.');
    }
  }

  static Future<String> askClaude(String prompt) async {
    final response = await http.post(
      Uri.parse('$baseUrl/insights/claude/ask'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'prompt': prompt}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'] ?? '';
    } else {
      throw Exception('Failed to ask Claude');
    }
  }
}
