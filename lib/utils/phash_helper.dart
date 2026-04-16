import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class PhashHelper {
  // Compute pHash for the image at [path]. Returns a 64-bit hash as int,
  // or null if the image cannot be decoded.
  static Future<int?> computePhash(String path) {
    return compute(_computePhashInIsolate, path);
  }

  // Number of differing bits between two 64-bit hashes.
  static int hammingDistance(int a, int b) {
    int xor = a ^ b;
    int count = 0;
    while (xor != 0) {
      count += xor & 1;
      xor = xor >>> 1; // unsigned right shift avoids infinite loop on negative values
    }
    return count;
  }

  // Similarity as a percentage (0.0 – 100.0).
  static double similarity(int a, int b) {
    return ((64 - hammingDistance(a, b)) / 64) * 100.0;
  }

  // Convert hash int to string for DB storage.
  static String hashToString(int hash) => hash.toString();

  // Parse a stored hash string back to int. Returns null on failure.
  static int? hashFromString(String s) => int.tryParse(s);
}

// Top-level function required by compute() — runs in a background isolate.
int? _computePhashInIsolate(String path) {
  try {
    final file = File(path);
    if (!file.existsSync()) return null;

    final bytes = file.readAsBytesSync();
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    // Step 1: resize to 32×32 using bilinear interpolation
    final resized = img.copyResize(
      decoded,
      width: 32,
      height: 32,
      interpolation: img.Interpolation.average,
    );

    // Step 2: build 32×32 grayscale matrix
    final matrix = List.generate(32, (y) => List.generate(32, (x) {
      final pixel = resized.getPixel(x, y);
      return 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
    }));

    // Step 3: apply 2D DCT (rows then columns)
    final dct = _dct2d(matrix, 32);

    // Step 4: extract top-left 8×8 = 64 low-frequency coefficients
    final coefficients = <double>[];
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        coefficients.add(dct[y][x]);
      }
    }

    // Step 5: compute median of the 63 AC coefficients (skip DC at [0,0])
    // ac always has 63 elements (odd), so median is the middle element at index 31
    final ac = coefficients.sublist(1)..sort();
    final median = ac[ac.length ~/ 2];

    // Step 6: build 64-bit hash — bit i set if coefficients[i+1] > median
    int hash = 0;
    for (int i = 0; i < 63; i++) {
      if (coefficients[i + 1] > median) {
        hash |= (1 << i);
      }
    }

    return hash;
  } catch (_) {
    return null;
  }
}

// Apply 2D DCT by transforming rows then columns.
List<List<double>> _dct2d(List<List<double>> matrix, int size) {
  // DCT each row
  final rowTransformed = List.generate(size, (y) => _dct1d(matrix[y], size));

  // DCT each column
  final result = List.generate(size, (_) => List<double>.filled(size, 0.0));
  for (int x = 0; x < size; x++) {
    final col = List.generate(size, (y) => rowTransformed[y][x]);
    final colDct = _dct1d(col, size);
    for (int y = 0; y < size; y++) {
      result[y][x] = colDct[y];
    }
  }
  return result;
}

// 1D DCT-II.
List<double> _dct1d(List<double> values, int n) {
  final result = List<double>.filled(n, 0.0);
  for (int k = 0; k < n; k++) {
    double sum = 0.0;
    for (int i = 0; i < n; i++) {
      sum += values[i] * cos(pi * k * (2 * i + 1) / (2 * n));
    }
    result[k] = sum;
  }
  return result;
}
