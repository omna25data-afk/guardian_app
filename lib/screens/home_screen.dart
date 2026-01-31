import 'package:flutter/material.dart';
import 'package:guardian_app/features/records/presentation/screens/record_book_notebooks_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guardian_app/widgets/stat_card.dart';
import 'package:provider/provider.dart';

import 'package:guardian_app/providers/dashboard_provider.dart';
import 'package:guardian_app/features/dashboard/data/models/dashboard_data.dart';
import 'package:guardian_app/providers/record_book_provider.dart';
import 'package:guardian_app/providers/registry_entry_provider.dart';
import 'package:guardian_app/features/registry/presentation/add_entry_screen.dart';
import 'package:guardian_app/features/registry/presentation/entry_details_screen.dart'; // Add Import
import 'package:guardian_app/features/profile/presentation/profile_screen.dart';

// --- Main HomeScreen (Shell) ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
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

    final List<Widget> widgetOptions = <Widget>[
      const MainTab(),
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
      const AddEntryScreen(), // Use new AddEntryScreen
      const ToolsTab(),
      const ProfileScreen(), // Use ProfileScreen instead of MoreTab
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('بوابة الأمين الشرعي'),
        titleTextStyle: GoogleFonts.tajawal(
            textStyle: textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF006400),
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
      body: _selectedIndex == 1
          ? Column(
              children: [
                // Custom Tab Bar Container
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'سجلاتي'),
                      Tab(text: 'قيودي'),
                    ],
                    indicator: BoxDecoration(
                      color: const Color(0xFF006400),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    // unselectedLabelColor: Colors.grey[600],
                    labelStyle: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    unselectedLabelStyle: GoogleFonts.tajawal(
                        fontWeight: FontWeight.w500, fontSize: 16),
                    dividerColor: Colors.transparent,
                    padding: const EdgeInsets.all(4),
                  ),
                ),
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
            )
          : Center(
              child: widgetOptions.elementAt(_selectedIndex),
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(
              icon: Icon(Icons.book_online), label: 'سجلاتي'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle, size: 40), label: 'إضافة'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'الأدوات'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF006400),
        //unselectedLabelColor: Colors.grey[600],
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
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('حدث خطأ أثناء جلب البيانات',
                  style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              ElevatedButton(
                  onPressed: () => provider.fetchDashboard(),
                  child: const Text('إعادة المحاولة')),
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
      onRefresh: () => Provider.of<DashboardProvider>(context, listen: false)
          .fetchDashboard(),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildWelcomeCard(context, dashboard),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              "إحصائياتي",
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildStatsGrid(context, dashboard.stats),
          const SizedBox(height: 24),
          _buildStatusCard(context, 'حالة الترخيص', dashboard.licenseStatus),
          const SizedBox(height: 12),
          _buildStatusCard(context, 'حالة البطاقة', dashboard.cardStatus),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, DashboardData dashboard) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dashboard.welcomeMessage,
              style: GoogleFonts.tajawal(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF006400),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dashboard.dateGregorian,
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(dashboard.dateHijri,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, DashboardStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2, // Adjust aspect ratio for the new card design
      children: [
        StatCard(
          title: 'إجمالي القيود',
          count: stats.totalEntries.toString(),
          icon: Icons.all_inbox_outlined,
          iconColor: Colors.blue,
        ),
        StatCard(
          title: 'المسودات',
          count: stats.totalDrafts.toString(),
          icon: Icons.drafts_outlined,
          iconColor: Colors.orange,
        ),
        StatCard(
          title: 'الموثق',
          count: stats.totalDocumented.toString(),
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
        ),
        StatCard(
          title: 'قيود هذا الشهر',
          count: stats.thisMonthEntries.toString(),
          icon: Icons.calendar_today_outlined,
          iconColor: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatusCard(
      BuildContext context, String title, RenewalStatus status) {
    return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                            'تنتهي في: ${status.expiryDate?.year}/${status.expiryDate?.month}/${status.expiryDate?.day}',
                            style: Theme.of(context).textTheme.bodySmall)
                      ]),
                  Row(children: [
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: status.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(status.label,
                            style: TextStyle(
                                color: status.color,
                                fontWeight: FontWeight.bold))),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey)
                  ])
                ])));
  }
}

// --- Widget for displaying Record Books as Cards ---
class RecordBooksList extends StatefulWidget {
  const RecordBooksList({super.key});
  @override
  State<RecordBooksList> createState() => _RecordBooksListState();
}

class _RecordBooksListState extends State<RecordBooksList> {
  String? _selectedCategory;
  bool _showArchive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecordBookProvider>(context, listen: false)
          .fetchRecordBooks();
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

