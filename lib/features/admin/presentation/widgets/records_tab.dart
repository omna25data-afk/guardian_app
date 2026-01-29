import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecordsTab extends StatelessWidget {
  const RecordsTab({super.key});

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
                Tab(text: 'السجلات'),
                Tab(text: 'القيود'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPlaceholder('إدارة السجلات'),
                _buildPlaceholder('إدارة القيود'),
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
