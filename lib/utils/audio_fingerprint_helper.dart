import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class _ComparisonRequest {
  final List<int> newFingerprint;
  final List<Map<String, dynamic>> existing; // [{id: int, fingerprint: List<int>}]
  final double threshold;

  _ComparisonRequest({
    required this.newFingerprint,
    required this.existing,
    required this.threshold,
  });
}

// Top-level function required by compute() — runs fpcalc in a background isolate.
Future<({List<int> fingerprint, bool tooShort})> _runFpcalcInIsolate(String filePath) async {
  try {
    final result = await Process.run('fpcalc', ['-json', '-raw', filePath]);
    if (result.exitCode != 0) {
      final stderr = result.stderr as String;
      final tooShort = stderr.contains('Empty fingerprint');
      debugPrint("fpcalc failed (exit ${result.exitCode}) on $filePath: $stderr");
      return (fingerprint: <int>[], tooShort: tooShort);
    }
    final json = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    final raw = json['fingerprint'] as List?;
    if (raw == null || raw.isEmpty) return (fingerprint: <int>[], tooShort: false);
    return (fingerprint: raw.cast<int>(), tooShort: false);
  } catch (e) {
    debugPrint("fpcalc exception on $filePath: $e");
    return (fingerprint: <int>[], tooShort: false);
  }
}

// Top-level function required by compute() — runs sliding window comparison in a background isolate.
List<Map<String, dynamic>> _runComparisonInIsolate(_ComparisonRequest req) {
  final results = <Map<String, dynamic>>[];
  for (final entry in req.existing) {
    final existing = (entry['fingerprint'] as List).cast<int>();
    final sim = _slidingWindowSimilarity(req.newFingerprint, existing);
    if (sim >= req.threshold) {
      results.add({'id': entry['id'], 'similarity': sim});
    }
  }
  return results;
}

// Always searches shorter inside longer. Returns best similarity found (0.0–100.0).
double _slidingWindowSimilarity(List<int> a, List<int> b) {
  if (a.isEmpty || b.isEmpty) return 0.0;
  final shorter = a.length <= b.length ? a : b;
  final longer  = a.length <= b.length ? b : a;
  double best = 0.0;
  for (int offset = 0; offset <= longer.length - shorter.length; offset++) {
    double bits = 0.0;
    for (int i = 0; i < shorter.length; i++) {
      bits += _hammingDistance32(shorter[i], longer[offset + i]);
    }
    final sim = (1.0 - (bits / shorter.length) / 32.0) * 100.0;
    if (sim > best) best = sim;
  }
  return best;
}

// 32-bit Hamming distance. Mask to 32 bits before counting — Chromaprint integers
// are signed 32-bit but Dart's int is 64-bit, so the XOR result needs masking.
// Uses >>> (unsigned right shift) to avoid infinite loop on negative values.
int _hammingDistance32(int a, int b) {
  int xor = (a ^ b) & 0xFFFFFFFF;
  int count = 0;
  while (xor != 0) {
    count += xor & 1;
    xor = xor >>> 1;
  }
  return count;
}

class AudioFingerprintHelper {
  AudioFingerprintHelper._();

  static Future<({List<int> fingerprint, bool tooShort})> computeFingerprint(String filePath) =>
      compute(_runFpcalcInIsolate, filePath);

  static Future<List<Map<String, dynamic>>> compareAll(
    List<int> newFingerprint,
    List<Map<String, dynamic>> existing,
    double threshold,
  ) =>
      compute(
        _runComparisonInIsolate,
        _ComparisonRequest(
          newFingerprint: newFingerprint,
          existing: existing,
          threshold: threshold,
        ),
      );

  static String fingerprintToString(List<int> fingerprint) =>
      fingerprint.join(',');

  static List<int>? fingerprintFromString(String s) {
    final parts = s.split(',');
    final result = <int>[];
    for (final part in parts) {
      final v = int.tryParse(part);
      if (v == null) return null;
      result.add(v);
    }
    return result.isEmpty ? null : result;
  }
}
