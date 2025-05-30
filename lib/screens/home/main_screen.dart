import 'package:flutter/material.dart';
import 'package:haoshengyi_jzzs_app/constants/app_constants.dart';
import 'package:haoshengyi_jzzs_app/providers/auth_provider.dart';
import 'package:haoshengyi_jzzs_app/providers/transaction_provider.dart';
import 'package:haoshengyi_jzzs_app/screens/home/home_page.dart';
import 'package:haoshengyi_jzzs_app/screens/home/profile_page.dart';
import 'package:haoshengyi_jzzs_app/screens/stats/stats_page.dart';
import 'package:haoshengyi_jzzs_app/screens/transactions/transactions_page.dart';
import 'package:haoshengyi_jzzs_app/theme/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// 主页面，包含底部导航栏和多个子页面
class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  // 页面列表
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // 初始化当前索引
    _currentIndex = widget.initialIndex;

    // 初始化页面
    _pages = [
      const HomePage(),
      const TransactionsPage(),
      const StatsPage(),
      const ProfilePage(),
    ];

    // 初始化数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  // 初始化数据
  Future<void> _initData() async {
    // 获取交易记录和统计数据
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);

    // 初始化数据
    await transactionProvider.initializeData();
  }

  // 切换页面
  void _onItemTapped(int index) {
    // 如果是从其他页面切换到首页（索引0），刷新首页数据
    if (_currentIndex != 0 && index == 0) {
      // 延迟一帧后刷新首页数据
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider =
            Provider.of<TransactionProvider>(context, listen: false);
        final today = DateTime.now();
        final todayStr =
            "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
        provider.getHomePageData(todayStr);
      });
    }
    // 如果是从其他页面切换到交易记录页（索引1），刷新交易记录数据
    else if (_currentIndex != 1 && index == 1) {
      // 延迟一帧后刷新交易记录数据
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider =
            Provider.of<TransactionProvider>(context, listen: false);
        final now = DateTime.now();
        final currentMonth =
            "${now.year}年${now.month.toString().padLeft(2, '0')}月";
        provider.getTransactionsByMonth(currentMonth);
      });
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12.sp,
          unselectedFontSize: 12.sp,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '首页',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: '流水',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart),
              label: '统计',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}
