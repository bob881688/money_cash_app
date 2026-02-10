import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class getData{
    static String? baseUrl = dotenv.env['BASE_URL'];

    static Future<List<dynamic>> fetchData() async {
        final url = Uri.parse("$baseUrl/api/data");
        
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
}