        // Filter based on Archive Mode and Category
        final allBooks = provider.recordBooks;

        // 1. Filter by Active/Archive
        final filteredBooks = allBooks
            .where((b) => _showArchive ? !b.isActive : b.isActive)
            .toList();

        // 2. Group by Fixed 7 Categories
        // Initialize with zeros
        final categoryMaxNumbers = <String, int>{
          'سجلات المبيع': 0,
          'سجلات الزواج': 0,
          'سجلات الطلاق': 0,
          'سجلات الرجعة': 0,
          'سجلات التصرفات': 0,
          'سجلات القسمة': 0,
          'سجلات الوكالات': 0,
        };

        // Helper to map API labels to our 7 categories
        String getStandardCategory(String label) {
          if (label.contains('مبيع') || label.contains('بيع')) return 'سجلات المبيع';
          if (label.contains('زواج') || label.contains('نكاح')) return 'سجلات الزواج';
          if (label.contains('طلاق')) return 'سجلات الطلاق';
          if (label.contains('رجعة')) return 'سجلات الرجعة';
          if (label.contains('تصرف') || label.contains('إقرار')) return 'سجلات التصرفات';
          if (label.contains('قسمة') || label.contains('تركة')) return 'سجلات القسمة';
          if (label.contains('وكال')) return 'سجلات الوكالات';
          return 'أخرى'; // Fallback
        }

        // Process books to find Max Book Number per category
        for (var book in filteredBooks) {
          // Use contractType instead of categoryLabel because categoryLabel is generic (e.g. "Guardian Recording")
          // while contractType holds the specific type (e.g. "Marriage Contract")
          final standardCat = getStandardCategory(book.contractType);
          if (categoryMaxNumbers.containsKey(standardCat)) {
             // Sum up the number of physical notebooks reported by the AP (notebooksCount)
             // Each 'book' item from API is now a container that might represent multiple notebooks.
             categoryMaxNumbers[standardCat] = (categoryMaxNumbers[standardCat] ?? 0) + book.notebooksCount;
          }
        }

