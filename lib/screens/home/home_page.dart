import 'package:flutter/material.dart';
import 'package:haoshengyi_jzzs_app/constants/app_constants.dart';
import 'package:haoshengyi_jzzs_app/models/transaction_model.dart';
import 'package:haoshengyi_jzzs_app/providers/transaction_provider.dart';
import 'package:haoshengyi_jzzs_app/screens/transactions/transaction_detail_screen.dart';
import 'package:haoshengyi_jzzs_app/screens/transactions/transactions_page.dart';
import 'package:haoshengyi_jzzs_app/theme/app_theme.dart';
import 'package:haoshengyi_jzzs_app/utils/format_util.dart';
import 'package:haoshengyi_jzzs_app/utils/toast_util.dart';
import 'package:haoshengyi_jzzs_app/widgets/voice_input_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

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

  // 查看交易详情
  void _viewTransactionDetail(TransactionModel transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailScreen(transaction: transaction),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, _) {
          final todayTransactions = transactionProvider.todayTransactions;
          double todayIncome = 0;
          double todayExpense = 0;

          for (final transaction in todayTransactions) {
            if (transaction.type == AppConstants.incomeType) {
              todayIncome += transaction.amount;
            } else if (transaction.type == AppConstants.expenseType) {
              todayExpense += transaction.amount;
            }
          }

          return RefreshIndicator(
            onRefresh: () async {
              await transactionProvider.refreshTransactions();
            },
            child: CustomScrollView(
              slivers: [
                // 可折叠的头部 - 修改为新设计
                SliverAppBar(
                  expandedHeight: 200.h, // 减小高度
                  pinned: true,
                  backgroundColor: AppTheme.primaryColor,
                  elevation: 0,
                  title: const Text('好生意记账本'),
                  actions: [
                    // 刷新按钮
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.white),
                      onPressed: () async {
                        await transactionProvider.refreshTransactions();
                        ToastUtil.showSuccess('刷新成功');
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
                      child: _buildTodaySummaryCard(todayIncome, todayExpense),
                    ),
                  ),
                ),

                // 语音记账区域 - 使用新的组件
                SliverToBoxAdapter(
                  child: VoiceInputWidget(
                    onAccountingSuccess: () {
                      // 刷新交易列表
                      transactionProvider.refreshTransactions();
                    },
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
                todayTransactions.isEmpty
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
                                '今日暂无交易记录',
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
                                  todayTransactions[index]);
                            },
                            childCount: todayTransactions.length,
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

  // 构建交易项
  Widget _buildTransactionItem(TransactionModel transaction) {
    // 使用 AppTheme 获取类型颜色和图标
    final typeColor = AppTheme.getTransactionTypeColor(transaction.type);
    final typeIcon = AppTheme.getTransactionTypeIcon(transaction.type);

    return Card(
      margin: EdgeInsets.only(bottom: 8.r),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _viewTransactionDetail(transaction),
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 10.r),
          child: Row(
            children: [
              // 分类图标 - 使用统一的图标和颜色
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

              // 交易详情
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.category,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      transaction.remark.isEmpty ? '无备注' : transaction.remark,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppTheme.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // 金额
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    FormatUtil.formatCurrency(transaction.amount),
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    FormatUtil.formatDateTimeWithFormat(
                        FormatUtil.parseDateTime(transaction.transactionDate)
                                ?.toLocal() ??
                            DateTime.now().toLocal(),
                        format: 'HH:mm'),
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
      ),
    );
  }

  // 新的收支卡片样式
  Widget _buildTodaySummaryCard(double income, double expense) {
    final profit = income - expense; // 计算利润

    // 使用 Builder 确保 context 可以访问到 Provider
    return Builder(builder: (context) {
      // 获取当前时间（使用本地时间，不依赖 Provider）
      final now = DateTime.now().toLocal();

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
                Text(
                  FormatUtil.formatDate(now), // 不传入 context
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.9),
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
    });
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
}
