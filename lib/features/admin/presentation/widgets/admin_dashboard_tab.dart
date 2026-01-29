import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardTab extends StatelessWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('لوحة الإحصائيات المتقدمة', style: GoogleFonts.tajawal(fontSize: 18, color: Colors.grey)),
          Text('(قيد التطوير)', style: GoogleFonts.tajawal(fontSize: 14, color: Colors.grey[400])),
        ],
      ),
    );
  }
}
