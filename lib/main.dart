import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'API.dart';

void main() async {
  // 因為 main() 內有 await（dotenv.load），先確保 Flutter 的 binding 已初始化。
  // 這是 Flutter 官方建議的寫法，避免某些平台上出現初始化時序問題。
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        scaffoldBackgroundColor: Color.fromARGB(255, 31, 31, 31),
        colorScheme: ColorScheme.fromSeed(
          onSurface: Color.fromARGB(255, 187, 187, 187),
          seedColor: const Color.fromARGB(255, 0, 0, 0),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF151515),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color.fromARGB(255, 187, 187, 187),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        listTileTheme: const ListTileThemeData(
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 16),
          textColor: Colors.white,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Color.fromARGB(255, 187, 187, 187)),
        ),
      ),

      home: const LogPage(),
    );
  }
}

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

  /// 從 API 載入資料。
  ///
  /// 我們做了兩件事：
  /// 1) 開始載入前把 isLoading 設為 true，UI 就會顯示中間的圈圈
  /// 2) 用 try/catch 捕捉失敗，顯示 SnackBar 告訴使用者原因
  Future<void> _loadLogs() async {
    // 進入載入狀態：觸發 UI 顯示 CircularProgressIndicator。
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final data = await getData.fetchData();

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
      balance = "${log['balance'].toString().trim()}";
    }else{
      balance = 0.toString().trim();
    }
    //final balance = log['balance']?.toString().trim() ?? '';

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

  /// 顯示「會自動消失」的底部提示（SnackBar）。
  ///
  /// 為什麼用 ScaffoldMessenger：
  /// - SnackBar 必須由 Scaffold 的 messenger 顯示
  /// - 就算你在不同 widget tree 也能穩定顯示
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

  

  Future<void> _openEditDialog(BuildContext context) async {
    await showDialog<_ConfirmEditResult>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return const ConfirmEditDialog(title: '確認修改');
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

enum _ConfirmEditTab { tab1, tab2, tab3 }

class _ConfirmEditResult {
  const _ConfirmEditResult({required this.tab, required this.confirmed});

  final _ConfirmEditTab tab;
  final bool confirmed;
}

class ConfirmEditDialog extends StatefulWidget {
  const ConfirmEditDialog({super.key, required this.title});

  final String title;

  @override
  State<ConfirmEditDialog> createState() => _ConfirmEditDialogState();
}

class _ConfirmEditDialogState extends State<ConfirmEditDialog> {
  _ConfirmEditTab _tab = _ConfirmEditTab.tab1;

  // 整個表單的key
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 單一個欄位的key
  final _fieldKeyTab1 = GlobalKey<FormFieldState<String>>();
  final _fieldKeyTab2A = GlobalKey<FormFieldState<String>>();
  final _fieldKeyTab2B = GlobalKey<FormFieldState<String>>();
  final _fieldKeyTab3 = GlobalKey<FormFieldState<String>>();

  final _textControllerTab1 = TextEditingController();
  final _textControllerTab2A = TextEditingController();
  final _textControllerTab2B = TextEditingController();
  final _textControllerTab3 = TextEditingController();

  final _textFocusNodeTab1 = FocusNode();
  final _textFocusNodeTab2A = FocusNode();
  final _textFocusNodeTab2B = FocusNode();
  final _textFocusNodeTab3 = FocusNode();
  bool _enableAutovalidate = false;

  @override
  void dispose() {
    _textControllerTab1.dispose();
    _textControllerTab2A.dispose();
    _textControllerTab2B.dispose();
    _textControllerTab3.dispose();
    _textFocusNodeTab1.dispose();
    _textFocusNodeTab2A.dispose();
    _textFocusNodeTab2B.dispose();
    _textFocusNodeTab3.dispose();
    super.dispose();
  }

  bool _containsSpecialSymbol(String value) {
    // 符合多數常見「特殊符號」的集合（不含英數與空白）。
    final regExp = RegExp("[!@#\\\$%^&*(),.?\":{}|<>_\\\\/\\[\\];'\"`~+=-]");
    return regExp.hasMatch(value);
  }

  // 檢查輸入格式的函式
  String? _validateInput(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) {
      return '輸入不能為空';
    }
    if (value.length < 3) {
      return '長度不能小於3';
    }
    if (!_containsSpecialSymbol(value)) {
      return '必須包含特殊符號';
    }
    return null;
  }

  String _labelForFieldIndex(int index) {
    switch (_tab) {
      case _ConfirmEditTab.tab1:
        return '請輸入文字1';
      case _ConfirmEditTab.tab2:
        return index == 0 ? '請輸入文字2' : '請輸入文字3';
      case _ConfirmEditTab.tab3:
        return '請輸入文字4';
    }
  }

  ///
  Widget _buildInputField({
    required GlobalKey<FormFieldState<String>> fieldKey,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
    required ColorScheme colorScheme,
    required Color onSurface,
    required Color borderColor,
  }) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      validator: _validateInput,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: onSurface),
        hintText: '至少3個字，且包含特殊符號',
        hintStyle: TextStyle(color: onSurface.withAlpha((0.6 * 255).round())),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent),
        ),
      ),
      onTap: () {
        if (!_enableAutovalidate) {
          setState(() {
            _enableAutovalidate = true;
          });
        }
        fieldKey.currentState?.validate();
      },
      onChanged: (_) {
        if (_enableAutovalidate) {
          fieldKey.currentState?.validate();
        }
      },
      textInputAction: () {
        if (fieldKey == _fieldKeyTab2B) {
          return TextInputAction.done;
        } else {
          return TextInputAction.next;
        }
      }(),
      onFieldSubmitted: (_) {
        fieldKey.currentState?.validate();
      },
    );
  }

  ///
  List<({TextEditingController controller, FocusNode focusNode})>
  _currentFields() {
    switch (_tab) {
      case _ConfirmEditTab.tab1:
        return [
          (controller: _textControllerTab1, focusNode: _textFocusNodeTab1),
        ];
      case _ConfirmEditTab.tab2:
        return [
          (controller: _textControllerTab2A, focusNode: _textFocusNodeTab2A),
          (controller: _textControllerTab2B, focusNode: _textFocusNodeTab2B),
        ];
      case _ConfirmEditTab.tab3:
        return [
          (controller: _textControllerTab3, focusNode: _textFocusNodeTab3),
        ];
    }
  }

  void _focusFirstInvalidField() {
    for (final field in _currentFields()) {
      final error = _validateInput(field.controller.text);
      if (error != null) {
        field.focusNode.requestFocus();
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    final borderColor = onSurface.withAlpha((0.35 * 255).round());

    return Dialog(
      backgroundColor:
          theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SizedBox(
          height: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    //color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Center(
                  child: ToggleButtons(
                    isSelected: [
                      _tab == _ConfirmEditTab.tab1,
                      _tab == _ConfirmEditTab.tab2,
                      _tab == _ConfirmEditTab.tab3,
                    ],
                    onPressed: (index) {
                      FocusScope.of(context).unfocus();
                      final nextTab = _ConfirmEditTab.values[index];
                      setState(() {
                        // 透過替換 GlobalKey 讓 Form/Field state 重建，清除錯誤顯示；
                        // controller 仍保留，因此每個 tab 的文字可以保留。
                        _formKey = GlobalKey<FormState>();
                        _tab = nextTab;
                        _enableAutovalidate = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    borderColor: borderColor,
                    selectedBorderColor: Color.fromARGB(255, 70, 70, 70),
                    fillColor: Color.fromARGB(255, 70, 70, 70),
                    selectedColor: colorScheme.onPrimary,
                    color: onSurface,
                    constraints: const BoxConstraints(
                      minHeight: 44,
                      minWidth: 96,
                    ),
                    children: const [Text('刪單'), Text('改量'), Text('改價')],
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _enableAutovalidate
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildInputField(
                            fieldKey: switch (_tab) {
                              _ConfirmEditTab.tab1 => _fieldKeyTab1,
                              _ConfirmEditTab.tab2 => _fieldKeyTab2A,
                              _ConfirmEditTab.tab3 => _fieldKeyTab3,
                            },
                            controller: _currentFields()[0].controller,
                            focusNode: _currentFields()[0].focusNode,
                            labelText: _labelForFieldIndex(0),
                            colorScheme: colorScheme,
                            onSurface: onSurface,
                            borderColor: borderColor,
                          ),
                          if (_tab == _ConfirmEditTab.tab2) ...[
                            const SizedBox(height: 12),
                            _buildInputField(
                              fieldKey: _fieldKeyTab2B,
                              controller: _currentFields()[1].controller,
                              focusNode: _currentFields()[1].focusNode,
                              labelText: _labelForFieldIndex(1),
                              colorScheme: colorScheme,
                              onSurface: onSurface,
                              borderColor: borderColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              SizedBox(
                height: 64,
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(
                              _ConfirmEditResult(tab: _tab, confirmed: false),
                            );
                          },
                          child: const Text('取消'),
                        ),
                      ),
                    ),
                    Container(width: 1, color: borderColor),
                    Expanded(
                      child: SizedBox(
                        height: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            if (!_enableAutovalidate) {
                              setState(() {
                                _enableAutovalidate = true;
                              });
                            }
                            final isValid =
                                _formKey.currentState?.validate() ?? false;
                            if (!isValid) {
                              _focusFirstInvalidField();
                              return;
                            }

                            Navigator.of(context).pop(
                              _ConfirmEditResult(tab: _tab, confirmed: true),
                            );
                          },
                          child: const Text('確定'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
