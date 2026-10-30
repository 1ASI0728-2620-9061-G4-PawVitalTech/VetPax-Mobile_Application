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
 
  List<Widget> _buildScreens() {
    return [
      DashboardTab(onNavigate: _controller.jumpToTab),
      const PetsTab(),
      const ClinicsTab(),
      const TreatmentsTab(),
      const ProfileTab(),
    ];
  }
 
  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home_outlined),
        inactiveIcon: const Icon(Icons.home),
        title: 'Inicio',
        activeColorPrimary: const Color(0xFF1DB9A9),
        inactiveColorPrimary: const Color(0xFF6B7280),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.pets_outlined),
        inactiveIcon: const Icon(Icons.pets),
        title: 'Mascotas',
        activeColorPrimary: const Color(0xFF1DB9A9),
        inactiveColorPrimary: const Color(0xFF6B7280),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.calendar_month_outlined),
        inactiveIcon: const Icon(Icons.calendar_month),
        title: 'Citas',
        activeColorPrimary: const Color(0xFF1DB9A9),
        inactiveColorPrimary: const Color(0xFF6B7280),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.medical_services_outlined),
        inactiveIcon: const Icon(Icons.medical_services),
        title: 'Cuidados',
        activeColorPrimary: const Color(0xFF1DB9A9),
        inactiveColorPrimary: const Color(0xFF6B7280),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person_outline),
        inactiveIcon: const Icon(Icons.person),
        title: 'Perfil',
        activeColorPrimary: const Color(0xFF1DB9A9),
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
