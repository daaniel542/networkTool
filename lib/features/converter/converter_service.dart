import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';

/// Supported converter operations per PRD section 10.3.
enum ConverterOperation {
  base64Encode,
  base64Decode,
  hexEncode,
  hexDecode,
  md5,
  sha1,
  sha256,
}

/// Thrown when [ConverterService.execute] encounters invalid input.
class ConverterServiceException implements Exception {
  const ConverterServiceException(this.message);
  final String message;
  @override
  String toString() => 'ConverterServiceException: $message';
}

/// Handles Base64 (encode/decode), Hex (encode/decode), MD5, SHA-1, SHA-256.
///
/// All decoding operations are wrapped in try/catch so malformed input produces
/// user-friendly [ConverterServiceException]s rather than runtime crashes
/// (PRD §10.3).
class ConverterService {
  /// Execute [operation] against [input] and return the result string.
  ///
  /// Throws [ConverterServiceException] on invalid input.
  String execute({
    required String input,
    required ConverterOperation operation,
  }) {
    try {
      return switch (operation) {
        ConverterOperation.base64Encode => base64.encode(utf8.encode(input)),
        ConverterOperation.base64Decode => _decodeBase64(input),
        ConverterOperation.hexEncode => hex.encode(utf8.encode(input)),
        ConverterOperation.hexDecode => _decodeHex(input),
        ConverterOperation.md5 => md5Hash.convert(utf8.encode(input)).toString(),
        ConverterOperation.sha1 => sha1Hash.convert(utf8.encode(input)).toString(),
        ConverterOperation.sha256 => sha256Hash.convert(utf8.encode(input)).toString(),
      };
    } on ConverterServiceException {
      rethrow;
    } catch (e) {
      throw ConverterServiceException('Unexpected error: $e');
    }
  }

  String _decodeBase64(String input) {
    try {
      return utf8.decode(base64.decode(input.trim()));
    } catch (_) {
      throw const ConverterServiceException('Invalid Base64 input.');
    }
  }

  String _decodeHex(String input) {
    try {
      return utf8.decode(hex.decode(input.trim().replaceAll(' ', '')));
    } catch (_) {
      throw const ConverterServiceException('Invalid hex input.');
    }
  }

  // Aliases to avoid name clashes with the enum values.
  static const md5Hash = md5;
  static const sha1Hash = sha1;
  static const sha256Hash = sha256;
}
