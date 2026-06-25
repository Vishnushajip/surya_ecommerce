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
  final Map<String, Future<Uint8List?>> _inFlight = {};
  Database? _db;

  String _hash(String url) => sha1.convert(utf8.encode(url)).toString();

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
      if (val == null) return null;
      // Handle multiple possible return types from IndexedDB.
      if (val is Uint8List) return val;
      if (val is List<int>) return Uint8List.fromList(val);
      if (val is List) return Uint8List.fromList(val.cast<int>());
      return null;
    } catch (e) {
      debugPrint('IndexedDB read failed: $e');
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
      _memoryCache.remove(_memoryCache.keys.first);
    }
    _memoryCache[url] = bytes;
  }

  Future<Uint8List?> getImage(String url) {
    if (_memoryCache.containsKey(url)) {
      return Future.value(_memoryCache[url]);
    }
    return _inFlight[url] ??= _load(
      url,
    ).whenComplete(() => _inFlight.remove(url));
  }

  Future<Uint8List?> _load(String url) async {
    final key = _hash(url);

    // 1. Persistent cache
    try {
      if (kIsWeb) {
        final cached = await _readWeb(key);
        if (cached != null && cached.isNotEmpty) {
          _putMemory(url, cached);
          return cached;
        }
      } else {
        final file = await _localFile(url);
        if (file != null && await file.exists()) {
          final bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) {
            _putMemory(url, bytes);
            return bytes;
          }
        }
      }
    } catch (e) {
      debugPrint('Cache read failed, falling back to network: $e');
    }

    // 2. Network
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
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
      debugPrint('Image fetch failed: ${res.statusCode} for $url');
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

  // Only pass a cache dimension when it's a sane, positive integer.
  int? _cacheDim(double? v) {
    if (v == null || !v.isFinite || v <= 0) return null;
    return v.round();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (imageUrl.isEmpty) {
      return errorWidget ?? const Icon(Icons.broken_image);
    }

    if (kIsWeb) {
      return Image.network(
        imageUrl,
        fit: fit,
        height: height,
        width: width,
        gaplessPlayback: true,
        cacheHeight: _cacheDim(height),
        cacheWidth: _cacheDim(width),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return placeholder ?? const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (_, _, _) =>
            errorWidget ?? const Icon(Icons.broken_image),
      );
    }

    final asyncImage = ref.watch(cachedImageProvider(imageUrl));

    return asyncImage.when(
      loading: () =>
          placeholder ?? const Center(child: CircularProgressIndicator()),
      error: (_, _) => errorWidget ?? const Icon(Icons.broken_image),
      data: (bytes) {
        if (bytes == null || bytes.isEmpty) {
          return errorWidget ?? const Icon(Icons.broken_image);
        }
        return Image.memory(
          bytes,
          fit: fit,
          height: height,
          width: width,
          gaplessPlayback: true,
          cacheHeight: _cacheDim(height),
          cacheWidth: _cacheDim(width),
          errorBuilder: (_, _, _) =>
              errorWidget ?? const Icon(Icons.broken_image),
        );
      },
    );
  }
}
