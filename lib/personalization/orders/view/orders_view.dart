import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/services/pdf_invoice_service.dart';
import '../../../data/models/order_model.dart';
import '../view_model/orders_view_model.dart';

class OrdersView extends ConsumerStatefulWidget {
  const OrdersView({super.key});

  @override
  ConsumerState<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends ConsumerState<OrdersView> {
  @override
  void initState() {
    super.initState();
    PdfInvoiceService.preWarm(); 
    _loadPhoneNumber();
  }

  Future<void> _loadPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('user_phone');
    if (phone != null && phone.isNotEmpty) {
      if (mounted) {
        ref.read(ordersViewModelProvider.notifier).fetchOrdersByPhone(phone);
      }
    }
  }

  Future<void> _downloadInvoice(OrderModel order) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.accentGold),
      ),
    );

    Uint8List? pdfBytes;
    String? errorMsg;
    try {
      pdfBytes = await PdfInvoiceService.generateInvoice(order);
    } catch (e) {
      errorMsg = e.toString();
    }


    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (pdfBytes != null) {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'invoice_${order.orderId}.pdf',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate invoice: $errorMsg')),
        );
      }
    });
  }

  void _showChangePhoneDialog(BuildContext context) {
    final TextEditingController phoneController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSoft),
        ),
        title: Text(
          'Change Phone Number',
          style: GoogleFonts.outfit(
            color: AppColors.accentGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter new phone number',
              hintStyle: GoogleFonts.outfit(color: AppColors.softGrey),
              prefixIcon: const Icon(Icons.phone, color: AppColors.accentGold),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSoft),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accentGold),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone number cannot be empty';
              }
              if (value.length < 10) {
                return 'Enter a valid phone number';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: AppColors.softGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newPhone = phoneController.text.trim();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_phone', newPhone);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  _loadPhoneNumber();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Save & Reload',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: const CustomAppBar(title: 'YOUR ORDERS', showBackButton: false),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Track Your Orders',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ordersState.when(
                    data: (orders) {
                      if (orders.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'No orders found for this number.',
                                style: GoogleFonts.outfit(
                                  color: AppColors.softGrey,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _showChangePhoneDialog(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentGold,
                                  foregroundColor: AppColors.primaryDark,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Change Phone Number',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return SingleChildScrollView(
                        child: SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: orders.map((order) => _buildOrderCard(context, order)).toList(),
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentGold,
                      ),
                    ),
                    error: (error, stack) => Center(
                      child: SelectableText(
                        'Error fetching orders: $error',
                        style: GoogleFonts.outfit(color: AppColors.error),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    final cardWidth = isDesktop ? 360.0 : double.infinity;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Order ID: ${order.orderId}',
                  style: GoogleFonts.outfit(
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: order.orderStatus.toLowerCase() == 'pending'
                      ? Colors.orange.withValues(alpha: 0.2)
                      : Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: order.orderStatus.toLowerCase() == 'pending'
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
                child: Text(
                  order.orderStatus.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: order.orderStatus.toLowerCase() == 'pending'
                        ? Colors.orange
                        : Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)}',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Text(
            'Products:',
            style: GoogleFonts.outfit(color: AppColors.softGrey, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Column(
            children: order.products.take(3).map((product) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imageUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, trace) => Container(
                          width: 40,
                          height: 40,
                          color: AppColors.borderSoft,
                          child: const Icon(Icons.image_not_supported, size: 20, color: AppColors.softGrey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.productName,
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Qty: ${product.quantity}  •  ₹${product.unitPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.outfit(color: AppColors.softGrey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (order.products.length > 3)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                '+ ${order.products.length - 3} more items',
                style: GoogleFonts.outfit(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderSoft),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total:',
                    style: GoogleFonts.outfit(color: AppColors.softGrey, fontSize: 12),
                  ),
                  Text(
                    '₹${order.grandTotal.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _downloadInvoice(order),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(
                  'Invoice',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.borderSoft),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
