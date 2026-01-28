import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:guardian_app/providers/dashboard_provider.dart';
import 'package:guardian_app/features/dashboard/data/models/dashboard_data.dart';
import 'package:guardian_app/providers/record_book_provider.dart';
import 'package:guardian_app/providers/registry_entry_provider.dart';

// --- Main HomeScreen (Shell) ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize TabController for the RecordsTab
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // The list of main widgets for the BottomNavigationBar
    final List<Widget> widgetOptions = <Widget>[
      const MainTab(),
      // RecordsTab is now built directly here to use the TabController
      Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                RecordBooksList(),
                RegistryEntriesList(),
              ],
            ),
          ),
        ],
      ),
      const AddEntryTab(),
      const ToolsTab(),
      const MoreTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('بوابة الأمين الشرعي'),
        titleTextStyle: GoogleFonts.tajawal(textStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF006400),
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        // Conditionally show the TabBar for the Records screen
        bottom: _selectedIndex == 1
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'سجلاتي'),
                  Tab(text: 'قيودي'),
                ],
                indicatorColor: Colors.white,
                labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
                unselectedLabelStyle: GoogleFonts.tajawal(),
              )
            : null,
      ),
      body: Center(
        child: widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.book_online), label: 'سجلاتي'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle, size: 40), label: 'إضافة'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'الأدوات'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'المزيد'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF006400),
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.tajawal(),
      ),
    );
  }
}

// --- Main Dashboard Tab ---
class MainTab extends StatefulWidget {
  const MainTab({super.key});
  @override
  State<MainTab> createState() => _MainTabState();
}

class _MainTabState extends State<MainTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.errorMessage != null || provider.dashboardData == null) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('حدث خطأ أثناء جلب البيانات', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: () => provider.fetchDashboard(), child: const Text('إعادة المحاولة')),
            ]),
          );
        }
        final dashboard = provider.dashboardData!;
        return _buildDashboardUI(context, dashboard);
      },
    );
  }

  Widget _buildDashboardUI(BuildContext context, DashboardData dashboard) {
    return RefreshIndicator(
      onRefresh: () => Provider.of<DashboardProvider>(context, listen: false).fetchDashboard(),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildWelcomeCard(context, dashboard),
          const SizedBox(height: 16),
          _buildStatsGrid(context, dashboard.stats),
          const SizedBox(height: 16),
          _buildStatusCard(context, 'حالة الترخيص', dashboard.licenseStatus),
          const SizedBox(height: 12),
          _buildStatusCard(context, 'حالة البطاقة', dashboard.cardStatus),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, DashboardData dashboard) {
    return Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(dashboard.welcomeMessage, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(dashboard.dateGregorian, style: Theme.of(context).textTheme.bodyMedium), Text(dashboard.dateHijri, style: Theme.of(context).textTheme.bodyMedium)])));
  }

  Widget _buildStatsGrid(BuildContext context, DashboardStats stats) {
    return GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.5, children: [_buildStatItem(context, 'إجمالي القيود', stats.totalEntries.toString()), _buildStatItem(context, 'المسودات', stats.totalDrafts.toString()), _buildStatItem(context, 'الموثق', stats.totalDocumented.toString()), _buildStatItem(context, 'قيود هذا الشهر', stats.thisMonthEntries.toString())]);
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Card(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), child: Padding(padding: const EdgeInsets.all(8.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center)])));
  }

  Widget _buildStatusCard(BuildContext context, String title, RenewalStatus status) {
    return Card(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 4), Text('تنتهي في: ${status.expiryDate?.year}/${status.expiryDate?.month}/${status.expiryDate?.day}', style: Theme.of(context).textTheme.bodySmall)]), Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: status.color.withAlpha(30), borderRadius: BorderRadius.circular(20)), child: Text(status.label, style: TextStyle(color: status.color, fontWeight: FontWeight.bold))), const SizedBox(width: 8), const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)])])));
  }
}

// --- Widget for displaying Record Books ---
class RecordBooksList extends StatefulWidget {
  const RecordBooksList({super.key});
  @override
  State<RecordBooksList> createState() => _RecordBooksListState();
}

class _RecordBooksListState extends State<RecordBooksList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecordBookProvider>(context, listen: false).fetchRecordBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordBookProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.recordBooks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.errorMessage != null) {
          return Center(child: Text(provider.errorMessage!));
        }
        return RefreshIndicator(
          onRefresh: () => provider.fetchRecordBooks(),
          child: ListView.builder(
            itemCount: provider.recordBooks.length,
            itemBuilder: (context, index) {
              final book = provider.recordBooks[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: book.statusColor, child: Text(book.number.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  title: Text(book.title),
                  subtitle: Text(book.contractType),
                  trailing: SizedBox(
                    width: 100,
                    child: Row(children:[
                      Expanded(child: LinearProgressIndicator(value: book.usagePercentage / 100, backgroundColor: Colors.grey[300], color: book.statusColor,)),
                      const SizedBox(width: 8),
                      Text('${book.usagePercentage}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ])
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// --- Widget for displaying Registry Entries ---
class RegistryEntriesList extends StatefulWidget {
  const RegistryEntriesList({super.key});
  @override
  State<RegistryEntriesList> createState() => _RegistryEntriesListState();
}

class _RegistryEntriesListState extends State<RegistryEntriesList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RegistryEntryProvider>(context, listen: false).fetchEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RegistryEntryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.entries.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.errorMessage != null) {
          return Center(child: Text(provider.errorMessage!));
        }
        return RefreshIndicator(
          onRefresh: () => provider.fetchEntries(),
          child: ListView.builder(
            itemCount: provider.entries.length,
            itemBuilder: (context, index) {
              final entry = provider.entries[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: Icon(Icons.description, color: entry.statusColor),
                  title: Text('${entry.firstParty} - ${entry.secondParty}'),
                  subtitle: Text('${entry.contractType} - ${entry.dateHijri}'),
                  trailing: Text(entry.statusLabel, style: TextStyle(color: entry.statusColor, fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// --- Other placeholder tabs ---
class AddEntryTab extends StatelessWidget {
  const AddEntryTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('إضافة قيد'));
}
class ToolsTab extends StatelessWidget {
  const ToolsTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('الأدوات'));
}
class MoreTab extends StatelessWidget {
  const MoreTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('المزيد'));
}
