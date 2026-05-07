import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Lodge a Complaint', showBackButton: false),
      backgroundColor: AppColors.primaryDark,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 120,
          vertical: 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SUBMIT YOUR COMPLAINT',
              style: GoogleFonts.outfit(
                color: AppColors.accentGold,
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We value your feedback and aim to resolve any issues you may have as quickly as possible.',
              style: GoogleFonts.outfit(
                color: AppColors.softGrey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Full Name'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hint: 'Enter your name',
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Email Address'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _emailController,
                              hint: 'email@example.com',
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v == null || !v.contains('@') ? 'Invalid email' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Phone Number'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _phoneController,
                              hint: 'Enter phone',
                              keyboardType: TextInputType.phone,
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildFieldLabel('Complaint Subject'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _subjectController,
                    hint: 'e.g., Product Quality, Delivery Delay',
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildFieldLabel('Detailed Message'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _messageController,
                    hint: 'Please describe your complaint in detail...',
                    maxLines: 6,
                    validator: (v) => v == null || v.length < 10 ? 'Minimum 10 characters' : null,
                  ),
                  const SizedBox(height: 40),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
                      : SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _submitComplaint,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentGold,
                              foregroundColor: AppColors.primaryDark,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              'SUBMIT COMPLAINT',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.outfit(
        color: AppColors.textWhite,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.outfit(color: AppColors.textWhite, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: AppColors.softGrey.withOpacity(0.4)),
        filled: true,
        fillColor: AppColors.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderSoft.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderSoft.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentGold, width: 1.5),
        ),
      ),
    );
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('complaints').add({
        'userName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'read': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your complaint has been submitted successfully.'),
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
