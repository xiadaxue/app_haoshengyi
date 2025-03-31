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
  late String _type; // 添加交易类型变量

  @override
  void initState() {
    super.initState();
    _category = widget.transaction.category;
    _remark = widget.transaction.remark ?? '';
    _amount = widget.transaction.amount;
    _type = widget.transaction.type; // 初始化交易类型
  }

  // 获取可用的交易类型列表
  List<Map<String, dynamic>> get _transactionTypes {
    return [
      {'value': AppConstants.incomeType, 'label': '收入'},
      {'value': AppConstants.expenseType, 'label': '支出'},
      {'value': 'borrow', 'label': '借入'},
      {'value': 'return', 'label': '还款'},
      {'value': 'settle', 'label': '结算'},
    ];
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
        type: _type, // 添加类型更新
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
                        final typeColor = AppTheme.getTransactionTypeColor(type['value']);
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
                
                // 分类
                TextFormField(
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: '分类',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '分类不能为空';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _category = value!;
                  },
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
                    labelText: '金额',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '金额不能为空';
                    }
                    if (double.tryParse(value) == null) {
                      return '请输入有效的金额';
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
