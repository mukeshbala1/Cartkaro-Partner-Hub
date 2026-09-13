import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';

// ════════════════════════════════════════════════════════════════════════
// MODELS
// ════════════════════════════════════════════════════════════════════════
class _UpiAccount {
  final String id;
  final String upiId;
  bool isSelected;

  _UpiAccount({required this.id, required this.upiId, this.isSelected = false});
}

class _OrderItemLine {
  final String name;
  final int qty;
  final double price;

  const _OrderItemLine({required this.name, required this.qty, required this.price});
}

enum PayoutMethod { bank, upi }

class _TransactionData {
  final String orderId;
  final String title;
  final String subtitle;
  final double amount;
  final bool isDeduction;
  final String customerName;
  final String dateTime;
  final String paymentStatus;
  final List<_OrderItemLine> items;
  final double deliveryCharge;
  final double platformFee;

  const _TransactionData({
    required this.orderId,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.isDeduction = false,
    this.customerName = '',
    this.dateTime = '',
    this.paymentStatus = '',
    this.items = const [],
    this.deliveryCharge = 0,
    this.platformFee = 0,
  });
}

// ════════════════════════════════════════════════════════════════════════
// SCREEN
// ════════════════════════════════════════════════════════════════════════
class EarningsScreen extends StatefulWidget {
  final String businessType;

  const EarningsScreen({Key? key, required this.businessType}) : super(key: key);

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  String _selectedDateRange = 'Today';
  DateTimeRange? _customRange;

  // Dummy balance + bank
  final double _availableBalance = 12450.00;
  final String _bankName = "HDFC Bank";
  final String _accountHolderName = "Mukesh Kumar";
  final String _accountNumber = "5021 4458 9632";
  final String _accountLast4 = "4589";
  final String _ifsc = "HDFC0001234";

  // Multiple UPI accounts — user can add more & switch which is selected
  late List<_UpiAccount> _upiAccounts;

  // Withdraw modal's chosen payout method
  PayoutMethod _withdrawMethod = PayoutMethod.bank;

  @override
  void initState() {
    super.initState();
    _upiAccounts = [
      _UpiAccount(id: 'upi_1', upiId: _businessUpiSeed(), isSelected: true),
    ];
  }

  // ── Business-aware copy ──
  String get _businessLabel {
    switch (widget.businessType) {
      case 'restaurant':
        return 'Restaurant';
      case 'medical':
        return 'Medical ';
      default:
        return 'Grocery ';
    }
  }

  String _businessUpiSeed() {
    switch (widget.businessType) {
      case 'restaurant':
        return 'myrestaurant@okhdfc';
      case 'medical':
        return 'mymedstore@okhdfc';
      default:
        return 'mukeshstore@okhdfc';
    }
  }

  _UpiAccount get _selectedUpi => _upiAccounts.firstWhere((u) => u.isSelected, orElse: () => _upiAccounts.first);

