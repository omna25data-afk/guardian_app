import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> with SingleTickerProviderStateMixin {
  late TabController _guardianStatsController;

  @override
  void initState() {
    super.initState();
    _guardianStatsController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _guardianStatsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50], // Light background
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Welcome / Summary Header
          _buildSectionHeader('ملخص النظام', Icons.analytics),
          const SizedBox(height: 12),
          _buildSummaryCards(),
          
          const SizedBox(height: 24),
          
          // 2. Urgent Actions
          _buildSectionHeader('الإجراءات العاجلة ⚠️', Icons.notification_important, color: Colors.red),
          _buildUrgentActionsList(),

          const SizedBox(height: 24),

          // 3. Guardians Data Section (Tabs for Grid)
          _buildSectionHeader('بيانات الأمناء والتراخيص', Icons.people),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                TabBar(
                  controller: _guardianStatsController,
                  labelColor: const Color(0xFF006400),
                  unselectedLabelColor: Colors.grey,
                  labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
                  indicatorColor: const Color(0xFF006400),
                  tabs: const [
                    Tab(text: 'الأمناء'),
                    Tab(text: 'التراخيص'),
                    Tab(text: 'البطائق'),
                  ],
                ),
                SizedBox(
                  height: 280, // Fixed height for Grid View
                  child: TabBarView(
                    controller: _guardianStatsController,
                    children: [
                      // A. Guardians Stats
                      _buildGridStats([
                        _StatItem('إجمالي الأمناء', '150', Colors.blue, Icons.group),
                        _StatItem('على رأس العمل', '120', Colors.green, Icons.work),
                        _StatItem('موقوفين مؤقتاً', '5', Colors.orange, Icons.pause_circle),
                        _StatItem('متواري / غائب', '25', Colors.red, Icons.cancel),
                      ]),
                      // B. Licenses Stats
                      _buildGridStats([
                        _StatItem('إجمالي التراخيص', '150', Colors.indigo, Icons.card_membership),
                        _StatItem('تراخيص سارية', '100', Colors.green, Icons.check_circle),
                        _StatItem('تنتهي قريباً', '15', Colors.amber, Icons.warning),
                        _StatItem('منتهية', '35', Colors.red, Icons.error),
                      ]),
                      // C. Cards Stats
                      _buildGridStats([
                        _StatItem('إجمالي البطائق', '150', Colors.teal, Icons.badge),
                        _StatItem('بطائق سارية', '110', Colors.green, Icons.check_circle),
                        _StatItem('تنتهي قريباً', '10', Colors.amber, Icons.warning),
                        _StatItem('منتهية', '30', Colors.red, Icons.error),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4. Logs Sections
          _buildSectionHeader('آخر العمليات (Logs)', Icons.history),
          const SizedBox(height: 8),
          _buildLogsTab(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {Color color = const Color(0xFF006400)}) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return SizedBox(
      height: 140, // Height for chart placeholder
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pie_chart, size: 40, color: Colors.grey),
              Text('مساحة للرسوم البيانية التاعلية', style: GoogleFonts.tajawal(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrgentActionsList() {
    return Card(
      elevation: 0,
      color: Colors.red.withAlpha(20), // Light red bg
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side:BorderSide(color: Colors.red.withAlpha(50))),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.warning_amber, color: Colors.red),
            title: Text('تجديد ترخيص - الأمين محمد علي', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
            subtitle: Text('ينتهي خلال 3 أيام', style: GoogleFonts.tajawal(color: Colors.red)),
            trailing: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                elevation: 0,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(horizontal: 12)
              ),
              child: Text('تجديد', style: GoogleFonts.tajawal()),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.warning_amber, color: Colors.orange),
            title: Text('اعتماد عقد زواج معلق', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
            subtitle: Text('تاريخ الرفع: 2026-01-29', style: GoogleFonts.tajawal()),
             trailing: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.orange,
                elevation: 0,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(horizontal: 12)
              ),
              child: Text('عرض', style: GoogleFonts.tajawal()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridStats(List<_StatItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 cards per row
        childAspectRatio: 1.4, // Card ratio
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: item.color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 32, color: item.color),
              const SizedBox(height: 8),
              Text(
                item.value,
                style: GoogleFonts.tajawal(fontSize: 24, fontWeight: FontWeight.bold, color: item.color),
              ),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogsTab() {
     return DefaultTabController(
       length: 2,
       child: Column(
         children: [
           TabBar(
             labelColor: Colors.black87,
             unselectedLabelColor: Colors.grey,
             labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
             indicatorColor: Colors.blue,
             tabs: const [
               Tab(text: 'عملياتي (Admin)'),
               Tab(text: 'عمليات الأمناء'),
             ],
           ),
           SizedBox(
             height: 200,
             child: TabBarView(
               children: [
                 ListView(children: const [ListTile(title: Text('تم تسجيل الدخول'), leading: Icon(Icons.login))]),
                 ListView(children: const [ListTile(title: Text('الأمين x أضاف عقداً'), leading: Icon(Icons.add_circle))]),
               ],
             ),
           )
         ],
       ),
     );
  }
}

class _StatItem {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  _StatItem(this.title, this.value, this.color, this.icon);
}
