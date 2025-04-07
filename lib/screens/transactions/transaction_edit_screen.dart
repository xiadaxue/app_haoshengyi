import 'package:flutter/material.dart';
import 'package:haoshengyi_jzzs_app/constants/app_constants.dart';
import 'package:haoshengyi_jzzs_app/models/transaction_model.dart';
import 'package:haoshengyi_jzzs_app/providers/transaction_provider.dart';
import 'package:haoshengyi_jzzs_app/theme/app_theme.dart';
import 'package:haoshengyi_jzzs_app/utils/toast_util.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class EditTransactionScreen extends StatefulWidget {
  final TransactionModel transaction;

  const EditTransactionScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _category;
  late String _remark;
  late double _amount;
  late String _type; // 交易类型
  late String _classType; // 交易分类类型 (cash/asset)

  @override
  void initState() {
    super.initState();
    _category = widget.transaction.category;
    _remark = widget.transaction.remark ?? '';
    _amount = widget.transaction.amount;
    _type = widget.transaction.type;
    _classType = widget.transaction.classType;
  }

  // 获取可用的交易分类类型列表
  List<Map<String, dynamic>> get _transactionClassTypes {
    return [
      {'value': AppConstants.cashType, 'label': '资金'},
      {'value': AppConstants.assetType, 'label': '资产'},
    ];
  }

  // 获取可用的交易类型列表，根据选择的分类类型进行过滤
  List<Map<String, dynamic>> get _transactionTypes {
    if (_classType == AppConstants.cashType) {
      // 现金类型只显示收入与支出
      return [
        {'value': AppConstants.incomeType, 'label': '收款'},
        {'value': AppConstants.expenseType, 'label': '付款'},
      ];
    } else {
      // 资产类型显示所有交易类型
      return [
        {'value': AppConstants.incomeType, 'label': '借出'},
        {'value': AppConstants.expenseType, 'label': '归还'},
      ];
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    try {
      final transactionProvider =
          Provider.of<TransactionProvider>(context, listen: false);

      final updatedTransaction = widget.transaction.copyWith(
        category: _category,
        remark: _remark,
        amount: _amount,
        type: _type,
        classType: _classType,
      );

      final success = await transactionProvider.updateTransaction(
          updatedTransaction.transactionId!, updatedTransaction);

      if (success) {
        ToastUtil.showSuccess('交易记录更新成功');
        Navigator.of(context).pop(true); // 返回上一页并传递成功状态
      } else {
        ToastUtil.showError('交易记录更新失败');
      }
    } catch (e) {
      ToastUtil.showError('更新失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑交易记录'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: EdgeInsets.all(15.r),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 交易资产类型选择器
                Text(
                  '资金/资产',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _classType,
                      isExpanded: true,
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      borderRadius: BorderRadius.circular(8.r),
                      items: _transactionClassTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type['value'],
                          child: Text(
                            type['label'],
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _classType = value;
                            // 如果切换到现金类型，且当前类型不是收入或支出，则重置为支出
                            if (value == AppConstants.cashType &&
                                _type != AppConstants.incomeType &&
                                _type != AppConstants.expenseType) {
                              _type = AppConstants.expenseType;
                            }
                          });
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: 15.h),

                // 交易类型选择器
                Text(
                  '交易类型',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _type,
                      isExpanded: true,
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      borderRadius: BorderRadius.circular(8.r),
                      items: _transactionTypes.map((type) {
                        final typeColor =
                            AppTheme.getTransactionTypeColor(type['value']);
                        return DropdownMenuItem<String>(
                          value: type['value'],
                          child: Row(
                            children: [
                              Icon(
                                AppTheme.getTransactionTypeIcon(type['value']),
                                color: typeColor,
                                size: 18.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                type['label'],
                                style: TextStyle(
                                  color: typeColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _type = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: 15.h),

                // 备注
                TextFormField(
                  initialValue: _remark,
                  decoration: InputDecoration(
                    labelText: '备注',
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) {
                    _remark = value!;
                  },
                ),
                SizedBox(height: 15.h),

                // 金额
                TextFormField(
                  initialValue: _amount.toString(),
                  decoration: InputDecoration(
                    labelText:
                        _classType == AppConstants.assetType ? '数量' : '金额',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return _classType == AppConstants.assetType
                          ? '数量不能为空'
                          : '金额不能为空';
                    }
                    if (double.tryParse(value) == null) {
                      return _classType == AppConstants.assetType
                          ? '请输入有效的数量'
                          : '请输入有效的金额';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _amount = double.parse(value!);
                  },
                ),
                SizedBox(height: 30.h),

                // 保存按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
