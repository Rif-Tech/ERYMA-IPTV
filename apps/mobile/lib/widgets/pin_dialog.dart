import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';

/// Asks for a PIN; resolves true when [expected] matches (or returns the entered value if [expected] is null).
Future<String?> showPinDialog(BuildContext context, {String? title, String? expected, bool confirm = false}) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();
  final confirmController = TextEditingController();
  String? error;

  return showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title ?? l10n.enterPin),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
              decoration: InputDecoration(labelText: l10n.pinCode, errorText: error),
              onSubmitted: (_) => confirm ? null : _submit(context, controller, confirmController, expected, confirm, l10n, (e) => setState(() => error = e)),
            ),
            if (confirm) ...[
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                decoration: InputDecoration(labelText: l10n.confirmPin),
                onSubmitted: (_) => _submit(context, controller, confirmController, expected, confirm, l10n, (e) => setState(() => error = e)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => _submit(context, controller, confirmController, expected, confirm, l10n, (e) => setState(() => error = e)),
            child: Text(l10n.ok),
          ),
        ],
      ),
    ),
  );
}

void _submit(
  BuildContext context,
  TextEditingController pin,
  TextEditingController confirmPin,
  String? expected,
  bool confirm,
  AppLocalizations l10n,
  void Function(String?) setError,
) {
  final value = pin.text.trim();
  if (value.isEmpty) {
    setError(l10n.fieldRequired);
    return;
  }
  if (confirm && value != confirmPin.text.trim()) {
    setError(l10n.pinMismatch);
    return;
  }
  if (expected != null && value != expected) {
    setError(l10n.pinIncorrect);
    return;
  }
  Navigator.pop(context, value);
}

/// Verifies the parental PIN (if set) before running [action].
Future<bool> requirePin(BuildContext context, String? expected, {String? title}) async {
  if (expected == null || expected.isEmpty) return true;
  final result = await showPinDialog(context, expected: expected, title: title);
  return result != null;
}
