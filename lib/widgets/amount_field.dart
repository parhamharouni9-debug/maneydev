import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/persian_numbers.dart';

/// A text field for entering money amounts.
/// - Accepts Persian, Arabic-Indic, or ASCII digits (normalizes as you type,
///   fixing the classic mobile-keyboard "می‌زنم فارسی ولی چیزی ثبت نمی‌شه" bug).
/// - Live-formats with thousands separators in Persian digits.
/// - Reports the parsed integer value and its Persian-words form upward.
class AmountField extends StatefulWidget {
  final String label;
  final int? initialValue;
  final ValueChanged<int?> onChanged;

  /// When true, a leading '-' is accepted and the field is treated as a
  /// signed adjustment (e.g. "add or subtract from last month's balance")
  /// rather than a plain always-positive amount.
  final bool allowNegative;

  const AmountField({
    super.key,
    required this.label,
    this.initialValue,
    required this.onChanged,
    this.allowNegative = false,
  });

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  late final TextEditingController _controller;
  String _words = '';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    _controller = TextEditingController(
      text: initial != null ? PersianNumbers.formatAmount(initial) : '',
    );
    _updateWords(initial);
  }

  void _updateWords(int? value) {
    if (value == null || value == 0) {
      _words = '';
      return;
    }
    final abs = value.abs();
    final suffix =
        widget.allowNegative ? (value < 0 ? ' کم میشه' : ' اضافه میشه') : '';
    _words = '${PersianNumbers.toWordsToman(abs)}$suffix';
  }

  void _onChanged(String raw) {
    final parsed = widget.allowNegative
        ? PersianNumbers.parseSignedAmount(raw)
        : PersianNumbers.parseAmount(raw);
    final formatted = parsed != null ? PersianNumbers.formatAmount(parsed) : '';
    _controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    setState(() => _updateWords(parsed));
    widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
          inputFormatters: [
            // Allow Persian/Arabic-Indic/ASCII digits and separators through
            // (and a leading minus when allowNegative); real normalization
            // happens in _onChanged.
            FilteringTextInputFormatter.allow(
              widget.allowNegative
                  ? RegExp(r'[0-9۰-۹٠-٩,٬\s\-−]')
                  : RegExp(r'[0-9۰-۹٠-٩,٬\s]'),
            ),
          ],
          decoration: InputDecoration(
            labelText: widget.label,
            suffixText: 'تومان',
          ),
          onChanged: _onChanged,
        ),
        if (_words.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 4),
            child: Text(
              _words,
              style: TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
