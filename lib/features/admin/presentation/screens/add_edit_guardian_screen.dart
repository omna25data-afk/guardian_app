import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:guardian_app/features/admin/data/models/admin_guardian_model.dart';
import 'package:guardian_app/features/admin/data/repositories/admin_guardian_repository.dart';
import 'package:guardian_app/features/admin/data/repositories/admin_areas_repository.dart';
import 'package:guardian_app/features/admin/data/models/admin_area_model.dart';

class AddEditGuardianScreen extends StatefulWidget {
  final AdminGuardian? guardian;

  const AddEditGuardianScreen({super.key, this.guardian});

  @override
  State<AddEditGuardianScreen> createState() => _AddEditGuardianScreenState();
}

class _AddEditGuardianScreenState extends State<AddEditGuardianScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // --- Controllers ---

  // 1. Basic Info
  final _serialNumberController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _grandfatherNameController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _greatGrandfatherNameController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _homePhoneController = TextEditingController();
  DateTime? _birthDate;

  // 2. Identity Info
  String _proofType = 'بطاقة شخصية';
  final _proofNumberController = TextEditingController();
  final _issuingAuthorityController = TextEditingController();
  DateTime? _issueDate;
  DateTime? _expiryDate;

  // 3. Professional Info
  final _qualificationController = TextEditingController();
  final _jobController = TextEditingController();
  final _workplaceController = TextEditingController();
  final _experienceNotesController = TextEditingController();

  // 4. Ministerial & License
  final _ministerialNumController = TextEditingController();
  DateTime? _ministerialDate;
  final _licenseNumController = TextEditingController();
  DateTime? _licenseIssueDate;
  DateTime? _licenseExpiryDate;

  // 5. Profession Card
  final _cardNumController = TextEditingController();
  DateTime? _cardIssueDate;
  DateTime? _cardExpiryDate;

  // 6. Geographic Area Selection
  AdminArea? _selectedMainDistrict;
  List<AdminArea> _selectedVillages = [];
  List<AdminArea> _selectedLocalities = [];
  
  // 7. Status & Notes
  String _employmentStatus = 'على رأس العمل'; // Default/Mapped
  DateTime? _stopDate;
  final _stopReasonController = TextEditingController();
  final _notesController = TextEditingController();


  @override
  void initState() {
    super.initState();
    if (widget.guardian != null) {
      _loadGuardianData();
    }
  }

  void _loadGuardianData() {
    final g = widget.guardian!;
    
    // Basic
    _serialNumberController.text = g.serialNumber;
    _firstNameController.text = g.firstName ?? '';
    _fatherNameController.text = g.fatherName ?? '';
    _grandfatherNameController.text = g.grandfatherName ?? '';
    _familyNameController.text = g.familyName ?? '';
    _greatGrandfatherNameController.text = g.greatGrandfatherName ?? '';
    _birthPlaceController.text = g.birthPlace ?? '';
    if (g.phone != null) _phoneController.text = g.phone!;
    _homePhoneController.text = g.homePhone ?? '';
    if (g.birthDate != null) _birthDate = DateTime.tryParse(g.birthDate!);

    // Identity
    _proofType = g.proofType ?? 'بطاقة شخصية';
    _proofNumberController.text = g.proofNumber ?? '';
    _issuingAuthorityController.text = g.issuingAuthority ?? '';
    if (g.issueDate != null) _issueDate = DateTime.tryParse(g.issueDate!);
    if (g.expiryDate != null) _expiryDate = DateTime.tryParse(g.expiryDate!);

    // Professional
    _qualificationController.text = g.qualification ?? '';
    _jobController.text = g.job ?? '';
    _workplaceController.text = g.workplace ?? '';
    _experienceNotesController.text = g.experienceNotes ?? '';

    // Ministerial
    _ministerialNumController.text = g.ministerialDecisionNumber ?? '';
    if (g.ministerialDecisionDate != null) _ministerialDate = DateTime.tryParse(g.ministerialDecisionDate!);
    _licenseNumController.text = g.licenseNumber ?? '';
    if (g.licenseIssueDate != null) _licenseIssueDate = DateTime.tryParse(g.licenseIssueDate!);
    if (g.licenseExpiryDate != null) _licenseExpiryDate = DateTime.tryParse(g.licenseExpiryDate!);

    // Card
    _cardNumController.text = g.professionCardNumber ?? '';
    if (g.professionCardIssueDate != null) _cardIssueDate = DateTime.tryParse(g.professionCardIssueDate!);
    if (g.professionCardExpiryDate != null) _cardExpiryDate = DateTime.tryParse(g.professionCardExpiryDate!);

    // Geographic
    // Logic for loading areas would go here if we fetched them.

    // Status
    _employmentStatus = g.employmentStatus ?? 'على رأس العمل';
    if (g.stopDate != null) _stopDate = DateTime.tryParse(g.stopDate!);
    _stopReasonController.text = g.stopReason ?? '';
    _notesController.text = g.notes ?? '';
  }

  @override
  void dispose() {
    _serialNumberController.dispose();
    _firstNameController.dispose();
    _fatherNameController.dispose();
    _grandfatherNameController.dispose();
    _familyNameController.dispose();
    _greatGrandfatherNameController.dispose();
    _birthPlaceController.dispose();
    _phoneController.dispose();
    _homePhoneController.dispose();
    _proofNumberController.dispose();
    _issuingAuthorityController.dispose();
    _qualificationController.dispose();
    _jobController.dispose();
    _workplaceController.dispose();
    _experienceNotesController.dispose();
    _ministerialNumController.dispose();
    _licenseNumController.dispose();
    _cardNumController.dispose();
    _stopReasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  String _formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }
  
  // --- Area Selection Helpers ---
  void _openAreaSelection(String type, bool multi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AreaSelectionSheet(
        type: type,
        multi: multi,
        repo: context.read<AdminAreasRepository>(),
        currentSelection: type == 'عزلة' 
          ? (_selectedMainDistrict != null ? [_selectedMainDistrict!] : [])
          : (type == 'قرية' ? _selectedVillages : _selectedLocalities),
        onSelected: (List<AdminArea> items) {
          setState(() {
            if (type == 'عزلة') {
              _selectedMainDistrict = items.isNotEmpty ? items.first : null;
            } else if (type == 'قرية') {
              _selectedVillages = items;
            } else if (type == 'محل') {
              _selectedLocalities = items;
            }
          });
        },
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
        final repo = context.read<AdminGuardianRepository>();
      
        final Map<String, dynamic> data = {
            'serial_number': _serialNumberController.text, // Often hidden/auto
            'first_name': _firstNameController.text,
            'father_name': _fatherNameController.text,
            'grandfather_name': _grandfatherNameController.text,
            'family_name': _familyNameController.text,
            'great_grandfather_name': _greatGrandfatherNameController.text,
            'birth_place': _birthPlaceController.text,
            'phone_number': _phoneController.text,
            'home_phone': _homePhoneController.text,
            
            'proof_type': _proofType,
            'proof_number': _proofNumberController.text,
            'issuing_authority': _issuingAuthorityController.text,
            
            'qualification': _qualificationController.text,
            'job': _jobController.text,
            'workplace': _workplaceController.text,
            'experience_notes': _experienceNotesController.text,
            
            'ministerial_decision_number': _ministerialNumController.text,
            'license_number': _licenseNumController.text,
            
            'profession_card_number': _cardNumController.text,
            
            'employment_status': _employmentStatus,
            'stop_reason': _stopReasonController.text,
            'notes': _notesController.text,
        };

        // Dates
        if (_birthDate != null) data['birth_date'] = _formatDate(_birthDate!);
        if (_issueDate != null) data['issue_date'] = _formatDate(_issueDate!);
        if (_expiryDate != null) data['expiry_date'] = _formatDate(_expiryDate!);
        if (_ministerialDate != null) data['ministerial_decision_date'] = _formatDate(_ministerialDate!);
        if (_licenseIssueDate != null) data['license_issue_date'] = _formatDate(_licenseIssueDate!);
        if (_licenseExpiryDate != null) data['license_expiry_date'] = _formatDate(_licenseExpiryDate!);
        if (_cardIssueDate != null) data['profession_card_issue_date'] = _formatDate(_cardIssueDate!);
        if (_cardExpiryDate != null) data['profession_card_expiry_date'] = _formatDate(_cardExpiryDate!);
        if (_stopDate != null) data['stop_date'] = _formatDate(_stopDate!);

        // Areas
        if (_selectedMainDistrict != null) {
          data['main_district_id'] = _selectedMainDistrict!.id.toString();
        }
        if (_selectedVillages.isNotEmpty) {
           data['village_ids'] = _selectedVillages.map((e) => e.id).toList();
        }
        if (_selectedLocalities.isNotEmpty) {
           data['locality_ids'] = _selectedLocalities.map((e) => e.id).toList();
        }
        
        if (widget.guardian == null) {
            await repo.createGuardian(data, imagePath: _selectedImage?.path);
        } else {
            // Ensure ID is passed for update if needed contextually, usually separate arg
            await repo.updateGuardian(widget.guardian!.id, data, imagePath: _selectedImage?.path);
        }

        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح')));
            Navigator.pop(context, true);
        }
    } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    } finally {
        if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Step> get _steps => [
    Step(
      title: const Text('البيانات الشخصية'),
      isActive: _currentStep >= 0,
       state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
           GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[200],
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!)
                    : (widget.guardian?.photoUrl != null ? NetworkImage(widget.guardian!.photoUrl!) as ImageProvider : null),
                child: (_selectedImage == null && widget.guardian?.photoUrl == null)
                    ? const Icon(Icons.camera_alt, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            _buildTextField(_serialNumberController, 'الرقم التسلسلي', keyboardType: TextInputType.number),
           
            const SizedBox(height: 10),
            TextFormField(
               controller: _firstNameController,
               decoration: const InputDecoration(labelText: 'الاسم الأول *', border: OutlineInputBorder()),
               validator: (v) => v!.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
               controller: _fatherNameController,
               decoration: const InputDecoration(labelText: 'اسم الأب *', border: OutlineInputBorder()),
               validator: (v) => v!.isEmpty ? 'مطلوب' : null,
            ),
             const SizedBox(height: 10),
            TextFormField(
               controller: _grandfatherNameController,
               decoration: const InputDecoration(labelText: 'اسم الجد *', border: OutlineInputBorder()),
               validator: (v) => v!.isEmpty ? 'مطلوب' : null,
            ),
             const SizedBox(height: 10),
            TextFormField(
               controller: _familyNameController,
               decoration: const InputDecoration(labelText: 'اللقب *', border: OutlineInputBorder()),
               validator: (v) => v!.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 10),
            _buildTextField(_greatGrandfatherNameController, 'اسم الجد الكبير'),
            const SizedBox(height: 10),
             _buildDatePicker('تاريخ الميلاد *', _birthDate, (d) => setState(() => _birthDate = d)),
            const SizedBox(height: 10),
            _buildTextField(_birthPlaceController, 'محال الميلاد *', required: true),
            const SizedBox(height: 10),
            _buildTextField(_phoneController, 'الجوال *', keyboardType: TextInputType.phone, required: true),
            const SizedBox(height: 10),
            _buildTextField(_homePhoneController, 'هاتف المنزل', keyboardType: TextInputType.phone),
        ],
      )
    ),
    Step(
      title: const Text('الهوية'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
            DropdownButtonFormField<String>(
                value: _proofType,
                decoration: const InputDecoration(labelText: 'نوع الإثبات'),
                items: const [
                  DropdownMenuItem(value: 'بطاقة شخصية', child: Text('بطاقة شخصية')),
                  DropdownMenuItem(value: 'جواز سفر', child: Text('جواز سفر')),
                  DropdownMenuItem(value: 'بطاقة عسكرية', child: Text('بطاقة عسكرية')),
                  DropdownMenuItem(value: 'بطاقة عائلية', child: Text('بطاقة عائلية')),
                ],
                onChanged: (val) => setState(() => _proofType = val!),
            ),
            const SizedBox(height: 10),
            _buildTextField(_proofNumberController, 'رقم الإثبات *', required: true),
            const SizedBox(height: 10),
            _buildTextField(_issuingAuthorityController, 'جهة الإصدار *', required: true),
            const SizedBox(height: 10),
             _buildDatePicker('تاريخ الإصدار', _issueDate, (d) {
               setState(() {
                 _issueDate = d;
                 _expiryDate = DateTime(d.year + 10, d.month, d.day);
               });
             }),
            const SizedBox(height: 10),
             _buildDatePicker('تاريخ الانتهاء', _expiryDate, (d) => setState(() => _expiryDate = d)),
        ],
      )
    ),
    Step(
      title: const Text('المهنة'),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
             _buildTextField(_qualificationController, 'المؤهل العلمي'),
             const SizedBox(height: 10),
             _buildTextField(_jobController, 'الوظيفة'),
             const SizedBox(height: 10),
             _buildTextField(_workplaceController, 'جهة العمل'),
             const SizedBox(height: 10),
             _buildTextField(_experienceNotesController, 'ملاحظات الخبرة', maxLines: 2),
        ],
      )
    ),
     Step(
      title: const Text('الرخصة'),
      isActive: _currentStep >= 3,
      state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
            _buildTextField(_ministerialNumController, 'رقم القرار الوزاري'),
             const SizedBox(height: 10),
            _buildDatePicker('تاريخ القرار', _ministerialDate, (d) => setState(() => _ministerialDate = d)),
             const SizedBox(height: 10),
            _buildTextField(_licenseNumController, 'رقم الترخيص'),
             const SizedBox(height: 10),
             _buildDatePicker('إصدار الترخيص', _licenseIssueDate, (d) {
               setState(() {
                 _licenseIssueDate = d;
                 _licenseExpiryDate = DateTime(d.year + 3, d.month, d.day);
               });
             }),
            const SizedBox(height: 10),
             _buildDatePicker('انتهاء الترخيص', _licenseExpiryDate, (d) => setState(() => _licenseExpiryDate = d)),
             const SizedBox(height: 10),
             _buildTextField(_cardNumController, 'رقم بطاقة المهنة'),
             const SizedBox(height: 10),
             _buildDatePicker('إصدار البطاقة', _cardIssueDate, (d) {
               setState(() {
                 _cardIssueDate = d;
                 _cardExpiryDate = DateTime(d.year + 1, d.month, d.day);
               });
             }),
            const SizedBox(height: 10),
             _buildDatePicker('انتهاء البطاقة', _cardExpiryDate, (d) => setState(() => _cardExpiryDate = d)),
        ],
      )
    ),
    Step(
       title: const Text('المناطق'),
       isActive: _currentStep >= 4,
       state: _currentStep > 4 ? StepState.complete : StepState.indexed,
       content: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            ListTile(
              title: const Text('عزلة الاختصاص الرئيسية'),
              subtitle: Text(_selectedMainDistrict?.name ?? 'اختر العزلة'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _openAreaSelection('عزلة', false),
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
             const SizedBox(height: 10),
             ListTile(
              title: const Text('القرى (Multi-Select)'),
              subtitle: Text(_selectedVillages.isEmpty 
                  ? 'اختر القرى' 
                  : _selectedVillages.map((e) => e.name).join(', ')),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _openAreaSelection('قرية', true),
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
             const SizedBox(height: 10),
             ListTile(
              title: const Text('المحلات (Multi-Select)'),
              subtitle: Text(_selectedLocalities.isEmpty 
                  ? 'اختر المحلات' 
                  : _selectedLocalities.map((e) => e.name).join(', ')),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _openAreaSelection('محل', true),
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
         ],
       )
    ),
     Step(
      title: const Text('الحالة'),
      isActive: _currentStep >= 5,
      state: _currentStep > 5 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
            DropdownButtonFormField<String>(
                value: _employmentStatus,
                decoration: const InputDecoration(labelText: 'الحالة الوظيفية'),
                items: const [
                  DropdownMenuItem(value: 'على رأس العمل', child: Text('على رأس العمل')),
                  DropdownMenuItem(value: 'متوقف عن العمل', child: Text('متوقف عن العمل')),
                ],
                onChanged: (val) => setState(() => _employmentStatus = val!),
            ),
             if (_employmentStatus == 'متوقف عن العمل') ...[
                const SizedBox(height: 10),
                _buildDatePicker('تاريخ التوقف', _stopDate, (d) => setState(() => _stopDate = d)),
                const SizedBox(height: 10),
                _buildTextField(_stopReasonController, 'سبب التوقف', maxLines: 2),
              ],
              const SizedBox(height: 10),
              _buildTextField(_notesController, 'ملاحظات عامة', maxLines: 3),
        ],
      )
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.guardian == null ? 'إضافة أمين' : 'تعديل أمين')),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepTapped: (index) => setState(() => _currentStep = index),
          onStepContinue: () {
             if (_currentStep < _steps.length - 1) {
               setState(() => _currentStep += 1);
             } else {
               _save();
             }
          },
          onStepCancel: () {
             if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            }
          },
          controlsBuilder: (ctx, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: Text(_currentStep == _steps.length - 1 ? 'حفظ البيانات' : 'التالي'),
                    ),
                  ),
                  if (_currentStep > 0) ...[
                     const SizedBox(width: 8),
                     Expanded(
                       child: OutlinedButton(
                         onPressed: details.onStepCancel, 
                         child: const Text('السابق'),
                       ),
                     )
                  ]
                ],
              ),
            );
          },
          steps: _steps,
        ),
      ),
    );
  }
  
  Widget _buildTextField(TextEditingController c, String label, {TextInputType? keyboardType, bool required = false, int maxLines = 1}) {
    return TextFormField(
      controller: c,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: required ? (v) => v == null || v.isEmpty ? 'مطلوب' : null : null,
    );
  }

  Widget _buildDatePicker(String label, DateTime? selectedDate, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context, 
          initialDate: selectedDate ?? DateTime.now(), 
          firstDate: DateTime(1900), 
          lastDate: DateTime(2100)
        );
        if (d != null) onSelect(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(
           labelText: label,
           border: const OutlineInputBorder(),
           suffixIcon: const Icon(Icons.calendar_today)
        ),
        child: Text(selectedDate != null ? _formatDate(selectedDate) : ''),
      ),
    );
  }
}

