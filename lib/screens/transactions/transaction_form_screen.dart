import 'package:flutter/material.dart';
import 'package:haoshengyi_jzzs_app/constants/app_constants.dart';
import 'package:haoshengyi_jzzs_app/models/transaction_model.dart';
import 'package:haoshengyi_jzzs_app/providers/transaction_provider.dart';
import 'package:haoshengyi_jzzs_app/theme/app_theme.dart';
import 'package:haoshengyi_jzzs_app/utils/format_util.dart';
import 'package:haoshengyi_jzzs_app/utils/toast_util.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// 通用交易表单页面，既可用于创建也可用于编辑交易
class TransactionFormScreen extends StatefulWidget {
  final TransactionModel? transaction; // 如果为null则为创建模式
  final bool isEdit; // 是否为编辑模式

  const TransactionFormScreen({
    super.key,
    this.transaction,
    this.isEdit = false,
  });

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _category;
  late String _remark;
  late double _amount;
  late String _type; // 交易类型 (income/expense)
  late String _classType; // 交易分类类型 (cash/asset)
  late DateTime _transactionDate; // 交易日期
  List<String> _tags = []; // 标签
  List<String> _users = []; // 用户
  String? _settlementStatus; // 结算状态

  bool get isCreateMode => !widget.isEdit;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.transaction != null) {
      // 编辑模式 - 使用现有交易数据初始化字段
      final transaction = widget.transaction!;
      _category = transaction.category;
      _remark = transaction.remark;
      _amount = transaction.amount;
      _type = transaction.type;
      _classType = transaction.classType;

      // 修复日期解析问题
      try {
        final dateStr = transaction.transactionDate;
        if (dateStr != null && dateStr.isNotEmpty) {
          if (dateStr.contains('T')) {
            // ISO8601格式，直接解析
            _transactionDate = DateTime.parse(dateStr);
          } else if (dateStr.contains(' ')) {
            // 常规日期时间格式，如 "2025-04-06 23:38:44"
            final parts = dateStr.split(' ');
            if (parts.length == 2) {
              final dateParts = parts[0].split('-');
              final timeParts = parts[1].split(':');
              if (dateParts.length == 3 && timeParts.length == 3) {
                _transactionDate = DateTime(
                  int.parse(dateParts[0]),
                  int.parse(dateParts[1]),
                  int.parse(dateParts[2]),
                  int.parse(timeParts[0]),
                  int.parse(timeParts[1]),
                  int.parse(timeParts[2]),
                );
              } else {
                _transactionDate = DateTime.now();
              }
            } else {
              _transactionDate = DateTime.now();
            }
          } else {
            // 只有日期部分
            final dateParts = dateStr.split('-');
            if (dateParts.length == 3) {
              _transactionDate = DateTime(
                int.parse(dateParts[0]),
                int.parse(dateParts[1]),
                int.parse(dateParts[2]),
              );
            } else {
              _transactionDate = DateTime.now();
            }
          }
        } else {
          _transactionDate = DateTime.now();
        }
      } catch (e) {
        print('日期解析失败: ${transaction.transactionDate}, 错误: $e');
        _transactionDate = DateTime.now();
      }

      _tags = transaction.tags ?? [];
      _users = transaction.users ?? [];
      _settlementStatus = transaction.settlementStatus;
    } else {
      // 创建模式 - 使用默认值
      _category = '';
      _remark = '';
      _amount = 0;
      _type = AppConstants.expenseType; // 默认为支出
      _classType = AppConstants.cashType; // 默认为现金
      _transactionDate = DateTime.now();
      _settlementStatus = TransactionModel.unsettledStatus; // 默认未结算
    }
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

  // 保存交易记录
  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    try {
      final transactionProvider =
          Provider.of<TransactionProvider>(context, listen: false);

      // 确保日期格式符合下游需要的格式: "yyyy-MM-ddTHH:mm:ss+08:00"
      // 构建带有北京时区(+08:00)的ISO8601标准格式
      final year = _transactionDate.year;
      final month = _transactionDate.month.toString().padLeft(2, '0');
      final day = _transactionDate.day.toString().padLeft(2, '0');
      final hour = _transactionDate.hour.toString().padLeft(2, '0');
      final minute = _transactionDate.minute.toString().padLeft(2, '0');
      final second = _transactionDate.second.toString().padLeft(2, '0');

      // 使用中国时区 +08:00
      final formattedDate = "$year-$month-${day}T$hour:$minute:$second+08:00";

      print('使用格式化日期: $formattedDate (符合服务器要求的ISO8601格式)');

      bool success = false;

      if (isCreateMode) {
        // 创建模式
        final newTransaction = TransactionModel(
          type: _type,
          amount: _amount,
          category: _category,
          remark: _remark,
          transactionDate: formattedDate,
          tags: _tags,
          users: _users,
          settlementStatus:
              _settlementStatus ?? TransactionModel.unsettledStatus,
          classType: _classType,
        );

        print('准备创建交易记录：');
        print('- 交易日期: ${newTransaction.transactionDate}');
        print('- 类型: ${newTransaction.type}');
        print('- 金额: ${newTransaction.amount}');
        print('- 分类: ${newTransaction.category}');

        final transactionId =
            await transactionProvider.createTransaction(newTransaction);
        success = transactionId.isNotEmpty;

        if (success) {
          print('交易记录创建成功，ID: $transactionId');
          ToastUtil.showSuccess('交易记录创建成功');
        } else {
          print('交易记录创建失败');
          ToastUtil.showError('交易记录创建失败');
        }
      } else {
        // 编辑模式
        final updatedTransaction = widget.transaction!.copyWith(
          category: _category,
          remark: _remark,
          amount: _amount,
          type: _type,
          classType: _classType,
          transactionDate: formattedDate,
          tags: _tags,
          users: _users,
          settlementStatus: _settlementStatus,
        );

        print('准备更新交易记录：');
        print('- ID: ${updatedTransaction.transactionId}');
        print('- 交易日期: ${updatedTransaction.transactionDate}');
        print('- 类型: ${updatedTransaction.type}');
        print('- 金额: ${updatedTransaction.amount}');

        success = await transactionProvider.updateTransaction(
            updatedTransaction.transactionId!, updatedTransaction);

        if (success) {
          print('交易记录更新成功');
          ToastUtil.showSuccess('交易记录更新成功');
        } else {
          print('交易记录更新失败');
          ToastUtil.showError('交易记录更新失败');
        }
      }

      if (success) {
        Navigator.of(context).pop(true); // 返回上一页并传递成功状态
      }
    } catch (e) {
      print('保存交易记录失败: $e');
      ToastUtil.showError('保存失败：$e');
    }
  }

  // 选择日期
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)), // 允许未来一年内的日期
    );

    if (picked != null && picked != _transactionDate) {
      setState(() {
        _transactionDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isCreateMode ? '创建交易记录' : '编辑交易记录'),
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
                  child: Row(
                    children: _transactionClassTypes.map((item) {
                      final isSelected = item['value'] == _classType;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _classType = item['value'];
                              // 如果切换类型，可能需要重置交易类型
                              if (!_transactionTypes
                                  .any((t) => t['value'] == _type)) {
                                _type = _transactionTypes.first['value'];
                              }
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Center(
                              child: Text(
                                item['label'],
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
                  child: Row(
                    children: _transactionTypes.map((item) {
                      final isSelected = item['value'] == _type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _type = item['value'];
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Center(
                              child: Text(
                                item['label'],
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 15.h),

                // 交易日期
                Text(
                  '交易日期',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8.h),
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 15.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          FormatUtil.formatDate(_transactionDate),
                          style: TextStyle(
                            fontSize: 14.sp,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today,
                          size: 18.sp,
                          color: Colors.grey[600],
                        ),
                      ],
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
                  initialValue: _amount > 0 ? _amount.toString() : '',
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
                SizedBox(height: 15.h),

                // 用户字段（简单文本输入，可扩展为多选）
                TextFormField(
                  initialValue: _users.join(', '),
                  decoration: InputDecoration(
                    labelText: '关联用户（多个用户用逗号分隔）',
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) {
                    if (value != null && value.isNotEmpty) {
                      _users = value
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                    } else {
                      _users = [];
                    }
                  },
                ),
                SizedBox(height: 15.h),

                // 标签字段（简单文本输入，可扩展为多选）
                TextFormField(
                  initialValue: _tags.join(', '),
                  decoration: InputDecoration(
                    labelText: '标签（多个标签用逗号分隔）',
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) {
                    if (value != null && value.isNotEmpty) {
                      _tags = value
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                    } else {
                      _tags = [];
                    }
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
                    child: Text(isCreateMode ? '创建' : '保存'),
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