        return Column(
          children: [
            // Archive Toggle Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _showArchive
                        ? '🗄️ الأرشيف (السجلات السابقة)'
                        : '📂 السجلات النشطة (الحالية)',
                    style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.bold,
                      color: _showArchive
                          ? Colors.amber[900]
                          : const Color(0xFF006400),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _showArchive,
                      onChanged: (val) {
                        setState(() {
                          _showArchive = val;
                          _selectedCategory =
                              null; // Reset selection when switching modes
                        });
                      },
                      activeThumbColor: Colors.amber[900],
                      inactiveThumbColor: const Color(0xFF006400),
                      inactiveTrackColor:
                          const Color(0xFF006400).withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),

            // Breadcrumb if category selected
            if (_selectedCategory != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      onPressed: () => setState(() => _selectedCategory = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedCategory!,
                      style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),

            // Main Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.fetchRecordBooks(),
                child: _selectedCategory == null
                    ? _buildCategoriesGrid(categoryMaxNumbers)
                    : _buildBooksList(filteredBooks
                        .where((b) => getStandardCategory(b.categoryLabel) == _selectedCategory)
                        .toList()),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoriesGrid(Map<String, int> categories) {
    if (categories.values.every((v) => v == 0) && _showArchive) {
       // Only show empty state if ALL are zero in Archive mode (Active mode usually shows categories even if empty)
       // But user wanted 7 containers always potentially? Let's keep showing them.
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories.keys.elementAt(index);
        final count = categories[category]!;
        return _buildCategoryCard(category, count);
      },
    );
  }

  Widget _buildCategoryCard(String title, int count) {
    return InkWell(
      onTap: () => setState(() => _selectedCategory = title),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _showArchive
                    ? Colors.amber[50]
                    : const Color(0xFF006400).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(title),
                color:
                    _showArchive ? Colors.amber[900] : const Color(0xFF006400),
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.tajawal(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count دفاتر',
                style: GoogleFonts.tajawal(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksList(List<dynamic> books) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return _buildRecordBookCard(book);
      },
    );
  }

  IconData _getCategoryIcon(String title) {
    if (title.contains('زواج')) return Icons.favorite;
    if (title.contains('طلاق')) return Icons.heart_broken;
    if (title.contains('وكالات')) return Icons.handshake;
    if (title.contains('مبيع')) return Icons.store;
    if (title.contains('تركة') || title.contains('قسمة')) {
      return Icons.pie_chart;
    }
    if (title.contains('تصرفات')) return Icons.gavel;
    if (title.contains('رجعة')) return Icons.replay;
    return Icons.menu_book;
  }



  Widget _buildRecordBookCard(dynamic book) {
    return InkWell(
      onTap: () {
         if (book.contractTypeId != null) {
           Navigator.push(context, MaterialPageRoute(
              builder: (_) => RecordBookNotebooksScreen(
                  contractTypeId: book.contractTypeId!, 
                  contractTypeName: book.contractType
              )
           ));
         }
      },
      child: Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              book.statusColor.withValues(alpha: 0.1),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: book.statusColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: book.statusColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '📖',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'سجل رقم ${book.number}',
                          style: GoogleFonts.tajawal(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${book.contractType} | ${book.hijriYear}هـ',
                          style: GoogleFonts.tajawal(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: book.statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      book.statusLabel,
                      style: TextStyle(
                        color: book.statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Statistics Row
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStat(Icons.list_alt, '${book.totalEntries}', 'إجمالي', Colors.blue),
                    _buildMiniStat(Icons.check_circle_outline, '${book.completedEntries}', 'موثق', Colors.green),
                    _buildMiniStat(Icons.history_edu, '${book.draftEntries}', 'غير موثق', Colors.orange),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Progress Section
              Row(
                children: [
                  Icon(Icons.description, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${book.usedPages}/${book.totalPages} صفحة',
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${book.usagePercentage}%',
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: book.statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: book.usagePercentage / 100,
                  minHeight: 10,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(book.statusColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16, color: color),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

// --- Widget for displaying Registry Entries as Table ---
class RegistryEntriesList extends StatefulWidget {
  const RegistryEntriesList({super.key});
  @override
  State<RegistryEntriesList> createState() => _RegistryEntriesListState();
}

class _RegistryEntriesListState extends State<RegistryEntriesList> {
  String _sortBy = 'date';
  bool _sortAscending = false;
  String? _filterStatus;

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

        // Filter and sort entries
        var entries = provider.entries.toList();
        if (_filterStatus != null) {
          entries =
              entries.where((e) => e.statusLabel == _filterStatus).toList();
        }

        return Column(
          children: [
            // Sort/Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  // Sort dropdown
                  DropdownButton<String>(
                    value: _sortBy,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'date', child: Text('التاريخ')),
                      DropdownMenuItem(value: 'status', child: Text('الحالة')),
                    ],
                    onChanged: (v) => setState(() => _sortBy = v!),
                  ),
                  IconButton(
                    icon: Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 18),
                    onPressed: () =>
                        setState(() => _sortAscending = !_sortAscending),
                  ),
                  const Spacer(),
                  // Filter chips
                  FilterChip(
                    label: const Text('الكل'),
                    selected: _filterStatus == null,
                    onSelected: (_) => setState(() => _filterStatus = null),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('مسودة'),
                    selected: _filterStatus == 'مسودة',
                    onSelected: (_) => setState(() => _filterStatus =
                        _filterStatus == 'مسودة' ? null : 'مسودة'),
                  ),
                ],
              ),
            ),
            // Entries Table
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.fetchEntries(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _buildEntryCard(entry);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEntryCard(dynamic entry) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Contract Info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.firstParty} ضد ${entry.secondParty}',
                        style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.contractType} | ${entry.dateHijri}هـ',
                        style: GoogleFonts.tajawal(
                            color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                // Serial Number Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${entry.serialNumber ?? "-"}',
                    style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Statuses Row
            Row(
              children: [
                // Documentation Status
                _buildStatusBadge(
                  label: entry.statusLabel,
                  color: entry.statusColor,
                  icon: Icons.assignment_turned_in,
                ),
                const SizedBox(width: 12),
                // Delivery Status
                if (entry.deliveryStatusLabel != null)
                  _buildStatusBadge(
                    label: entry.deliveryStatusLabel!,
                    color: entry.deliveryStatusColor,
                    icon: Icons.local_shipping,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Footer: View Details Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showEntryDetails(entry),
                icon: const Icon(Icons.visibility, size: 18),
                label: Text('عرض التفاصيل',
                    style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFF006400)),
                  foregroundColor: const Color(0xFF006400),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
      {required String label, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.tajawal(
                color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showEntryDetails(dynamic entry) {
    if (entry.id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EntryDetailsScreen(
          entryId: entry.id!, // Make sure your Entry model has 'id'
          entrySummary: entry, // Pass specific fields if needed
        ),
      ),
    ).then((_) {
        // Refresh list when coming back
        if (mounted) {
           Provider.of<RegistryEntryProvider>(context, listen: false).fetchEntries();
        }
    });
  }


}

// --- Tools Tab ---
class ToolsTab extends StatelessWidget {
  const ToolsTab({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('الأدوات - قريباً'));
}
