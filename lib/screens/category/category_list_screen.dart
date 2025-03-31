import 'package:flutter/material.dart';
import 'package:haoshengyi_jzzs_app/models/category_model.dart';
import 'package:haoshengyi_jzzs_app/providers/category_provider.dart';
import 'package:haoshengyi_jzzs_app/theme/app_theme.dart';
import 'package:haoshengyi_jzzs_app/utils/toast_util.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// 类别管理页面
class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabTitles = ['支出', '收入'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 添加或编辑类别
  void _showCategoryForm({CategoryModel? category}) {
    // 如果是编辑，使用现有数据，否则创建新数据
    final isEditing = category != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category?.name ?? '');

    // 类型：支出或收入
    final type =
        category?.type ?? (_tabController.index == 0 ? 'expense' : 'income');

    // 选中的图标
    IconData selectedIcon = category?.icon ?? Icons.category;

    // 选中的颜色
    Color selectedColor = category?.color ?? Colors.blue;

    // 显示底部表单
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20.w,
                right: 20.w,
                top: 20.h,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      isEditing ? '编辑类别' : '添加类别',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // 类别名称
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: '类别名称',
                        hintText: '输入类别名称',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入类别名称';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20.h),

                    // 选择图标
                    Text(
                      '选择图标:',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 10.h),

                    // 图标选择器
                    Container(
                      height: 120.h,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: GridView.builder(
                        padding: EdgeInsets.all(10.r),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 10.w,
                          mainAxisSpacing: 10.h,
                        ),
                        itemCount: _icons.length,
                        itemBuilder: (context, index) {
                          final icon = _icons[index];
                          return InkWell(
                            onTap: () {
                              setState(() {
                                selectedIcon = icon;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: selectedIcon == icon
                                    ? selectedColor.withOpacity(0.1)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: selectedIcon == icon
                                      ? selectedColor
                                      : Colors.transparent,
                                ),
                                borderRadius: BorderRadius.circular(5.r),
                              ),
                              child: Icon(
                                icon,
                                color: selectedIcon == icon
                                    ? selectedColor
                                    : Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // 选择颜色
                    Text(
                      '选择颜色:',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 10.h),

                    // 颜色选择器
                    Container(
                      height: 50.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _colors.length,
                        itemBuilder: (context, index) {
                          final color = _colors[index];
                          return InkWell(
                            onTap: () {
                              setState(() {
                                selectedColor = color;
                              });
                            },
                            child: Container(
                              width: 40.w,
                              height: 40.w,
                              margin: EdgeInsets.symmetric(horizontal: 5.w),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor == color
                                      ? Colors.black
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 30.h),

                    // 操作按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // 取消按钮
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('取消'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 10.h,
                            ),
                          ),
                        ),

                        // 保存按钮
                        ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final categoryProvider =
                                  Provider.of<CategoryProvider>(
                                context,
                                listen: false,
                              );

                              try {
                                if (isEditing) {
                                  // 更新类别
                                  await categoryProvider.updateCategory(
                                    category!.id,
                                    CategoryModel(
                                      id: category.id,
                                      name: nameController.text,
                                      type: type,
                                      icon: selectedIcon,
                                      color: selectedColor,
                                      isDefault: category.isDefault,
                                    ),
                                  );
                                  ToastUtil.showSuccess('类别已更新');
                                } else {
                                  // 添加类别
                                  final id = DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString();
                                  await categoryProvider.addCategory(
                                    CategoryModel(
                                      id: id,
                                      name: nameController.text,
                                      type: type,
                                      icon: selectedIcon,
                                      color: selectedColor,
                                    ),
                                  );
                                  ToastUtil.showSuccess('类别已添加');
                                }

                                if (!mounted) return;
                                Navigator.pop(context);
                              } catch (e) {
                                ToastUtil.showError(e.toString());
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 10.h,
                            ),
                          ),
                          child: Text(isEditing ? '更新' : '添加'),
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 显示删除确认对话框
  Future<void> _showDeleteConfirmation(
      BuildContext context, CategoryModel category) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('您确定要删除"${category.name}"类别吗？'),
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

    if (result == true) {
      try {
        final categoryProvider =
            Provider.of<CategoryProvider>(context, listen: false);
        await categoryProvider.deleteCategory(category.id);
        ToastUtil.showSuccess('类别已删除');
      } catch (e) {
        ToastUtil.showError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('类别管理'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryForm(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 支出类别列表
          _buildCategoryList('expense'),

          // 收入类别列表
          _buildCategoryList('income'),
        ],
      ),
    );
  }

  // 构建类别列表
  Widget _buildCategoryList(String type) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, _) {
        final categories = categoryProvider.getCategoriesByType(type);

        return Padding(
          padding: EdgeInsets.all(15.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${type == 'expense' ? '支出' : '收入'}类别',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10.h),
              Expanded(
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];

                    return Card(
                      margin: EdgeInsets.only(bottom: 10.r),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40.r,
                          height: 40.r,
                          decoration: BoxDecoration(
                            color: category.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            category.icon,
                            color: category.color,
                          ),
                        ),
                        title: Text(
                          category.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: category.isDefault
                            ? Text(
                                '默认类别',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 12.sp,
                                ),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 编辑按钮
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _showCategoryForm(category: category),
                              color: Colors.blue,
                            ),

                            // 删除按钮
                            if (!category.isDefault)
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    _showDeleteConfirmation(context, category),
                                color: Colors.red,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 可选择的图标列表
  final List<IconData> _icons = [
    Icons.restaurant,
    Icons.shopping_bag,
    Icons.directions_car,
    Icons.home,
    Icons.school,
    Icons.local_hospital,
    Icons.movie,
    Icons.sports_basketball,
    Icons.flight_takeoff,
    Icons.hotel,
    Icons.beach_access,
    Icons.child_care,
    Icons.pets,
    Icons.fitness_center,
    Icons.wifi,
    Icons.phone_android,
    Icons.account_balance,
    Icons.credit_card,
    Icons.card_giftcard,
    Icons.attach_money,
    Icons.trending_up,
    Icons.store,
    Icons.business,
    Icons.work,
    Icons.more_horiz,
  ];

  // 可选择的颜色列表
  final List<Color> _colors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];
}
