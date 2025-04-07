import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:haoshengyi_jzzs_app/theme/app_theme.dart';

class FilterBar extends StatelessWidget {
  final String typeFilter;
  final String sortBy;
  final bool sortAsc;
  final Function(String) onTypeFilterChanged;
  final Function(String, bool) onSortChanged;

  const FilterBar({
    Key? key,
    required this.typeFilter,
    required this.sortBy,
    required this.sortAsc,
    required this.onTypeFilterChanged,
    required this.onSortChanged,
  }) : super(key: key);

  // 初始化静态默认值
  static const String defaultSortBy = 'time';
  static const bool defaultSortAsc = true; // 默认降序

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 8.r),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 筛选标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.filter_list, size: 18.sp, color: Colors.grey[600]),
                  SizedBox(width: 4.w),
                  Text(
                    '筛选',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              // 排序切换按钮
              InkWell(
                onTap: () {
                  onSortChanged(sortBy, !sortAsc);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 4.r),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        sortAsc ? '升序' : '降序',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16.sp,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // 基本交易类型筛选芯片 - 单行显示
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: '全部交易',
                  isSelected: typeFilter == 'all',
                  onSelected: (selected) {
                    onTypeFilterChanged('all');
                  },
                ),
                SizedBox(width: 6.w),
                _buildFilterChip(
                  label: '收款',
                  isSelected: typeFilter == 'cash_income',
                  onSelected: (selected) {
                    onTypeFilterChanged('cash_income');
                  },
                  color: Colors.green,
                ),
                SizedBox(width: 6.w),
                _buildFilterChip(
                  label: '付款',
                  isSelected: typeFilter == 'cash_expense',
                  onSelected: (selected) {
                    onTypeFilterChanged('cash_expense');
                  },
                  color: Colors.red,
                ),
                SizedBox(width: 6.w),
                _buildFilterChip(
                  label: '借出',
                  isSelected: typeFilter == 'asset_income',
                  onSelected: (selected) {
                    onTypeFilterChanged('asset_income');
                  },
                  color: Colors.green,
                ),
                SizedBox(width: 6.w),
                _buildFilterChip(
                  label: '归还',
                  isSelected: typeFilter == 'asset_expense',
                  onSelected: (selected) {
                    onTypeFilterChanged('asset_expense');
                  },
                  color: Colors.red,
                ),
              ],
            ),
          ),

          SizedBox(height: 6.h),

          // 排序方式选择
          Row(
            children: [
              Text(
                '排序:',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(width: 8.w),
              DropdownButton<String>(
                value: sortBy,
                isDense: true,
                icon: Icon(Icons.sort, size: 16.sp),
                underline: SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'time', child: Text('按时间')),
                  DropdownMenuItem(value: 'amount', child: Text('按金额')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onSortChanged(value, sortAsc);
                  }
                },
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建筛选芯片
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
    Color? color,
  }) {
    final chipColor = color ?? AppTheme.primaryColor;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: Colors.grey[200],
      selectedColor: chipColor,
      checkmarkColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 4.r, vertical: 0),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
