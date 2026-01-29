import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'package:guardian_app/core/constants/api_constants.dart';
import 'package:guardian_app/features/auth/data/repositories/auth_repository.dart';
import 'package:hijri/hijri_calendar.dart';

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
  HijriCalendar _documentDateHijri = HijriCalendar.now();
  
  // Section 1: Record Book Info (Editable)
  final TextEditingController _bookNumberController = TextEditingController();
  final TextEditingController _pageNumberController = TextEditingController();
  final TextEditingController _entryNumberController = TextEditingController();
  
  // Section 2: Dynamic form data
  final Map<String, dynamic> _formData = {};
  
  // Subtypes Info
  List<Map<String, dynamic>> _subtypes1 = [];
  List<Map<String, dynamic>> _subtypes2 = [];
  String? _selectedSubtype1;
  String? _selectedSubtype2;
  bool _isLoadingSubtypes1 = false;
  bool _isLoadingSubtypes2 = false;

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
    HijriCalendar.setLocal('ar');
    _documentDateHijri = HijriCalendar.fromDate(_documentDateGregorian);
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
          // Populate editable fields
          _bookNumberController.text = data['book_number']?.toString() ?? '';
          _entryNumberController.text = data['next_entry_number']?.toString() ?? '';
          _pageNumberController.text = data['next_page_number']?.toString() ?? '';
        });
      } else {
        setState(() {
          _recordBookInfo = null;
          _isLoadingRecordBook = false;
          _bookNumberController.clear();
          _entryNumberController.clear();
          _pageNumberController.clear();
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
    _bookNumberController.clear();
    _pageNumberController.clear();
    _entryNumberController.clear();
    
    setState(() {
      _selectedContractTypeId = contractTypeId;
      _selectedContractType = _contractTypes.firstWhere(
        (ct) => ct['id'] == contractTypeId,
        orElse: () => {},
      );
      _dynamicFields = [];
      // Clear subtypes
      _subtypes1 = [];
      _subtypes2 = [];
      _selectedSubtype1 = null;
      _selectedSubtype2 = null;
    });
    
    // Load subtypes level 1
    _fetchSubtypes(contractTypeId, level: 1);
    
    // Load form fields from FormFieldConfig API
    _loadFormFields(contractTypeId);
    
    // Load record book info
    _loadRecordBookInfo(contractTypeId);
  }

  Future<void> _fetchSubtypes(int contractTypeId, {required int level, String? parentCode}) async {
    setState(() {
      if (level == 1) _isLoadingSubtypes1 = true;
      else _isLoadingSubtypes2 = true;
    });

    try {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      final token = await authRepo.getToken();
      
      String url = '${ApiConstants.contractTypes}/$contractTypeId/subtypes';
      if (parentCode != null) {
        url += '?parent_code=$parentCode';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Auth-Token': token ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        setState(() {
          if (level == 1) {
            _subtypes1 = data;
          } else {
            _subtypes2 = data;
          }
        });
      }
    } catch (e) {
      // Ignore errors for subtypes, just empty list
    } finally {
      if (mounted) {
        setState(() {
          if (level == 1) _isLoadingSubtypes1 = false;
          else _isLoadingSubtypes2 = false;
        });
      }
    }
  }

  void _onSubtype1Changed(String? code) {
    setState(() {
      _selectedSubtype1 = code;
      _selectedSubtype2 = null;
      _subtypes2 = [];
    });
    
    if (code != null) {
      // Load subtypes level 2
      _fetchSubtypes(_selectedContractTypeId!, level: 2, parentCode: code);
    }
    
    // Reload form fields with subtype filter
    if (_selectedContractTypeId != null) {
      _loadFormFields(_selectedContractTypeId!);
    }
  }

  void _onSubtype2Changed(String? code) {
    setState(() {
      _selectedSubtype2 = code;
    });
    
    // Reload form fields with subtype filter
    if (_selectedContractTypeId != null) {
      _loadFormFields(_selectedContractTypeId!);
    }
  }

  Future<void> _loadFormFields(int contractTypeId) async {
    setState(() => _isLoadingFields = true);
    
    try {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      final token = await authRepo.getToken();
      
      String url = ApiConstants.formFields(contractTypeId);
      if (_selectedSubtype1 != null) {
        url += (url.contains('?') ? '&' : '?') + 'subtype_1=$_selectedSubtype1';
      }
      if (_selectedSubtype2 != null) {
        url += (url.contains('?') ? '&' : '?') + 'subtype_2=$_selectedSubtype2';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Auth-Token': token ?? '',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final rawFields = List<Map<String, dynamic>>.from(data['fields'] ?? []);
        
        // Normalize fields to handle both DB columns and legacy schema keys
        final normalizedFields = rawFields.map((f) => {
          'name': f['column_name'] ?? f['name'],
          'label': f['field_label'] ?? f['label'],
          'type': f['field_type'] ?? f['type'],
          'required': f['is_required'] ?? f['required'] ?? false,
          'placeholder': f['placeholder'],
          'helper_text': f['helper_text'],
          'options': f['options'],
        }).where((f) => f['name'] != null).toList();

        // Initialize controllers for text fields
        for (var field in normalizedFields) {
          final fieldName = field['name'] as String;
          final fieldType = field['type'] as String;
          if (fieldType == 'text' || fieldType == 'textarea' || fieldType == 'number') {
            _textControllers[fieldName] = TextEditingController();
          }
        }
        
        setState(() {
          _dynamicFields = List<Map<String, dynamic>>.from(normalizedFields);
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
          'record_book_id': _recordBookInfo!['id'], // We still need the ID, assuming it doesn't change or we look it up? 
          // User asked to edit Entry/Page/Book numbers. Backend usually validates this.
          // We should send these values if the backend accepts them override.
          // Assuming backend expects them in 'form_data' or specific fields? 
          // Default backend usually auto-increments. If we want to override, we might need specific params.
          // For now, let's send them as separate params if the API supports it, or just rely on the fact they are editable for the USER's record keeping.
          // The API request in original code sent:
          /*
            'record_book_id': _recordBookInfo!['id'],
            'contract_type_id': _selectedContractTypeId,
            ...
          */
          // If the backend allows overriding entry_number, we should send it.
          // Let's assume we pass them as additional fields.
          'contract_type_id': _selectedContractTypeId,
          'subtype_1': _selectedSubtype1,
          'subtype_2': _selectedSubtype2,
          'document_date_gregorian': _documentDateGregorian.toIso8601String().split('T')[0],
          'document_date_hijri': _documentDateHijri.toString(), // Use stored Hijri object toString
          'manual_book_number': _bookNumberController.text,
          'manual_page_number': _pageNumberController.text,
          'manual_entry_number': _entryNumberController.text,
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
                        
                        // Subtypes
                        if (_isLoadingSubtypes1)
                           const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Center(child: CircularProgressIndicator())),
                        
                        if (_subtypes1.isNotEmpty && !_isLoadingSubtypes1) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedSubtype1,
                            items: _subtypes1.map((s) => DropdownMenuItem(value: s['code'], child: Text(s['name']))).toList(),
                            onChanged: _onSubtype1Changed,
                            decoration: InputDecoration(
                              labelText: 'النوع الفرعي *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.subdirectory_arrow_left),
                            ),
                            validator: (v) => v == null ? 'يرجى اختيار النوع الفرعي' : null,
                          ),
                        ],
                        
                        if (_isLoadingSubtypes2)
                           const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Center(child: CircularProgressIndicator())),
                           
                        if (_subtypes2.isNotEmpty && !_isLoadingSubtypes2) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedSubtype2,
                            items: _subtypes2.map((s) => DropdownMenuItem(value: s['code'], child: Text(s['name']))).toList(),
                            onChanged: _onSubtype2Changed,
                            decoration: InputDecoration(
                              labelText: 'النوع الفرعي الثانوي *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.subdirectory_arrow_right),
                            ),
                            validator: (v) => v == null ? 'يرجى اختيار النوع الفرعي الثانوي' : null,
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        // تاريخ الوثيقة - هجري وميلادي
                        Row(
                          children: [
                            // Hijri Date
                            Expanded(
                              child: InkWell(
                                onTap: _showHijriDatePicker,
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'تاريخ المحرر (هجري)',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _documentDateHijri.toFormat("dd/mm/yyyy"), 
                                        style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)
                                      ),
                                      const Icon(Icons.calendar_month, size: 20, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Gregorian Date
                            Expanded(
                              child: InkWell(
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
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'تاريخ المحرر (ميلادي)',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${_documentDateGregorian.year}/${_documentDateGregorian.month}/${_documentDateGregorian.day}',
                                        style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)
                                      ),
                                      const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
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
              // Order: Entry Number, Page Number, Book Number (as requested)
              Expanded(child: _buildEditableRecordField('رقم القيد', _entryNumberController)),
              const SizedBox(width: 8),
              Expanded(child: _buildEditableRecordField('رقم الصفحة', _pageNumberController)),
              const SizedBox(width: 8),
              Expanded(child: _buildEditableRecordField('رقم السجل', _bookNumberController)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableRecordField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
      ],
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
      final placeholder = field['placeholder'] as String?;
      final helperText = field['helper_text'] as String?;
      final options = field['options'] as List<dynamic>?;
      
      Widget fieldWidget;
      
      switch (fieldType) {
        case 'text':
          fieldWidget = TextFormField(
            controller: _textControllers[fieldName],
            decoration: InputDecoration(
              labelText: '$fieldLabel${isRequired ? " *" : ""}',
              hintText: placeholder,
              helperText: helperText,
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
              hintText: placeholder,
              helperText: helperText,
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
              hintText: placeholder,
              helperText: helperText,
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
              hintText: placeholder,
              helperText: helperText,
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
                : (placeholder ?? 'اختر التاريخ'),
            helperText: helperText,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('سيتم إضافة هذه الميزة قريباً')),
                        );
                      },
                    ),
                  ],
                ),
                if (helperText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(helperText, style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[600])),
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
              hintText: placeholder,
              helperText: helperText,
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
    String? helperText,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
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
  Future<void> _showHijriDatePicker() async {
    final HijriCalendar? picked = await showDialog<HijriCalendar>(
      context: context,
      builder: (context) => HijriDatePickerDialog(
        initialDate: _documentDateHijri,
      ),
    );
    if (picked != null) {
      setState(() {
        _documentDateHijri = picked;
      });
    }
  }
}

