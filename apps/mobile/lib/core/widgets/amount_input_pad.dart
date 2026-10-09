import 'package:flutter/material.dart';
import '../theme/color_tokens.dart';
import '../theme/app_spacing.dart';
import 'package:intl/intl.dart';

class AmountInputPad extends StatefulWidget {
  final double initialAmount;
  final ValueChanged<double> onChanged;
  final String currencySymbol;

  const AmountInputPad({
    super.key,
    this.initialAmount = 0.0,
    required this.onChanged,
    this.currencySymbol = 'ر.ي',
  });

  @override
  State<AmountInputPad> createState() => _AmountInputPadState();
}

class _AmountInputPadState extends State<AmountInputPad> {
  String _inputString = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount > 0) {
      // Convert initial amount to string avoiding scientific notation
      _inputString = widget.initialAmount.toStringAsFixed(2);
      if (_inputString.endsWith('.00')) {
        _inputString = _inputString.substring(0, _inputString.length - 3);
      }
    }
  }

  void _onKeyPressed(String key) {
    setState(() {
      if (key == 'C') {
        _inputString = '';
      } else if (key == 'DEL') {
        if (_inputString.isNotEmpty) {
          _inputString = _inputString.substring(0, _inputString.length - 1);
        }
      } else if (key == '.') {
        if (!_inputString.contains('.')) {
          _inputString = _inputString.isEmpty ? '0.' : '$_inputString.';
        }
      } else {
        if (_inputString == '0') {
          _inputString = key;
        } else {
          _inputString += key;
        }
      }
    });

    final double amount = double.tryParse(_inputString) ?? 0.0;
    widget.onChanged(amount);
  }

  String get _formattedAmount {
    if (_inputString.isEmpty) return '0';
    final parts = _inputString.split('.');
    final number = int.tryParse(parts[0]) ?? 0;
    final formatter = NumberFormat('#,##0', 'en_US');
    String result = formatter.format(number);
    if (parts.length > 1) {
      result += '.${parts[1]}';
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Display Area
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg, horizontal: AppSpacing.xl),
          decoration: BoxDecoration(
            color: ColorTokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.currencySymbol,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              Expanded(
                child: Text(
                  _formattedAmount,
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Keypad Area
        LayoutBuilder(builder: (context, constraints) {
          final buttonWidth = (constraints.maxWidth - (AppSpacing.md * 2)) / 3;
          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (var i = 1; i <= 9; i++) _buildKey(i.toString(), buttonWidth),
              _buildKey('.', buttonWidth),
              _buildKey('0', buttonWidth),
              _buildKey('DEL', buttonWidth, icon: Icons.backspace_outlined),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildKey(String label, double width, {IconData? icon}) {
    return SizedBox(
      width: width,
      height: 56, // Accessible touch target > 48dp
      child: Material(
        color: ColorTokens.surface,
        borderRadius: BorderRadius.circular(8),
        elevation: 1,
        child: InkWell(
          onTap: () => _onKeyPressed(label),
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: icon != null
                ? Icon(icon, size: 24, color: Colors.black87)
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
