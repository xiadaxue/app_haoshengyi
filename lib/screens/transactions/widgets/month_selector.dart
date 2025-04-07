import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:haoshengyi_jzzs_app/providers/transaction_provider.dart';
import 'package:haoshengyi_jzzs_app/theme/app_theme.dart';
import 'package:haoshengyi_jzzs_app/utils/format_util.dart';

class MonthSelector extends StatelessWidget {
  final List<String> months;
  final String? selectedMonth;
  final bool isLoading;
  final Function(String) onMonthChanged;
  final VoidCallback onCalendarPressed;

  const MonthSelector({
    Key? key,
    required this.months,
    required this.selectedMonth,
    required this.isLoading,
    required this.onMonthChanged,
    required this.onCalendarPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        if (isLoading) {
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.date_range, size: 18.sp, color: AppTheme.primaryColor),
              SizedBox(width: 8.w),
              Expanded(
                child: InkWell(
                  onTap: () => _showMonthPicker(context, provider),
                  child: Row(
                    children: [
                      Text(
                        selectedMonth ??
                            (months.isNotEmpty
                                ? months.last
                                : FormatUtil.formatCurrentMonth()),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: AppTheme.primaryColor,
                        size: 24.sp,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              // 日历按钮
              IconButton(
                icon: Icon(
                  Icons.calendar_today,
                  size: 18.sp,
                  color: AppTheme.primaryColor,
                ),
                onPressed: onCalendarPressed,
                padding: EdgeInsets.all(4.r),
                constraints: BoxConstraints(),
                splashRadius: 20.r,
              ),
            ],
          ),
        );
      },
    );
  }

  // 显示月份选择对话框
  void _showMonthPicker(BuildContext context, TransactionProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '选择月份',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  height: 300.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: months.isEmpty
                      ? _buildEmptyMonthView()
                      : ListView.builder(
                          itemCount: months.length,
                          itemBuilder: (context, index) {
                            final month = months[
                                months.length - 1 - index]; // 倒序显示，最新的月份在最前面
                            final isSelected = month == selectedMonth;
                            final hasData = provider.hasDataForMonth(month);

                            return ListTile(
                              title: Text(
                                month,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : (hasData ? Colors.black : Colors.grey),
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle,
                                      color: AppTheme.primaryColor)
                                  : null,
                              selected: isSelected,
                              selectedTileColor:
                                  AppTheme.primaryColor.withOpacity(0.1),
                              onTap: () {
                                Navigator.of(context).pop();
                                onMonthChanged(month);
                              },
                            );
                          },
                        ),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('取消'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onCalendarPressed(); // 跳转到日历选择
                      },
                      child: Text('日历选择'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 空状态视图
  Widget _buildEmptyMonthView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 48.sp,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16.h),
          Text(
            '无可用月份',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
