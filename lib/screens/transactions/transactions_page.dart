import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:haoshengyi_jzzs_app/constants/app_constants.dart';
import 'package:haoshengyi_jzzs_app/providers/transaction_provider.dart';
import 'package:haoshengyi_jzzs_app/utils/format_util.dart';
import 'package:haoshengyi_jzzs_app/utils/toast_util.dart';
import 'package:haoshengyi_jzzs_app/theme/app_theme.dart';
import 'package:haoshengyi_jzzs_app/models/transaction_model.dart';
import 'package:haoshengyi_jzzs_app/screens/home/main_screen.dart';
import 'package:haoshengyi_jzzs_app/screens/transactions/transaction_form_screen.dart';

// 导入分离的组件
import 'widgets/transaction_item.dart';
import 'widgets/filter_bar.dart';
import 'widgets/month_selector.dart';
import 'widgets/calendar_dialog.dart';
import 'widgets/empty_state.dart';
import 'delegates/sliver_delegates.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({Key? key}) : super(key: key);

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _typeFilter = 'all';
  String _sortBy = FilterBar.defaultSortBy;
  bool _sortAsc = FilterBar.defaultSortAsc;
  bool _showSearchBar = false;
  String _searchQuery = '';
  List<String> _availableMonths = [];
  String? _selectedMonth;
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  // 加载初始数据
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<TransactionProvider>(context, listen: false);

      // 获取月份列表
      _availableMonths = provider.availableMonths;
      if (_availableMonths.isEmpty) {
        // 如果月份列表为空，初始化数据
        await provider.initializeData();
        _availableMonths = provider.availableMonths;
      }

      // 初始化加载当前月份的交易记录
      final now = DateTime.now();
      final currentMonth =
          "${now.year}年${now.month.toString().padLeft(2, '0')}月";

      // 加载当前月份数据
      await provider.getTransactionsByMonth(currentMonth);

      // 默认选中当前月份
      setState(() {
        if (_availableMonths.contains(currentMonth)) {
          _selectedMonth = currentMonth;
        } else if (_availableMonths.isNotEmpty) {
          _selectedMonth = _availableMonths.last;
        } else {
          // 如果生成的月份列表为空，直接使用当前月份
          _selectedMonth = currentMonth;
          _availableMonths.add(currentMonth);
        }
      });
    } catch (e) {
      print('初始化数据加载失败: $e');
      ToastUtil.showError('数据加载失败');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onMonthSelected(String month) {
    print("选择月份: $month");

    // 如果正在加载或者选择的是当前月份，则不重复加载
    if (_isLoading || month == _selectedMonth) return;

    setState(() {
      _selectedMonth = month;
      _isLoading = true;
    });

    final provider = Provider.of<TransactionProvider>(context, listen: false);

    // 加载指定月份的数据
    provider.getTransactionsByMonth(month).then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ToastUtil.showSuccess('已加载 $month 的交易数据');
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ToastUtil.showError('加载交易数据失败');
        print('错误详情: $error');
      }
    });
  }

  void _onDaySelected(DateTime day) {
    print("选择日期: ${FormatUtil.formatDate(day)}");
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final formattedDate = FormatUtil.formatDate(day);

    // 获取选中日期的交易记录
    provider.getTransactionsByDate(formattedDate).then((_) {
      if (mounted) {
        // 刷新UI以显示选中日期的交易
        setState(() {
          _isLoading = false;

          // 确保显示正确的月份
          final month = "${day.year}年${day.month.toString().padLeft(2, '0')}月";
          if (_availableMonths.contains(month)) {
            _selectedMonth = month;
          }
        });

        // 显示成功提示
        ToastUtil.showSuccess('已加载 ${FormatUtil.formatDate(day)} 的交易数据');
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ToastUtil.showError('加载交易数据失败: $error');
      }
    });
  }

  void _showCalendarPickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CalendarDialog(
          onDaySelected: _onDaySelected,
          focusedDay: _parseDateFromSelectedMonth(),
        );
      },
    );
  }

  DateTime? _parseDateFromSelectedMonth() {
    if (_selectedMonth == null) return DateTime.now();

    try {
      // 解析月份格式，例如："2025年04月"
      final parts = _selectedMonth!.split('年');
      if (parts.length == 2) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1].replaceAll('月', ''));
        return DateTime(year, month, 15);
      }
    } catch (e) {
      print('解析月份失败: $_selectedMonth, $e');
    }

    return DateTime.now();
  }

  // 刷新交易列表
  Future<void> _refreshTransactions() async {
    print("刷新交易列表");

    // 如果已经在加载中，则不重复请求
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<TransactionProvider>(context, listen: false);

      // 刷新当前数据
      await provider.refreshCurrentData();

      // 更新月份列表
      setState(() {
        _availableMonths = provider.availableMonths;
      });

      ToastUtil.showSuccess('数据已刷新');
    } catch (e) {
      print('刷新交易列表失败: $e');
      ToastUtil.showError('刷新交易列表失败');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    return Future.value(); // 确保返回Future以配合RefreshIndicator
  }

  void _applyFilters(TransactionProvider provider) {
    // 这里应该根据实际的 TransactionProvider 方法来实现过滤
    setState(() {
      // 仅更新状态，实际过滤在 build 时处理
    });
  }

  List<dynamic> _filterTransactions(List<dynamic> transactions) {
    if (transactions.isEmpty) return [];

    // 按类型筛选
    var filtered = transactions.toList();

    // 按交易类型筛选
    if (_typeFilter != 'all') {
      switch (_typeFilter) {
        case 'cash_income':
          filtered = filtered
              .where((t) =>
                  t.classType == AppConstants.cashType &&
                  t.type == AppConstants.incomeType)
              .toList();
          break;
        case 'cash_expense':
          filtered = filtered
              .where((t) =>
                  t.classType == AppConstants.cashType &&
                  t.type == AppConstants.expenseType)
              .toList();
          break;
        case 'asset_income':
          filtered = filtered
              .where((t) =>
                  t.classType == AppConstants.assetType &&
                  t.type == AppConstants.incomeType)
              .toList();
          break;
        case 'asset_expense':
          filtered = filtered
              .where((t) =>
                  t.classType == AppConstants.assetType &&
                  t.type == AppConstants.expenseType)
              .toList();
          break;
      }
    }

    // 按备注搜索
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((t) =>
              t.remark.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // 排序 - 确保使用本地时区进行比较
    filtered.sort((a, b) {
      int result;

      if (_sortBy == 'time') {
        final aTime =
            (FormatUtil.parseDateTime(a.transactionDate) ?? DateTime.now())
                .toLocal();
        final bTime =
            (FormatUtil.parseDateTime(b.transactionDate) ?? DateTime.now())
                .toLocal();
        result = bTime.compareTo(aTime); // 默认时间倒序
      } else {
        // amount
        result = a.amount.compareTo(b.amount);
      }

      return _sortAsc ? result : -result;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 确保错误信息被显示在控制台
    FlutterError.onError = (FlutterErrorDetails details) {
      print('Flutter错误: ${details.exception}');
      print('堆栈信息: ${details.stack}');
      FlutterError.presentError(details);
    };

    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, _) {
        // 安全处理，确保不会有空值异常
        final List<dynamic> safeTransactions =
            transactionProvider.transactions ?? [];
        final isLoading = transactionProvider.isLoading || _isLoading;
        final transactions = _filterTransactions(safeTransactions);

        print('构建交易流水页面，数据条数: ${transactions.length}, 是否加载中: $isLoading');

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: _refreshTransactions,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // 应用栏
                SliverAppBar(
                  expandedHeight: 100.h,
                  floating: true,
                  pinned: true,
                  snap: false,
                  title: const Text('交易记录'),
                  actions: [
                    IconButton(
                      icon: Icon(_showSearchBar ? Icons.close : Icons.search),
                      onPressed: () {
                        setState(() {
                          _showSearchBar = !_showSearchBar;
                          if (!_showSearchBar) {
                            _searchController.clear();
                            _searchQuery = '';
                            setState(() {});
                          }
                        });
                      },
                    ),
                    IconButton(
                      onPressed: _refreshTransactions,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                  bottom: PreferredSize(
                      preferredSize: Size.fromHeight(0), child: Container()),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      padding: EdgeInsets.only(top: 100.h - 10.h),
                      alignment: Alignment.bottomCenter,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.primaryGradientStart,
                            AppTheme.primaryGradientStart,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 搜索栏 - 显示在顶部
                if (_showSearchBar)
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.r, vertical: 8.r),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '搜索交易记录...',
                          prefixIcon:
                              Icon(Icons.search, color: Colors.grey.shade600),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.r, vertical: 10.r),
                        ),
                        style:
                            TextStyle(color: Colors.black87, fontSize: 14.sp),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ),

                // 筛选栏
                SliverToBoxAdapter(
                  child: FilterBar(
                    typeFilter: _typeFilter,
                    sortBy: _sortBy,
                    sortAsc: _sortAsc,
                    onTypeFilterChanged: (String type) {
                      setState(() {
                        _typeFilter = type;
                      });
                      _applyFilters(transactionProvider);
                    },
                    onSortChanged: (String field, bool asc) {
                      setState(() {
                        _sortBy = field;
                        _sortAsc = asc;
                      });
                      _applyFilters(transactionProvider);
                    },
                  ),
                ),

                // 月份选择器
                SliverToBoxAdapter(
                  child: Container(
                    height: 50.h,
                    child: MonthSelector(
                      months: _availableMonths,
                      selectedMonth: _selectedMonth ??
                          (_availableMonths.isNotEmpty
                              ? _availableMonths.last
                              : null),
                      isLoading: _isLoading,
                      onMonthChanged: _onMonthSelected,
                      onCalendarPressed: _showCalendarPickerDialog,
                    ),
                  ),
                ),

                // 加载指示器或空状态或列表内容
                if (isLoading)
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.all(16.r),
                      height: 100.h,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                else if (transactions.isEmpty)
                  SliverFillRemaining(
                    child: EmptyState(
                      title: '没有找到交易记录',
                      description: '尝试更改筛选条件或选择其他月份',
                      icon: Icons.receipt_long_outlined,
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= transactions.length) {
                          return null;
                        }
                        final transaction = transactions[index];
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.r),
                          child: TransactionItem(
                            transaction: transaction,
                            onStatusChanged: () {
                              // 当状态变化时，强制刷新UI
                              setState(() {});
                            },
                          ),
                        );
                      },
                      childCount: transactions.length,
                    ),
                  ),

                // 底部安全区域填充
                SliverToBoxAdapter(
                  child: SizedBox(height: 16.h),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
