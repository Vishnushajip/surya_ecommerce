import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/responsive/responsive_helper.dart';

class ContactUsView extends ConsumerStatefulWidget {
  final bool isInline;
  const ContactUsView({super.key, this.isInline = false});

  @override
  ConsumerState<ContactUsView> createState() => _ContactUsViewState();
}

class _ContactUsViewState extends ConsumerState<ContactUsView> {
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
    final body = SingleChildScrollView(
      physics: widget.isInline ? const NeverScrollableScrollPhysics() : null,
      child: Column(
        children: [
          _buildContactInfoSection(context),
          _buildContactFormSection(context),
          _buildMapSection(context),
        ],
      ),
    );

    if (widget.isInline) return body;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Contact Us'),
      backgroundColor: AppColors.primaryDark,
      body: body,
    );
  }

  Widget _buildContactInfoSection(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 80,
        vertical: isMobile ? 36 : 56,
      ),
      color: AppColors.primaryDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'CONTACT\nINFORMATION',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: AppColors.accentGold,
              fontSize: isMobile ? 32 : 42,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Container(width: 48, height: 3, color: AppColors.accentGold),
          SizedBox(height: isMobile ? 28 : 40),
          isMobile
              ? Column(
                  children: [
                    _buildInfoCard(
                      icon: Icons.location_on,
                      title: 'Our Address',
                      content: AppConstants.companyAddress,
                      onTap: () => _launchUrl(
                        'https://maps.google.com/?q=${Uri.encodeComponent(AppConstants.companyAddress)}',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildInfoCard(
                      icon: Icons.phone,
                      title: 'Call Us',
                      content: AppConstants.companyPhone,
                      onTap: () =>
                          _launchUrl('tel:${AppConstants.companyPhone}'),
                    ),
                    const SizedBox(height: 14),
                    _buildInfoCard(
                      icon: Icons.email_outlined,
                      title: 'Email Us',
                      content: AppConstants.companyEmail,
                      onTap: () =>
                          _launchUrl('mailto:${AppConstants.companyEmail}'),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.location_on,
                        title: 'Our Address',
                        content: AppConstants.companyAddress,
                        onTap: () => _launchUrl(
                          'https://maps.google.com/?q=${Uri.encodeComponent(AppConstants.companyAddress)}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.phone,
                        title: 'Call Us',
                        content: AppConstants.companyPhone,
                        onTap: () =>
                            _launchUrl('tel:${AppConstants.companyPhone}'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.email_outlined,
                        title: 'Email Us',
                        content: AppConstants.companyEmail,
                        onTap: () =>
                            _launchUrl('mailto:${AppConstants.companyEmail}'),
                      ),
                    ),
                  ],
                ),
          SizedBox(height: isMobile ? 24 : 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton(
                icon: Icons.chat_outlined,
                label: 'WHATSAPP',
                url:
                    'https://wa.me/${AppConstants.whatsappNumber.replaceAll('+', '')}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderSoft.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.accentGold, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: AppColors.accentGold,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    content,
                    style: GoogleFonts.outfit(
                      color: AppColors.softGrey,
                      fontSize: 13,
                      height: 1.5,
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

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required String url,
  }) {
    return ElevatedButton.icon(
      onPressed: () => _launchUrl(url),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }

  Widget _buildContactFormSection(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 80,
        vertical: isMobile ? 32 : 52,
      ),
      color: AppColors.secondaryDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEND US A MESSAGE',
            style: GoogleFonts.outfit(
              color: AppColors.textWhite,
              fontSize: isMobile ? 20 : 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(width: 36, height: 3, color: AppColors.accentGold),
          const SizedBox(height: 28),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel('Your Name'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _nameController,
                  hint: 'Enter your full name',
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 18),
                _buildFieldLabel('Your Email'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _emailController,
                  hint: 'example@gmail.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!v.contains('@')) return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _buildFieldLabel('Your Phone'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _phoneController,
                  hint: '+91 00000 00000',
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty
                      ? 'Please enter your phone number'
                      : null,
                ),
                const SizedBox(height: 18),
                _buildFieldLabel('Subject'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _subjectController,
                  hint: 'What is this regarding?',
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Please enter a subject' : null,
                ),
                const SizedBox(height: 18),
                _buildFieldLabel('Your Message'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _messageController,
                  hint: 'Write your message here...',
                  maxLines: 5,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please enter your message';
                    }
                    if (v.length < 10) {
                      return 'Message must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentGold,
                          strokeWidth: 1,
                        ),
                      )
                    : SizedBox(
                        width: isMobile ? double.infinity : 260,
                        height: 52,
                        child: Align(
                          alignment: isMobile
                              ? Alignment.center
                              : Alignment.centerLeft,
                          child: SizedBox(
                            width: isMobile ? double.infinity : 260,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentGold,
                                foregroundColor: AppColors.primaryDark,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'SEND INQUIRY',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        color: AppColors.textWhite,
        fontSize: 13,
        fontWeight: FontWeight.w600,
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
      style: GoogleFonts.outfit(color: AppColors.textWhite, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(
          color: AppColors.softGrey.withValues(alpha: 0.5),
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.cardDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.borderSoft.withValues(alpha: 0.4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.borderSoft.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accentGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildMapSection(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return GestureDetector(
      onTap: () => _launchUrl(
        'https://maps.google.com/?q=${Uri.encodeComponent(AppConstants.companyAddress)}',
      ),
      child: Container(
        width: double.infinity,
        height: isMobile ? 220 : 320,
        color: AppColors.primaryDark,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFF0d1f1a),
              child: CustomPaint(painter: _MapGridPainter()),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentGold.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.primaryDark,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppConstants.companyAddress,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: AppColors.softGrey,
                      fontSize: 13,
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('contact_submissions').add({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'timestamp': Timestamp.now(),
        'status': 'pending',
        'read': false,
      });

      _clearForm();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Message sent successfully! We\'ll get back to you soon.',
            ),
            backgroundColor: AppColors.accentGold,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _subjectController.clear();
    _messageController.clear();
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1a3a2a).withValues(alpha: 0.6)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const spacing = 28.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final curvePaint = Paint()
      ..color = AppColors.accentGold.withValues(alpha: 0.12)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path1 = Path()
      ..moveTo(size.width * 0.1, size.height * 0.6)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.2,
        size.width * 0.9,
        size.height * 0.5,
      );
    canvas.drawPath(path1, curvePaint);

    final path2 = Path()
      ..moveTo(size.width * 0.0, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.4,
        size.width * 1.0,
        size.height * 0.7,
      );
    canvas.drawPath(path2, curvePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
