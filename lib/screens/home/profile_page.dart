import 'package:flutter/material.dart';
import 'package:haoshengyi_jzzs_app/constants/app_constants.dart';
import 'package:haoshengyi_jzzs_app/models/user_model.dart';
import 'package:haoshengyi_jzzs_app/providers/auth_provider.dart';
import 'package:haoshengyi_jzzs_app/screens/auth/login_screen.dart';
import 'package:haoshengyi_jzzs_app/theme/app_theme.dart';
import 'package:haoshengyi_jzzs_app/utils/toast_util.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// 个人中心页面
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;

          return user == null
              ? _buildNotLoggedIn(context)
              : _buildProfile(context, authProvider, user);
        },
      ),
    );
  }

  // 构建未登录的视图
  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle,
            size: 100.sp,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 20.h),
          Text(
            '您尚未登录',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            '登录后可以查看您的个人信息',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          SizedBox(height: 30.h),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 12.h),
            ),
            child: const Text('立即登录'),
          ),
        ],
      ),
    );
  }

  // 构建已登录的个人中心
  Widget _buildProfile(
      BuildContext context, AuthProvider authProvider, UserModel user) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(15.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户头像和基本信息
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(15.r),
              child: Row(
                children: [
                  // 头像 - 添加点击修改功能
                  GestureDetector(
                    onTap: () =>
                        _showEditProfileDialog(context, authProvider, user),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40.r,
                          backgroundColor:
                              AppTheme.primaryColor.withOpacity(0.1),
                          child: Text(
                            user.nickname.isNotEmpty
                                ? user.nickname[0].toUpperCase()
                                : '用',
                            style: TextStyle(
                              fontSize: 30.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        // 添加编辑图标
                        // Positioned(
                        //   right: 0,
                        //   bottom: 0,
                        //   child: Container(
                        //     padding: EdgeInsets.all(4.r),
                        //     decoration: BoxDecoration(
                        //       color: Colors.white,
                        //       shape: BoxShape.circle,
                        //       border: Border.all(
                        //         color: Colors.grey.shade200,
                        //         width: 1,
                        //       ),
                        //     ),
                        //     child: Icon(
                        //       Icons.edit,
                        //       size: 16.sp,
                        //       color: AppTheme.primaryColor,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20.w),
                  // 用户信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user.nickname.isNotEmpty ? user.nickname : '用户',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 5.w),
                            // 添加编辑按钮
                            GestureDetector(
                              onTap: () => _showEditProfileDialog(
                                  context, authProvider, user),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 18.sp,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          user.phone,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20.h),

          // 功能选项列表
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Column(
              children: [
                _buildListTile(
                  context,
                  title: '账户信息',
                  icon: Icons.person,
                  onTap: () {
                    // TODO: 实现账户信息页面
                    ToastUtil.showInfo('账户信息页面开发中');
                  },
                ),
                _buildDivider(),
                _buildListTile(
                  context,
                  title: '我的会员',
                  icon: Icons.card_membership,
                  onTap: () {
                    // TODO: 实现会员页面
                    ToastUtil.showInfo('会员功能开发中');
                  },
                ),
                _buildDivider(),
                _buildListTile(
                  context,
                  title: '设置',
                  icon: Icons.settings,
                  onTap: () {
                    // TODO: 实现设置页面
                    ToastUtil.showInfo('设置页面开发中');
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // 帮助和支持
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Column(
              children: [
                _buildListTile(
                  context,
                  title: '帮助中心',
                  icon: Icons.help,
                  onTap: () {
                    // TODO: 实现帮助中心
                    ToastUtil.showInfo('帮助中心开发中');
                  },
                ),
                _buildDivider(),
                _buildListTile(
                  context,
                  title: '关于我们',
                  icon: Icons.info,
                  onTap: () {
                    // TODO: 实现关于我们页面
                    ToastUtil.showInfo('关于我们页面开发中');
                  },
                ),
                _buildDivider(),
                _buildListTile(
                  context,
                  title: '反馈问题',
                  icon: Icons.feedback,
                  onTap: () {
                    // TODO: 实现反馈问题页面
                    ToastUtil.showInfo('反馈问题页面开发中');
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 30.h),

          // 退出登录按钮 - 风格调整
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => _logout(context, authProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.r),
                  side: BorderSide(color: Colors.red.withOpacity(0.3), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    '退出登录',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  // 退出登录
  Future<void> _logout(BuildContext context, AuthProvider authProvider) async {
    // 显示确认对话框
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('您确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              '退出',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      ToastUtil.showLoading(message: '正在退出...');
      await authProvider.logout();
      final success = true;
      ToastUtil.dismissLoading();

      if (success) {
        ToastUtil.showSuccess('已退出登录');
      } else {
        ToastUtil.showError('退出登录失败');
      }
    } catch (e) {
      ToastUtil.dismissLoading();
      ToastUtil.showError('退出登录失败：$e');
    }
  }

  // 构建列表项
  Widget _buildListTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.primaryColor,
        size: 24.sp,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15.sp,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey,
        size: 22.sp,
      ),
      onTap: onTap,
    );
  }

  // 构建分隔线
  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 70.w,
      endIndent: 0,
      color: Colors.grey.shade200,
    );
  }
}

// 添加编辑个人资料对话框
Future<void> _showEditProfileDialog(
    BuildContext context, AuthProvider authProvider, UserModel user) async {
  final TextEditingController nicknameController =
      TextEditingController(text: user.nickname);

  final result = await showDialog<Map<String, String?>>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('编辑个人资料'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 昵称输入框
          TextField(
            controller: nicknameController,
            decoration: InputDecoration(
              labelText: '昵称',
              hintText: '请输入您的昵称',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            maxLength: 50,
          ),
          SizedBox(height: 15.h),
          // 头像上传功能（简化版）
          Text(
            '头像功能暂未开放，敬请期待',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'nickname': nicknameController.text.trim(),
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: Text('保存'),
        ),
      ],
    ),
  );

  // 如果用户点击了保存按钮
  if (result != null) {
    final newNickname = result['nickname'];

    // 如果昵称有变化
    if (newNickname != null && newNickname != user.nickname) {
      try {
        ToastUtil.showLoading(message: '正在更新...');

        // 调用API更新用户信息
        await authProvider.updateUserInfo(nickname: newNickname);

        ToastUtil.dismissLoading();
        ToastUtil.showSuccess('更新成功');
      } catch (e) {
        ToastUtil.dismissLoading();
        ToastUtil.showError('更新失败: $e');
      }
    }
  }
}
