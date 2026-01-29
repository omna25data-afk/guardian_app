import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guardian_app/core/constants/api_constants.dart';
import 'package:guardian_app/screens/home_screen.dart';
import 'package:guardian_app/screens/debug_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final url = Uri.parse(ApiConstants.login);
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'phone_number': _phoneController.text,
          'password': _passwordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == true) {
           final user = data['user'];
           final isGuardian = user['is_guardian'] == true;
           
           if (isGuardian) {
             const storage = FlutterSecureStorage();
             await storage.write(key: 'auth_token', value: data['token'] ?? data['access_token']);
             await storage.write(key: 'user_data', value: jsonEncode(user));

             if (!mounted) return;

             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('تم تسجيل الدخول بنجاح!', style: GoogleFonts.tajawal()), backgroundColor: Colors.green),
             );

             Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );

           } else {
             setState(() {
               _errorMessage = 'عذراً، هذا الحساب ليس حساب أمين شرعي.';
             });
           }
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'فشل تسجيل الدخول';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'خطأ في الاتصال بالخادم (${response.statusCode})';
        });
      }
    } catch (e) {
      if(mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ غير متوقع: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/ministry_logo.jpg', height: 120),
                const SizedBox(height: 16),
                Text(
                  'وزارة العدل وحقوق الإنسان',
                  style: GoogleFonts.tajawal(textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF333333))),
                ),
                Text(
                  'محكمة السياني الإبتدائية',
                  style: GoogleFonts.tajawal(textStyle: textTheme.bodyLarge?.copyWith(color: const Color(0xFF555555))),
                ),
                const SizedBox(height: 32),
                Text(
                  'نظام إدارة قلم التوثيق', // Corrected System Name
                  style: GoogleFonts.tajawal(textStyle: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF006400))),
                ),
                const SizedBox(height: 8),
                Text(
                  'بوابة الأمين الشرعي',
                   style: GoogleFonts.tajawal(textStyle: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF006400))),
                ),
                const SizedBox(height: 48),
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text(
                      _errorMessage,
                      style: GoogleFonts.tajawal(color: Colors.red, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.tajawal(),
                  decoration: InputDecoration(
                    labelText: 'رقم الجوال',
                    labelStyle: GoogleFonts.tajawal(),
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال رقم الجوال';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.tajawal(),
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    labelStyle: GoogleFonts.tajawal(),
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال كلمة المرور';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006400),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('تسجيل الدخول', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            ),
          ),
          // Debug Button
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DebugScreen()),
                );
              },
              icon: const Icon(Icons.bug_report, color: Colors.grey),
              label: const Text("فحص الاتصال (Debug)", style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}
