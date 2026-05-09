import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/responsive/responsive_helper.dart';

class ComplaintFormView extends ConsumerStatefulWidget {
  const ComplaintFormView({super.key});

  @override
  ConsumerState<ComplaintFormView> createState() => _ComplaintFormViewState();
}

class _ComplaintFormViewState extends ConsumerState<ComplaintFormView> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _altPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();

  final _productNameController = TextEditingController();
  final _brandNameController = TextEditingController();
  final _modelNumberController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  DateTime? _purchaseDate;

  String _complaintType = 'Not Working';
  final _messageController = TextEditingController();
  PlatformFile? _productImageFile;
  PlatformFile? _billCopyFile;

  DateTime? _preferredServiceDate;
  bool _technicianVisitRequired = true;
  String _warrantyStatus = 'Under Warranty';

  bool _isLoading = false;

  final List<String> _complaintTypes = [
    'Not Working',
    'Damaged Product',
    'Noise Issue',
    'Heating Issue',
    'Remote Problem',
    'Installation Issue',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _productNameController.dispose();
    _brandNameController.dispose();
    _modelNumberController.dispose();
    _serialNumberController.dispose();
    _invoiceNumberController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(bool isProductImage) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: isProductImage ? FileType.image : FileType.custom,
        allowedExtensions: isProductImage
            ? null
            : ['pdf', 'jpg', 'png', 'jpeg'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          if (isProductImage) {
            _productImageFile = result.files.first;
          } else {
            _billCopyFile = result.files.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  Future<String?> _uploadFile(PlatformFile file, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final storageRef = FirebaseStorage.instance.ref().child(
        'complaints/$folder/$fileName',
      );

      final uploadTask = storageRef.putData(file.bytes!);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> _selectDate(BuildContext context, bool isPurchaseDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentGold,
              onPrimary: AppColors.primaryDark,
              surface: AppColors.cardDark,
              onSurface: AppColors.textWhite,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isPurchaseDate) {
          _purchaseDate = picked;
        } else {
          _preferredServiceDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Product Complaint Register',
        showBackButton: false,
      ),
      backgroundColor: AppColors.primaryDark,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 120,
          vertical: 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),

              // 1. BASIC CUSTOMER DETAILS
              _buildSectionTitle(1, 'BASIC CUSTOMER DETAILS', Icons.person),
              _buildSectionCard([
                _buildResponsiveRow(isMobile, [
                  _buildInputField(
                    'Customer Name *',
                    _nameController,
                    'Enter your full name',
                    (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  _buildInputField(
                    'Mobile Number *',
                    _phoneController,
                    'Enter mobile number',
                    (v) => v == null || v.isEmpty ? 'Required' : null,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildInputField(
                    'Alternate Contact Number',
                    _altPhoneController,
                    'Enter alternate number',
                    null,
                    keyboardType: TextInputType.phone,
                  ),
                ]),
                const SizedBox(height: 16),
                _buildInputField(
                  'Address *',
                  _addressController,
                  'Enter your complete address',
                  (v) => v == null || v.isEmpty ? 'Required' : null,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  'Email ID (Optional)',
                  _emailController,
                  'Enter email address',
                  null,
                  keyboardType: TextInputType.emailAddress,
                ),
              ]),

              const SizedBox(height: 24),

              // 2. PRODUCT DETAILS
              _buildSectionTitle(2, 'PRODUCT DETAILS', Icons.inventory_2),
              _buildSectionCard([
                _buildResponsiveRow(isMobile, [
                  _buildInputField(
                    'Product Name *',
                    _productNameController,
                    'Enter product name',
                    (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  _buildInputField(
                    'Brand Name *',
                    _brandNameController,
                    'Enter brand name',
                    (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  _buildInputField(
                    'Model Number *',
                    _modelNumberController,
                    'Enter model number',
                    (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ]),
                const SizedBox(height: 16),
                _buildResponsiveRow(isMobile, [
                  _buildInputField(
                    'Product Serial Number (Optional)',
                    _serialNumberController,
                    'Enter serial number',
                    null,
                  ),
                  _buildDatePickerField(
                    'Date of Purchase *',
                    _purchaseDate,
                    () => _selectDate(context, true),
                  ),
                  _buildInputField(
                    'Invoice / Bill Number *',
                    _invoiceNumberController,
                    'Enter invoice or bill number',
                    (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ]),
              ]),

              const SizedBox(height: 24),

              // 3. COMPLAINT DETAILS
              _buildSectionTitle(3, 'COMPLAINT DETAILS', Icons.error_outline),
              _buildSectionCard([
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Complaint Type *'),
                          const SizedBox(height: 12),
                          _buildComplaintTypeGrid(),
                          const SizedBox(height: 20),
                          _buildInputField(
                            'Complaint Description *',
                            _messageController,
                            'Please describe the issue in detail',
                            (v) => v == null || v.isEmpty ? 'Required' : null,
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                    if (!isMobile) const SizedBox(width: 32),
                    if (!isMobile)
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildUploadPlaceholder(
                              'Upload Product Image (Optional)',
                              Icons.add_a_photo_outlined,
                              _productImageFile,
                              () => _pickFile(true),
                            ),
                            const SizedBox(height: 16),
                            _buildUploadPlaceholder(
                              'Upload Bill Copy (Optional)',
                              Icons.file_present_outlined,
                              _billCopyFile,
                              () => _pickFile(false),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (isMobile) ...[
                  const SizedBox(height: 24),
                  _buildUploadPlaceholder(
                    'Upload Product Image (Optional)',
                    Icons.add_a_photo_outlined,
                    _productImageFile,
                    () => _pickFile(true),
                  ),
                  const SizedBox(height: 16),
                  _buildUploadPlaceholder(
                    'Upload Bill Copy (Optional)',
                    Icons.file_present_outlined,
                    _billCopyFile,
                    () => _pickFile(false),
                  ),
                ],
              ]),

              const SizedBox(height: 24),

              // 4. SERVICE DETAILS
              _buildSectionTitle(4, 'SERVICE DETAILS', Icons.build),
              _buildSectionCard([
                _buildResponsiveRow(isMobile, [
                  _buildDatePickerField(
                    'Preferred Service Date',
                    _preferredServiceDate,
                    () => _selectDate(context, false),
                  ),
                  _buildRadioSection(
                    'Technician Visit Required? *',
                    ['Yes', 'No'],
                    _technicianVisitRequired ? 'Yes' : 'No',
                    (v) =>
                        setState(() => _technicianVisitRequired = v == 'Yes'),
                  ),
                  _buildRadioSection(
                    'Warranty Status *',
                    ['Under Warranty', 'Out of Warranty'],
                    _warrantyStatus,
                    (v) => setState(() => _warrantyStatus = v!),
                  ),
                ]),
              ]),

              const SizedBox(height: 40),

              // BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: isMobile ? 140 : 200,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _formKey.currentState?.reset();
                        setState(() {
                          _productImageFile = null;
                          _billCopyFile = null;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('RESET FORM'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: isMobile ? 180 : 250,
                    height: 50,
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accentGold,
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _submitComplaint,
                            icon: const Icon(Icons.send),
                            label: const Text('SUBMIT COMPLAINT'),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 16,
                      color: AppColors.softGrey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your information is safe with us. We value your trust.',
                      style: GoogleFonts.outfit(
                        color: AppColors.softGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRODUCT COMPLAINT REGISTER',
          style: GoogleFonts.outfit(
            color: AppColors.accentGold,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please fill in the details below to register your product complaint.\nOur support team will contact you shortly.',
          style: GoogleFonts.outfit(
            color: AppColors.softGrey,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(int number, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentGold,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            '$number. $title',
            style: GoogleFonts.outfit(
              color: AppColors.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderSoft.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildResponsiveRow(bool isMobile, List<Widget> children) {
    if (isMobile) {
      return Column(
        children: children
            .map(
              (w) =>
                  Padding(padding: const EdgeInsets.only(bottom: 16), child: w),
            )
            .toList(),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children
          .map(
            (w) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: w,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        color: AppColors.textWhite,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String hint,
    String? Function(String?)? validator, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.outfit(color: AppColors.textWhite, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField(
    String label,
    DateTime? date,
    VoidCallback onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              border: Border.all(color: AppColors.borderSoft),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date == null
                      ? 'dd-mm-yyyy'
                      : DateFormat('dd-MM-yyyy').format(date),
                  style: GoogleFonts.outfit(
                    color: date == null
                        ? AppColors.textMuted
                        : AppColors.textWhite,
                    fontSize: 14,
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: AppColors.softGrey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComplaintTypeGrid() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: _complaintTypes.map((type) {
        return InkWell(
          onTap: () => setState(() => _complaintType = type),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<String>(
                value: type,
                groupValue: _complaintType,
                activeColor: AppColors.accentGold,
                onChanged: (v) => setState(() => _complaintType = v!),
                visualDensity: VisualDensity.compact,
              ),
              Text(
                type,
                style: GoogleFonts.outfit(
                  color: AppColors.textWhite,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRadioSection(
    String label,
    List<String> options,
    String currentValue,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 4),
        Row(
          children: options.map((opt) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<String>(
                  value: opt,
                  groupValue: currentValue,
                  activeColor: AppColors.accentGold,
                  onChanged: onChanged,
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  opt,
                  style: GoogleFonts.outfit(
                    color: AppColors.textWhite,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUploadPlaceholder(
    String label,
    IconData icon,
    PlatformFile? file,
    VoidCallback onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(
                color: file != null
                    ? AppColors.accentGold
                    : AppColors.borderSoft,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
              color: file != null
                  ? AppColors.accentGold.withOpacity(0.05)
                  : Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  file != null ? Icons.check_circle : icon,
                  color: file != null
                      ? AppColors.accentGold
                      : AppColors.softGrey,
                  size: 32,
                ),
                const SizedBox(height: 8),
                if (file == null)
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(
                        color: AppColors.softGrey,
                        fontSize: 12,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Click to upload ',
                          style: TextStyle(
                            color: AppColors.accentGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: 'or drag and drop'),
                      ],
                    ),
                  )
                else
                  Text(
                    file.name,
                    style: GoogleFonts.outfit(
                      color: AppColors.accentGold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  'JPG, PNG, PDF (Max. 5MB)',
                  style: GoogleFonts.outfit(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;
    if (_purchaseDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select purchase date')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? productImageUrl;
      String? billCopyUrl;

      if (_productImageFile != null) {
        productImageUrl = await _uploadFile(_productImageFile!, 'images');
      }
      if (_billCopyFile != null) {
        billCopyUrl = await _uploadFile(_billCopyFile!, 'bills');
      }

      await FirebaseFirestore.instance.collection('complaints').add({
        // 1. Basic Customer Details
        'userName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'alternatePhone': _altPhoneController.text.trim(),
        'address': _addressController.text.trim(),
        'email': _emailController.text.trim(),

        // 2. Product Details
        'productName': _productNameController.text.trim(),
        'brandName': _brandNameController.text.trim(),
        'modelNumber': _modelNumberController.text.trim(),
        'serialNumber': _serialNumberController.text.trim(),
        'purchaseDate': _purchaseDate != null
            ? Timestamp.fromDate(_purchaseDate!)
            : null,
        'invoiceNumber': _invoiceNumberController.text.trim(),

        // 3. Complaint Details
        'complaintType': _complaintType,
        'message': _messageController.text.trim(),
        'productImageUrl': productImageUrl,
        'billCopyUrl': billCopyUrl,

        // 4. Service Details
        'preferredServiceDate': _preferredServiceDate != null
            ? Timestamp.fromDate(_preferredServiceDate!)
            : null,
        'technicianVisitRequired': _technicianVisitRequired,
        'warrantyStatus': _warrantyStatus,

        // Metadata
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'read': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your complaint has been registered successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
