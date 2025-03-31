import 'package:flutter/material.dart';
import 'package:haoshengyi_jzzs_app/constants/app_constants.dart';
import 'package:haoshengyi_jzzs_app/models/transaction_model.dart'
    hide Container;
import 'package:haoshengyi_jzzs_app/providers/transaction_provider.dart';
import 'package:haoshengyi_jzzs_app/screens/home/main_screen.dart';
import 'package:haoshengyi_jzzs_app/screens/transactions/transaction_detail_screen.dart';
import 'package:haoshengyi_jzzs_app/theme/app_theme.dart';
import 'package:haoshengyi_jzzs_app/utils/format_util.dart';
import 'package:haoshengyi_jzzs_app/utils/toast_util.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// 交易记录页面
class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage>
    with AutomaticKeepAliveClientMixin {
    bool _isLoading = false;
    List<String> _months = [];
    String? _selectedMonth;

    // 筛选条件
    String _typeFilter = 'all'; // all, income, expense
    String _sortBy = 'time'; // time, amount
    bool _sortAsc = false;

    @override
    bool get wantKeepAlive => true;

    @override
    void initState() {
      super.initState();
      _loadMonths();
  }

  // 加载月份列表（优化后）
  Future<void> _loadMonths() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final transactionProvider = context.read<TransactionProvider>();
      
      // 使用 Provider 的专用方法获取月份（需要先在 TransactionProvider 中添加此方法）
      final months = await transactionProvider.getAvailableMonths();

      // 空数据检查和处理
      if (months.isEmpty) {
        ToastUtil.showInfo('暂无历史月份数据');
        return;
      }

      // 自动选择最新月份
      setState(() {
        _months = months;
        _selectedMonth = months.last;
      });

      // 加载选中月份的数据
      await _loadTransactionsForSelectedMonth();
    } catch (e) {
      ToastUtil.showError('月份加载失败: ${e.toString()}');
      // 添加重试逻辑（可选）
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 刷新交易列表
  Future<void> _refreshTransactions() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final transactionProvider =
          Provider.of<TransactionProvider>(context, listen: false);

      // 先重新获取月份列表
      await _loadMonths();

      // 然后根据选中的月份获取交易记录
      await transactionProvider.fetchTransactions(
        month: _selectedMonth,
      );

      // 清除缓存以确保获取最新数据
      await _loadTransactionsForSelectedMonth();
    } catch (e) {
      ToastUtil.showError('刷新交易列表失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 加载选定月份的交易记录
  Future<void> _loadTransactionsForSelectedMonth() async {
    if (_selectedMonth == null) {
      // 添加默认月份处理
      final now = DateTime.now().toLocal(); // 使用本地时区
      _selectedMonth = '${now.year}年${now.month.toString().padLeft(2, '0')}月';
      print('Using default month: $_selectedMonth');
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final transactionProvider =
          Provider.of<TransactionProvider>(context, listen: false);

      // 添加调试信息
      print('Fetching transactions for month: $_selectedMonth');

      // 计算日期范围 - 确保使用本地时区
      final year = int.parse(_selectedMonth!.substring(0, 4));
      final month = int.parse(_selectedMonth!.substring(5, 7));
      final startDate = DateTime(year, month, 1).toLocal();
      final endDate = DateTime(year, month + 1, 0).toLocal();

      await transactionProvider.getTransactions(
        startDate: FormatUtil.formatDate(startDate),
        endDate: FormatUtil.formatDate(endDate),
        refresh: true,
      );

      // 添加调试信息
      print('Transactions fetched: ${transactionProvider.transactions.length}');
    } catch (e) {
      ToastUtil.showError('加载交易记录失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 过滤交易列表
  List<TransactionModel> _filterTransactions(
      List<TransactionModel> transactions) {
    if (transactions.isEmpty) return [];

    // 按类型筛选
    var filtered = transactions;
    if (_typeFilter == 'income') {
      filtered =
          filtered.where((t) => t.type == AppConstants.incomeType).toList();
    } else if (_typeFilter == 'expense') {
      filtered =
          filtered.where((t) => t.type == AppConstants.expenseType).toList();
    } else if (_typeFilter == 'borrow') {
      filtered =
          filtered.where((t) => t.type == AppConstants.borrowType).toList();
    } else if (_typeFilter == 'return') {
      filtered =
          filtered.where((t) => t.type == AppConstants.returnType).toList();
    } else if (_typeFilter == 'settle') {
      filtered =
          filtered.where((t) => t.type == AppConstants.settleType).toList();
    }
    // 排序 - 确保使用本地时区进行比较
    filtered.sort((a, b) {
      int result;

      if (_sortBy == 'time') {
        final aTime =
            (FormatUtil.parseDateTime(a.transactionDate) ?? DateTime.now()).toLocal();
        final bTime =
            (FormatUtil.parseDateTime(b.transactionDate) ?? DateTime.now()).toLocal();
        result = bTime.compareTo(aTime); // 默认时间倒序
      } else {
        // amount
        result = a.amount.compareTo(b.amount);
      }

      return _sortAsc ? result : -result;
    });

    return filtered;
  }

  // 修复加载状态处理，避免出现蒙层问题
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('交易记录'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            onPressed: _refreshTransactions,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // 筛选栏
          _buildFilterBar(),

          // 月份选择器
          _buildMonthSelector(),

          // 交易列表 - 修改加载状态处理逻辑，避免蒙层问题
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, transactionProvider, _) {
                // 仅在初始加载时显示加载指示器
                if (_isLoading && transactionProvider.transactions.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 过滤并排序交易列表
                final filteredTransactions =
                    _filterTransactions(transactionProvider.transactions);

                if (filteredTransactions.isEmpty) {
                  return _buildEmptyView();
                }

                return RefreshIndicator(
                  onRefresh: _refreshTransactions,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 8.r),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      return _buildTransactionItem(transaction);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

// 新增月份切换处理方法
void _handleMonthChange(String newMonth) async {
  if (_selectedMonth == newMonth) return;
  
  setState(() {
    _selectedMonth = newMonth;
    _isLoading = true;
  });

  try {
    await _loadTransactionsForSelectedMonth();
  } catch (e) {
    ToastUtil.showError('切换月份失败: ${e.toString()}');
  } finally {
    setState(() => _isLoading = false);
  }
}

  // 新增空状态组件
  Widget _buildEmptyMonthView() {
    return Text(
      '无可用月份',
      style: TextStyle(
        fontSize: 14.sp,
        color: Colors.grey,
      ),
    );
  }

  // 构建空数据视图
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            '没有找到任何交易记录',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            '请尝试选择其他月份或创建新的交易记录',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // 构建交易项
  Widget _buildTransactionItem(TransactionModel transaction) {
    final typeColor = AppTheme.getTransactionTypeColor(transaction.type);
    final typeIcon = AppTheme.getTransactionTypeIcon(transaction.type);

    // 格式化日期时间 - 确保使用本地时区
    final dateTime =
        FormatUtil.parseDateTime(transaction.transactionDate)?.toLocal() ??
            DateTime.now().toLocal();
    final formattedDate =
        FormatUtil.formatDateTimeWithFormat(dateTime, format: 'MM/dd');
    final formattedTime =
        FormatUtil.formatDateTimeWithFormat(dateTime, format: 'HH:mm');

    final isIncome = transaction.type == AppConstants.incomeType;
    
    // 判断是否需要显示角标
    final bool showBadge = _shouldShowBadge(transaction);
    final String badgeText = _getBadgeText(transaction);
    final Color badgeColor = _getBadgeColor(transaction);
    
    return Card(
      margin: EdgeInsets.only(bottom: 6.r),
      elevation: 0.5, // 降低阴影
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
        side: BorderSide(color: Colors.grey.shade200), // 添加边框
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TransactionDetailScreen(transaction: transaction),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8.r),
        child: Stack(
          children: [
            // 交易项主体内容
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 10.r),
              child: Row(
                children: [
                  // 分类图标 - 减小尺寸
                  Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      typeIcon,
                      color: typeColor,
                      size: 18.sp,
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // 交易详情 - 优化布局
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                transaction.category,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // 日期显示在右侧
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 3.h),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                transaction.remark.isEmpty
                                    ? '无备注'
                                    : transaction.remark,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // 时间显示在右侧
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 8.w),

                  // 金额 - 优化显示
                  Text(
                    '${isIncome ? '+' : '-'} ${FormatUtil.formatCurrency(transaction.amount)}',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // 角标
            if (showBadge)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.r, vertical: 2.r),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8.r),
                      bottomLeft: Radius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // 判断是否需要显示角标（简化版）
  bool _shouldShowBadge(TransactionModel transaction) {
    return transaction.type == 'borrow' || 
           transaction.type == 'return' || 
           transaction.type == 'settle';
  }
  
  // 获取角标文本（简化版）
  String _getBadgeText(TransactionModel transaction) {
    switch (transaction.type) {
      case 'borrow':
        return '待归还';
      case 'return':
        return '已归还';
      case 'settle':
        return '已结算';
      default:
        return '';
    }
  }
  
  // 获取角标颜色（简化版）
  Color _getBadgeColor(TransactionModel transaction) {
    switch (transaction.type) {
      case 'borrow':
        return Colors.orange;
      case 'return':
        return Colors.green;
      case 'settle':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // 优化筛选栏，减少高度
  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 8.r),
      color: Colors.white,
      child: Row(
        children: [
          // 类型筛选
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _typeFilter,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('全部')),
                DropdownMenuItem(value: 'income', child: Text('收入')),
                DropdownMenuItem(value: 'expense', child: Text('支出')),
                DropdownMenuItem(value: 'borrow', child: Text('借入')),
                DropdownMenuItem(value: 'return', child: Text('还款')),
                DropdownMenuItem(value: 'settle', child: Text('结算')),
              ],
              onChanged: (value) {
                setState(() {
                  _typeFilter = value!;
                });
              },
            ),
          ),

          SizedBox(width: 10.w),

          // 排序方式
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _sortBy,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 5.r),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'time', child: Text('按时间')),
                DropdownMenuItem(value: 'category', child: Text('按分类')),
              ],
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
              },
            ),
          ),

          SizedBox(width: 10.w),

          // 升序/降序
          InkWell(
            onTap: () {
              setState(() {
                _sortAsc = !_sortAsc;
              });
            },
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                size: 24.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 优化月份选择器，减少高度
  Widget _buildMonthSelector() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return LinearProgressIndicator(minHeight: 2.h);
        }

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 8.r),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              Text('选择月份:', style: TextStyle(fontSize: 14.sp)),
              SizedBox(width: 8.w),
              Expanded(
                child: _months.isEmpty
                    ? _buildEmptyMonthView()
                    : DropdownButtonFormField<String>(
                        value: _selectedMonth != null && _months.contains(_selectedMonth) 
                            ? _selectedMonth 
                            : _months.lastOrNull,
                        onChanged: _isLoading 
                            ? null 
                            : (value) => _handleMonthChange(value!),
                        items: _months.map((month) => DropdownMenuItem(
                          value: month,
                          child: Text(
                            month,
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        )).toList(),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          isDense: true,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
