import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:guardian_app/features/admin/data/models/admin_guardian_model.dart';
import 'package:guardian_app/features/admin/data/repositories/admin_guardian_repository.dart';

class AddEditGuardianScreen extends StatefulWidget {
  final AdminGuardian? guardian;

  const AddEditGuardianScreen({super.key, this.guardian});

  @override
  State<AddEditGuardianScreen> createState() => _AddEditGuardianScreenState();
}

class _AddEditGuardianScreenState extends State<AddEditGuardianScreen> {
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
  String _proofType = 'بطاقة شخصية'; // Default
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

  // 6. Geographic
  final _mainDistrictIdController = TextEditingController(); // For simple ID input now

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
    if (g.mainDistrictId != null) _mainDistrictIdController.text = g.mainDistrictId.toString();

    // Status
    _employmentStatus = g.employmentStatus ?? 'على رأس العمل';
    // Fix mismatch if any (English vs Arabic) - Model should hold the value used in UI or we map it.
    // The previous mapping was for *Filters*. For stored data, it's usually Arabic in DB?
    // Let's assume the API returns the Arabic string 'على رأس العمل'.
    
    if (g.stopDate != null) _stopDate = DateTime.tryParse(g.stopDate!);
    _stopReasonController.text = g.stopReason ?? '';
    _notesController.text = g.notes ?? '';
  }

  @override
  void dispose() {
    // Dispose all controllers
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
    _mainDistrictIdController.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة الحقول المطلوبة (بالأحمر)')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = context.read<AdminGuardianRepository>();
      
      final Map<String, String> data = {
        'serial_number': _serialNumberController.text,
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
        
        'main_district_id': _mainDistrictIdController.text,
        
        'employment_status': _employmentStatus,
        'stop_reason': _stopReasonController.text,
        'notes': _notesController.text,
      };

      // Helper to add dates
      if (_birthDate != null) data['birth_date'] = _formatDate(_birthDate!);
      if (_issueDate != null) data['issue_date'] = _formatDate(_issueDate!);
      if (_expiryDate != null) data['expiry_date'] = _formatDate(_expiryDate!);
      if (_ministerialDate != null) data['ministerial_decision_date'] = _formatDate(_ministerialDate!);
      if (_licenseIssueDate != null) data['license_issue_date'] = _formatDate(_licenseIssueDate!);
      if (_licenseExpiryDate != null) data['license_expiry_date'] = _formatDate(_licenseExpiryDate!);
      if (_cardIssueDate != null) data['profession_card_issue_date'] = _formatDate(_cardIssueDate!);
      if (_cardExpiryDate != null) data['profession_card_expiry_date'] = _formatDate(_cardExpiryDate!);
      if (_stopDate != null) data['stop_date'] = _formatDate(_stopDate!);


      if (widget.guardian == null) {
        await repo.createGuardian(data, imagePath: _selectedImage?.path);
      } else {
        await repo.updateGuardian(widget.guardian!.id, data, imagePath: _selectedImage?.path);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم الحفظ بنجاح')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.guardian == null ? 'إضافة أمين جديد' : 'تعديل بيانات الأمين'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Section
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (widget.guardian?.photoUrl != null
                            ? NetworkImage(widget.guardian!.photoUrl!) as ImageProvider
                            : null),
                    child: (_selectedImage == null && widget.guardian?.photoUrl == null)
                        ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
              ),
              const Center(child: Text('اضغط لتغيير الصورة', style: TextStyle(color: Colors.grey))),
              const SizedBox(height: 20),

              _buildSectionTitle('البيانات الشخصية'),
              _buildTextField(_serialNumberController, 'الرقم التسلسلي *', keyboardType: TextInputType.number, required: true),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildTextField(_firstNameController, 'الاسم الأول *', required: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTextField(_fatherNameController, 'اسم الأب *', required: true)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                   Expanded(child: _buildTextField(_grandfatherNameController, 'اسم الجد *', required: true)),
                   const SizedBox(width: 8),
                   Expanded(child: _buildTextField(_familyNameController, 'اللقب *', required: true)),
                ],
              ),
              const SizedBox(height: 10),
              _buildTextField(_greatGrandfatherNameController, 'اسم الجد الكبير'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildDatePicker('تاريخ الميلاد *', _birthDate, (d) => setState(() => _birthDate = d))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTextField(_birthPlaceController, 'محال الميلاد *', required: true)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                   Expanded(child: _buildTextField(_phoneController, 'الجوال *', keyboardType: TextInputType.phone, required: true)),
                   const SizedBox(width: 8),
                   Expanded(child: _buildTextField(_homePhoneController, 'هاتف المنزل', keyboardType: TextInputType.phone)),
                ],
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('بيانات الهوية'),
              DropdownButtonFormField<String>(
                initialValue: _proofType,
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
              Row(
                children: [
                  Expanded(child: _buildDatePicker('تاريخ الإصدار *', _issueDate, (d) => setState(() => _issueDate = d))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDatePicker('تاريخ الانتهاء', _expiryDate, (d) => setState(() => _expiryDate = d))),
                ],
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('البيانات المهنية'),
              _buildTextField(_qualificationController, 'المؤهل العلمي *', required: true),
              const SizedBox(height: 10),
              _buildTextField(_jobController, 'الوظيفة *', required: true),
              const SizedBox(height: 10),
              _buildTextField(_workplaceController, 'جهة العمل *', required: true),
              const SizedBox(height: 10),
              _buildTextField(_experienceNotesController, 'ملاحظات الخبرة', maxLines: 2),

              const SizedBox(height: 24),
              _buildSectionTitle('القرار الوزاري والرخصة'),
              _buildTextField(_ministerialNumController, 'رقم القرار الوزاري'),
              const SizedBox(height: 10),
              _buildDatePicker('تاريخ القرار', _ministerialDate, (d) => setState(() => _ministerialDate = d)),
              const SizedBox(height: 10),
              _buildTextField(_licenseNumController, 'رقم الترخيص'),
              const SizedBox(height: 10),
               Row(
                children: [
                  Expanded(child: _buildDatePicker('إصدار الترخيص', _licenseIssueDate, (d) => setState(() => _licenseIssueDate = d))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDatePicker('انتهاء الترخيص', _licenseExpiryDate, (d) => setState(() => _licenseExpiryDate = d))),
                ],
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('بطاقة المهنة'),
               _buildTextField(_cardNumController, 'رقم البطاقة'),
              const SizedBox(height: 10),
               Row(
                children: [
                  Expanded(child: _buildDatePicker('إصدار البطاقة', _cardIssueDate, (d) => setState(() => _cardIssueDate = d))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDatePicker('انتهاء البطاقة', _cardExpiryDate, (d) => setState(() => _cardExpiryDate = d))),
                ],
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('الموقع الجغرافي'),
              _buildTextField(_mainDistrictIdController, 'رقم العزلة (District ID)', keyboardType: TextInputType.number),
              // Note: Ideally a Dropdown.
              
              const SizedBox(height: 24),
              _buildSectionTitle('الحالة الوظيفية'),
              DropdownButtonFormField<String>(
                initialValue: _employmentStatus,
                decoration: const InputDecoration(labelText: 'الحالة'),
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

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('حفظ البيانات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {
    TextInputType? keyboardType, 
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: required ? (val) => val == null || val.isEmpty ? 'مطلوب' : null : null,
    );
  }

  Widget _buildDatePicker(String label, DateTime? selectedDate, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (d != null) onSelect(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          suffixIcon: const Icon(Icons.calendar_today, size: 20),
        ),
        child: Text(
          selectedDate != null ? _formatDate(selectedDate) : '',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
