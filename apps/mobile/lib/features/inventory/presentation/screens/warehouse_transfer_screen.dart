import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/color_tokens.dart';

class WarehouseTransferScreen extends StatefulWidget {
  final String? initialFromWarehouseId;
  const WarehouseTransferScreen({super.key, this.initialFromWarehouseId});

  @override
  State<WarehouseTransferScreen> createState() => _WarehouseTransferScreenState();
}

class _WarehouseTransferScreenState extends State<WarehouseTransferScreen> {
  String? _fromWarehouseId;
  String? _toWarehouseId;
  String? _selectedProductId;
  final TextEditingController _qtyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fromWarehouseId = widget.initialFromWarehouseId;
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _processTransfer() {
    if (_fromWarehouseId == null || _toWarehouseId == null || _selectedProductId == null || _qtyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تعبئة جميع الحقول')),
      );
      return;
    }
    
    if (_fromWarehouseId == _toWarehouseId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن التحويل لنفس المخزن')),
      );
      return;
    }

    // Process logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تحويل البضاعة بنجاح!'),
        backgroundColor: ColorTokens.positive,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحويل بضاعة بين الفروع'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('من مخزن:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _fromWarehouseId,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: '1', child: Text('المخزن الرئيسي')),
                DropdownMenuItem(value: '2', child: Text('فرع عدن')),
                DropdownMenuItem(value: '3', child: Text('مستودع الأدوية')),
              ],
              onChanged: (val) => setState(() => _fromWarehouseId = val),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            const Text('إلى مخزن:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _toWarehouseId,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: '1', child: Text('المخزن الرئيسي')),
                DropdownMenuItem(value: '2', child: Text('فرع عدن')),
                DropdownMenuItem(value: '3', child: Text('مستودع الأدوية')),
              ],
              onChanged: (val) => setState(() => _toWarehouseId = val),
            ),

            const SizedBox(height: AppSpacing.xl),
            
            const Text('الصنف المراد تحويله:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _selectedProductId,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'p1', child: Text('عصير تفاح - متوفر 150')),
                DropdownMenuItem(value: 'p2', child: Text('زيت طبخ - متوفر 80')),
              ],
              onChanged: (val) => setState(() => _selectedProductId = val),
            ),

            const SizedBox(height: AppSpacing.xl),

            const Text('الكمية:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'أدخل الكمية',
                suffixText: 'حبة/كرتون',
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _processTransfer,
                icon: const Icon(Icons.check),
                label: const Text('اعتماد التحويل', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorTokens.neutralInfo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
