import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guardian_app/features/admin/data/models/admin_guardian_model.dart';
import 'package:guardian_app/providers/admin_guardians_provider.dart';
import 'package:guardian_app/features/admin/presentation/screens/add_edit_guardian_screen.dart';
import 'dart:async';

class GuardiansListTab extends StatefulWidget {
  const GuardiansListTab({super.key});

  @override
  State<GuardiansListTab> createState() => _GuardiansListTabState();
}

class _GuardiansListTabState extends State<GuardiansListTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    
    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _fetchData();
    }
  }

  void _fetchData() {
    final status = switch (_tabController.index) {
      0 => 'all',
      1 => 'active',
      2 => 'stopped',
      _ => 'all',
    };
    
    Provider.of<AdminGuardiansProvider>(context, listen: false)
        .fetchGuardians(refresh: true, status: status, search: _searchController.text);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<AdminGuardiansProvider>(context, listen: false)
          .setSearchQuery(query);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

      ],
    );
  }

  // Floating Action Button needed?
  // Since this is a tab inside a scaffold, we can return the body or we might need to modify the parent screen to show FAB.
  // Instead of FAB, we can add a 'Add' button in the header or use an Overlay entry or just modify the parent `AdminGuardiansManagementScreen`.
  // However, `AdminGuardiansManagementScreen` uses DefaultTabController.
  // Let's add the FAB inside the Stack or Scaffold.
  // Actually, we are returning a Column. We can use a Stack or wrap content in Scaffold (nested) or just put a button in the UI.
  // A clean way is adding a button in search row or a floating button.
  
  // Let's add a '+' button next to Query field or as a FAB in `AdminGuardiansManagementScreen`.
  // But since I am editing `GuardiansListTab`, I can wrap the Column in a generic Widget that has a Stack for FAB if needed, OR relies on the parent.
  // Let's modify the build method to return Expanded + Stack or similar.
  // Simplest: Add an IconButton in the Search Row.

  // Let's modify the Build Method to use Stack for FAB
  /* 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEdit(null),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(...)
    );
  }
  */
  // But wait, it's a tab, nested Scaffold works.

  Future<void> _navigateToEdit(AdminGuardian? guardian) async {
     final result = await Navigator.push(
       context,
       MaterialPageRoute(builder: (_) => AddEditGuardianScreen(guardian: guardian)),
     );
     
     if (result == true) {
       _fetchData();
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEdit(null),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'بحث عن أمين (الاسم، الرقم...)',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
            tabs: const [
              Tab(text: 'الكل'),
              Tab(text: 'على رأس العمل'),
              Tab(text: 'متوقف'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // List
        Expanded(
          child: Consumer<AdminGuardiansProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.guardians.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(provider.error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _fetchData(),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }

              if (provider.guardians.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'لا يوجد أمناء',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (!provider.isLoading &&
                      provider.hasMore &&
                      scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                    provider.fetchGuardians();
                  }
                  return false;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: provider.guardians.length + (provider.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.guardians.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final guardian = provider.guardians[index];
                    return _buildGuardianCard(context, guardian);
                  },
                ),
              );
            },
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildGuardianCard(BuildContext context, AdminGuardian guardian) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToEdit(guardian),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[100],
                  backgroundImage: guardian.photoUrl != null 
                    ? NetworkImage(guardian.photoUrl!) 
                    : null,
                  child: guardian.photoUrl == null
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              guardian.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusBadge(
                            guardian.employmentStatus ?? 'غير محدد',
                            guardian.employmentStatusColor ?? 'grey',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الرقم التسلسلي: ${guardian.serialNumber}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      if (guardian.phone != null)
                        Text(
                          'الهاتف: ${guardian.phone}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      
                      const SizedBox(height: 8),
                      
                      // Badges Row
                      Row(
                        children: [
                          if (guardian.licenseStatus != null)
                            Expanded(child: _buildMiniBadge('الترخيص', guardian.licenseStatus!, guardian.licenseColor)),
                          const SizedBox(width: 8),
                          if (guardian.cardStatus != null)
                            Expanded(child: _buildMiniBadge('البطاقة', guardian.cardStatus!, guardian.cardColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, String colorName) {
    Color color;
    switch (colorName) {
      case 'success': color = Colors.green; break;
      case 'danger': color = Colors.red; break;
      case 'warning': color = Colors.orange; break;
      case 'primary': color = const Color(0xFF006400); break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMiniBadge(String label, String value, String? colorName) {
    Color color;
    switch (colorName) {
      case 'success': color = Colors.green; break;
      case 'danger': color = Colors.red; break;
      case 'warning': color = Colors.orange; break;
      default: color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