class _AreaSelectionSheet extends StatefulWidget {
  final String type;
  final bool multi;
  final AdminAreasRepository repo;
  final List<AdminArea> currentSelection;
  final Function(List<AdminArea>) onSelected;

  const _AreaSelectionSheet({
      required this.type, 
      required this.multi, 
      required this.repo, 
      required this.currentSelection, 
      required this.onSelected
  });

  @override
  State<_AreaSelectionSheet> createState() => _AreaSelectionSheetState();
}

class _AreaSelectionSheetState extends State<_AreaSelectionSheet> {
    List<AdminArea> _items = [];
    List<AdminArea> _selected = [];
    bool _loading = false;
    final _searchCtrl = TextEditingController();
    Timer? _debounce;

    @override
    void initState() {
      super.initState();
      _selected = List.from(widget.currentSelection);
      _fetch();
    }

    void _fetch({String? query}) async {
        setState(() => _loading = true);
        try {
            final items = await widget.repo.getAreas(type: widget.type, searchQuery: query);
            if (mounted) setState(() => _items = items);
        } catch (e) {
           // Handle error
        } finally {
            if (mounted) setState(() => _loading = false);
        }
    }

    void _onSearch(String val) {
        if (_debounce?.isActive ?? false) _debounce!.cancel();
        _debounce = Timer(const Duration(milliseconds: 500), () => _fetch(query: val));
    }

