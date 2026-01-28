import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guardian_app/providers/dashboard_provider.dart';
import 'package:guardian_app/providers/record_book_provider.dart';
import 'package:guardian_app/providers/registry_entry_provider.dart';
import 'package:guardian_app/features/auth/data/repositories/auth_repository.dart';
import 'package:guardian_app/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:guardian_app/features/records/data/repositories/records_repository.dart';
import 'package:guardian_app/features/registry/data/repositories/registry_repository.dart';
import 'package:guardian_app/screens/login_screen.dart';
import 'package:provider/provider.dart';

void main() {
  // Create repositories
  final authRepository = AuthRepository();
  final dashboardRepository = DashboardRepository(authRepository: authRepository);
  final recordsRepository = RecordsRepository(authRepository: authRepository);
  final registryRepository = RegistryRepository(authRepository: authRepository);

  runApp(MyApp(
    dashboardRepository: dashboardRepository,
    recordsRepository: recordsRepository,
    registryRepository: registryRepository,
  ));
}

class MyApp extends StatelessWidget {
  final DashboardRepository dashboardRepository;
  final RecordsRepository recordsRepository;
  final RegistryRepository registryRepository;

  const MyApp({
    super.key, 
    required this.dashboardRepository,
    required this.recordsRepository,
    required this.registryRepository,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MultiProvider(
      providers: [
        // Provide the DashboardProvider
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(dashboardRepository),
        ),
        // Provider for the list of record books
        ChangeNotifierProvider(
          create: (_) => RecordBookProvider(recordsRepository),
        ),
        // Provider for the list of registry entries
        ChangeNotifierProvider(
          create: (_) => RegistryEntryProvider(registryRepository),
        ),
      ],
      child: MaterialApp(
        title: 'بوابة الأمين الشرعي',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF006400),
            primary: const Color(0xFF006400),
            secondary: const Color(0xFF004d00),
          ),
          scaffoldBackgroundColor: Colors.grey[50],
          textTheme: GoogleFonts.tajawalTextTheme(textTheme).copyWith(
            bodyMedium: GoogleFonts.tajawal(textStyle: textTheme.bodyMedium),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF006400),
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
      ),
    );
  }
}
