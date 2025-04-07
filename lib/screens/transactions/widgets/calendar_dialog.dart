import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:haoshengyi_jzzs_app/providers/transaction_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:haoshengyi_jzzs_app/theme/app_theme.dart';
import 'package:haoshengyi_jzzs_app/utils/format_util.dart';

class CalendarDialog extends StatefulWidget {
  final Function(DateTime) onDaySelected;
  final DateTime? focusedDay;

  const CalendarDialog({
    Key? key,
    required this.onDaySelected,
    this.focusedDay,
  }) : super(key: key);

  @override
  State<CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<CalendarDialog> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // 记录哪些日期有数据
  final Map<DateTime, bool> _markedDates = {};

  // 防止重复加载数据
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.focusedDay ?? DateTime.now();
    _selectedDay = _focusedDay;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMonthDataForDisplay(_focusedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题和关闭按钮
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      '选择日期',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // 添加关闭按钮
                IconButton(
                  icon: Icon(Icons.close, size: 20.sp),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ),

          // 日历
          TableCalendar(
            locale: 'zh_CN',
            firstDay: DateTime(2025, 1, 1), // 从2025年1月1日开始
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: TextStyle(fontSize: 16.sp),
            ),
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            calendarStyle: CalendarStyle(
              markerDecoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                // 检查日期是否在标记列表中，如果是则显示特殊样式
                final bool hasData = _hasDataOnDay(day);

                return Container(
                  margin: EdgeInsets.all(4.r),
                  alignment: Alignment.center,
                  decoration: hasData
                      ? BoxDecoration(
                          border: Border.all(
                            color: AppTheme.primaryColor,
                            width: 1.5,
                          ),
                          shape: BoxShape.circle,
                        )
                      : null,
                  child: Text(
                    day.day.toString(),
                    style: TextStyle(
                      color: hasData ? AppTheme.primaryColor : null,
                    ),
                  ),
                );
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
                _selectedDay = null;
              });
              // 当页面改变时，仅加载该月的数据进行展示，不影响交易列表
              _loadMonthDataForDisplay(focusedDay);
            },
          ),

          // 添加底部确认按钮
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '取消',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 10.h,
                    ),
                  ),
                  onPressed: _selectedDay == null
                      ? null
                      : () {
                          widget.onDaySelected(_selectedDay!);
                          Navigator.pop(context);
                        },
                  child: Text('确认选择'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 检查某一天是否有数据的辅助方法
  bool _hasDataOnDay(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    return _markedDates[dateOnly] == true;
  }

  // 加载月份数据仅为了显示，不影响交易列表
  Future<void> _loadMonthDataForDisplay(DateTime month) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<TransactionProvider>(context, listen: false);

      // 构建月份的日期范围
      final formattedMonth =
          "${month.year}-${month.month.toString().padLeft(2, '0')}";

      // 构建月份显示格式
      final displayMonth =
          "${month.year}年${month.month.toString().padLeft(2, '0')}月";

      // 尝试获取该月份的日期数据
      final monthData = await provider.getDatesWithDataForMonth(displayMonth);

      // 清除旧数据
      _markedDates.clear();

      // 标记有数据的日期
      for (var date in monthData) {
        final dateTime = FormatUtil.parseDateTime(date);
        if (dateTime != null) {
          final dateOnly =
              DateTime(dateTime.year, dateTime.month, dateTime.day);
          _markedDates[dateOnly] = true;
        }
      }

      setState(() {});
    } catch (e) {
      print('加载月份数据失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