  // ── Dummy transactions per business type ──
  List<_TransactionData> get _transactions {
    if (widget.businessType == 'restaurant') {
      return [
        _TransactionData(
          orderId: '#ORD1024',
          title: 'Order #1024 (Biryani)',
          subtitle: 'Today, 2:30 PM',
          amount: 450,
          customerName: 'Ankit Sharma',
          dateTime: 'Today, 2:30 PM',
          paymentStatus: 'Paid Online',
          items: const [
            _OrderItemLine(name: 'Chicken Biryani', qty: 1, price: 280),
            _OrderItemLine(name: 'Cold Drink', qty: 2, price: 60),
          ],
          deliveryCharge: 30,
          platformFee: 10,
        ),
        _TransactionData(
          orderId: '#ORD1023',
          title: 'Order #1023 (Pizza)',
          subtitle: 'Today, 1:15 PM',
          amount: 850,
          customerName: 'Divya Kapoor',
          dateTime: 'Today, 1:15 PM',
          paymentStatus: 'Paid Online',
          items: const [
            _OrderItemLine(name: 'Margherita Pizza', qty: 2, price: 210),
            _OrderItemLine(name: 'Garlic Bread', qty: 1, price: 130),
          ],
          deliveryCharge: 25,
          platformFee: 10,
        ),
        const _TransactionData(
          orderId: 'FEE-1023',
          title: 'Platform Fee Deduction',
          subtitle: 'Today, 1:15 PM',
          amount: -35,
          isDeduction: true,
        ),
        _TransactionData(
          orderId: '#ORD1022',
          title: 'Order #1022 (Meals)',
          subtitle: 'Today, 11:00 AM',
          amount: 320,
          customerName: 'Rohit Malhotra',
          dateTime: 'Today, 11:00 AM',
          paymentStatus: 'COD',
          items: const [
            _OrderItemLine(name: 'Veg Thali', qty: 1, price: 280),
          ],
          deliveryCharge: 20,
          platformFee: 10,
        ),
      ];
    } else if (widget.businessType == 'medical') {
      return [
        _TransactionData(
          orderId: '#ORD1024',
          title: 'Order #1024 (Medicines)',
          subtitle: 'Today, 2:30 PM',
          amount: 450,
          customerName: 'Pratik Joshi',
          dateTime: 'Today, 2:30 PM',
          paymentStatus: 'Paid Online',
          items: const [
            _OrderItemLine(name: 'Azithromycin 500mg', qty: 1, price: 85),
            _OrderItemLine(name: 'Vitamin C Tablets', qty: 1, price: 120),
          ],
          deliveryCharge: 20,
          platformFee: 5,
        ),
        _TransactionData(
          orderId: '#ORD1023',
          title: 'Order #1023 (First Aid)',
          subtitle: 'Today, 1:15 PM',
          amount: 850,
          customerName: 'Sunita Deshmukh',
          dateTime: 'Today, 1:15 PM',
          paymentStatus: 'COD',
          items: const [
            _OrderItemLine(name: 'Blood Pressure Monitor', qty: 1, price: 1450),
          ],
          deliveryCharge: 0,
          platformFee: 10,
        ),
        const _TransactionData(
          orderId: 'FEE-1023',
          title: 'Platform Fee Deduction',
          subtitle: 'Today, 1:15 PM',
          amount: -35,
          isDeduction: true,
        ),
        _TransactionData(
          orderId: '#ORD1022',
          title: 'Order #1022 (Supplements)',
          subtitle: 'Today, 11:00 AM',
          amount: 320,
          customerName: 'Imran Khan',
          dateTime: 'Today, 11:00 AM',
          paymentStatus: 'Paid Online',
          items: const [
            _OrderItemLine(name: 'Vitamin D3 Tablets', qty: 2, price: 160),
          ],
          deliveryCharge: 20,
          platformFee: 5,
        ),
      ];
    } else {
      return [
        _TransactionData(
          orderId: '#ORD1024',
          title: 'Order #1024 (Grocery)',
          subtitle: 'Today, 2:30 PM',
          amount: 450,
          customerName: 'Riya Mehta',
          dateTime: 'Today, 2:30 PM',
          paymentStatus: 'Paid Online',
          items: const [
            _OrderItemLine(name: 'Amul Milk', qty: 2, price: 30),
            _OrderItemLine(name: 'Rice Bag (5kg)', qty: 1, price: 420),
          ],
          deliveryCharge: 25,
          platformFee: 5,
        ),
        _TransactionData(
          orderId: '#ORD1023',
          title: 'Order #1023 (Dairy)',
          subtitle: 'Today, 1:15 PM',
          amount: 850,
          customerName: 'Karan Verma',
          dateTime: 'Today, 1:15 PM',
          paymentStatus: 'COD',
          items: const [
            _OrderItemLine(name: 'Curd', qty: 4, price: 40),
            _OrderItemLine(name: 'Paneer (500g)', qty: 2, price: 150),
          ],
          deliveryCharge: 20,
          platformFee: 5,
        ),
        const _TransactionData(
          orderId: 'FEE-1023',
          title: 'Platform Fee Deduction',
          subtitle: 'Today, 1:15 PM',
          amount: -35,
          isDeduction: true,
        ),
        _TransactionData(
          orderId: '#ORD1022',
          title: 'Order #1022 (Fruits)',
          subtitle: 'Today, 11:00 AM',
          amount: 320,
          customerName: 'Sneha Joshi',
          dateTime: 'Today, 11:00 AM',
          paymentStatus: 'Paid Online',
          items: const [
            _OrderItemLine(name: 'Apples (1kg)', qty: 1, price: 180),
            _OrderItemLine(name: 'Bananas (1 dozen)', qty: 1, price: 60),
          ],
          deliveryCharge: 20,
          platformFee: 5,
        ),
      ];
    }
  }

