import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GetData{
    static String? baseUrl = dotenv.env['BASE_URL'];

    static Future<void> createData(Map<String, dynamic> data) async {
        final url = Uri.parse("$baseUrl/data");
        
        try{
            final response = await http.post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: json.encode(data),
            );
        
            if ( response.statusCode != 201 ) {
                throw Exception('無法送出資料，狀態碼: ${response.statusCode}');
            }

        }catch(e){
            throw Exception('$e');
        }
    }

    static Future<List<dynamic>> fetchData() async {
        final url = Uri.parse("$baseUrl/data?user_id=1");
        
        try{
            final response = await http.get(url);
        
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
                headers: {'Content-Type': 'application/json'},
                body: json.encode(data),
            );
        
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
            final response = await http.delete(url);
        
            if ( response.statusCode != 200 ) {
                throw Exception('無法刪除資料，狀態碼: ${response.statusCode}');
            }

        }catch(e){
            throw Exception('$e');
        }
    }
}