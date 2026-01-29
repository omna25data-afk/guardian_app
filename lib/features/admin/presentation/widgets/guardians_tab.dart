import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GuardiansTab extends StatelessWidget {
  const GuardiansTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              isScrollable: true,
              labelColor: const Color(0xFF006400),
              unselectedLabelColor: Colors.grey,
              labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
              indicatorColor: const Color(0xFF006400),
              tabs: const [
                Tab(text: 'الأمناء'),
                Tab(text: 'التراخيص'),
                Tab(text: 'البطائق'),
                Tab(text: 'مناطق الإختصاص'),
                Tab(text: 'التكليفات'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPlaceholder('قائمة الأمناء'),
                _buildPlaceholder('إدارة التراخيص'),
                _buildPlaceholder('إدارة البطائق'),
                _buildPlaceholder('مناطق الإختصاص'),
                _buildPlaceholder('التكليفات والمهام'),
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
