import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vu_mcqs_app/screen/home_screen.dart';
import 'package:vu_mcqs_app/screen/test_screen.dart';
import 'package:vu_mcqs_app/screen/progress_screen.dart';
import 'package:vu_mcqs_app/screen/user_profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  static const List<String> _tabTitles = [
    'Study',
    'Progress',
    'Test',
    'Me',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedIndex == 0
          ? const HomeScreen()
          : _selectedIndex == 1
              ? const ProgressScreen()
              : _selectedIndex == 2
                  ? const TestScreen()
                  : const UserProfileScreen(),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/bottomTab/study.svg', width: 24, height: 24),
            label: 'Study',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/bottomTab/progress.svg', width: 24, height: 24),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/bottomTab/test.svg', width: 24, height: 24),
            label: 'Test',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/bottomTab/person.svg', width: 24, height: 24),
            label: 'Me',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        backgroundColor: Theme.of(context).colorScheme.surface,
        onTap: _onItemTapped,
        showSelectedLabels: true,
        showUnselectedLabels: false,
      ),
    );
  }
}