  double get _periodTotal {
    final txns = _transactions;
    return txns.fold(0.0, (sum, t) => sum + t.amount);
  }

  // ── Custom date picker ──
  void _selectCustomDate() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.kPrimary,
              onPrimary: Colors.white,
              onSurface: AppColors.kDarkText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _selectedDateRange = "${picked.start.day}/${picked.start.month} - ${picked.end.day}/${picked.end.month}";
      });
    }
  }

  // ── Add new UPI ──
  void _showAddUpiSheet() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            const Text('Add New UPI ID', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.kDarkText)),
            const SizedBox(height: 6),
            const Text('Add a UPI ID to receive payouts', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 18),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'UPI ID',
                hintText: 'yourname@bank',
                prefixIcon: const Icon(LucideIcons.smartphone, color: AppColors.kPrimary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.kPrimary, width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.isEmpty || !value.contains('@')) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Enter a valid UPI ID'), backgroundColor: Colors.red));
                    return;
                  }
                  setState(() {
                    for (var u in _upiAccounts) {
                      u.isSelected = false;
                    }
                    _upiAccounts.add(_UpiAccount(id: 'upi_${_upiAccounts.length + 1}', upiId: value, isSelected: true));
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UPI ID added & selected for payouts'), backgroundColor: Colors.green));
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Add UPI ID', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Linked UPI card tap → shows list (1 or many) + switch + add new ──
  void _showUpiListSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Linked UPI IDs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.kDarkText)),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAddUpiSheet();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(color: AppColors.kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(LucideIcons.plus, size: 14, color: AppColors.kPrimary),
                        SizedBox(width: 4),
                        Text('Add New', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.kPrimary)),
                      ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _upiAccounts.length > 1 ? 'Select which UPI ID receives your payouts' : 'This UPI ID is used to receive payouts',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ..._upiAccounts.map((u) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          for (var acc in _upiAccounts) {
                            acc.isSelected = acc.id == u.id;
                          }
                        });
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: u.isSelected ? AppColors.kPrimary.withOpacity(0.05) : Colors.white,
                          border: Border.all(color: u.isSelected ? AppColors.kPrimary : Colors.grey.shade300, width: u.isSelected ? 1.5 : 1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(color: AppColors.kPrimary.withOpacity(0.08), shape: BoxShape.circle),
                              child: const Icon(LucideIcons.smartphone, color: AppColors.kPrimary, size: 17),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u.upiId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  if (u.isSelected) const Text('Active for payouts', style: TextStyle(fontSize: 11.5, color: AppColors.kPrimary, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            Icon(
                              u.isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                              color: u.isSelected ? AppColors.kPrimary : Colors.grey.shade300,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done', style: TextStyle(color: AppColors.kPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bank account card tap → full details popup ──
  void _showBankDetailsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.landmark, color: Colors.blueGrey, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Bank Account Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.kDarkText)),
              ],
            ),
            const SizedBox(height: 20),
            _bankDetailRow('Account Holder', _accountHolderName),
            _bankDetailRow('Bank Name', _bankName),
            _bankDetailRow('Account Number', _accountNumber),
            _bankDetailRow('IFSC Code', _ifsc),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade200)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.info, size: 16, color: Colors.amber.shade800),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'To change your bank account, go to Settings.',
                      style: TextStyle(fontSize: 12.5, color: Colors.amber.shade900, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bankDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.kDarkText))),
        ],
      ),
    );
  }

  // ── Withdraw modal — switch between Bank / UPI ──
  void _showWithdrawModal() {
    final amountController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                const Text('Withdraw Funds', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.kDarkText)),
                const SizedBox(height: 4),
                Text('Available: ₹${_availableBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Enter Amount (₹)',
                    hintText: 'Max ₹${_availableBalance.toStringAsFixed(0)}',
                    prefixIcon: const Icon(LucideIcons.indianRupee, color: AppColors.kPrimary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.kPrimary, width: 2)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Select Payout Method', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.kLightText)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => setSheetState(() => _withdrawMethod = PayoutMethod.bank),
                  child: _buildPayoutOption(
                    LucideIcons.landmark,
                    'Bank Account',
                    '$_bankName •••• $_accountLast4',
                    _withdrawMethod == PayoutMethod.bank,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => setSheetState(() => _withdrawMethod = PayoutMethod.upi),
                  child: _buildPayoutOption(
                    LucideIcons.smartphone,
                    'UPI Transfer',
                    _selectedUpi.upiId,
                    _withdrawMethod == PayoutMethod.upi,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final amtText = amountController.text.trim();
                      final amt = double.tryParse(amtText);
                      if (amt == null || amt <= 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Enter a valid amount'), backgroundColor: Colors.red));
                        return;
                      }
                      if (amt > _availableBalance) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Amount exceeds available balance'), backgroundColor: Colors.red));
                        return;
                      }
                      final destination = _withdrawMethod == PayoutMethod.bank ? '$_bankName •••• $_accountLast4' : _selectedUpi.upiId;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('₹${amt.toStringAsFixed(0)} withdrawal initiated to $destination'), backgroundColor: Colors.green));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('Proceed to Withdraw', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPayoutOption(IconData icon, String title, String subtitle, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.kPrimary.withOpacity(0.05) : Colors.white,
        border: Border.all(color: isSelected ? AppColors.kPrimary : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: isSelected ? AppColors.kPrimary : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (isSelected) const Icon(LucideIcons.checkCircle2, color: AppColors.kPrimary)
        ],
      ),
    );
  }

  // ── Transaction / order detail popup ──
  void _showTransactionDetail(_TransactionData txn) {
    if (txn.isDeduction) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              const Text('Platform Fee Deduction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.kDarkText)),
              const SizedBox(height: 6),
              Text(txn.subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              Text('-₹${txn.amount.abs().toStringAsFixed(0)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.red)),
              const SizedBox(height: 8),
              const Text('Deducted as per platform commission policy for the associated order.', style: TextStyle(fontSize: 13, color: AppColors.kLightText, height: 1.4)),
            ],
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(txn.orderId, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.kDarkText)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                  child: Text(txn.paymentStatus, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.green.shade700)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(txn.dateTime, style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
            const SizedBox(height: 20),
            Text('CUSTOMER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.kPrimary.withOpacity(0.1),
                  child: Text(
                    txn.customerName.isNotEmpty ? txn.customerName[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.kPrimary, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                Text(txn.customerName, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.kDarkText)),
              ],
            ),
            const SizedBox(height: 22),
            Text('ORDER ITEMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            ...txn.items.map((it) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(7)),
                        child: Text('${it.qty}x', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.kPrimary)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(it.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.kDarkText))),
                      Text('₹${(it.price * it.qty).toStringAsFixed(0)}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.kDarkText)),
                    ],
                  ),
                )),
            const SizedBox(height: 22),
            Text('AMOUNT BREAKDOWN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            _amountRow('Item Total', txn.items.fold(0.0, (s, i) => s + i.price * i.qty)),
            if (txn.deliveryCharge > 0) _amountRow('Delivery Charge', txn.deliveryCharge),
            if (txn.platformFee > 0) _amountRow('Platform Fee', -txn.platformFee, isDeduction: true),
            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
            Row(
              children: [
                const Expanded(child: Text('You Earned', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.kDarkText))),
                Text('₹${txn.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _amountRow(String label, double value, {bool isDeduction = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.kLightText, fontWeight: FontWeight.w500))),
          Text(
            '${isDeduction ? '-' : ''}₹${value.abs().toStringAsFixed(0)}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDeduction ? Colors.red : AppColors.kDarkText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txns = _transactions;

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: AppColors.kBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.kDarkText, size: 22),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Earnings & Payouts', style: TextStyle(color: AppColors.kDarkText, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
            Text('$_businessLabel Earnings', style: const TextStyle(color: AppColors.kLightText, fontWeight: FontWeight.w600, fontSize: 12.5)),
          ],
        ),
        toolbarHeight: 64,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Available Balance Hero Card ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.kPrimary, AppColors.kPrimary.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.kPrimary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Available for Withdrawal', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.store, size: 12, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(_businessLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('₹${_availableBalance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showWithdrawModal,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.kPrimary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.wallet, size: 17),
                          SizedBox(width: 8),
                          Text('Withdraw Funds', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Date Filters ──
            Row(
              children: [
                _filterChip('Today'),
                const SizedBox(width: 8),
                _filterChip('This Week'),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _selectCustomDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedDateRange != 'Today' && _selectedDateRange != 'This Week' ? AppColors.kPrimary : Colors.white,
                      border: Border.all(color: _selectedDateRange != 'Today' && _selectedDateRange != 'This Week' ? AppColors.kPrimary : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.calendarDays, size: 16, color: _selectedDateRange != 'Today' && _selectedDateRange != 'This Week' ? Colors.white : AppColors.kDarkText),
                        const SizedBox(width: 6),
                        Text(
                          (_selectedDateRange != 'Today' && _selectedDateRange != 'This Week') ? _selectedDateRange : 'Custom',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _selectedDateRange != 'Today' && _selectedDateRange != 'This Week' ? Colors.white : AppColors.kDarkText),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),

            // ── Connected Accounts ──
            const Text('Payout Methods', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.kDarkText)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _showBankDetailsSheet,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(LucideIcons.landmark, color: Colors.blueGrey),
                              Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey.shade400),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(_bankName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('**** $_accountLast4', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _showUpiListSheet,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(LucideIcons.smartphone, color: Colors.teal),
                              Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey.shade400),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Flexible(child: Text('Linked UPI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)),
                              if (_upiAccounts.length > 1) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(color: AppColors.kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Text('${_upiAccounts.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.kPrimary)),
                                ),
                              ],
                            ],
                          ),
                          Text(_selectedUpi.upiId, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Recent Earning Transactions ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Earnings for $_selectedDateRange', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.kDarkText))),
                Text('${_periodTotal >= 0 ? '₹' : '-₹'}${_periodTotal.abs().toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            ...txns.map((t) => GestureDetector(
                  onTap: () => _showTransactionDetail(t),
                  child: _buildTransactionTile(t),
                )),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    bool isSelected = _selectedDateRange == label;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedDateRange = label;
        _customRange = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.kPrimary : Colors.white,
          border: Border.all(color: isSelected ? AppColors.kPrimary : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.kDarkText)),
      ),
    );
  }

  Widget _buildTransactionTile(_TransactionData txn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: txn.isDeduction ? Colors.red.shade50 : Colors.green.shade50, shape: BoxShape.circle),
            child: Icon(txn.isDeduction ? LucideIcons.arrowDownRight : LucideIcons.arrowUpRight, color: txn.isDeduction ? Colors.red : Colors.green, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 4),
                Text(txn.subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text('${txn.isDeduction ? '-' : '+'}₹${txn.amount.abs().toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: txn.isDeduction ? Colors.red : Colors.green)),
          const SizedBox(width: 6),
          Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey.shade300),
        ],
      ),
    );
  }
}