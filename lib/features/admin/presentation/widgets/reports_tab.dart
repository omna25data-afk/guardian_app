import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: const Color(0xFF006400),
              unselectedLabelColor: Colors.grey,
              labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
              indicatorColor: const Color(0xFF006400),
              tabs: const [
                Tab(text: 'التقارير'),
                Tab(text: 'الإحصائيات'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPlaceholder('التقارير العامة'),
                _buildPlaceholder('الإحصائيات التفصيلية'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String title) {
    return Center(
      child: Text(title, style: GoogleFonts.tajawal(fontSize: 18, color: Colors.grey)),
    );
  }
}
