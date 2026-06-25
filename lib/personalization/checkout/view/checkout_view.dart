import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:surya_ecommerce/core/widgets/custom_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/cart_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../core/services/pdf_invoice_service.dart';
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
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

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
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _handlePlaceOrder(CartSummary cartSummary) async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please complete all required fields.', AppColors.error);
      return;
    }

    if (_isLoading) return;

    final confirmed = await _showConfirmationDialog();
    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();
      final products = cartSummary.items.map((item) => OrderProductModel(
        productId: item.product.id,
        productName: item.product.productName,
        imageUrl: item.product.imageUrls.isNotEmpty ? item.product.imageUrls.first : '',
        quantity: item.quantity,
        unitPrice: item.product.price,
        totalPrice: item.totalPrice,
      )).toList();

      final order = OrderModel(
        orderId: orderId,
        createdAt: DateTime.now(),
        customerName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        paymentType: 'WhatsApp',
        orderStatus: 'Pending',
        subtotal: cartSummary.subtotal,
        discount: 0,
        deliveryCharge: 0,
        tax: 0,
        grandTotal: cartSummary.grandTotal,
        products: products,
      );

      // Save order to Firestore
      await ref.read(orderRepositoryProvider).saveOrder(order);

      // Track ordered status locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('orderDone', true);
      final productIds = cartSummary.items.map((e) => e.product.id).toList();
      await prefs.setStringList('orderedProductIds', productIds);
      await prefs.setInt('orderedTime', DateTime.now().millisecondsSinceEpoch);

      // Generate PDF Invoice
      final pdfBytes = await PdfInvoiceService.generateInvoice(order);
      
      // Download / Share PDF on Web
      Printing.sharePdf(bytes: pdfBytes, filename: 'invoice_$orderId.pdf');

      // WhatsApp Message
      final message = _generateWhatsAppMessage(order);
      const adminPhoneNumber = '919846203815'; // Change if needed
      final whatsappUrl = Uri.parse(
        'https://wa.me/$adminPhoneNumber?text=${Uri.encodeComponent(message)}',
      );

      if (await canLaunchUrl(whatsappUrl)) {
        launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
        _showSnackBar('Order placed successfully. Our sales executive will contact you shortly.', AppColors.accentGold);
        await ref.read(cartViewModelProvider.notifier).clearCart();
        if (mounted) AppRouter.goHome(context);
      } else {
        _showSnackBar('Order saved successfully. Unable to open WhatsApp.', AppColors.accentGold);
      }
    } catch (e) {
      _showSnackBar('Error: $e', AppColors.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: Text(
            'Confirm Order',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to place this order?\n\nOnce your order is placed, our sales executive/customer care team will contact you shortly to confirm your order and delivery details.',
            style: GoogleFonts.outfit(color: AppColors.softGrey),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Place Order', style: GoogleFonts.outfit(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
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

  String _generateWhatsAppMessage(OrderModel order) {
    final buffer = StringBuffer();

    buffer.writeln('Hello,');
    buffer.writeln('A new order has been placed.');
    buffer.writeln('');
    buffer.writeln('Order ID: ${order.orderId}');
    buffer.writeln('Please find the attached order invoice.');
    buffer.writeln('');
    buffer.writeln('Customer: ${order.customerName}');
    buffer.writeln('Phone: ${order.phone}');

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: CustomAppBar(title: 'CHECKOUT'),
      body: Stack(
        children: [
          cartAsync.when(
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
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 800),
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
                        ),
                      ),
                      _buildBottomAction(cartSummary),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.accentGold),
              ),
            ),
        ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 600;
        
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
            if (isDesktop) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _nameController,
                      hint: "Your Full Name",
                      icon: Icons.person_outline,
                      validator: (v) => v!.isEmpty ? "Name is required" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _phoneController,
                      hint: "WhatsApp Phone Number",
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Phone is required";
                        if (!RegExp(r'^\d{10}$').hasMatch(v)) return "Enter a valid 10-digit number";
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
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
                validator: (v) {
                  if (v == null || v.isEmpty) return "Phone is required";
                  if (!RegExp(r'^\d{10}$').hasMatch(v)) return "Enter a valid 10-digit number";
                  return null;
                },
              ),
            ],
          ],
        );
      },
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _handlePlaceOrder(summary),
          icon: _isLoading ? const SizedBox.shrink() : const FaIcon(FontAwesomeIcons.whatsapp, size: 22),
          label: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  "Place Order via WhatsApp",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 16,
                  ),
                ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF25D366).withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
            ),
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
