import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'package:guardian_app/core/constants/api_constants.dart';
import 'package:guardian_app/features/auth/data/repositories/auth_repository.dart';

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // State
  bool _isLoading = false;
  bool _isLoadingContractTypes = true;
  bool _isLoadingRecordBook = false;
  List<Map<String, dynamic>> _contractTypes = [];
  int? _selectedContractTypeId;
  Map<String, dynamic>? _selectedContractType;
  Map<String, dynamic>? _recordBookInfo;
  List<Map<String, dynamic>> _dynamicFields = [];  // Fields from FormFieldConfig
  bool _isLoadingFields = false;
  
  // Section 1: Document dates
  DateTime _documentDateGregorian = DateTime.now();
  String _documentDateHijri = '';
  
  // Section 2: Dynamic form data
  final Map<String, dynamic> _formData = {};
  final Map<String, TextEditingController> _textControllers = {};
  
  // Section 3: Delivery status
  String _deliveryStatus = 'preserved'; // preserved | delivered
  DateTime? _deliveryDate;
  File? _deliveryReceiptImage;

  @override
  void initState() {
    super.initState();
    _loadContractTypes();
    _updateHijriDate();
  }

  @override
  void dispose() {
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateHijriDate() {
    // Simple Hijri date approximation (for display purposes)
    // In production, use a proper Hijri calendar library
    final gregorian = _documentDateGregorian;
    // Approximate conversion (not accurate, just for display)
    final hijriYear = ((gregorian.year - 622) * 33 / 32).round();
    _documentDateHijri = '$hijriYear هـ';
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
    
    // Clear previous form data
    _formData.clear();
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    _textControllers.clear();
    
    setState(() {
      _selectedContractTypeId = contractTypeId;
      _selectedContractType = _contractTypes.firstWhere(
        (ct) => ct['id'] == contractTypeId,
        orElse: () => {},
      );
      _dynamicFields = [];
    });
    
    // Load form fields from FormFieldConfig API
    _loadFormFields(contractTypeId);
    
    // Load record book info
    _loadRecordBookInfo(contractTypeId);
  }

  Future<void> _loadFormFields(int contractTypeId) async {
    setState(() => _isLoadingFields = true);
    
    try {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      final token = await authRepo.getToken();
      
      final response = await http.get(
        Uri.parse(ApiConstants.formFields(contractTypeId)),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Auth-Token': token ?? '',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final fields = List<Map<String, dynamic>>.from(data['fields'] ?? []);
        
        // Initialize controllers for text fields
        for (var field in fields) {
          final fieldName = field['name'] as String;
          final fieldType = field['type'] as String;
          if (fieldType == 'text' || fieldType == 'textarea' || fieldType == 'number') {
            _textControllers[fieldName] = TextEditingController();
          }
        }
        
        setState(() {
          _dynamicFields = fields;
          _isLoadingFields = false;
        });
      } else {
        // Fallback to form_schema from contract type if FormFieldConfig not found
        final formSchema = _selectedContractType?['form_schema'] as List<dynamic>? ?? [];
        for (var field in formSchema) {
          final fieldName = field['name'] as String;
          final fieldType = field['type'] as String;
          if (fieldType == 'text' || fieldType == 'textarea' || fieldType == 'number') {
            _textControllers[fieldName] = TextEditingController();
          }
        }
        setState(() {
          _dynamicFields = formSchema.map((f) => Map<String, dynamic>.from(f)).toList();
          _isLoadingFields = false;
        });
      }
    } catch (e) {
      // Fallback to form_schema
      final formSchema = _selectedContractType?['form_schema'] as List<dynamic>? ?? [];
      for (var field in formSchema) {
        final fieldName = field['name'] as String;
        final fieldType = field['type'] as String;
        if (fieldType == 'text' || fieldType == 'textarea' || fieldType == 'number') {
          _textControllers[fieldName] = TextEditingController();
        }
      }
      setState(() {
        _dynamicFields = formSchema.map((f) => Map<String, dynamic>.from(f)).toList();
        _isLoadingFields = false;
      });
    }
  }

  Future<void> _pickDeliveryReceiptImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _deliveryReceiptImage = File(pickedFile.path);
      });
    }
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
      
      // Collect dynamic form data
      for (var entry in _textControllers.entries) {
        _formData[entry.key] = entry.value.text;
      }
      
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
          'document_date_gregorian': _documentDateGregorian.toIso8601String().split('T')[0],
          'document_date_hijri': _documentDateHijri,
          'form_data': _formData,
          'delivery_status': _deliveryStatus,
          'delivery_date': _deliveryStatus == 'delivered' 
              ? _deliveryDate?.toIso8601String().split('T')[0] 
              : null,
          // Note: Image upload would need multipart request in production
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
          for (var controller in _textControllers.values) {
            controller.clear();
          }
          setState(() {
            _selectedContractTypeId = null;
            _selectedContractType = null;
            _recordBookInfo = null;
            _formData.clear();
            _deliveryReceiptImage = null;
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
      appBar: AppBar(
        title: Text('إضافة قيد جديد', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF006400),
        foregroundColor: Colors.white,
      ),
      body: _isLoadingContractTypes
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ========== القسم الأول: بيانات الوثيقة ==========
                    _buildSectionCard(
                      title: 'القسم الأول: بيانات الوثيقة',
                      icon: Icons.description,
                      children: [
                        // نوع العقد
                        DropdownButtonFormField<int>(
                          initialValue: _selectedContractTypeId,
                          decoration: InputDecoration(
                            labelText: 'نوع العقد *',
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
                        
                        // تاريخ الوثيقة الهجري
                        _buildDatePicker(
                          label: 'تاريخ المحرر (هجري)',
                          displayValue: _documentDateHijri,
                          onTap: () => _showHijriDatePicker(),
                        ),
                        const SizedBox(height: 16),
                        
                        // تاريخ الوثيقة الميلادي
                        _buildDatePicker(
                          label: 'تاريخ المحرر (ميلادي)',
                          displayValue: '${_documentDateGregorian.year}/${_documentDateGregorian.month}/${_documentDateGregorian.day}',
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _documentDateGregorian,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _documentDateGregorian = picked;
                                _updateHijriDate();
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // بيانات القيد في السجل
                        if (_isLoadingRecordBook)
                          const Center(child: CircularProgressIndicator())
                        else if (_recordBookInfo != null)
                          _buildRecordBookInfo(),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // ========== القسم الثاني: بيانات المحرر (ديناميكي) ==========
                    if (_selectedContractType != null)
                      _buildSectionCard(
                        title: 'القسم الثاني: بيانات المحرر',
                        icon: Icons.edit_document,
                        children: _buildDynamicFormFields(),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // ========== القسم الثالث: بيانات التوثيق ==========
                    _buildSectionCard(
                      title: 'القسم الثالث: بيانات التوثيق',
                      icon: Icons.verified,
                      children: [
                        _buildDeliveryStatusSelector(),
                        
                        if (_deliveryStatus == 'delivered') ...[
                          const SizedBox(height: 16),
                          _buildDatePicker(
                            label: 'تاريخ التسليم',
                            displayValue: _deliveryDate != null 
                                ? '${_deliveryDate!.year}/${_deliveryDate!.month}/${_deliveryDate!.day}'
                                : 'اختر التاريخ',
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _deliveryDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => _deliveryDate = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildImagePicker(),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // زر الحفظ
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
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF006400)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF006400),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRecordBookInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'بيانات القيد في السجل',
            style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInfoChip('رقم السجل', _recordBookInfo!['book_number'].toString())),
              Expanded(child: _buildInfoChip('السنة الهجرية', _recordBookInfo!['hijri_year'].toString())),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildInfoChip('رقم الصفحة', _recordBookInfo!['next_page_number'].toString())),
              Expanded(child: _buildInfoChip('رقم القيد', _recordBookInfo!['next_entry_number'].toString())),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  List<Widget> _buildDynamicFormFields() {
    // Show loading indicator while fetching fields
    if (_isLoadingFields) {
      return [const Center(child: CircularProgressIndicator())];
    }
    
    if (_dynamicFields.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            'لا توجد حقول مخصصة لهذا النوع من العقود',
            style: GoogleFonts.tajawal(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ),
      ];
    }
    
    final List<Widget> fields = [];
    
    for (var field in _dynamicFields) {
      final fieldName = field['name'] as String;
      final fieldLabel = field['label'] as String;
      final fieldType = field['type'] as String;
      final isRequired = field['required'] == true;
      final options = field['options'] as List<dynamic>?;
      
      Widget fieldWidget;
      
      switch (fieldType) {
        case 'text':
          fieldWidget = TextFormField(
            controller: _textControllers[fieldName],
            decoration: InputDecoration(
              labelText: '$fieldLabel${isRequired ? " *" : ""}',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: isRequired 
                ? (v) => v?.isEmpty == true ? 'هذا الحقل مطلوب' : null 
                : null,
          );
          break;
          
        case 'textarea':
          fieldWidget = TextFormField(
            controller: _textControllers[fieldName],
            maxLines: 3,
            decoration: InputDecoration(
              labelText: '$fieldLabel${isRequired ? " *" : ""}',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: isRequired 
                ? (v) => v?.isEmpty == true ? 'هذا الحقل مطلوب' : null 
                : null,
          );
          break;
          
        case 'number':
          fieldWidget = TextFormField(
            controller: _textControllers[fieldName],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '$fieldLabel${isRequired ? " *" : ""}',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: isRequired 
                ? (v) => v?.isEmpty == true ? 'هذا الحقل مطلوب' : null 
                : null,
          );
          break;
          
        case 'select':
          fieldWidget = DropdownButtonFormField<String>(
            initialValue: _formData[fieldName] as String?,
            decoration: InputDecoration(
              labelText: '$fieldLabel${isRequired ? " *" : ""}',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: options?.map((opt) {
              return DropdownMenuItem<String>(
                value: opt.toString(),
                child: Text(opt.toString()),
              );
            }).toList(),
            onChanged: (v) => setState(() => _formData[fieldName] = v),
            validator: isRequired 
                ? (v) => v == null ? 'هذا الحقل مطلوب' : null 
                : null,
          );
          break;
          
        case 'date':
          final dateValue = _formData[fieldName] as DateTime?;
          fieldWidget = _buildDatePicker(
            label: '$fieldLabel${isRequired ? " *" : ""}',
            displayValue: dateValue != null 
                ? '${dateValue.year}/${dateValue.month}/${dateValue.day}'
                : 'اختر التاريخ',
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: dateValue ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _formData[fieldName] = picked);
              }
            },
          );
          break;
          
        case 'repeater':
          // Simplified repeater - just show a note for now
          fieldWidget = Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.list, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$fieldLabel (قائمة متعددة)',
                    style: GoogleFonts.tajawal(color: Colors.grey[600]),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF006400)),
                  onPressed: () {
                    // Repeater feature - will be implemented in future version
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('سيتم إضافة هذه الميزة قريباً')),
                    );
                  },
                ),
              ],
            ),
          );
          break;
          
        default:
          fieldWidget = TextFormField(
            controller: _textControllers[fieldName],
            decoration: InputDecoration(
              labelText: fieldLabel,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
      }
      
      fields.add(fieldWidget);
      fields.add(const SizedBox(height: 16));
    }
    
    return fields;
  }

  Widget _buildDatePicker({
    required String label,
    required String displayValue,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(displayValue, style: GoogleFonts.tajawal()),
      ),
    );
  }

  void _showHijriDatePicker() {
    // Show a simple dialog for Hijri date input since Flutter doesn't have native Hijri picker
    final hijriController = TextEditingController(text: _documentDateHijri);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('أدخل التاريخ الهجري', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: hijriController,
          decoration: InputDecoration(
            hintText: '1446/01/15',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _documentDateHijri = hijriController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006400)),
            child: Text('تأكيد', style: GoogleFonts.tajawal(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'حالة الوثيقة',
          style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatusOption(
                label: 'محفوظة لدينا للتوثيق',
                value: 'preserved',
                icon: Icons.lock,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatusOption(
                label: 'مسلمة لصاحب الشأن',
                value: 'delivered',
                icon: Icons.send,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusOption({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _deliveryStatus == value;
    return InkWell(
      onTap: () => setState(() => _deliveryStatus = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF006400) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFF006400).withAlpha(25) : null,
        ),
        child: Column(
          children: [
            Icon(
              isSelected ? Icons.check_circle : icon,
              color: isSelected ? const Color(0xFF006400) : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF006400) : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'صورة محضر التسليم',
          style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDeliveryReceiptImage,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: _deliveryReceiptImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_deliveryReceiptImage!, fit: BoxFit.cover, width: double.infinity),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'اضغط لإرفاق صورة',
                          style: GoogleFonts.tajawal(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
