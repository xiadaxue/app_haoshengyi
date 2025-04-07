import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:haoshengyi_jzzs_app/constants/app_constants.dart';
import 'package:haoshengyi_jzzs_app/models/transaction_model.dart';
import 'package:haoshengyi_jzzs_app/screens/transactions/transaction_detail_screen.dart';
import 'package:haoshengyi_jzzs_app/theme/app_theme.dart';
import 'package:haoshengyi_jzzs_app/utils/format_util.dart';
import 'package:haoshengyi_jzzs_app/screens/transactions/widgets/settlement_status_widget.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onStatusChanged;

  const TransactionItem({
    Key? key,
    required this.transaction,
    this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
    final isExpense = transaction.type == AppConstants.expenseType;
    final isCash = transaction.classType == AppConstants.cashType;
    final isAsset = transaction.classType == AppConstants.assetType;

    // 判断颜色: 支出、借出(借入也计入借出)用红色，收入、借出后回收用绿色
    final amountColor = (isExpense)
        ? Colors.red
        : (isIncome || isAsset)
            ? Colors.green
            : Colors.grey;

    // 显示金额或数量
    final displayAmount = isCash
        ? FormatUtil.formatCurrency(transaction.amount)
        : _getContainerQuantity(transaction.containers);

    // 显示交易类型标签
    String typeLabel = '';
    if (isAsset) {
      if (isIncome) {
        typeLabel = '借出';
      } else if (isExpense) {
        typeLabel = '归还';
      }
    } else if (isCash) {
      if (isIncome) {
        typeLabel = '收款';
      } else if (isExpense) {
        typeLabel = '付款';
      }
    }

    // 判断是否需要显示角标
    final bool showBadge = _shouldShowBadge(transaction);
    final String badgeText = _getBadgeText(transaction);
    final Color badgeColor = _getBadgeColor(transaction);
    // 显示交易关联的用户或类别
    String displayName = '';
    if (transaction.users != null && transaction.users!.isNotEmpty) {
      // 如果有用户信息，显示第一个用户
      displayName = transaction.users!.first;
    } else {
      // 如果没有用户信息，显示类别
      displayName = transaction.category;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8.r),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionDetailScreen(
                transaction: transaction,
              ),
            ),
          ).then((result) {
            // 如果详情页返回true，表示有修改，触发刷新
            if (result == true && onStatusChanged != null) {
              onStatusChanged!();
            }
          });
        },
        borderRadius: BorderRadius.circular(8.r),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 10.r),
              child: Row(
                children: [
                  // 左侧日期显示
                  Container(
                    width: 45.w,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          formattedTime,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 10.w),

                  // 中间分隔线
                  Container(
                    height: 40.h,
                    width: 1.w,
                    color: Colors.grey.withOpacity(0.3),
                  ),

                  SizedBox(width: 10.w),

                  // 交易信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // 分类图标
                            Container(
                              width: 24.r,
                              height: 24.r,
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                typeIcon,
                                color: typeColor,
                                size: 14.sp,
                              ),
                            ),
                            SizedBox(width: 8.w),

                            // 分类名称
                            Expanded(
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 3.h),

                        // 备注文本
                        Text(
                          transaction.remark.isEmpty
                              ? '无备注'
                              : transaction.remark,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // 添加用户信息
                        if (transaction.users != null &&
                            transaction.users!.isNotEmpty)
                          Text(
                            '交易人: ${transaction.users!.join(', ')}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  SizedBox(width: 8.w),

                  // 右侧金额
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isExpense ? '-$displayAmount' : '+$displayAmount',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                        ),
                      ),
                      SizedBox(height: 4.h),

                      // 结算状态显示 - 添加状态变化回调
                      SettlementStatusWidget(
                        transaction: transaction,
                        onStatusChanged: onStatusChanged,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 根据类型显示角标
            if (showBadge)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 2.r),
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

            // 显示资产类型标记
            if (isAsset)
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.r, vertical: 2.r),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.7),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8.r),
                      bottomLeft: Radius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    '资产',
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

  // 判断是否需要显示角标
  bool _shouldShowBadge(TransactionModel transaction) {
    return transaction.type == AppConstants.borrowType ||
        transaction.type == AppConstants.returnType ||
        transaction.type == AppConstants.settleType;
  }

  // 获取角标文本
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

  // 获取角标颜色
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
