import 'package:flutter/material.dart';
import 'package:haoshengyi_jzzs_app/constants/app_constants.dart';
import 'package:haoshengyi_jzzs_app/models/transaction_model.dart';
import 'package:haoshengyi_jzzs_app/providers/transaction_provider.dart';
import 'package:haoshengyi_jzzs_app/screens/transactions/transaction_edit_screen.dart';
import 'package:haoshengyi_jzzs_app/theme/app_theme.dart';
import 'package:haoshengyi_jzzs_app/utils/format_util.dart';
import 'package:haoshengyi_jzzs_app/utils/toast_util.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// 交易详情页面
class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  // 删除交易记录
  Future<void> _deleteTransaction(BuildContext context) async {
    // 显示确认对话框
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('您确定要删除这条交易记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              '删除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      ToastUtil.showLoading(message: '正在删除...');

      final transactionProvider =
          Provider.of<TransactionProvider>(context, listen: false);
      final success = await transactionProvider
          .deleteTransaction(transaction.transactionId!);

      ToastUtil.dismissLoading();

      if (success) {
        ToastUtil.showSuccess('删除成功');
        Navigator.of(context).pop();
      } else {
        ToastUtil.showError('删除失败');
      }
    } catch (e) {
      ToastUtil.dismissLoading();
      ToastUtil.showError('删除失败：$e');
    }
  }

  // 删除原有的 _getTransactionTypeLabel 方法，使用 AppTheme 中的方法
  // 修改 build 方法中的相关代码
  
  @override
  Widget build(BuildContext context) {
    // 使用 AppTheme 获取类型颜色
    final typeColor = AppTheme.getTransactionTypeColor(transaction.type);
  
    return Scaffold(
      appBar: AppBar(
        title: const Text('交易详情'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            onPressed: () => _deleteTransaction(context),
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(15.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 金额卡片 - 使用统一的类型颜色
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius: BorderRadius.circular(15.r),
                boxShadow: [
                  BoxShadow(
                    color: typeColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 交易类型 - 使用 AppTheme 中的方法获取标签
                  Text(
                    AppTheme.getTransactionTypeLabel(transaction.type),
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // 详细信息卡片
            Container(
              padding: EdgeInsets.all(15.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                        red: Colors.black.red.toDouble(),
                        green: Colors.black.green.toDouble(),
                        blue: Colors.black.blue.toDouble(),
                        alpha: 0.05 * 255),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  /// 替换描述字段
                  _buildInfoItem('备注', transaction.remark ?? '无备注'),

                  // 添加用户字段
                  if (transaction.users != null &&
                      transaction.users!.isNotEmpty)
                    _buildInfoItem('用户', transaction.users!.join(', ')),

                  // 添加产品字段
                  if (transaction.products != null &&
                      transaction.products!.isNotEmpty)
                    _buildInfoItem(
                      '产品',
                      transaction.products!
                          .map((product) =>
                              '${product.name} (${product.quantity}${product.unit})')
                          .join(', '),
                    ),

                  // 添加容器字段
                  if (transaction.containers != null &&
                      transaction.containers!.isNotEmpty)
                    _buildInfoItem(
                      '容器',
                      transaction.containers!
                          .map((container) =>
                              '${container.name} (${container.quantity})')
                          .join(', '),
                    ),

                  // 分类
                  _buildInfoItem('分类', transaction.category),

                  // 标签
                  if (transaction.tags != null && transaction.tags!.isNotEmpty)
                    _buildInfoItem('标签', transaction.tags!.join(', ')),

                  // 创建时间
                  if (transaction.createdAt != null)
                    _buildInfoItem(
                        '创建时间',
                        FormatUtil.formatDateTime(
                          FormatUtil.parseDateTime(transaction.createdAt!) ??
                              DateTime.now(),
                        )),

                  // 更新时间
                  if (transaction.updatedAt != null)
                    _buildInfoItem(
                        '更新时间',
                        FormatUtil.formatDateTime(
                          FormatUtil.parseDateTime(transaction.updatedAt!) ??
                              DateTime.now(),
                        )),
                ],
              ),
            ),

            SizedBox(height: 30.h),

            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditTransactionScreen(transaction: transaction),
                        ),
                      );

                      if (result == true) {
                        ToastUtil.showSuccess('交易记录已更新');
                        Navigator.of(context).pop(); // 返回上一页并刷新数据
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('编辑'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建信息项
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
