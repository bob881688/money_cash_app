import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api.dart';
import 'stock_search.dart';
import 'login_page.dart';

abstract class _DisplayItem {
  const _DisplayItem();
}

class _DateHeaderItem extends _DisplayItem {
  const _DateHeaderItem(this.date);
  final String date;
}

class _LogRowItem extends _DisplayItem {
  const _LogRowItem(this.log, this.no);
  final dynamic log;
  final int no; // 同一天內的序號（最新=1）
}

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  List<dynamic> logs = [];
  var displayItems = <_DisplayItem>[];
  bool isLoading = true;

  int totalBalance = 0;

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
          displayItems = _buildDisplayItems(logs);
        });
      }
    } catch (e) {
      if (e is AuthRequiredException) {
        if (!mounted) return;
        _showErrorSnackBar(e.toString());
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
        return;
      }

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

    if (logs.isNotEmpty) {
      totalBalance = 0;

      for (dynamic log in logs) {
        totalBalance += (log["balance"] as num).toInt();
      }
    }
  }

  List<_DisplayItem> _buildDisplayItems(List<dynamic> sourceLogs) {
    final items = <_DisplayItem>[];

    String? currentDate;
    var dayNo = 0;

    for (final log in sourceLogs) {
      final dateKey = log["record_date"]?.toString().trim() ?? '';

      if (currentDate != dateKey) {
        currentDate = dateKey;
        dayNo = 0;
        items.add(_DateHeaderItem(dateKey.isEmpty ? '-' : dateKey));
      }

      dayNo += 1;
      items.add(_LogRowItem(log, dayNo));
    }

    return items;
  }

  Widget _buildTotalBalanceRow(BuildContext context, int balance) {
    final balanceDisplay = (balance > 0)
        ? "+$balance"
        : (balance < 0)
        ? "$balance"
        : "0";
    final displayColor = (balance > 0)
        ? Colors.red
        : (balance < 0)
        ? Colors.green
        : Colors.white;
    final backgroundColor =
        Theme.of(context).appBarTheme.backgroundColor ?? Colors.black;

    return Container(
      height: 62,
      width: double.infinity,
      color: backgroundColor,
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor
              .withRed(60)
              .withGreen(60)
              .withBlue(60)
              .withAlpha(60),
          border: Border.all(color: backgroundColor.withAlpha(100)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text("目前總損益:", style: TextStyle(color: Colors.grey, fontSize: 11)),
            Text(
              balanceDisplay,
              style: TextStyle(
                color: displayColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final dividerColor = onSurface.withAlpha((0.18 * 255).round());

    Widget cell(
      String text, {
      int flex = 2,
      TextAlign align = TextAlign.center,
    }) {
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
          cell('編號', flex: 2),
          const SizedBox(width: 12),
          Align(
            alignment: Alignment.center,
            child: Container(width: 1, height: 18, color: dividerColor),
          ),
          const SizedBox(width: 12),
          cell('內容', flex: 8),
          const SizedBox(width: 12),
          Align(
            alignment: Alignment.center,
            child: Container(width: 1, height: 18, color: dividerColor),
          ),
          const SizedBox(width: 12),
          cell('股數', flex: 3),
          const SizedBox(width: 12),
          Align(
            alignment: Alignment.center,
            child: Container(width: 1, height: 18, color: dividerColor),
          ),
          const SizedBox(width: 12),
          cell('金額', flex: 3),
        ],
      ),
    );
  }

  Widget _buildLogRow(BuildContext context, dynamic log, int no) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    final recordDate = log['record_date']?.toString().trim() ?? '';
    final info = log['info']?.toString().trim() ?? '';
    final stockAmount = log['stock_amount']?.toString().trim() ?? '';
    final String balance;

    if (log['balance'] > 0) {
      balance = "+${log['balance'].toString().trim()}";
    } else if (log['balance'] < 0) {
      balance = log['balance'].toString().trim();
    } else {
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
        _openDialog(context: context, log: log, mode: "edit");
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            cell(no.toString(), flex: 2, color: Colors.white),
            const SizedBox(width: 12),
            cell(
              info.isEmpty ? '-' : info,
              flex: 8,
              color: Colors.white,
              align: TextAlign.left,
            ),
            const SizedBox(width: 12),
            cell(
              stockAmount == '0' ? '-' : stockAmount,
              flex: 3,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            cell(
              balance,
              flex: 3,
              color: balance[0] == '+'
                  ? Colors.red
                  : balance[0] == '-'
                  ? Colors.green
                  : Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeaderRow(BuildContext context, String dateText) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      width: double.infinity,
      color: const Color.fromARGB(255, 13, 39, 52),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      alignment: Alignment.centerLeft,
      child: Text(
        dateText,
        style: theme.textTheme.titleSmall?.copyWith(
              color: onSurface,
              fontWeight: FontWeight.bold,
            ) ??
            TextStyle(color: onSurface, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Future<void> _openDialog({
    required BuildContext context,
    dynamic log,
    required String mode,
  }) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        // 在 Dialog route 內提供自己的 ScaffoldMessenger/Scaffold，
        // 讓 ConfirmDialog 內的 SnackBar 顯示在同一層（不會跑到背後的頁面）。
        return ConfirmDialog(log: log, mode: mode);
      },
    );

    // 若 Dialog 內有成功送出修改，回來後刷新資料。
    if (changed == true) {
      await _loadLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      appBar: AppBar(
        elevation: 0,
        title: const Text('記帳app'),
        actions: [
          IconButton(
            onPressed: () {
              _loadLogs();
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              _openDialog(context: context, mode: "new");
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTotalBalanceRow(context, totalBalance),
            _buildHeaderRow(context),
            const Divider(height: 1),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: displayItems.length,
                      itemBuilder: (context, index) {
                        final log = displayItems[index];

                        if ( log is _DateHeaderItem ){
                          return _buildDateHeaderRow(context, log.date);
                        }

                        final logRow = log as _LogRowItem;
                        return _buildLogRow(context, logRow.log, logRow.no);
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


class ConfirmDialog extends StatefulWidget {
  const ConfirmDialog({super.key, this.log, required this.mode});

  final dynamic log;
  final String mode;

  @override
  State<ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<ConfirmDialog> with WidgetsBindingObserver {
  int _tab = 0;
  String? _tradeMethod;

  final _formKey = GlobalKey<FormState>();

  StockItem? selectedStock;

  final test = FocusNode();

  final _stockSearchFocusNode = FocusNode();
  final _stockAmountFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();
  final _balanceFocusNode = FocusNode();

  FocusNode? _lastInputFocusNode;
  bool _restoreKeyboardOnResume = false;
  bool _keyboardWasVisible = false;
  bool _isLeavingForeground = false;

  final _stockNumberController = SearchController();
  final _stockAmountController = TextEditingController();
  final _contentController = TextEditingController();
  final _balanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    StockSearch.instance.ensureLoaded();

    void trackFocus(FocusNode node) {
      node.addListener(() {
        if (node.hasFocus) {
          _lastInputFocusNode = node;
        }
      });
    }

    trackFocus(_stockSearchFocusNode);
    trackFocus(_stockAmountFocusNode);
    trackFocus(_contentFocusNode);
    trackFocus(_balanceFocusNode);

    if (widget.mode == "edit" && widget.log != null) {
      _stockAmountController.text = widget.log["stock_amount"].toString();
      _contentController.text = widget.log["info"].toString();
      _balanceController.text = widget.log["balance"].toString();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _isLeavingForeground = true;
        // 如果切到背景前正在輸入，記下來：回到前景時自動恢復鍵盤。
        _restoreKeyboardOnResume =
            _keyboardWasVisible &&
            (_lastInputFocusNode?.hasFocus ?? false);
        break;
      case AppLifecycleState.resumed:
        _isLeavingForeground = false;
        if (!_restoreKeyboardOnResume) return;

        final node = _lastInputFocusNode;
        if (node == null || !node.canRequestFocus) return;

        // 確保畫面已經穩定，然後再叫出鍵盤。
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          // 重新取得 focus，並嘗試叫出系統鍵盤。
          FocusScope.of(context).requestFocus(node);
          SystemChannels.textInput.invokeMethod('TextInput.show');
        });

        _restoreKeyboardOnResume = false;
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;

    // 切到背景時，系統常會先把鍵盤收起來再送出 paused/hidden；
    // 若我們在「離開前景」期間更新鍵盤狀態，會把原本的 true 覆蓋成 false，導致回來無法恢復。
    if (_isLeavingForeground) return;

    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final bottomInset = view.viewInsets.bottom / view.devicePixelRatio;
    _keyboardWasVisible = bottomInset > 0;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    _stockNumberController.dispose();
    _stockAmountController.dispose();
    _contentController.dispose();
    _balanceController.dispose();
    test.dispose();
    _stockSearchFocusNode.dispose();
    _stockAmountFocusNode.dispose();
    _contentFocusNode.dispose();
    _balanceFocusNode.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;

    final dialogHeight =
        ((MediaQuery.of(context).size.height - viewInsets.bottom - 48.0).clamp(
          260.0,
          510.0,
        )).toDouble();

    return Dialog(
      backgroundColor: theme.appBarTheme.backgroundColor,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SizedBox(
          height: dialogHeight,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                    child: Text(
                      widget.mode == "edit" ? "確認修改" : "新增記錄",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                widget.mode == "edit"
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Center(
                        child: ToggleButtons(
                          isSelected: [_tab == 0, _tab == 1],
                          onPressed: (index) {
                            setState(() {
                              _tab = index;
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          borderColor: theme.colorScheme.onSurface.withAlpha((0.35 * 255).round()),
                          selectedColor: theme.colorScheme.onPrimary,
                          selectedBorderColor: Color.fromARGB(
                            255,
                            70,
                            70,
                            70,
                          ),
                          fillColor: Color.fromARGB(255, 70, 70, 70),
                          color: theme.colorScheme.onSurface,
                          splashColor: Color.fromARGB(255, 70, 70, 70),
                          constraints: const BoxConstraints(
                            minHeight: 44,
                            minWidth: 96,
                          ),
                          children: const [Text("修改"), Text("刪除")],
                        ),
                      ),
                    )
                  : Container(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_tab == 0) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                            child: SizedBox(
                              width: 180,
                              child: DropdownButtonFormField(
                                focusNode: test,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '請選擇交易類別';
                                  }
                                  return null;
                                },
                                hint: Text(
                                  "(選擇交易類別)",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                dropdownColor: const Color.fromARGB(255, 37, 37, 37),
                                disabledHint: Text(
                                  "功能開發中",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: "股票買入",
                                    child: Text(
                                      "股票買入",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: "股票賣出",
                                    child: Text(
                                      "股票賣出",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: "一般收入",
                                    child: Text(
                                      "一般收入",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: "一般支出",
                                    child: Text(
                                      "一般支出",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (mounted) {
                                    setState(() {
                                      _tradeMethod = value?.toString();
                                      if (_tradeMethod != "股票買入" &&
                                          _tradeMethod != "股票賣出") {
                                        selectedStock = null;
                                        _stockNumberController.clear();
                                        _stockAmountController.clear();
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                                child: SizedBox(
                                  height: 48,
                                  width: 180,
                                  child: SearchAnchor(
                                    searchController: _stockNumberController,
                                    isFullScreen: false,
                                    viewTrailing: [
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            selectedStock = null;
                                            _stockNumberController.clear();
                                          });
                                        },
                                        icon: Icon(Icons.close),
                                      ),
                                    ],
                                    viewOnClose: () {
                                      if (selectedStock != null) {
                                        setState(() {
                                          _stockNumberController.text = selectedStock!.symbol; // 顯示在備註欄；你真正存到記帳資料應該是 item.symbol
                                        });
                                      }
                                    },
                                    builder: (context, controller) {
                                      return SearchBar(
                                        controller: controller,
                                        focusNode: _stockSearchFocusNode,
                                        padding: const WidgetStatePropertyAll(
                                          EdgeInsets.symmetric(horizontal: 12.0),
                                        ),
                                        onTap: controller.openView,
                                        onChanged: (_) => controller.openView(),
                                        leading: const Icon(Icons.search, size: 15,),
                                        hintText: '輸入代號或名稱',
                                      );
                                    },
                                    suggestionsBuilder: (context, controller) {
                                      final q = controller.text.trim();
                                      if (q.isEmpty) return [];
                                      final isDigits = RegExp(r'^\\d+$').hasMatch(q);

                                      // 避免名稱 1 個字就掃 3 萬筆（例如「大」）
                                      if (!isDigits && q.length < 2) {
                                        return [
                                          ListTile(title: Text('請至少輸入2個字'))
                                        ];
                                      }

                                      final results = StockSearch.instance.search(q, limit: 20);

                                      if (results.isEmpty) {
                                        return [
                                          ListTile(title: Text('找不到符合的股票'))
                                        ];
                                      }

                                      return results.map((item) {
                                        return ListTile(
                                          title: Text(item.label),
                                          // "0050 元大台灣50"
                                          onTap: () {
                                            setState(() {
                                              selectedStock = item;
                                              _contentController.text = item.name;
                                              // 顯示在備註欄；你真正存到記帳資料應該是 item.symbol
                                            });
                                            // SearchBar 顯示 label；你真正存到記帳資料應該是 item.symbol
                                            controller.closeView(item.symbol);
                                          },
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                                  child: TextFormField(
                                    controller: _stockAmountController,
                                    focusNode: _stockAmountFocusNode,
                                    decoration: InputDecoration(
                                      labelText: "股數",
                                      labelStyle: TextStyle(color: Colors.grey),
                                      prefixIcon: Icon(
                                        Icons.confirmation_number,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(signed: false, decimal: false),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                            child: SizedBox(
                              width: 270,
                              child: TextFormField(
                                controller: _contentController,
                                focusNode: _contentFocusNode,
                                decoration: InputDecoration(
                                  labelText: "備註",
                                  labelStyle: TextStyle(color: Colors.grey),
                                  prefixIcon: Icon(
                                    Icons.edit_note,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                ),
                                keyboardType: TextInputType.text,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                            child: SizedBox(
                              width: 150,
                              child: TextFormField(
                                controller: _balanceController,
                                focusNode: _balanceFocusNode,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return '請輸入金額';
                                  }
                                  if (int.tryParse(value.trim()) == null) {
                                    return '金額必須是數字';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: "金額",
                                  labelStyle: TextStyle(color: Colors.grey),
                                  prefixIcon: Icon(
                                    Icons.attach_money,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                ),
                                keyboardType: TextInputType.numberWithOptions(
                                  signed: false,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ] else ...[
                          SizedBox(
                            height: 260,
                            child: Center(
                              child: Text(
                                "確定要刪除嗎?",
                                style: TextStyle(fontSize: 25, color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                SizedBox(
                  height: 60,
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(
                                //_ConfirmEditResult(tab: _tab, confirmed: false),
                              );
                            },
                            child: const Text('取消'),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        color: Color.fromARGB(255, 96, 96, 96),
                      ),
                      Expanded(
                        child: SizedBox(
                          height: double.infinity,
                          child: TextButton(
                            onPressed: () async {
                              if (!_formKey.currentState!.validate()) {
                                return;
                              }

                              final info = (_tradeMethod == "股票買入" || _tradeMethod == "股票賣出")
                                        ? "${_stockNumberController.text} ${_contentController.text}"
                                        : _contentController.text;
                              final stockAmount = int.tryParse(_stockAmountController.text) ?? 0;
                              final balance = (_tradeMethod == "股票買入" || _tradeMethod == "一般支出")
                                          ? -(int.tryParse(_balanceController.text) ?? 0)
                                          : int.tryParse(_balanceController.text) ?? 0;

                              try {
                                widget.mode == "edit"
                                  ? _tab == 0
                                    ? await GetData.editData(
                                        widget.log["log_id"],
                                        {
                                          "info": info,
                                          "stock_amount": stockAmount,
                                          "balance": balance,
                                        },
                                      )
                                    : await GetData.deleteData(
                                        widget.log["log_id"],
                                      )
                                  : await GetData.createData({
                                      "info": info,
                                      "stock_amount": stockAmount,
                                      "balance": balance,
                                    });
                              }catch (e){
                                widget.mode == "edit"
                                  ? _tab == 0
                                    ? _showSnackBar(
                                        "修改失敗: ${e.toString().replaceAll("Exception: ", "")}",
                                      )
                                    : _showSnackBar(
                                        "刪除失敗: ${e.toString().replaceAll("Exception: ", "")}",
                                      )
                                  : _showSnackBar(
                                      "新增失敗: ${e.toString().replaceAll("Exception: ", "")}",
                                    );
                              }

                              // 回傳 true 給外層，表示已成功修改；外層收到後刷新列表。
                              if (!context.mounted) return;
                              Navigator.of(context).pop(true);
                            },
                            child: const Text('確定'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                //Text(selectedStock?.symbol.toString() ?? "未選擇股票")
              ],
            ),
          ),
        ),
      ),
    );
  }
}
