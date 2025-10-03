import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ui_quiz/screens/quiz/quiz_list_screen.dart';
import 'package:ui_quiz/screens/profile/profile_screen.dart';
import 'package:ui_quiz/screens/quiz/quiz_generator.dart';

class CustomTabBarWidget extends StatefulWidget {
  final int initialIndex;

  const CustomTabBarWidget({super.key, this.initialIndex = 0});

  @override
  State<CustomTabBarWidget> createState() => _CustomTabBarWidgetState();
}

class _CustomTabBarWidgetState extends State<CustomTabBarWidget> {
  late int _selectedIndex;

  final List<Widget> _pages = [
    const QuizGeneratorContent(),
    const QuizListScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: FlashyTabBar(
        selectedIndex: _selectedIndex,
        showElevation: true,
        onItemSelected: (index) => setState(() => _selectedIndex = index),
        items: [
          FlashyTabBarItem(
            icon: Image.asset('asset/icon/magic.png', width: 30, height: 30),
            title: const Text('Generate'),
            activeColor: Colors.lime,
          ),
          FlashyTabBarItem(
            icon: Image.asset(
              'asset/icon/checklist.png',
              width: 26,
              height: 26,
            ),
            title: const Text('Saved'),
            activeColor: Colors.lime,
          ),
          FlashyTabBarItem(
            icon: Image.asset('asset/icon/account.png', width: 28, height: 28),
            title: const Text('Profile'),
            activeColor: Colors.lime,
          ),
        ],
      ),
    );
  }

  // Dış kaynaklardan tab değiştirme için method
  void changeTab(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }
}
