import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final List<Map<String, dynamic>> _products = [
    {'id': '1', 'name': 'عصير تفاح', 'price': 500.0, 'barcode': '123456789'},
    {'id': '2', 'name': 'بسكويت شوكولاتة', 'price': 250.0, 'barcode': '987654321'},
    {'id': '3', 'name': 'حليب طويل الأجل', 'price': 1200.0, 'barcode': '456123789'},
    {'id': '4', 'name': 'شامبو أطفال', 'price': 3500.0, 'barcode': '789123456'},
    {'id': '5', 'name': 'زيت طبخ 1.5 لتر', 'price': 4000.0, 'barcode': '321654987'},
  ];

  final Map<String, int> _cart = {};

  void _addToCart(String productId) {
    setState(() {
      _cart[productId] = (_cart[productId] ?? 0) + 1;
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      if (_cart[productId] != null && _cart[productId]! > 1) {
        _cart[productId] = _cart[productId]! - 1;
      } else {
        _cart.remove(productId);
      }
    });
  }

  double get _totalPrice {
    double total = 0;
    _cart.forEach((id, qty) {
      final product = _products.firstWhere((p) => p['id'] == id);
      total += (product['price'] as double) * qty;
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نقطة البيع (POS)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              // Simulated barcode scanner
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('سيتم تشغيل الكاميرا لقراءة الباركود')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              // Select customer
            },
          )
        ],
      ),
      body: Row(
        children: [
          // Products Grid
          Expanded(
            flex: 2,
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Could be responsive
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.1,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return InkWell(
                  onTap: () => _addToCart(product['id'] as String),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2, size: 40, color: ColorTokens.neutralInfo),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            product['name'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${product['price']} ريال',
                            style: const TextStyle(color: ColorTokens.positive, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Vertical Divider
          Container(width: 1, color: Colors.grey.shade300),

          // Cart Section
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  color: Colors.grey.shade100,
                  width: double.infinity,
                  child: const Text(
                    'الفاتورة الحالية',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: _cart.isEmpty
                      ? const Center(child: Text('السلة فارغة'))
                      : ListView.builder(
                          itemCount: _cart.length,
                          itemBuilder: (context, index) {
                            final String id = _cart.keys.elementAt(index);
                            final int qty = _cart[id]!;
                            final product = _products.firstWhere((p) => p['id'] == id);
                            final double lineTotal = (product['price'] as double) * qty;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                              title: Text(product['name'] as String, style: const TextStyle(fontSize: 14)),
                              subtitle: Text('${product['price']} × $qty = $lineTotal', style: const TextStyle(fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: ColorTokens.negative),
                                    onPressed: () => _removeFromCart(id),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: ColorTokens.positive),
                                    onPressed: () => _addToCart(id),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                // Checkout Panel
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text(
                            '$_totalPrice ريال',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: ColorTokens.positive),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _cart.isEmpty ? null : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم الدفع واصدار الفاتورة بنجاح!')),
                            );
                            setState(() {
                              _cart.clear();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorTokens.positive,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          ),
                          child: const Text('دفع (Cash)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
