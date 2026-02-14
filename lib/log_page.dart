import 'package:flutter/material.dart';
import 'api.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  List<dynamic> logs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

	/// 顯示「會自動消失」的底部提示（SnackBar）。
  void _showErrorSnackBar(String message) {
    // initState 裡 await 之後，widget 可能已被移除；避免對已 dispose 的 context 操作。
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    // 先清掉舊的 SnackBar，避免連續錯誤時堆疊。
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5), // 一段時間後自動消失
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 從 API 載入資料。
  Future<void> _loadLogs() async {
    // 進入載入狀態：觸發 UI 顯示 CircularProgressIndicator。
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final data = await GetData.fetchData();

      // await 結束後要再檢查 mounted，避免 setState 在 dispose 後被呼叫。
      if (mounted) {
        setState(() {
          //logs = _fakeLogs();
          logs = data;
        });
      }
    } catch (e) {
      // 任何例外都視為載入失敗：
      // - 畫面會停止 loading
      // - 底部跳出 SnackBar 顯示錯誤原因
      _showErrorSnackBar(
        '載入失敗：${e.toString().replaceAll("Exception:", "")}，5秒後將自動重試',
      );
      // 5秒後自動重試載入。
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          _loadLogs();
        }
      });
    } finally {
      // 不管成功或失敗，最後都要關掉 loading。
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildHeaderRow(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final dividerColor = onSurface.withAlpha((0.18 * 255).round());

    Widget cell(String text, {int flex = 2, TextAlign align = TextAlign.center}) {
      return Expanded(
        flex: flex,
        child: Text(
          text,
          textAlign: align,
          style:
              theme.textTheme.titleSmall?.copyWith(
                color: onSurface,
                fontWeight: FontWeight.bold,
              ) ??
              TextStyle(color: onSurface, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Container(
      color: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          cell('日期', flex: 2),
          const SizedBox(width: 12),
          Align(
            alignment: Alignment.center,
            child: Container(width: 1, height: 18, color: dividerColor),
          ),
          const SizedBox(width: 12),
          cell('內容', flex: 4),
          const SizedBox(width: 12),
          Align(
            alignment: Alignment.center,
            child: Container(width: 1, height: 18, color: dividerColor),
          ),
          const SizedBox(width: 12),
          cell('股數', flex: 2),
          const SizedBox(width: 12),
          Align(
            alignment: Alignment.center,
            child: Container(width: 1, height: 18, color: dividerColor),
          ),
          const SizedBox(width: 12),
          cell('金額', flex: 2),
        ],
      ),
    );
  }

  Widget _buildLogRow(BuildContext context, dynamic log, int index) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    final recordDate = log['record_date']?.toString().trim() ?? '';
    final info = log['info']?.toString().trim() ?? '';
    final stockAmount = log['stock_amount']?.toString().trim() ?? '';
    final String balance;

    if ( log['balance'] > 0 ){
      balance = "+${log['balance'].toString().trim()}";
    }else if ( log['balance'] < 0 ){
      balance = log['balance'].toString().trim();
    }else{
      balance = 0.toString().trim();
    }

    Widget cell(
      String text, {
      int flex = 2,
      TextAlign align = TextAlign.center,
      Color? color,
    }) {
      return Expanded(
        flex: flex,
        child: Text(
          text.isEmpty ? '-' : text,
          textAlign: align,
          style:
              theme.textTheme.bodyMedium?.copyWith(color: color ?? onSurface) ??
              TextStyle(color: color ?? onSurface),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    }

    return InkWell(
      onTap: () {
        _openEditDialog(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            cell(recordDate, flex: 2, color: Colors.white),
            const SizedBox(width: 12),
            cell(
              info.isEmpty ? 'Item $index' : info,
              flex: 4,
              color: Colors.white,
              align: TextAlign.left
            ),
            const SizedBox(width: 12),
            cell(stockAmount, flex: 2, color: Colors.white),
            const SizedBox(width: 12),
            cell(balance, flex: 2, color: balance[0] == '+' ? Colors.red : balance[0] == '-' ? Colors.green : Colors.white),
          ],
        ),
      ),
    );
  }

  

  

  Future<void> _openEditDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return const ConfirmDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      appBar: AppBar(elevation: 0, title: const Text('記帳app')),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderRow(context),
            const Divider(height: 1),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return _buildLogRow(context, log, index);
                      },
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConfirmDialog extends StatefulWidget{
	const ConfirmDialog({super.key});

	@override
	State<ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<ConfirmDialog>{
	@override
  Widget build(BuildContext context) {
		return Dialog();
	}
}