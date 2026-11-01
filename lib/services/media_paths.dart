import 'dart:io';
import 'package:flutter/material.dart';

const kDefaultAvatarUrl =
    'https://www.pngitem.com/pimgs/m/150-1503945_transparent-user-png-default-user-image-png-png.png';

/// Local file path, http(s) URL, or empty → default avatar.
ImageProvider mediaImageProvider(String? path) {
  if (path == null || path.isEmpty) {
    return const NetworkImage(kDefaultAvatarUrl);
  }
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  }
  final file = File(path);
  if (file.existsSync()) {
    return FileImage(file);
  }
  return const NetworkImage(kDefaultAvatarUrl);
}

Widget mediaImage({
  required String? path,
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
}) {
  return Image(
    image: mediaImageProvider(path),
    fit: fit,
    width: width,
    height: height,
    errorBuilder: (_, __, ___) => Icon(
      Icons.person,
      size: width ?? 40,
      color: Colors.white54,
    ),
  );
}
