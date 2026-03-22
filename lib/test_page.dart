import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TestPage extends StatefulWidget{
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage>{
	final baseUrl = "https://mis.twse.com.tw/stock/api/getStockInfo.jsp";
	Map<String,dynamic> stock = {};

	@override
  void initState(){
    super.initState();
    fetch(2337);
  }

	Future<void> fetch( int stock_no ) async{
		final url = Uri.parse("$baseUrl?ex_ch=tse_$stock_no.tw&json=1&delay=0&_=1772079689035&lang=zh_tw");
		
		print("重新載入: $stock_no");
		try{
			final response = await http.get(url);

			if ( response.statusCode == 200 ) {
				if (mounted){
					setState(() {
        		stock = json.decode(response.body);
					});
				}
      }else{
        throw Exception('無法取得資料，狀態碼: ${response.statusCode}');
      }
    }catch(e){
			print(e);
    }finally{
			Future.delayed(const Duration(seconds: 5), (){
				fetch(stock_no);
			});
		}
	}

	@override
  Widget build(BuildContext context) {
		final msgArray = stock["msgArray"];
  	final z = (msgArray is List && msgArray.isNotEmpty) ? msgArray[0]["z"] : null;
    return Scaffold(
			body: Center(
				child: Text(z?.toString() ?? "載入中..."),
			),
		);
  }
}