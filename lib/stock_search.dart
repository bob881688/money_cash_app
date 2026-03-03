import 'dart:convert';
import 'package:flutter/services.dart';

class StockItem{
  final String symbol;
  final String name;
  const StockItem(this.symbol, this.name);

  String get label => '$symbol $name';
}

class StockSearch{
  // 確保全 app 只有一份資料，且方便在任何地方使用。
  StockSearch._();
  static final StockSearch instance = StockSearch._();

  bool _loaded = false;
  final List<StockItem> _items = [];

  Future<void> ensureLoaded() async{
    if (_loaded) return;

    final text = await rootBundle.loadString('assets/stocks_chart.txt');
    final lines = const LineSplitter().convert(text);

    for (final line in lines){
      final v = line.trim();
      if (v.isEmpty) continue;

      // 用第一個空白切開：前面代號、後面名稱（名稱裡若還有空白也OK）
      final i = v.indexOf(RegExp(r'\s+'));
      if (i <= 0) continue;

      final symbol = v.substring(0, i).trim();
      final name = v.substring(i).trim();

      final item = StockItem(symbol, name);
      _items.add(item);
    }
    _loaded = true;
  }

  List<StockItem> search(String rawQuery, {int limit = 20}){
    if (!_loaded) throw StateError('StockSearch not loaded; call ensureLoaded()');

    final q = rawQuery.trim();
    if (q.isEmpty) return const [];

    final isDigits = RegExp(r'^\d+$').hasMatch(q);
    final out = <StockItem>[];

    if (isDigits){
      for (final it in _items) {
        if (it.symbol.startsWith(q)) {
          out.add(it);
          if (out.length >= limit) break;
        }
      }
    }else {
      for (final it in _items) {
        if (it.name.contains(q)) {
          out.add(it);
          if (out.length >= limit) break;
        }
      }
    }
    return out;
  }
}