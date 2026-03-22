import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRequiredException implements Exception{
    final String message;
    AuthRequiredException(this.message);
    @override
    String toString() => message;
}

class AuthApi{
    static String? baseUrl = dotenv.env['BASE_URL'];
    static String? accessToken;

    static const _tokenKey = 'access_token';
    static const FlutterSecureStorage _storage = FlutterSecureStorage();

    static Future<void> loadToken() async {
        try{
            final token = await _storage.read(key: _tokenKey);
            if (token != null && token.isNotEmpty) {
                accessToken = token;
            }
        }catch(e){
            throw Exception('$e');
        }
    }

    static Future<void> _saveToken(String token) async {
        try{
            await _storage.write(key: _tokenKey, value: token);
        }catch(e){
            throw Exception('$e');
        }
    }

    static Future<void> logout() async {
        accessToken = null;
        try{
            await _storage.delete(key: _tokenKey);
        }catch(e){
            throw Exception('$e');
        }
    }

    static Future<bool> verifyToken() async {
        final token = accessToken;
        if (token == null || token.isEmpty) {
            return false;
        }

        final url = Uri.parse("$baseUrl/users/me/");
        try{
            final response = await http.get(
                url,
                headers: {
                    'Authorization': 'Bearer $token',
                },
            );

            if (response.statusCode == 200) {
                return true;
            }
            if (response.statusCode == 401) {
                await logout();
                return false;
            }

            return false;
        }catch(_){
            return false;
        }
    }

    static Future<void> login({
        required String username,
        required String password,
    }) async {
        final url = Uri.parse("$baseUrl/token");

        try{
            final response = await http.post(
                url,
                headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                body: {
                    'username': username,
                    'password': password,
                },
            );

            if ( response.statusCode != 200 ) {
                throw Exception('登入失敗，狀態碼: ${response.statusCode}');
            }

            final decoded = json.decode(response.body);
            final token = decoded['access_token']?.toString();
            if (token == null || token.isEmpty) {
                throw Exception('登入失敗：未取得 access_token');
            }

            accessToken = token;
            await _saveToken(token);
        }catch(e){
            throw Exception('$e');
        }
    }
}

class GetData{
    static String? baseUrl = dotenv.env['BASE_URL'];

    static Map<String, String> _authHeader() {
        final token = AuthApi.accessToken;
        if (token == null || token.isEmpty) {
            throw AuthRequiredException('尚未登入，請先登入');
        }
        return {'Authorization': 'Bearer $token'};
    }

    static Future<void> _handleIfUnauthorized(http.Response response) async {
        if (response.statusCode == 401) {
            await AuthApi.logout();
            throw AuthRequiredException('登入已過期，請重新登入');
        }
    }

    static Future<void> createData(Map<String, dynamic> data) async {
        final url = Uri.parse("$baseUrl/data");
        
        try{
            final response = await http.post(
                url,
                headers: {
                    'Content-Type': 'application/json',
                    ..._authHeader(),
                },
                body: json.encode(data),
            );

            await _handleIfUnauthorized(response);
        
            if ( response.statusCode != 201 ) {
                throw Exception('無法送出資料，狀態碼: ${response.statusCode}');
            }

        }catch(e){
            throw Exception('$e');
        }
    }

    static Future<List<dynamic>> fetchData() async {
        final url = Uri.parse("$baseUrl/data");
        
        try{
            final response = await http.get(
                url,
                headers: {
                    ..._authHeader(),
                },
            );

            await _handleIfUnauthorized(response);
        
            if ( response.statusCode == 200 ) {
                return List<dynamic>.from(json.decode(response.body));
            }else{
                throw Exception('無法取得資料，狀態碼: ${response.statusCode}');
            }

        }catch(e){
            throw Exception('錯誤: $e');
        }
    }

    static Future<void> editData(int logId, Map<String, dynamic> data) async {
        final url = Uri.parse("$baseUrl/data/$logId");
        
        try{
            final response = await http.put(
                url,
                headers: {
                    'Content-Type': 'application/json',
                    ..._authHeader(),
                },
                body: json.encode(data),
            );

            await _handleIfUnauthorized(response);
        
            if ( response.statusCode != 200 ) {
                throw Exception('無法送出資料，狀態碼: ${response.statusCode}');
            }

        }catch(e){
            throw Exception('$e');
        }
    }

    static Future<void> deleteData(int logId) async {
        final url = Uri.parse("$baseUrl/data/$logId");
        
        try{
            final response = await http.delete(
                url,
                headers: {
                    ..._authHeader(),
                },
            );

            await _handleIfUnauthorized(response);
        
            if ( response.statusCode != 200 ) {
                throw Exception('無法刪除資料，狀態碼: ${response.statusCode}');
            }

        }catch(e){
            throw Exception('$e');
        }
    }
}