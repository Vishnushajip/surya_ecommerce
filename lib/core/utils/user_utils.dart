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

    if (name == null || name.isEmpty) {
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please enter your name to personalize your experience.',
              style: GoogleFonts.outfit(
                color: AppColors.softGrey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              style: GoogleFonts.outfit(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: GoogleFonts.outfit(
                  color: AppColors.softGrey.withOpacity(0.5),
                ),
                border: InputBorder.none,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    final prefs = await SharedPreferences.getInstance();
                    final id = Random().nextInt(900000) + 100000;

                    await prefs.setString('user_name', name);
                    await prefs.setInt('user_id', id);

                    await _registerNewUser(name, id);

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

  static Future<void> _registerNewUser(String name, int id) async {
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
      final id = _prefs?.getInt('user_id');

      if (name != null && id != null) {
        FirebaseFirestore.instance
            .collection('live_users')
            .doc(id.toString())
            .set({
              'id': id,
              'name': name,
              'lastSeen': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    } catch (e) {}
  }

  static void stopLiveHeartbeat() {
    _heartbeatTimer?.cancel();
  }
}
