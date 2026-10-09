import 'package:flutter/material.dart';
import '../widgets/simple_summary_card.dart';

class OptimisticSubmissionWrapper extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onSave;
  final String successTitle;
  final String successAmountText;
  final bool isPositive;

  const OptimisticSubmissionWrapper({
    super.key,
    required this.child,
    required this.onSave,
    required this.successTitle,
    required this.successAmountText,
    required this.isPositive,
  });

  @override
  State<OptimisticSubmissionWrapper> createState() => _OptimisticSubmissionWrapperState();
}

class _OptimisticSubmissionWrapperState extends State<OptimisticSubmissionWrapper> {
  bool _isSubmitted = false;

  void _handleSubmit() {
    setState(() {
      _isSubmitted = true;
    });
    
    // Optimistically assuming success instantly
    widget.onSave().catchError((error) {
      // Revert if it actually fails (though in local-first, SQLite saves are near-instant)
      if (mounted) {
        setState(() {
          _isSubmitted = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الحفظ: $error')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text(
                'تم الحفظ محلياً بنجاح',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              SimpleSummaryCard(
                title: widget.successTitle,
                amountText: widget.successAmountText,
                isPositive: widget.isPositive,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSubmitted = false;
                  });
                },
                child: const Text('إجراء عملية جديدة'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(child: widget.child),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('حفظ'),
            ),
          ),
        ),
      ],
    );
  }
}
