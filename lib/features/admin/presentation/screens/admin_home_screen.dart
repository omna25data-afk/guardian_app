import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guardian_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:guardian_app/features/admin/presentation/widgets/admin_dashboard_tab.dart';
import 'package:guardian_app/features/admin/presentation/widgets/guardians_tab.dart';
import 'package:guardian_app/features/admin/presentation/widgets/records_tab.dart';
import 'package:guardian_app/features/admin/presentation/widgets/reports_tab.dart';
import 'package:guardian_app/features/admin/presentation/widgets/tools_tab.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminDashboardTab(),
    const GuardiansTab(),
    const RecordsTab(),
    const ReportsTab(),
    const ToolsTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF006400),
        automaticallyImplyLeading: false, // Hide back button
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: user?.avatarUrl != null 
                  ? NetworkImage(user!.avatarUrl!) 
                  : const AssetImage('assets/images/placeholder_avatar.png') as ImageProvider,
              radius: 18,
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              onSelected: (value) {
                if (value == 'logout') {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.black54),
                        const SizedBox(width: 8),
                        Text('الملف الشخصي', style: GoogleFonts.tajawal()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        const Icon(Icons.settings, color: Colors.black54),
                        const SizedBox(width: 8),
                        Text('الإعدادات', style: GoogleFonts.tajawal()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'dark_mode',
                    child: Row(
                      children: [
                        const Icon(Icons.nightlight_round, color: Colors.black54),
                        const SizedBox(width: 8),
                        Text('الوضع الليلي', style: GoogleFonts.tajawal()),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('تسجيل الخروج', style: GoogleFonts.tajawal(color: Colors.red)),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        actions: [
           IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Notification logic
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                'مرحباً، ${user?.name ?? "الرئيس"}',
                style: GoogleFonts.tajawal(
                  textStyle: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'الأمناء'),
          BottomNavigationBarItem(icon: Icon(Icons.source), label: 'السجلات'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'التقارير'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'الأدوات'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF006400),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        selectedLabelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.tajawal(),
      ),
    );
  }
}