    @override
    Widget build(BuildContext context) {
       return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
               Text('اختر ${widget.type}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               const SizedBox(height: 10),
               TextField(
                 controller: _searchCtrl,
                 decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'بحث...'),
                 onChanged: _onSearch,
               ),
               const SizedBox(height: 10),
               Expanded(
                 child: _loading 
                   ? const Center(child: CircularProgressIndicator())
                   : ListView.builder(
                       itemCount: _items.length,
                       itemBuilder: (ctx, i) {
                           final item = _items[i];
                           final isSelected = _selected.any((s) => s.id == item.id);
                           return ListTile(
                             title: Text(item.name),
                             trailing: isSelected 
                               ? const Icon(Icons.check, color: Colors.green)
                               : null,
                             onTap: () {
                                 setState(() {
                                    if (widget.multi) {
                                       if (isSelected) {
                                          _selected.removeWhere((s) => s.id == item.id);
                                       } else {
                                          _selected.add(item);
                                       }
                                    } else {
                                        _selected = [item];
                                        widget.onSelected(_selected);
                                        Navigator.pop(context);
                                    }
                                 });
                             },
                           );
                       },
                   ),
               ),
               if (widget.multi)
                 ElevatedButton(
                   onPressed: () {
                      widget.onSelected(_selected);
                      Navigator.pop(context);
                   },
                   child: const Text('تأكيد الاختيار'),
                 )
            ],
          ),
       );
    }
}
