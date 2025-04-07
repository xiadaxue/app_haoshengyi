import 'package:flutter/material.dart';
import 'package:haoshengyi_jzzs_app/constants/app_constants.dart';
import 'package:haoshengyi_jzzs_app/models/transaction_model.dart';
import 'package:haoshengyi_jzzs_app/providers/transaction_provider.dart';
import 'package:haoshengyi_jzzs_app/screens/transactions/transaction_detail_screen.dart';
import 'package:haoshengyi_jzzs_app/screens/transactions/transaction_form_screen.dart';
import 'package:haoshengyi_jzzs_app/screens/transactions/transactions_page.dart';
import 'package:haoshengyi_jzzs_app/theme/app_theme.dart';
import 'package:haoshengyi_jzzs_app/utils/format_util.dart';
import 'package:haoshengyi_jzzs_app/utils/toast_util.dart';
import 'package:haoshengyi_jzzs_app/widgets/voice_input_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:haoshengyi_jzzs_app/screens/transactions/widgets/settlement_status_widget.dart';

/// 首页
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // 添加日期选择相关变量
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  String? _currentDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHomeData(forceRefresh: true);
    });
  }

  Future<void> _loadHomeData(
      {bool forceRefresh = false, bool silent = false}) async {
    final today = DateTime.now();
    final todayStr = FormatUtil.formatDate(today);

    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // 加载首页数据和统计数据
      final provider = Provider.of<TransactionProvider>(context, listen: false);

      // 初始化数据（如果还未初始化）
      if (provider.availableMonths.isEmpty) {
        await provider.initializeData();
      }

      // 获取今日数据
      await provider.getHomePageData(todayStr, forceRefresh: forceRefresh);

      // 获取今日统计
      await provider.getTodaySummary(refresh: forceRefresh);

      if (!silent) {
        setState(() {
          _isLoading = false;
          _currentDate = todayStr;
        });
      }
    } catch (e) {
      print('加载首页数据失败: $e');
      if (!silent) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 切换显示的日期
  void _onDateChanged(DateTime date) {
    final dateStr = FormatUtil.formatDate(date);

    // 如果已经是当前日期，不需要重新加载
    if (dateStr == _currentDate) return;

    setState(() {
      _isLoading = true;
      _selectedDate = date; // 更新选中日期，确保UI一致
    });

    // 获取指定日期的交易记录
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    provider.getHomePageData(dateStr, forceRefresh: true).then((_) {
      setState(() {
        _isLoading = false;
        _currentDate = dateStr;
      });
    }).catchError((e) {
      print('加载日期数据失败: $e');
      setState(() {
        _isLoading = false;
      });
      ToastUtil.showError('加载日期数据失败: $e');
    });
  }

  // 刷新首页数据
  Future<void> _refreshHomeData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final provider = Provider.of<TransactionProvider>(context, listen: false);

      if (_currentDate != null) {
        // 刷新当前显示的日期数据，强制刷新以确保最新数据
        await provider.getHomePageData(_currentDate!, forceRefresh: true);
      } else {
        // 如果没有当前日期，则加载今日数据
        final today = FormatUtil.formatDate(DateTime.now());
        await provider.getHomePageData(today, forceRefresh: true);
        _currentDate = today;
      }

      // 刷新今日统计
      await provider.getTodaySummary(refresh: true);

      if (!silent) {
        setState(() {
          _isLoading = false;
        });
        ToastUtil.showSuccess('数据已刷新');
      }

      // 确保列表滚动到顶部以查看最新记录
      if (provider.homePageTransactions.isNotEmpty && !silent) {
        // 这里可以添加逻辑滚动到顶部
        // 如果有ScrollController可使用 _scrollController.animateTo(0, ...)
      }
    } catch (e) {
      print('刷新首页数据失败: $e');
      if (!silent) {
        setState(() {
          _isLoading = false;
        });
        ToastUtil.showError('刷新数据失败: $e');
      }
    }

    return Future.value();
  }

  // 查看交易详情
  void _viewTransactionDetail(TransactionModel transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailScreen(transaction: transaction),
      ),
    );
  }

  // 日期选择方法 - 使用弹窗
  void _selectDate(BuildContext context) async {
    final initialDate = _selectedDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _focusedDate = picked;
      });

      // 加载选中日期的数据
      _onDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, _) {
          final homeTransactions = transactionProvider.homePageTransactions;
          double todayIncome = 0;
          double todayExpense = 0;

          for (final transaction in homeTransactions) {
            if (transaction.type == AppConstants.incomeType) {
              todayIncome += transaction.amount;
            } else if (transaction.type == AppConstants.expenseType) {
              todayExpense += transaction.amount;
            }
          }

          return RefreshIndicator(
            onRefresh: () => _refreshHomeData(),
            child: CustomScrollView(
              slivers: [
                // 可折叠的头部
                SliverAppBar(
                  expandedHeight: 200.h,
                  pinned: true,
                  backgroundColor: AppTheme.primaryColor,
                  elevation: 0,
                  title: const Text('好生意记账本'),
                  actions: [
                    // 添加刷新按钮
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.white),
                      onPressed: () {
                        _refreshHomeData();
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      color: AppTheme.primaryColor,
                      padding: EdgeInsets.only(
                        top: kToolbarHeight +
                            MediaQuery.of(context).padding.top +
                            10.h,
                        left: 15.w,
                        right: 15.w,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTodaySummaryCard(todayIncome, todayExpense),
                        ],
                      ),
                    ),
                  ),
                ),

                // 语音记账区域 - 使用新的组件
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      VoiceInputWidget(
                        onAccountingSuccess: () {
                          // 刷新首页数据
                          _refreshHomeData();
                        },
                      ),
                    ],
                  ),
                ),

                // 最近交易标题
                SliverPadding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '最近交易',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // 直接导航到交易页面
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TransactionsPage(),
                              ),
                            );
                          },
                          child: Text(
                            '查看全部',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 今日交易列表
                homeTransactions.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt,
                                size: 60.sp,
                                color: Colors.grey.shade300,
                              ),
                              SizedBox(height: 15.h),
                              Text(
                                '暂无交易记录',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                '点击下方按钮，用语音方式记账',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 15.r),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _buildTransactionItem(
                                  homeTransactions[index]);
                            },
                            childCount: homeTransactions.length,
                          ),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 构建交易项目
  Widget _buildTransactionItem(TransactionModel transaction) {
    // 使用 AppTheme 获取类型颜色和图标
    final typeColor = AppTheme.getTransactionTypeColor(transaction.type);
    final typeIcon = AppTheme.getTransactionTypeIcon(transaction.type);

    final isIncome = transaction.type == AppConstants.incomeType;
    final isExpense = transaction.type == AppConstants.expenseType;
    final isCash = transaction.classType == AppConstants.cashType;

    // 显示交易关联的用户或类别
    String displayName = '';
    if (transaction.users != null && transaction.users!.isNotEmpty) {
      // 如果有用户信息，显示第一个用户
      displayName = transaction.users!.first;
    } else {
      // 如果没有用户信息，显示类别
      displayName = transaction.category;
    }
    // 显示金额或数量
    final displayAmount = isCash
        ? FormatUtil.formatCurrency(transaction.amount)
        : _getContainerQuantity(transaction.containers);

    return GestureDetector(
      onTap: () {
        _viewTransactionDetail(transaction);
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(
            children: [
              // 左侧图标
              CircleAvatar(
                radius: 22.r,
                backgroundColor: isIncome ? Colors.green[50] : Colors.red[50],
                child: Icon(
                  typeIcon,
                  color: isIncome ? Colors.green : Colors.red,
                  size: 20.r,
                ),
              ),
              SizedBox(width: 12.w),
              // 中间内容：用户或类别和备注
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName, // 使用用户名称替代类别
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      transaction.remark,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // 右侧金额
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    displayAmount,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  // 添加结算状态显示
                  SettlementStatusWidget(
                    transaction: transaction,
                    onStatusChanged: () {
                      // 当状态改变时刷新首页数据
                      _refreshHomeData();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 新的收支卡片样式 - 更新日期选择部分
  Widget _buildTodaySummaryCard(double income, double expense) {
    final profit = income - expense; // 计算利润

    return Container(
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '今日收支',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              Spacer(),
              // 修改为可点击的日期组件
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        FormatUtil.formatDate(_selectedDate),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          // 金额显示区域
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 收入
              _buildAmountColumn(FormatUtil.formatCurrency(income), '收入'),

              // 支出
              _buildAmountColumn(FormatUtil.formatCurrency(expense), '支出'),

              // 利润
              _buildAmountColumn(FormatUtil.formatCurrency(profit), '利润'),
            ],
          ),
        ],
      ),
    );
  }

  // 提取出金额列的公共部分
  Widget _buildAmountColumn(String amount, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          amount,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  // 获取容器的数量
  String _getContainerQuantity(List<ContainerModel>? containers) {
    if (containers == null || containers.isEmpty) {
      return '0个'; // 如果没有容器，显示 0 个
    }

    // 累加所有容器的数量
    int totalQuantity = containers.fold<int>(
      0,
      (sum, container) => sum + (int.tryParse(container.quantity) ?? 0),
    );

    return '$totalQuantity个'; // 返回总数量
  }
}
