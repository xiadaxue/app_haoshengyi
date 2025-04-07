import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:haoshengyi_jzzs_app/constants/app_constants.dart';
import 'package:haoshengyi_jzzs_app/models/transaction_model.dart';
import 'package:haoshengyi_jzzs_app/providers/transaction_provider.dart';
import 'package:haoshengyi_jzzs_app/theme/app_theme.dart';
import 'package:haoshengyi_jzzs_app/utils/toast_util.dart';

class SettlementStatusWidget extends StatefulWidget {
  final TransactionModel transaction;
  final bool inlineStyle; // 是否使用内联样式（用于列表项中）
  final VoidCallback? onStatusChanged; // 添加状态变化回调

  const SettlementStatusWidget({
    Key? key,
    required this.transaction,
    this.inlineStyle = true,
    this.onStatusChanged,
  }) : super(key: key);

  @override
  State<SettlementStatusWidget> createState() => _SettlementStatusWidgetState();
}

class _SettlementStatusWidgetState extends State<SettlementStatusWidget> {
  late bool _isSettled;
  bool _isUpdating = false; // 添加状态更新标志，防止重复调用

  @override
  void initState() {
    super.initState();
    // 获取初始结算状态
    _isSettled =
        widget.transaction.settlementStatus == AppConstants.settledStatus;
  }

  @override
  void didUpdateWidget(SettlementStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当外部传入的交易对象更新时，更新本地状态
    if (oldWidget.transaction.settlementStatus !=
        widget.transaction.settlementStatus) {
      _isSettled =
          widget.transaction.settlementStatus == AppConstants.settledStatus;
    }
  }

  // 点击切换结算状态
  Future<void> toggleSettlementStatus() async {
    // 防止重复点击
    if (_isUpdating) return;

    final provider = Provider.of<TransactionProvider>(context, listen: false);

    setState(() {
      _isUpdating = true;
    });

    try {
      // 新的状态
      final newStatus = _isSettled
          ? AppConstants.unsettledStatus
          : AppConstants.settledStatus;

      // 先更新本地UI状态，提供即时反馈
      setState(() {
        _isSettled = !_isSettled;
      });

      // 创建一个新的交易记录，并更新结算状态
      final updatedTransaction = widget.transaction.copyWith(
        settlementStatus: newStatus,
      );

      // 调用更新接口
      final success = await provider.updateTransactionWithoutRefresh(
        widget.transaction.transactionId!,
        updatedTransaction,
      );

      if (success) {
        // 成功后，更新本地列表中的交易记录
        provider.updateLocalTransaction(updatedTransaction);

        print('结算状态更新成功: ${widget.transaction.transactionId} -> $newStatus');

        // 触发回调
        if (widget.onStatusChanged != null) {
          // 用延迟触发回调，确保状态已完全更新
          Future.delayed(Duration(milliseconds: 100), () {
            if (mounted) {
              widget.onStatusChanged!();
            }
          });
        }

        // 显示成功提示
        ToastUtil.showSuccess(
          _isSettled ? '已标记为已结算' : '已标记为未结算',
        );

        // 确保数据更新显示，立即通知然后再延迟通知
        provider.notifyListeners();
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) {
            provider.notifyListeners();
          }
        });
      } else {
        // 如果API调用失败，撤销本地状态更改
        setState(() {
          _isSettled = !_isSettled;
        });
        ToastUtil.showError('状态更新失败');
      }
    } catch (e) {
      // 如果出错，恢复原来的状态
      setState(() {
        _isSettled = !_isSettled;
      });
      ToastUtil.showError('状态更新失败: $e');
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.inlineStyle) {
      // 内联样式 - 用于列表项
      return GestureDetector(
        onTap: toggleSettlementStatus,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6.r, vertical: 2.r),
          decoration: BoxDecoration(
            color: _isSettled
                ? Colors.green.withOpacity(0.7)
                : Colors.orange.withOpacity(0.7),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Text(
            _isSettled ? '已结算' : '未结算',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else {
      // 详情页样式 - 开关控件样式
      return Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '结算状态:',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            SizedBox(width: 16.w),
            // 使用自定义开关控件，更符合图片中的样式
            GestureDetector(
              onTap: toggleSettlementStatus,
              child: Container(
                width: 50.w,
                height: 28.h,
                padding: EdgeInsets.all(2.r),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  color: _isSettled ? Colors.green : Colors.grey.shade300,
                ),
                child: Row(
                  mainAxisAlignment: _isSettled
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 24.h,
                      height: 24.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              _isSettled ? '已结算' : '未结算',
              style: TextStyle(
                fontSize: 14.sp,
                color: _isSettled ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
  }
}
