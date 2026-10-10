import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_helper.dart';
import 'pdf_invoice_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AppRoot(),
  ));
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String _userName = '';
  String _userPhone = '';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    final phone = prefs.getString('user_phone') ?? '';

    setState(() {
      _userName = name;
      _userPhone = phone;
      _isLoggedIn = name.isNotEmpty && phone.isNotEmpty;
      _isLoading = false;
    });
  }

  void _onLoginSuccess(String name, String phone) {
    setState(() {
      _userName = name;
      _userPhone = phone;
      _isLoggedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _isLoggedIn
        ? AmafhhApp(userName: _userName, userPhone: _userPhone)
        : LoginScreen(onLoginSuccess: _onLoginSuccess);
  }
}

// ----------------- LOGIN / SETUP SCREEN -----------------
class LoginScreen extends StatefulWidget {
  final Function(String, String) onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController(text: 'MD SULTAN AHMED');
  final _phoneController = TextEditingController(text: '9986053878');

  Future<void> _submitLogin() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both Name and Mobile Number')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_phone', phone);

    widget.onLoginSuccess(name, phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade900,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text('AE', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  Text('AMAFHH ENTERPRISES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                  const Text('Billing App Setup', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Author / Operator Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _submitLogin,
                      child: const Text('Save & Continue', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------- MAIN APP WITH PERMANENT SIGNATURE -----------------
class AmafhhApp extends StatefulWidget {
  final String userName;
  final String userPhone;
  const AmafhhApp({super.key, required this.userName, required this.userPhone});

  @override
  State<AmafhhApp> createState() => _AmafhhAppState();
}

class _AmafhhAppState extends State<AmafhhApp> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0
          ? BillingScreen(userName: widget.userName, userPhone: widget.userPhone)
          : const HistoryScreen(),
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
  final String userName;
  final String userPhone;
  const BillingScreen({super.key, required this.userName, required this.userPhone});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _customerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _paymentMode = 'CASH';

  final _itemNameController = TextEditingController();
  final _itemPriceController = TextEditingController();
  final _itemQtyController = TextEditingController(text: '1');

  final List<Map<String, dynamic>> _cart = [];
  List<List<double?>> _savedSignature = [];

  @override
  void initState() {
    super.initState();
    _loadPermanentSignature();
  }

  Future<void> _loadPermanentSignature() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('permanent_signature');
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        setState(() {
          _savedSignature = decoded.map<List<double?>>((item) {
            return (item as List<dynamic>).map<double?>((val) => val != null ? (val as num).toDouble() : null).toList();
          }).toList();
        });
      } catch (_) {}
    }
  }

  void _openSignatureDialog() {
    List<Offset?> tempPoints = [];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Set Permanent Signature'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Draw your signature once. It will be automatically saved for all future bills.', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 10),
                  Container(
                    height: 130,
                    width: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.blue.shade900, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: GestureDetector(
                      onPanUpdate: (DragUpdateDetails details) {
                        setDialogState(() {
                          tempPoints.add(details.localPosition);
                        });
                      },
                      onPanEnd: (DragEndDetails details) => tempPoints.add(null),
                      child: CustomPaint(
                        painter: SignaturePainter(points: tempPoints),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => setDialogState(() => tempPoints.clear()),
                  child: const Text('Clear', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (tempPoints.isNotEmpty) {
                      final serialized = tempPoints.map((p) => p != null ? [p.dx, p.dy] : [null, null]).toList();
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('permanent_signature', jsonEncode(serialized));

                      setState(() {
                        _savedSignature = serialized;
                      });
                    }
                    if (context.mounted) Navigator.pop(dialogCtx);
                  },
                  child: const Text('Save Permanently'),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Customer / Shop Name')));
      return;
    }
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one item to the bill')));
      return;
    }

    final now = DateTime.now().toIso8601String();
    final billId = await DBHelper.instance.insertBill(
      customerName: customer,
      total: _total,
      paymentMode: _paymentMode,
      items: _cart,
    );

    // Uses saved signature automatically
    await PdfInvoiceService.generateAndShareInvoice(
      billId: billId,
      customerName: customer,
      customerPhone: phone,
      customerAddress: address,
      dateTime: now,
      paymentMode: _paymentMode,
      totalAmount: _total,
      items: _cart,
      signaturePoints: _savedSignature.isNotEmpty ? _savedSignature : null,
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
              // Store & Operator Status Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Author: ${widget.userName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Mob: ${widget.userPhone} / 99862 68994', style: const TextStyle(fontSize: 12)),
                          const Text('RML NAGAR 2nd CROSS, SHIVAMOGGA', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                      // Permanent Signature Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _savedSignature.isNotEmpty ? Colors.green.shade800 : Colors.orange.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        icon: Icon(_savedSignature.isNotEmpty ? Icons.check_circle : Icons.edit, size: 16),
                        label: Text(_savedSignature.isNotEmpty ? 'Sign Saved' : 'Set Sign', style: const TextStyle(fontSize: 11)),
                        onPressed: _openSignatureDialog,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

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

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0D47A1)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
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
