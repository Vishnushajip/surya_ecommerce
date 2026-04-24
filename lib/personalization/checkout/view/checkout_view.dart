import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/cart_model.dart';
import '../../cart/view_model/cart_view_model.dart';
import '../../../routes/app_router.dart';

class CheckoutView extends ConsumerStatefulWidget {
  const CheckoutView({super.key});

  @override
  ConsumerState<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends ConsumerState<CheckoutView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handlePlaceOrder(CartSummary cartSummary) async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please enter your details to proceed.', AppColors.error);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('orderDone', true);
      final productIds = cartSummary.items.map((e) => e.product.id).toList();
      await prefs.setStringList('orderedProductIds', productIds);
      await prefs.setInt('orderedTime', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error saving order: $e');
    }

    final message = _generateWhatsAppMessage(cartSummary);
    const adminPhoneNumber = '919846203815';
    final whatsappUrl = Uri.parse(
      'https://wa.me/$adminPhoneNumber?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
        await ref.read(cartViewModelProvider.notifier).clearCart();
        if (mounted) AppRouter.goHome(context);
      } else {
        _showSnackBar(
          'WhatsApp not found. Please install it to proceed.',
          AppColors.error,
        );
      }
    } catch (e) {
      _showSnackBar('Error: $e', AppColors.error);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _generateWhatsAppMessage(CartSummary cartSummary) {
    final buffer = StringBuffer();
    final dateStr = DateFormat('EEE dd MMMM yyyy').format(DateTime.now());

    buffer.writeln('NEW ORDER - SUN ASSOCIATES');
    buffer.writeln('--------------------');
    buffer.writeln('Date: $dateStr');
    buffer.writeln('--------------------');
    buffer.writeln('CUSTOMER DETAILS:');
    buffer.writeln('Name: ${_nameController.text.trim()}');
    buffer.writeln('Phone: ${_phoneController.text.trim()}');
    buffer.writeln('--------------------');
    buffer.writeln('PRODUCT LIST:');
    buffer.writeln('');

    for (int i = 0; i < cartSummary.items.length; i++) {
      final item = cartSummary.items[i];
      buffer.writeln('${i + 1}. ${item.product.productName}');
      buffer.writeln(
        '   Qty: ${item.quantity} | Total: ${item.formattedTotalPrice}\n',
      );
    }

    buffer.writeln('--------------------');
    buffer.writeln('GRAND TOTAL: ${cartSummary.formattedGrandTotal}');
    buffer.writeln('--------------------');
    buffer.writeln('');
    buffer.writeln('Please confirm my order. Thank you!');

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: Text(
          'CHECKOUT',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/cart'),
        ),
      ),
      body: cartAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentGold),
        ),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (cartSummary) {
          if (cartSummary.isEmpty) return _buildEmptyState();

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          _buildHeader(cartSummary),
                          const SizedBox(height: 30),
                          _buildCustomerForm(),
                          const SizedBox(height: 30),
                          ...cartSummary.items.map(
                            (item) => _buildOrderCard(item),
                          ),
                          const SizedBox(height: 10),
                          _buildTotalCard(cartSummary),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomAction(cartSummary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(CartSummary cartSummary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Final Checkout',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Review your order and provide delivery info',
          style: GoogleFonts.outfit(color: AppColors.softGrey, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildCustomerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "CUSTOMER INFORMATION",
          style: GoogleFonts.outfit(
            color: AppColors.accentGold,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _nameController,
          hint: "Your Full Name",
          icon: Icons.person_outline,
          validator: (v) => v!.isEmpty ? "Name is required" : null,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _phoneController,
          hint: "WhatsApp Phone Number",
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (v) => v!.isEmpty ? "Phone is required" : null,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.outfit(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
            color: AppColors.softGrey.withOpacity(0.5),
          ),
          prefixIcon: Icon(icon, color: AppColors.accentGold, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(CartModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.productName,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantity: ${item.quantity}',
                  style: GoogleFonts.outfit(
                    color: AppColors.softGrey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.formattedTotalPrice,
            style: GoogleFonts.outfit(
              color: AppColors.accentGold,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(CartSummary summary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondaryDark, AppColors.cardDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Grand Total",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            summary.formattedGrandTotal,
            style: GoogleFonts.outfit(
              color: AppColors.accentGold,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(CartSummary summary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton.icon(
          onPressed: () => _handlePlaceOrder(summary),
          icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 22),
          label: Text(
            "PLACE ORDER",
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 16,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'Nothing to checkout.',
        style: GoogleFonts.outfit(color: AppColors.softGrey),
      ),
    );
  }
}