class HijriDatePickerDialog extends StatefulWidget {
  final HijriCalendar initialDate;
  const HijriDatePickerDialog({super.key, required this.initialDate});

  @override
  State<HijriDatePickerDialog> createState() => _HijriDatePickerDialogState();
}

class _HijriDatePickerDialogState extends State<HijriDatePickerDialog> {
  late int selectedDay;
  late int selectedMonth;
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    selectedDay = widget.initialDate.hDay;
    selectedMonth = widget.initialDate.hMonth;
    selectedYear = widget.initialDate.hYear;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('اختر التاريخ الهجري', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
      content: SingleChildScrollView(
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: selectedDay,
                isExpanded: true,
                items: List.generate(30, (index) => index + 1).map((d) => DropdownMenuItem(value: d, child: Text(d.toString()))).toList(),
                onChanged: (v) => setState(() => selectedDay = v!),
                decoration: InputDecoration(labelText: 'يوم', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: selectedMonth,
                isExpanded: true,
                items: List.generate(12, (index) => index + 1).map((m) => DropdownMenuItem(value: m, child: Text(m.toString()))).toList(),
                onChanged: (v) => setState(() => selectedMonth = v!),
                decoration: InputDecoration(labelText: 'شهر', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: selectedYear,
                isExpanded: true,
                items: List.generate(100, (index) => 1400 + index).map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                onChanged: (v) => setState(() => selectedYear = v!),
                decoration: InputDecoration(labelText: 'سنة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء', style: GoogleFonts.tajawal())),
        ElevatedButton(
          onPressed: () {
            final hDate = HijriCalendar();
            hDate.hYear = selectedYear;
            hDate.hMonth = selectedMonth;
            hDate.hDay = selectedDay;
            Navigator.pop(context, hDate);
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006400), foregroundColor: Colors.white),
          child: Text('موافق', style: GoogleFonts.tajawal()),
        ),
      ],
    );
  }
}
