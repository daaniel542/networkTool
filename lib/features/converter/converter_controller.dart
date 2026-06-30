import 'package:flutter/foundation.dart';
import 'converter_service.dart';

/// Controller for the Encoding / Hashing Converter screen.
///
/// Holds the raw input text, the selected operation, and the result string.
/// Enforces the 50,000-character input cap (PRD §10.3). All computation is
/// delegated to [ConverterService].
class ConverterController extends ChangeNotifier {
  ConverterController({required ConverterService service}) : _service = service;

  final ConverterService _service;

  /// Maximum allowed input length before truncation (PRD §10.3).
  static const int maxInputLength = 50000;

  // -------------------------------------------------------------------------
  // Input state
  // -------------------------------------------------------------------------

  /// The text payload entered by the user.
  String inputText = '';

  /// Currently selected operation.
  ConverterOperation operation = ConverterOperation.base64Encode;

  // -------------------------------------------------------------------------
  // Output state
  // -------------------------------------------------------------------------

  /// Result of the last convert / hash operation.
  String outputText = '';

  /// Error message if the last operation failed.
  String? error;

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  /// Execute the selected operation against [inputText].
  void convert() {
    error = null;
    outputText = '';

    try {
      outputText = _service.execute(
        input: inputText,
        operation: operation,
      );
    } on ConverterServiceException catch (e) {
      error = e.message;
    }

    notifyListeners();
  }

  /// Update [inputText], enforcing the [maxInputLength] cap.
  void setInput(String value) {
    inputText =
        value.length > maxInputLength ? value.substring(0, maxInputLength) : value;
    notifyListeners();
  }

  /// Update [operation] and notify listeners.
  void setOperation(ConverterOperation op) {
    operation = op;
    notifyListeners();
  }
}
