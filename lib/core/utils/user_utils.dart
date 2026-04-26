import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

class UserUtils {
  static Timer? _heartbeatTimer;
  static SharedPreferences? _prefs;

  static Future<void> checkAndPromptUser(BuildContext context) async {
    _prefs ??= await SharedPreferences.getInstance();
    final name = _prefs!.getString('user_name');
    final phone = _prefs!.getString('user_phone');

    if (name == null || name.isEmpty || phone == null || phone.isEmpty) {
      if (context.mounted) {
        _showNameDialog(context);
      }
    } else {
      _updateTrafficAndStats();
      startLiveHeartbeat();
    }
  }

  static Future<void> _updateTrafficAndStats() async {
    _prefs ??= await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final monthKey = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    final lastTraffic = _prefs!.getInt('last_traffic_time') ?? 0;
    final lastDate = _prefs!.getString('last_counted_date') ?? "";

    final batch = FirebaseFirestore.instance.batch();
    bool needsCommit = false;

    if (now.millisecondsSinceEpoch - lastTraffic > 600000) {
      final dailyRef = FirebaseFirestore.instance
          .collection('stats')
          .doc('daily_$dateKey');
      batch.set(dailyRef, {
        'traffic': FieldValue.increment(1),
      }, SetOptions(merge: true));
      final monthlyRef = FirebaseFirestore.instance
          .collection('stats')
          .doc('monthly_$monthKey');
      batch.set(monthlyRef, {
        'traffic': FieldValue.increment(1),
      }, SetOptions(merge: true));

      await _prefs!.setInt('last_traffic_time', now.millisecondsSinceEpoch);
      needsCommit = true;
    }

    if (lastDate != dateKey) {
      final dailyRef = FirebaseFirestore.instance
          .collection('stats')
          .doc('daily_$dateKey');
      batch.set(dailyRef, {
        'users': FieldValue.increment(1),
      }, SetOptions(merge: true));
      final monthlyRef = FirebaseFirestore.instance
          .collection('stats')
          .doc('monthly_$monthKey');
      batch.set(monthlyRef, {
        'users': FieldValue.increment(1),
      }, SetOptions(merge: true));

      await _prefs!.setString('last_counted_date', dateKey);
      needsCommit = true;
    }

    if (needsCommit) await batch.commit();
  }

  static void _showNameDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSoft),
        ),
        title: Text(
          'WELCOME TO SUN ASSOCIATES',
          style: GoogleFonts.outfit(
            color: AppColors.accentGold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please enter your details to personalize your experience.',
                style: GoogleFonts.outfit(
                  color: AppColors.softGrey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: nameController,
                style: GoogleFonts.outfit(color: Colors.white),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
                    return 'Please enter letters only';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  hintStyle: GoogleFonts.outfit(
                    color: AppColors.softGrey.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: AppColors.primaryDark.withOpacity(0.3),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.borderSoft.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.borderSoft.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accentGold),
                  ),
                  errorStyle: GoogleFonts.outfit(
                    color: Colors.redAccent,
                    fontSize: 12,
                  ),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: AppColors.accentGold,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                style: GoogleFonts.outfit(color: Colors.white),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter phone number';
                  }
                  final phoneDigits = value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (phoneDigits.length != 10) {
                    return 'Please enter a 10-digit phone number';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Enter 10-digit phone number',
                  hintStyle: GoogleFonts.outfit(
                    color: AppColors.softGrey.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: AppColors.primaryDark.withOpacity(0.3),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.borderSoft.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.borderSoft.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accentGold),
                  ),
                  errorStyle: GoogleFonts.outfit(
                    color: Colors.redAccent,
                    fontSize: 12,
                  ),
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.accentGold,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Center(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();

                    final prefs = await SharedPreferences.getInstance();
                    final id = Random().nextInt(900000) + 100000;

                    await prefs.setString('user_name', name);
                    await prefs.setString('user_phone', phone);
                    await prefs.setInt('user_id', id);

                    await _registerNewUser(name, phone, id);

                    if (context.mounted) {
                      Navigator.pop(context);
                      startLiveHeartbeat();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Welcome, $name!',
                            style: GoogleFonts.outfit(),
                          ),
                          backgroundColor: AppColors.accentGold,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'GET STARTED',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _registerNewUser(
    String name,
    String phone,
    int id,
  ) async {
    final now = DateTime.now();
    final dateKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final monthKey = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_traffic_time', now.millisecondsSinceEpoch);
    await prefs.setString('last_counted_date', dateKey);

    final batch = FirebaseFirestore.instance.batch();

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(id.toString());
    batch.set(userRef, {
      'id': id,
      'name': name,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final dailyRef = FirebaseFirestore.instance
        .collection('stats')
        .doc('daily_$dateKey');
    batch.set(dailyRef, {
      'users': FieldValue.increment(1),
      'traffic': FieldValue.increment(1),
    }, SetOptions(merge: true));

    final monthlyRef = FirebaseFirestore.instance
        .collection('stats')
        .doc('monthly_$monthKey');
    batch.set(monthlyRef, {
      'users': FieldValue.increment(1),
      'traffic': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  static void startLiveHeartbeat() {
    _heartbeatTimer?.cancel();
    _updateLiveStatus();

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateLiveStatus();
    });
  }

  static Future<void> _updateLiveStatus() async {
    try {
      final name = _prefs?.getString('user_name');
      final phone = _prefs?.getString('user_phone');
      final id = _prefs?.getInt('user_id');

      if (name != null && id != null) {
        FirebaseFirestore.instance
            .collection('live_users')
            .doc(id.toString())
            .set({
              'id': id,
              'name': name,
              'phone': phone,
              'lastSeen': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    } catch (e) {}
  }

  static void stopLiveHeartbeat() {
    _heartbeatTimer?.cancel();
  }
}
