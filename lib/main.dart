import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';
import 'pdf_invoice_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AmafhhApp(),
  ));
}

class AmafhhApp extends StatefulWidget {
  const AmafhhApp({super.key});

  @override
  State<AmafhhApp> createState() => _AmafhhAppState();
}

class _AmafhhAppState extends State<AmafhhApp> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0 ? const BillingScreen() : const HistoryScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Create Bill'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Bill History'),
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
  // Customer Details
  final _customerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _paymentMode = 'CASH';

  // Manual Item Entry Controllers
  final _itemNameController = TextEditingController();
  final _itemPriceController = TextEditingController();
  final _itemQtyController = TextEditingController(text: '1');

  final List<Map<String, dynamic>> _cart = [];

  void _addManualItem() {
    final name = _itemNameController.text.trim();
    final price = double.tryParse(_itemPriceController.text.trim()) ?? 0.0;
    final qty = int.tryParse(_itemQtyController.text.trim()) ?? 1;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter item/particular name')));
      return;
    }
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid rate/price')));
      return;
    }

    setState(() {
      _cart.add({
        'name': name,
        'price': price,
        'qty': qty,
      });
      _itemNameController.clear();
      _itemPriceController.clear();
      _itemQtyController.text = '1';
    });
  }

  double get _total => _cart.fold(0, (sum, i) => sum + (i['price'] * i['qty']));

  Future<void> _saveAndSendBill() async {
    final customer = _customerController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    if (customer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Customer / Shop Name')),
      );
      return;
    }
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item to the bill')),
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
      customerPhone: phone,
      customerAddress: address,
      dateTime: now,
      paymentMode: _paymentMode,
      totalAmount: _total,
      items: _cart,
    );

    if (mounted) {
      setState(() {
        _cart.clear();
        _customerController.clear();
        _phoneController.clear();
        _addressController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AMAFHH ENTERPRISES'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Header Details Card
              Card(
                color: Colors.blue.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Prop: MD SULTAN AHMED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Mob: 99860 53878 / 99862 68994 | WhatsApp: 90084 60450', style: TextStyle(fontSize: 12)),
                      Text('Address: RML NAGAR 2nd CROSS, SHIVAMOGGA - 577202', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Customer Details
              const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              TextField(
                controller: _customerController,
                decoration: const InputDecoration(labelText: 'Customer / Shop Name (To:)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Customer Address (e.g. City Center)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _paymentMode,
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Bill Type'),
                      items: const [
                        DropdownMenuItem(value: 'CASH', child: Text('CASH BILL')),
                        DropdownMenuItem(value: 'CREDIT', child: Text('CREDIT BILL')),
                        DropdownMenuItem(value: 'UPI', child: Text('UPI / ONLINE')),
                      ],
                      onChanged: (val) => setState(() => _paymentMode = val!),
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),

              // Manual Item Entry Section
              const Text('Add Particulars & Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              TextField(
                controller: _itemNameController,
                decoration: const InputDecoration(labelText: 'Particulars (e.g. Pineapple, Mango)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _itemPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Rate (Rs)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _itemQtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _addManualItem,
                    child: const Text('Add Item'),
                  ),
                ],
              ),
              const Divider(height: 30),

              // Items Table / Cart
              const Text('Items Added in Bill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              _cart.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: Text('No items added yet')),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _cart.length,
                      itemBuilder: (context, idx) {
                        final item = _cart[idx];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade900,
                              foregroundColor: Colors.white,
                              child: Text('${idx + 1}'),
                            ),
                            title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Rate: Rs. ${item['price']}  |  Qty: ${item['qty']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Rs. ${(item['price'] * item['qty']).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => setState(() => _cart.removeAt(idx)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Grand Total: Rs. ${_total.toStringAsFixed(2)}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                      icon: const Icon(Icons.send),
                      onPressed: _saveAndSendBill,
                      label: const Text('Save & Share Bill'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      appBar: AppBar(
        title: const Text('AMAFHH Billing History'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
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
              final formattedDate = DateFormat('dd/MM/yyyy').format(date);
              final billNum = b['id'].toString().padLeft(3, '0');

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade900,
                  foregroundColor: Colors.white,
                  child: Text('No.$billNum', style: const TextStyle(fontSize: 10)),
                ),
                title: Text(b['customer_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Date: $formattedDate | ${b['payment_mode']} BILL'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Rs. ${b['total_amount']}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.green),
                      onPressed: () async {
                        final items = await DBHelper.instance.fetchBillDetails(b['id']);
                        await PdfInvoiceService.generateAndShareInvoice(
                          billId: b['id'],
                          customerName: b['customer_name'],
                          customerPhone: '',
                          customerAddress: '',
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
