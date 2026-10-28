import 'package:flutter/material.dart';
import 'package:vetpax_frontend/features/vetpax/presentation/pages/owner_tabs.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
 
class MainPage extends StatefulWidget {
  const MainPage({super.key});
 
  @override
  State<MainPage> createState() => _MainPageState();
}
 
class _MainPageState extends State<MainPage> {
  late PersistentTabController _controller;
 
  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
  }
 
  // Pantallas en blanco — cada equipo las completa
  List<Widget> _buildScreens() {
    return const [
      PetsTab(),
      ClinicsTab(),
      TreatmentsTab(),
      AdherenceTab(),
      ProfileTab(),
    ];
  }
 
  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home_outlined),
        inactiveIcon: const Icon(Icons.home),
        title: 'Home',
        activeColorPrimary: const Color(0xFF2563EB),
        inactiveColorPrimary: const Color(0xFF6B7280),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.search_outlined),
        inactiveIcon: const Icon(Icons.search),
        title: 'Search',
        activeColorPrimary: const Color(0xFF2563EB),
        inactiveColorPrimary: const Color(0xFF6B7280),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.pending_outlined),
        inactiveIcon: const Icon(Icons.pending),
        title: 'Process',
        activeColorPrimary: const Color(0xFF2563EB),
        inactiveColorPrimary: const Color(0xFF6B7280),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.card_giftcard_outlined),
        inactiveIcon: const Icon(Icons.card_giftcard),
        title: 'Rewards',
        activeColorPrimary: const Color(0xFF2563EB),
        inactiveColorPrimary: const Color(0xFF6B7280),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person_outline),
        inactiveIcon: const Icon(Icons.person),
        title: 'Profile',
        activeColorPrimary: const Color(0xFF2563EB),
        inactiveColorPrimary: const Color(0xFF6B7280),
      ),
    ];
  }
 
  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      confineToSafeArea: true,
      backgroundColor: Colors.white,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
      hideNavigationBarWhenKeyboardAppears: true,
      navBarStyle: NavBarStyle.style3,
    );
  }
 
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}