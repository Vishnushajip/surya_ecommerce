import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, Uint8List> _memoryCache = {};

  String _hash(String url) => sha1.convert(utf8.encode(url)).toString();

  Future<File?> _localFile(String url) async {
    if (kIsWeb) return null;
    try {
      final dir = await getTemporaryDirectory();
      return File('${dir.path}/${_hash(url)}.img');
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List?> getImage(String url) async {
    if (_memoryCache.containsKey(url)) return _memoryCache[url];

    if (!kIsWeb) {
      final file = await _localFile(url);
      if (file != null && await file.exists()) {
        final bytes = await file.readAsBytes();
        _memoryCache[url] = bytes;
        return bytes;
      }
    }

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final bytes = res.bodyBytes;
        if (!kIsWeb) {
          final file = await _localFile(url);
          if (file != null) {
            await file.writeAsBytes(bytes, flush: true);
          }
        }
        _memoryCache[url] = bytes;
        return bytes;
      }
    } catch (e) {
      debugPrint("Error loading image: $e");
    }
    return null;
  }
}

final cachedImageProvider = FutureProvider.family<Uint8List?, String>((
  ref,
  url,
) async {
  return await CacheService().getImage(url);
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
      error: (_, __) => errorWidget ?? const Icon(Icons.broken_image),
      data: (bytes) {
        if (bytes != null) {
          return Image.memory(
            bytes, 
            fit: fit, 
            height: height, 
            width: width,
            gaplessPlayback: true,
          );
        }
        return errorWidget ?? const Icon(Icons.broken_image);
      },
    );
  }
}
