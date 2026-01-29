import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:guardian_app/core/constants/api_constants.dart';
import 'package:guardian_app/features/auth/data/repositories/auth_repository.dart';

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form Controllers
  final _firstPartyController = TextEditingController();
  final _secondPartyController = TextEditingController();
  final _notesController = TextEditingController();
  
  // State
  bool _isLoading = false;
  bool _isLoadingContractTypes = true;
  bool _isLoadingRecordBook = false;
  List<Map<String, dynamic>> _contractTypes = [];
  int? _selectedContractTypeId;
  Map<String, dynamic>? _recordBookInfo;
  DateTime _transactionDate = DateTime.now();
  String _deliveryStatus = 'preserved'; // preserved | delivered
  DateTime? _deliveryDate;
  
  // Dynamic labels based on contract type
  String _firstPartyLabel = 'الطرف الأول';
  String _secondPartyLabel = 'الطرف الثاني';

  @override
  void initState() {
    super.initState();
    _loadContractTypes();
  }

  @override
  void dispose() {
    _firstPartyController.dispose();
    _secondPartyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadContractTypes() async {
    try {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      final token = await authRepo.getToken();
      
      final response = await http.get(
        Uri.parse(ApiConstants.contractTypes),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Auth-Token': token ?? '',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _contractTypes = List<Map<String, dynamic>>.from(data);
          _isLoadingContractTypes = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingContractTypes = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل أنواع العقود: $e')),
        );
      }
    }
  }

  Future<void> _loadRecordBookInfo(int contractTypeId) async {
    setState(() => _isLoadingRecordBook = true);
    
    try {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      final token = await authRepo.getToken();
      
      final response = await http.get(
        Uri.parse(ApiConstants.myRecordBook(contractTypeId)),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Auth-Token': token ?? '',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _recordBookInfo = data;
          _isLoadingRecordBook = false;
        });
      } else {
        setState(() {
          _recordBookInfo = null;
          _isLoadingRecordBook = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا يوجد سجل نشط لهذا النوع من العقود')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoadingRecordBook = false);
    }
  }

  void _onContractTypeChanged(int? contractTypeId) {
    if (contractTypeId == null) return;
    
    setState(() => _selectedContractTypeId = contractTypeId);
    
    // Update labels based on contract type
    final contractType = _contractTypes.firstWhere(
      (ct) => ct['id'] == contractTypeId,
      orElse: () => {},
    );
    
    final settings = contractType['settings'] as Map<String, dynamic>?;
    setState(() {
      _firstPartyLabel = settings?['first_party_label'] ?? 'الطرف الأول';
      _secondPartyLabel = settings?['second_party_label'] ?? 'الطرف الثاني';
    });
    
    // Load record book info
    _loadRecordBookInfo(contractTypeId);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedContractTypeId == null || _recordBookInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار نوع العقد')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      final token = await authRepo.getToken();
      
      final response = await http.post(
        Uri.parse(ApiConstants.registryEntries),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Auth-Token': token ?? '',
        },
        body: jsonEncode({
          'record_book_id': _recordBookInfo!['id'],
          'contract_type_id': _selectedContractTypeId,
          'first_party_name': _firstPartyController.text,
          'second_party_name': _secondPartyController.text,
          'transaction_date': _transactionDate.toIso8601String().split('T')[0],
          'notes': _notesController.text,
          'delivery_status': _deliveryStatus,
          'delivery_date': _deliveryStatus == 'delivered' 
              ? _deliveryDate?.toIso8601String().split('T')[0] 
              : null,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إضافة القيد بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          // Clear form
          _formKey.currentState!.reset();
          _firstPartyController.clear();
          _secondPartyController.clear();
          _notesController.clear();
          setState(() {
            _selectedContractTypeId = null;
            _recordBookInfo = null;
          });
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'فشل في إضافة القيد');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoadingContractTypes
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Contract Type Dropdown
                    _buildSectionHeader('بيانات القيد'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedContractTypeId,
                      decoration: InputDecoration(
                        labelText: 'نوع العقد',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.category),
                      ),
                      items: _contractTypes.map((ct) {
                        return DropdownMenuItem<int>(
                          value: ct['id'],
                          child: Text(ct['name']),
                        );
                      }).toList(),
                      onChanged: _onContractTypeChanged,
                      validator: (v) => v == null ? 'يرجى اختيار نوع العقد' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Record Book Info (Auto-filled)
                    if (_isLoadingRecordBook)
                      const Center(child: CircularProgressIndicator())
                    else if (_recordBookInfo != null)
                      _buildRecordBookInfo(),
                    
                    const SizedBox(height: 24),
                    
                    // Transaction Date
                    _buildDatePicker(
                      label: 'تاريخ تحرير العقد',
                      value: _transactionDate,
                      onChanged: (date) => setState(() => _transactionDate = date),
                    ),
                    
                    const SizedBox(height: 24),
                    _buildSectionHeader('بيانات الأطراف'),
                    const SizedBox(height: 8),
                    
                    // First Party
                    TextFormField(
                      controller: _firstPartyController,
                      decoration: InputDecoration(
                        labelText: _firstPartyLabel,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (v) => v?.isEmpty == true ? 'هذا الحقل مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Second Party
                    TextFormField(
                      controller: _secondPartyController,
                      decoration: InputDecoration(
                        labelText: _secondPartyLabel,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (v) => v?.isEmpty == true ? 'هذا الحقل مطلوب' : null,
                    ),
                    
                    const SizedBox(height: 24),
                    _buildSectionHeader('حالة التسليم'),
                    const SizedBox(height: 8),
                    
                    // Delivery Status
                    _buildDeliveryStatusSelector(),
                    
                    if (_deliveryStatus == 'delivered') ...[
                      const SizedBox(height: 16),
                      _buildDatePicker(
                        label: 'تاريخ التسليم',
                        value: _deliveryDate ?? DateTime.now(),
                        onChanged: (date) => setState(() => _deliveryDate = date),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.notes),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006400),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'حفظ القيد',
                              style: GoogleFonts.tajawal(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.tajawal(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF006400),
      ),
    );
  }

  Widget _buildRecordBookInfo() {
    return Card(
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip('رقم السجل', _recordBookInfo!['book_number'].toString()),
                _buildInfoChip('السنة الهجرية', _recordBookInfo!['hijri_year'].toString()),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip('رقم الصفحة', _recordBookInfo!['next_page_number'].toString()),
                _buildInfoChip('رقم القيد', _recordBookInfo!['next_entry_number'].toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[600])),
        Text(value, style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime value,
    required ValueChanged<DateTime> onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text('${value.year}/${value.month}/${value.day}'),
      ),
    );
  }

  Widget _buildDeliveryStatusSelector() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _deliveryStatus = 'preserved'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _deliveryStatus == 'preserved' ? const Color(0xFF006400) : Colors.grey,
                ),
                borderRadius: BorderRadius.circular(8),
                color: _deliveryStatus == 'preserved' ? const Color(0xFF006400).withAlpha(25) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    _deliveryStatus == 'preserved' ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: _deliveryStatus == 'preserved' ? const Color(0xFF006400) : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: Text('محفوظة للتوثيق', style: GoogleFonts.tajawal(fontSize: 13))),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _deliveryStatus = 'delivered'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _deliveryStatus == 'delivered' ? const Color(0xFF006400) : Colors.grey,
                ),
                borderRadius: BorderRadius.circular(8),
                color: _deliveryStatus == 'delivered' ? const Color(0xFF006400).withAlpha(25) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    _deliveryStatus == 'delivered' ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: _deliveryStatus == 'delivered' ? const Color(0xFF006400) : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: Text('مسلمة لصاحب الشأن', style: GoogleFonts.tajawal(fontSize: 13))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
