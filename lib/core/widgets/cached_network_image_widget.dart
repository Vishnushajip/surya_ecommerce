import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:idb_shim/idb_browser.dart';
import 'package:path_provider/path_provider.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const _dbName = 'image_cache';
  static const _storeName = 'images';
  static const _maxMemoryEntries = 100;

  final Map<String, Uint8List> _memoryCache = {};
  // Dedupe concurrent requests for the same URL.
  final Map<String, Future<Uint8List?>> _inFlight = {};
  Database? _db;

  String _hash(String url) => sha1.convert(utf8.encode(url)).toString();

  // ---- Web (IndexedDB) ----
  Future<Database?> _openDb() async {
    if (_db != null) return _db;
    try {
      final factory = getIdbFactory();
      if (factory == null) return null;
      _db = await factory.open(
        _dbName,
        version: 1,
        onUpgradeNeeded: (e) {
          final db = e.database;
          if (!db.objectStoreNames.contains(_storeName)) {
            db.createObjectStore(_storeName);
          }
        },
      );
      return _db;
    } catch (e) {
      debugPrint('IndexedDB open failed: $e');
      return null;
    }
  }

  Future<Uint8List?> _readWeb(String key) async {
    final db = await _openDb();
    if (db == null) return null;
    try {
      final txn = db.transaction(_storeName, idbModeReadOnly);
      final store = txn.objectStore(_storeName);
      final val = await store.getObject(key);
      await txn.completed;
      if (val is List<int>) return Uint8List.fromList(val);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeWeb(String key, Uint8List bytes) async {
    final db = await _openDb();
    if (db == null) return;
    try {
      final txn = db.transaction(_storeName, idbModeReadWrite);
      final store = txn.objectStore(_storeName);
      await store.put(bytes, key);
      await txn.completed;
    } catch (e) {
      debugPrint('IndexedDB write failed: $e');
    }
  }

  // ---- Mobile/Desktop (filesystem) ----
  Future<File?> _localFile(String url) async {
    if (kIsWeb) return null;
    try {
      final dir = await getTemporaryDirectory();
      return File('${dir.path}/${_hash(url)}.img');
    } catch (_) {
      return null;
    }
  }

  void _putMemory(String url, Uint8List bytes) {
    if (_memoryCache.length >= _maxMemoryEntries) {
      _memoryCache.remove(_memoryCache.keys.first); // simple FIFO eviction
    }
    _memoryCache[url] = bytes;
  }

  Future<Uint8List?> getImage(String url) {
    if (_memoryCache.containsKey(url)) {
      return Future.value(_memoryCache[url]);
    }
    // Reuse in-flight request so the same image isn't fetched twice.
    return _inFlight[url] ??= _load(url).whenComplete(() => _inFlight.remove(url));
  }

  Future<Uint8List?> _load(String url) async {
    final key = _hash(url);

    // 1. Persistent cache
    if (kIsWeb) {
      final cached = await _readWeb(key);
      if (cached != null) {
        _putMemory(url, cached);
        return cached;
      }
    } else {
      final file = await _localFile(url);
      if (file != null && await file.exists()) {
        final bytes = await file.readAsBytes();
        _putMemory(url, bytes);
        return bytes;
      }
    }

    // 2. Network
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final bytes = res.bodyBytes;
        _putMemory(url, bytes);
        if (kIsWeb) {
          unawaited(_writeWeb(key, bytes));
        } else {
          final file = await _localFile(url);
          if (file != null) {
            unawaited(file.writeAsBytes(bytes, flush: true));
          }
        }
        return bytes;
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
    }
    return null;
  }
}

final cachedImageProvider = FutureProvider.family<Uint8List?, String>((
  ref,
  url,
) async {
  // Keep decoded image in provider cache instead of disposing immediately.
  ref.keepAlive();
  return CacheService().getImage(url);
});

class CachedNetworkImageWidget extends ConsumerWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BoxFit fit;

  const CachedNetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.placeholder,
    this.errorWidget,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (imageUrl.isEmpty) {
      return errorWidget ?? const Icon(Icons.broken_image);
    }

    final asyncImage = ref.watch(cachedImageProvider(imageUrl));

    return asyncImage.when(
      loading: () =>
          placeholder ?? const Center(child: CircularProgressIndicator()),
      error: (_, _) => errorWidget ?? const Icon(Icons.broken_image),
      data: (bytes) {
        if (bytes == null) {
          return errorWidget ?? const Icon(Icons.broken_image);
        }
        return Image.memory(
          bytes,
          fit: fit,
          height: height,
          width: width,
          gaplessPlayback: true,
          // Cache decoded bitmap at display resolution -> less memory, faster paint.
          cacheHeight: height?.isFinite == true ? height!.round() : null,
          cacheWidth: width?.isFinite == true ? width!.round() : null,
        );
      },
    );
  }
}