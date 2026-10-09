import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';
import 'pdf_invoice_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: WholesaleBillingApp(),
  ));
}

class WholesaleBillingApp extends StatefulWidget {
  const WholesaleBillingApp({super.key});

  @override
  State<WholesaleBillingApp> createState() => _WholesaleBillingAppState();
}

class _WholesaleBillingAppState extends State<WholesaleBillingApp> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0 ? const BillingScreen() : const HistoryScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Billing'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _customerController = TextEditingController();
  String _paymentMode = 'Cash';

  final List<Map<String, dynamic>> _catalog = [
    {'name': 'Mango Crate (12x1L)', 'price': 850.0},
    {'name': 'Orange Can (5L)', 'price': 600.0},
    {'name': 'Pineapple (24x200ml)', 'price': 520.0},
    {'name': 'Apple Crate (10x1L)', 'price': 780.0},
  ];

  final List<Map<String, dynamic>> _cart = [];

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final index = _cart.indexWhere((item) => item['name'] == product['name']);
      if (index >= 0) {
        _cart[index]['qty']++;
      } else {
        _cart.add({
          'name': product['name'],
          'price': product['price'],
          'qty': 1,
        });
      }
    });
  }

  double get _total => _cart.fold(0, (sum, i) => sum + (i['price'] * i['qty']));

  Future<void> _saveAndShare() async {
    final customer = _customerController.text.trim();
    if (customer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Customer / Shop Name')),
      );
      return;
    }
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item')),
      );
      return;
    }

    final now = DateTime.now().toIso8601String();
    final billId = await DBHelper.instance.insertBill(
      customerName: customer,
      total: _total,
      paymentMode: _paymentMode,
      items: _cart,
    );

    await PdfInvoiceService.generateAndShareInvoice(
      billId: billId,
      customerName: customer,
      dateTime: now,
      paymentMode: _paymentMode,
      totalAmount: _total,
      items: _cart,
    );

    if (mounted) {
      setState(() {
        _cart.clear();
        _customerController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wholesale Juice POS')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: _customerController,
                  decoration: const InputDecoration(
                    labelText: 'Customer / Shop Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _paymentMode,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'UPI', child: Text('UPI / Online')),
                    DropdownMenuItem(value: 'Credit', child: Text('Credit (Udhar)')),
                  ],
                  onChanged: (val) => setState(() => _paymentMode = val!),
                ),
              ],
            ),
          ),
          const Text('Tap items to add:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _catalog.length,
              itemBuilder: (context, idx) {
                final item = _catalog[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ActionChip(
                    label: Text('${item['name']}\nRs. ${item['price']}'),
                    onPressed: () => _addToCart(item),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Expanded(
            child: _cart.isEmpty
                ? const Center(child: Text('Cart is empty'))
                : ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (context, idx) {
                      final item = _cart[idx];
                      return ListTile(
                        title: Text(item['name']),
                        subtitle: Text('Rs. ${item['price']} x ${item['qty']}'),
                        trailing: Text('Rs. ${(item['price'] * item['qty']).toStringAsFixed(2)}'),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: Rs. ${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  onPressed: _saveAndShare,
                  label: const Text('Save & WhatsApp'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _billsFuture;

  @override
  void initState() {
    super.initState();
    _billsFuture = DBHelper.instance.fetchBills();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Billing History')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _billsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final bills = snapshot.data!;
          if (bills.isEmpty) return const Center(child: Text('No previous bills found.'));

          return ListView.separated(
            itemCount: bills.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, idx) {
              final b = bills[idx];
              final date = DateTime.parse(b['date_time']);
              final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);

              return ListTile(
                leading: CircleAvatar(child: Text('#${b['id']}')),
                title: Text(b['customer_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$formattedDate\nPayment: ${b['payment_mode']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Rs. ${b['total_amount']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.blue),
                      onPressed: () async {
                        final items = await DBHelper.instance.fetchBillDetails(b['id']);
                        await PdfInvoiceService.generateAndShareInvoice(
                          billId: b['id'],
                          customerName: b['customer_name'],
                          dateTime: b['date_time'],
                          paymentMode: b['payment_mode'],
                          totalAmount: (b['total_amount'] as num).toDouble(),
                          items: items,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
