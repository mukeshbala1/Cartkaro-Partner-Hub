import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';

// ════════════════════════════════════════════════════════════════════════
// ENUM — Order lifecycle
// ════════════════════════════════════════════════════════════════════════
enum OrderStatus { newOrder, accepted, preparing, ready, outForDelivery, completed, cancelled }

class OrderStatusMeta {
  final String label;
  final Color color;
  const OrderStatusMeta(this.label, this.color);
}

const Map<OrderStatus, OrderStatusMeta> kStatusMeta = {
  OrderStatus.newOrder: OrderStatusMeta('New Order', Color(0xFFF59E0B)),
  OrderStatus.accepted: OrderStatusMeta('Accepted', Color(0xFFF59E0B)),
  OrderStatus.preparing: OrderStatusMeta('Preparing', Color(0xFF3B82F6)),
  OrderStatus.ready: OrderStatusMeta('Ready', Color(0xFF8B5CF6)),
  OrderStatus.outForDelivery: OrderStatusMeta('Out For Delivery', Color(0xFF22C55E)),
  OrderStatus.completed: OrderStatusMeta('Completed', Color(0xFF15803D)),
  OrderStatus.cancelled: OrderStatusMeta('Cancelled', Color(0xFFEF4444)),
};

// ════════════════════════════════════════════════════════════════════════
// CHAT MODELS
// ════════════════════════════════════════════════════════════════════════
enum ChatSender { customer, merchant }

class ChatMessageModel {
  final String text;
  final ChatSender sender;
  final String time;

  const ChatMessageModel({required this.text, required this.sender, required this.time});
}

// ════════════════════════════════════════════════════════════════════════
// MODELS
// ════════════════════════════════════════════════════════════════════════
class OrderItemModel {
  final String name;
  final int quantity;
  final double price;

  const OrderItemModel({required this.name, required this.quantity, required this.price});

  double get subtotal => price * quantity;
}

class OrderModel {
  final String id;
  final String customerName;
  final String customerPhone;
  final String address;
  final List<OrderItemModel> items;
  final String time;
  final String paymentMode; // 'Paid Online' or 'COD'
  final double itemTotal;
  final double deliveryCharge;
  final double platformFee;
  final double discount;
  final bool hasPrescription;
  OrderStatus status;
  final List<ChatMessageModel> messages;

  OrderModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.items,
    required this.time,
    required this.paymentMode,
    required this.itemTotal,
    this.deliveryCharge = 0,
    this.platformFee = 0,
    this.discount = 0,
    this.hasPrescription = false,
    this.status = OrderStatus.newOrder,
    List<ChatMessageModel>? messages,
  }) : messages = messages ?? [];

  double get finalAmount => itemTotal + deliveryCharge + platformFee - discount;

  bool get hasUnreadFromCustomer =>
      messages.isNotEmpty && messages.last.sender == ChatSender.customer;
}

// ════════════════════════════════════════════════════════════════════════
// DUMMY DATA — generated per business type
// ════════════════════════════════════════════════════════════════════════
List<OrderModel> _buildDummyOrders(String businessType) {
  final bt = businessType.toLowerCase();

  if (bt == 'restaurant') {
    return [
      OrderModel(
        id: '#ORD10245',
        customerName: 'Ankit Sharma',
        customerPhone: '+91 98765 43210',
        address: 'Flat 302, Silver Heights, MG Road, Pune',
        items: const [
          OrderItemModel(name: 'Chicken Biryani', quantity: 1, price: 280),
          OrderItemModel(name: 'Margherita Pizza', quantity: 2, price: 210),
        ],
        time: '2 mins ago',
        paymentMode: 'Paid Online',
        itemTotal: 700,
        deliveryCharge: 30,
        platformFee: 10,
        discount: 40,
        status: OrderStatus.newOrder,
        messages: [
          const ChatMessageModel(
            text: 'Please make the biryani less spicy, thank you!',
            sender: ChatSender.customer,
            time: '2 mins ago',
          ),
        ],
      ),
      OrderModel(
        id: '#ORD10246',
        customerName: 'Divya Kapoor',
        customerPhone: '+91 91234 56780',
        address: '14, Lakeview Residency, Baner, Pune',
        items: const [
          OrderItemModel(name: 'Paneer Butter Masala', quantity: 1, price: 260),
          OrderItemModel(name: 'Butter Naan', quantity: 4, price: 40),
        ],
        time: '10 mins ago',
        paymentMode: 'COD',
        itemTotal: 420,
        deliveryCharge: 25,
        platformFee: 10,
        discount: 20,
        status: OrderStatus.accepted,
      ),
      OrderModel(
        id: '#ORD10247',
        customerName: 'Rohit Malhotra',
        customerPhone: '+91 90909 12121',
        address: 'B-9, Orchid Towers, Viman Nagar, Pune',
        items: const [
          OrderItemModel(name: 'Veg Burger', quantity: 2, price: 150),
          OrderItemModel(name: 'Cold Drink', quantity: 2, price: 60),
        ],
        time: '18 mins ago',
        paymentMode: 'Paid Online',
        itemTotal: 420,
        deliveryCharge: 20,
        platformFee: 10,
        discount: 0,
        status: OrderStatus.preparing,
      ),
      OrderModel(
        id: '#ORD10248',
        customerName: 'Neha Kulkarni',
        customerPhone: '+91 89898 32132',
        address: '22, Greenfield Society, Kothrud, Pune',
        items: const [
          OrderItemModel(name: 'Masala Dosa', quantity: 2, price: 120),
          OrderItemModel(name: 'Filter Coffee', quantity: 2, price: 50),
        ],
        time: '30 mins ago',
        paymentMode: 'COD',
        itemTotal: 340,
        deliveryCharge: 20,
        platformFee: 5,
        discount: 15,
        status: OrderStatus.ready,
      ),
      OrderModel(
        id: '#ORD10249',
        customerName: 'Suresh Reddy',
        customerPhone: '+91 88776 65544',
        address: '5th Floor, Pinnacle Heights, Hinjewadi, Pune',
        items: const [
          OrderItemModel(name: 'Chicken Biryani', quantity: 2, price: 280),
        ],
        time: '40 mins ago',
        paymentMode: 'Paid Online',
        itemTotal: 560,
        deliveryCharge: 30,
        platformFee: 10,
        discount: 50,
        status: OrderStatus.outForDelivery,
        messages: [
          const ChatMessageModel(
            text: 'Where is my order? It is taking long.',
            sender: ChatSender.customer,
            time: '5 mins ago',
          ),
          const ChatMessageModel(
            text: 'Sir it is out for delivery, will reach in 10 mins.',
            sender: ChatSender.merchant,
            time: '3 mins ago',
          ),
        ],
      ),
      OrderModel(
        id: '#ORD10250',
        customerName: 'Kavita Bhatt',
        customerPhone: '+91 77665 54433',
        address: '3, Sunshine Apartments, Aundh, Pune',
        items: const [
          OrderItemModel(name: 'Gulab Jamun', quantity: 4, price: 30),
          OrderItemModel(name: 'Margherita Pizza', quantity: 1, price: 210),
        ],
        time: '1 hour ago',
        paymentMode: 'COD',
        itemTotal: 330,
        deliveryCharge: 25,
        platformFee: 10,
        discount: 0,
        status: OrderStatus.completed,
        messages: [
          const ChatMessageModel(
            text: 'Thank you, food was great!',
            sender: ChatSender.customer,
            time: '20 mins ago',
          ),
        ],
      ),
      OrderModel(
        id: '#ORD10251',
        customerName: 'Arjun Nambiar',
        customerPhone: '+91 99887 76655',
        address: '11, Palm Residency, Wakad, Pune',
        items: const [
          OrderItemModel(name: 'Chicken Biryani', quantity: 1, price: 280),
        ],
        time: 'Yesterday',
        paymentMode: 'Paid Online',
        itemTotal: 280,
        deliveryCharge: 25,
        platformFee: 5,
        discount: 10,
        status: OrderStatus.completed,
      ),
      OrderModel(
        id: '#ORD10252',
        customerName: 'Meena Iyer',
        customerPhone: '+91 90011 22334',
        address: '6, Lotus Enclave, Hadapsar, Pune',
        items: const [
          OrderItemModel(name: 'Veg Burger', quantity: 1, price: 150),
        ],
        time: 'Yesterday',
        paymentMode: 'COD',
        itemTotal: 150,
        status: OrderStatus.cancelled,
      ),
    ];
  } else if (bt == 'medical') {
    return [
      OrderModel(
        id: '#ORD30011',
        customerName: 'Pratik Joshi',
        customerPhone: '+91 98123 45670',
        address: 'Shop 4, Apollo Complex, FC Road, Pune',
        items: const [
          OrderItemModel(name: 'Paracetamol 650mg (Strip of 10)', quantity: 2, price: 30),
        ],
        time: '5 mins ago',
        paymentMode: 'Paid Online',
        itemTotal: 60,
        deliveryCharge: 20,
        platformFee: 5,
        status: OrderStatus.newOrder,
      ),
      OrderModel(
        id: '#ORD30012',
        customerName: 'Sunita Deshmukh',
        customerPhone: '+91 97123 88990',
        address: '9, Sai Krupa Society, Karve Nagar, Pune',
        items: const [
          OrderItemModel(name: 'Azithromycin 500mg', quantity: 1, price: 85),
          OrderItemModel(name: 'Vitamin C Tablets', quantity: 1, price: 120),
        ],
        time: '15 mins ago',
        paymentMode: 'COD',
        itemTotal: 205,
        deliveryCharge: 20,
        platformFee: 5,
        discount: 10,
        hasPrescription: true,
        status: OrderStatus.accepted,
        messages: [
          const ChatMessageModel(
            text: 'I have uploaded the prescription, please check.',
            sender: ChatSender.customer,
            time: '12 mins ago',
          ),
        ],
      ),
      OrderModel(
        id: '#ORD30013',
        customerName: 'Imran Khan',
        customerPhone: '+91 96123 77881',
        address: '17, Crescent Park, Camp, Pune',
        items: const [
          OrderItemModel(name: 'Cough Syrup 100ml', quantity: 1, price: 95),
        ],
        time: '22 mins ago',
        paymentMode: 'Paid Online',
        itemTotal: 95,
        deliveryCharge: 15,
        platformFee: 5,
        status: OrderStatus.preparing,
      ),
      OrderModel(
        id: '#ORD30014',
        customerName: 'Geeta Nair',
        customerPhone: '+91 95123 66772',
        address: '2B, Hill View Apartments, Bavdhan, Pune',
        items: const [
          OrderItemModel(name: 'Blood Pressure Monitor', quantity: 1, price: 1450),
        ],
        time: '40 mins ago',
        paymentMode: 'Paid Online',
        itemTotal: 1450,
        platformFee: 10,
        discount: 100,
        status: OrderStatus.ready,
      ),
      OrderModel(
        id: '#ORD30015',
        customerName: 'Faisal Ansari',
        customerPhone: '+91 94123 55663',
        address: '5, Star City, Wagholi, Pune',
        items: const [
          OrderItemModel(name: 'Insulin Pen', quantity: 1, price: 650),
        ],
        time: '55 mins ago',
        paymentMode: 'COD',
        itemTotal: 650,
        deliveryCharge: 20,
        platformFee: 5,
        hasPrescription: true,
        status: OrderStatus.outForDelivery,
      ),
      OrderModel(
        id: '#ORD30016',
        customerName: 'Lata Kulkarni',
        customerPhone: '+91 93123 44554',
        address: '8, Green Park Society, Erandwane, Pune',
        items: const [
          OrderItemModel(name: 'Hand Sanitizer 200ml', quantity: 2, price: 60),
          OrderItemModel(name: 'Face Masks (Box of 50)', quantity: 1, price: 180),
        ],
        time: '1 hour ago',
        paymentMode: 'Paid Online',
        itemTotal: 300,
        deliveryCharge: 20,
        platformFee: 5,
        discount: 15,
        status: OrderStatus.completed,
      ),
      OrderModel(
        id: '#ORD30017',
        customerName: 'Deepak Verma',
        customerPhone: '+91 92123 33445',
        address: '19, Maple Heights, Kondhwa, Pune',
        items: const [
          OrderItemModel(name: 'Paracetamol 650mg (Strip of 10)', quantity: 1, price: 30),
          OrderItemModel(name: 'Bandage Roll', quantity: 2, price: 25),
        ],
        time: 'Yesterday',
        paymentMode: 'COD',
        itemTotal: 80,
        deliveryCharge: 15,
        platformFee: 5,
        status: OrderStatus.completed,
      ),
      OrderModel(
        id: '#ORD30018',
        customerName: 'Anita Sharma',
        customerPhone: '+91 91123 22336',
        address: '4, Riverside Colony, Yerwada, Pune',
        items: const [
          OrderItemModel(name: 'Amoxicillin 500mg', quantity: 1, price: 110),
        ],
        time: 'Yesterday',
        paymentMode: 'Paid Online',
        itemTotal: 110,
        hasPrescription: true,
        status: OrderStatus.cancelled,
      ),
    ];
  } else {
    // Grocery / general store (default)
    return [
      OrderModel(
        id: '#ORD20011',
        customerName: 'Riya Mehta',
        customerPhone: '+91 90909 11223',
        address: 'B-12, Green Valley Society, Sector 21, Pune',
        items: const [
          OrderItemModel(name: 'Amul Milk', quantity: 2, price: 30),
          OrderItemModel(name: 'Rice Bag (5kg)', quantity: 1, price: 420),
        ],
        time: '3 mins ago',
        paymentMode: 'Paid Online',
        itemTotal: 480,
        deliveryCharge: 25,
        platformFee: 5,
        discount: 20,
        status: OrderStatus.newOrder,
        messages: [
          const ChatMessageModel(
            text: 'Can you pack the rice bag separately?',
            sender: ChatSender.customer,
            time: '3 mins ago',
          ),
        ],
      ),
      OrderModel(
        id: '#ORD20012',
        customerName: 'Karan Verma',
        customerPhone: '+91 88990 22110',
        address: 'Flat 7B, Sunrise Apartments, Baner Road, Pune',
        items: const [
          OrderItemModel(name: 'Tomatoes (2kg)', quantity: 1, price: 50),
          OrderItemModel(name: 'Onions (1kg)', quantity: 1, price: 30),
          OrderItemModel(name: 'Toor Dal (1kg)', quantity: 1, price: 140),
        ],
        time: '12 mins ago',
        paymentMode: 'COD',
        itemTotal: 220,
        deliveryCharge: 20,
        platformFee: 5,
        status: OrderStatus.accepted,
      ),
      OrderModel(
        id: '#ORD20013',
        customerName: 'Sneha Joshi',
        customerPhone: '+91 87654 11098',
        address: '18, Lakeside Residency, Baner, Pune',
        items: const [
          OrderItemModel(name: 'Apples (1kg)', quantity: 1, price: 180),
          OrderItemModel(name: 'Bananas (1 dozen)', quantity: 1, price: 60),
        ],
        time: '20 mins ago',
        paymentMode: 'Paid Online',
        itemTotal: 240,
        deliveryCharge: 20,
        platformFee: 5,
        discount: 10,
        status: OrderStatus.preparing,
      ),
      OrderModel(
        id: '#ORD20014',
        customerName: 'Manoj Pillai',
        customerPhone: '+91 86543 22109',
        address: '9, Palm Grove, Kothrud, Pune',
        items: const [
          OrderItemModel(name: 'Detergent Powder (1kg)', quantity: 1, price: 110),
          OrderItemModel(name: 'Dishwash Liquid', quantity: 1, price: 90),
        ],
        time: '35 mins ago',
        paymentMode: 'COD',
        itemTotal: 200,
        deliveryCharge: 25,
        platformFee: 5,
        status: OrderStatus.ready,
      ),
      OrderModel(
        id: '#ORD20015',
        customerName: 'Anjali Rao',
        customerPhone: '+91 85432 33210',
        address: '4, Hilltop Society, Wakad, Pune',
        items: const [
          OrderItemModel(name: 'Sunflower Oil (1L)', quantity: 1, price: 150),
          OrderItemModel(name: 'Wheat Flour (5kg)', quantity: 1, price: 250),
        ],
        time: '50 mins ago',
        paymentMode: 'Paid Online',
        itemTotal: 400,
        deliveryCharge: 30,
        platformFee: 5,
        discount: 30,
        status: OrderStatus.outForDelivery,
      ),
      OrderModel(
        id: '#ORD20016',
        customerName: 'Vivek Nair',
        customerPhone: '+91 84321 44321',
        address: '21, Riverdale Park, Hadapsar, Pune',
        items: const [
          OrderItemModel(name: 'Eggs (12 pc)', quantity: 1, price: 84),
          OrderItemModel(name: 'Bread', quantity: 1, price: 45),
        ],
        time: '1 hour ago',
        paymentMode: 'COD',
        itemTotal: 129,
        deliveryCharge: 20,
        platformFee: 5,
        status: OrderStatus.completed,
        messages: [
          const ChatMessageModel(
            text: 'Bread thoda fresh wala dena next time.',
            sender: ChatSender.customer,
            time: '40 mins ago',
          ),
        ],
      ),
      OrderModel(
        id: '#ORD20017',
        customerName: 'Pooja Iyer',
        customerPhone: '+91 83210 55432',
        address: '6, Garden View, Viman Nagar, Pune',
        items: const [
          OrderItemModel(name: 'Rice Bag (5kg)', quantity: 1, price: 420),
        ],
        time: 'Yesterday',
        paymentMode: 'Paid Online',
        itemTotal: 420,
        deliveryCharge: 25,
        platformFee: 5,
        discount: 20,
        status: OrderStatus.completed,
      ),
      OrderModel(
        id: '#ORD20018',
        customerName: 'Rahul Singh',
        customerPhone: '+91 82109 66543',
        address: '13, Maple Residency, Kondhwa, Pune',
        items: const [
          OrderItemModel(name: 'Amul Milk', quantity: 1, price: 30),
          OrderItemModel(name: 'Curd', quantity: 1, price: 40),
        ],
        time: 'Yesterday',
        paymentMode: 'COD',
        itemTotal: 70,
        status: OrderStatus.cancelled,
      ),
    ];
  }
}

// ════════════════════════════════════════════════════════════════════════
// CALL HELPER
// ════════════════════════════════════════════════════════════════════════
Future<void> _callNumber(BuildContext context, String phoneNumber) async {
  final cleaned = phoneNumber.replaceAll(' ', '');
  final uri = Uri(scheme: 'tel', path: cleaned);
  try {
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open dialer')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open dialer')),
      );
    }
  }
}

// ════════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ════════════════════════════════════════════════════════════════════════
class OrdersManagementScreen extends StatefulWidget {
  final String businessType;

  const OrdersManagementScreen({
    Key? key,
    required this.businessType,
  }) : super(key: key);

  @override
  State<OrdersManagementScreen> createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen> {
  late List<OrderModel> _orders;
  String _selectedFilter = 'All Orders';
  bool _showSearch = false;
  String _searchQuery = '';

  final List<String> _filters = const [
    'All Orders',
    'New Orders',
    'Preparing',
    'Ready',
    'Out For Delivery',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _orders = _buildDummyOrders(widget.businessType);
  }

  // ── Derived data ──
  int get _totalOrders => _orders.length;
  int get _pendingOrders => _orders
      .where((o) => o.status != OrderStatus.completed && o.status != OrderStatus.cancelled)
      .length;
  int get _completedOrders => _orders.where((o) => o.status == OrderStatus.completed).length;

  List<OrderModel> get _filteredOrders {
    Iterable<OrderModel> list = _orders;

    switch (_selectedFilter) {
      case 'New Orders':
        list = list.where((o) => o.status == OrderStatus.newOrder || o.status == OrderStatus.accepted);
        break;
      case 'Preparing':
        list = list.where((o) => o.status == OrderStatus.preparing);
        break;
      case 'Ready':
        list = list.where((o) => o.status == OrderStatus.ready);
        break;
      case 'Out For Delivery':
        list = list.where((o) => o.status == OrderStatus.outForDelivery);
        break;
      case 'Completed':
        list = list.where((o) => o.status == OrderStatus.completed);
        break;
      case 'Cancelled':
        list = list.where((o) => o.status == OrderStatus.cancelled);
        break;
      default:
        break;
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((o) =>
          o.id.toLowerCase().contains(q) || o.customerName.toLowerCase().contains(q));
    }

    return list.toList();
  }

  // ── Actions ──
  void _updateStatus(OrderModel order, OrderStatus status) {
    setState(() => order.status = status);
  }

  void _sendReply(OrderModel order, String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      order.messages.add(
        ChatMessageModel(text: text.trim(), sender: ChatSender.merchant, time: 'Just now'),
      );
    });
  }

  void _confirmReject(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Reject Order?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text(
          'Are you sure you want to reject order ${order.id}? This action cannot be undone.',
          style: const TextStyle(fontSize: 13.5, color: AppColors.kLightText, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.kLightText, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(order, OrderStatus.cancelled);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          decoration: const BoxDecoration(
            color: AppColors.kWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppColors.kBorder, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const Text('Sort Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.kDarkText)),
              const SizedBox(height: 6),
              _sortOption('Newest First'),
              _sortOption('Oldest First'),
              _sortOption('Amount: High to Low'),
              _sortOption('Amount: Low to High'),
            ],
          ),
        );
      },
    );
  }

  Widget _sortOption(String label) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.kDarkText)),
      trailing: const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.kLightText),
      onTap: () {
        Navigator.pop(context);
        setState(() {
          switch (label) {
            case 'Oldest First':
              _orders = _orders.reversed.toList();
              break;
            case 'Amount: High to Low':
              _orders.sort((a, b) => b.finalAmount.compareTo(a.finalAmount));
              break;
            case 'Amount: Low to High':
              _orders.sort((a, b) => a.finalAmount.compareTo(b.finalAmount));
              break;
            default:
              break;
          }
        });
      },
    );
  }

  void _openOrderDetails(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => StatefulBuilder(
            builder: (context, setSheetState) => _OrderDetailsSheet(
              order: order,
              scrollController: scrollController,
              onSendReply: (text) {
                _sendReply(order, text);
                setSheetState(() {});
              },
            ),
          ),
        );
      },
    );
  }

  // ── UI builders ──
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(LucideIcons.arrowLeft, size: 22, color: AppColors.kDarkText),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Orders Management',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.kDarkText, letterSpacing: -0.4),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage your customer orders',
                  style: TextStyle(fontSize: 13, color: AppColors.kLightText, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          _circleIconButton(
            icon: _showSearch ? LucideIcons.x : LucideIcons.search,
            onTap: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) _searchQuery = '';
            }),
          ),
          const SizedBox(width: 10),
          _circleIconButton(icon: LucideIcons.slidersHorizontal, onTap: _openSortSheet),
        ],
      ),
    );
  }

  Widget _circleIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.kWhite,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Icon(icon, size: 19, color: AppColors.kPrimary),
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: !_showSearch
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.kWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(fontSize: 13.5, color: AppColors.kDarkText),
                  decoration: InputDecoration(
                    hintText: 'Search by order ID or customer name',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.kLightText),
                    prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.kLightText),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildAnalyticsCards() {
    final cards = [
      _AnalyticsCardData(
        icon: LucideIcons.shoppingBag,
        label: 'Total Orders',
        value: '$_totalOrders',
        growth: '+12% this week',
        growthUp: true,
      ),
      _AnalyticsCardData(
        icon: LucideIcons.clock,
        label: 'Pending Orders',
        value: '$_pendingOrders',
        growth: 'Needs attention',
        growthUp: false,
      ),
      _AnalyticsCardData(
        icon: Icons.check_circle,
        label: 'Completed Orders',
        value: '$_completedOrders',
        growth: '+8% this week',
        growthUp: true,
      ),
    ];

    return SizedBox(
      height: 112,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _AnalyticsCard(data: cards[i]),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = _filters[i];
          final selected = f == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.kPrimary : AppColors.kWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: selected ? AppColors.kPrimary : AppColors.kBorder),
                boxShadow: selected
                    ? [BoxShadow(color: AppColors.kPrimary.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Text(
                f,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.kDarkText,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.kPrimary.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(LucideIcons.inbox, size: 36, color: AppColors.kPrimary),
            ),
            const SizedBox(height: 18),
            const Text('No orders yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.kDarkText)),
            const SizedBox(height: 6),
            const Text(
              'Your new orders will appear here',
              style: TextStyle(fontSize: 13, color: AppColors.kLightText, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;

    return Container(
      color: AppColors.kBackground,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildSearchBar(),
                      _buildAnalyticsCards(),
                      _buildFilterTabs(),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final order = filtered[index];
                        return _OrderCard(
                          order: order,
                          onTap: () => _openOrderDetails(order),
                          onAccept: () => _updateStatus(order, OrderStatus.accepted),
                          onReject: () => _confirmReject(order),
                          onAdvance: (s) => _updateStatus(order, s),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// ORDER CARD
// ════════════════════════════════════════════════════════════════════════
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final void Function(OrderStatus) onAdvance;

  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.onAccept,
    required this.onReject,
    required this.onAdvance,
  });

  Widget _buildFooter() {
    switch (order.status) {
      case OrderStatus.newOrder:
        return Row(
          children: [
            Expanded(child: _PrimaryActionButton(label: 'Accept Order', icon: LucideIcons.check, onTap: onAccept)),
            const SizedBox(width: 10),
            Expanded(child: _SecondaryActionButton(label: 'Reject', icon: LucideIcons.x, color: Colors.red, onTap: onReject)),
          ],
        );
      case OrderStatus.accepted:
        return _PrimaryActionButton(
          label: 'Start Preparing',
          icon: LucideIcons.utensils,
          fullWidth: true,
          onTap: () => onAdvance(OrderStatus.preparing),
        );
      case OrderStatus.preparing:
        return _PrimaryActionButton(
          label: 'Mark Ready',
          icon: LucideIcons.check,
          fullWidth: true,
          onTap: () => onAdvance(OrderStatus.ready),
        );
      case OrderStatus.ready:
        return _PrimaryActionButton(
          label: 'Send For Delivery',
          icon: LucideIcons.truck,
          fullWidth: true,
          onTap: () => onAdvance(OrderStatus.outForDelivery),
        );
      case OrderStatus.outForDelivery:
        return _PrimaryActionButton(
          label: 'Mark Completed',
          icon: LucideIcons.checkCircle,
          fullWidth: true,
          onTap: () => onAdvance(OrderStatus.completed),
        );
      case OrderStatus.completed:
        return const Row(
          children: [
            Icon(LucideIcons.checkCircle, size: 14, color: Color(0xFF15803D)),
            SizedBox(width: 6),
            Text('Delivered successfully', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15803D))),
          ],
        );
      case OrderStatus.cancelled:
        return const Row(
          children: [
            Icon(LucideIcons.x, size: 14, color: Colors.red),
            SizedBox(width: 6),
            Text('Order was cancelled', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red)),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = kStatusMeta[order.status]!;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.id,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.kDarkText, letterSpacing: -0.2),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: KeyedSubtree(
                          key: ValueKey(order.status),
                          child: _StatusBadge(label: meta.label, color: meta.color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.kPrimary.withOpacity(0.1),
                        child: Text(
                          order.customerName.isNotEmpty ? order.customerName[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppColors.kPrimary, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.customerName,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.kDarkText),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(LucideIcons.phone, size: 12, color: AppColors.kLightText),
                                const SizedBox(width: 4),
                                Text(
                                  order.customerPhone,
                                  style: const TextStyle(fontSize: 12, color: AppColors.kLightText, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Functional call button
                      GestureDetector(
                        onTap: () => _callNumber(context, order.customerPhone),
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: AppColors.kPrimary, borderRadius: BorderRadius.circular(11)),
                          child: const Icon(LucideIcons.phone, color: Colors.white, size: 15),
                        ),
                      ),
                      if (order.hasUnreadFromCustomer) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.kPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(LucideIcons.messageCircle, color: AppColors.kPrimary, size: 16),
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: AppColors.kBorder.withOpacity(0.6)),
                  const SizedBox(height: 12),
                  ...order.items.map(
                    (it) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${it.quantity}x ${it.name}',
                        style: const TextStyle(fontSize: 13, color: AppColors.kDarkText, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (order.hasPrescription)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 4),
                      child: Row(
                        children: [
                          Icon(LucideIcons.fileText, size: 13, color: Colors.orange.shade700),
                          const SizedBox(width: 5),
                          Text(
                            'Prescription Attached',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.orange.shade700),
                          ),
                        ],
                      ),
                    ),
                  if (order.messages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 4),
                      child: Row(
                        children: [
                          Icon(LucideIcons.messageSquare, size: 13, color: AppColors.kPrimary),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              order.messages.last.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.kPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(LucideIcons.clock, size: 12, color: AppColors.kLightText),
                            const SizedBox(width: 4),
                            Text(
                              order.time,
                              style: const TextStyle(fontSize: 12, color: AppColors.kLightText, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${order.finalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.kDarkText),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.paymentMode,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: order.paymentMode == 'Paid Online' ? Colors.green.shade700 : Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: KeyedSubtree(key: ValueKey(order.status), child: _buildFooter()),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// SMALL REUSABLE WIDGETS
// ════════════════════════════════════════════════════════════════════════
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool fullWidth;

  const _PrimaryActionButton({required this.label, required this.icon, required this.onTap, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SecondaryActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.4)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _AnalyticsCardData {
  final IconData icon;
  final String label;
  final String value;
  final String growth;
  final bool growthUp;

  const _AnalyticsCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.growth,
    required this.growthUp,
  });
}

class _AnalyticsCard extends StatelessWidget {
  final _AnalyticsCardData data;

  const _AnalyticsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final accent = data.growthUp ? const Color(0xFF15803D) : Colors.orange.shade700;
    final accentBg = data.growthUp ? const Color(0xFF15803D).withOpacity(0.1) : Colors.orange.shade700.withOpacity(0.1);

    return Container(
      width: 190,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.kWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
            child: Icon(data.icon, size: 17, color: AppColors.kPrimary),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.kDarkText, height: 1.0),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  data.label,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.kLightText, fontWeight: FontWeight.w600, height: 1.0),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: accentBg, borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(data.growthUp ? LucideIcons.trendingUp : LucideIcons.trendingDown, size: 9, color: accent),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          data.growth,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: accent, height: 1.0),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// CHAT SECTION (inside Order Details sheet)
// ════════════════════════════════════════════════════════════════════════
class _OrderChatSection extends StatefulWidget {
  final OrderModel order;
  final void Function(String text) onSendReply;

  const _OrderChatSection({required this.order, required this.onSendReply});

  @override
  State<_OrderChatSection> createState() => _OrderChatSectionState();
}

class _OrderChatSectionState extends State<_OrderChatSection> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    widget.onSendReply(text);
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.order.messages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (messages.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.kBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'No messages yet',
              style: TextStyle(fontSize: 12.5, color: AppColors.kLightText, fontWeight: FontWeight.w500),
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: AppColors.kBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(10),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: messages.length,
              itemBuilder: (context, i) => _ChatBubble(message: messages[i]),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.kWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 13, color: AppColors.kDarkText),
                  decoration: const InputDecoration(
                    hintText: 'Type a reply…',
                    hintStyle: TextStyle(fontSize: 12.5, color: AppColors.kLightText),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.kPrimary, borderRadius: BorderRadius.circular(13)),
                child: const Icon(LucideIcons.send, color: Colors.white, size: 17),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessageModel message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMerchant = message.sender == ChatSender.merchant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: isMerchant ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: isMerchant ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(
                    color: isMerchant ? AppColors.kPrimary : AppColors.kWhite,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isMerchant ? 14 : 4),
                      bottomRight: Radius.circular(isMerchant ? 4 : 14),
                    ),
                    border: isMerchant ? null : Border.all(color: AppColors.kBorder),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isMerchant ? Colors.white : AppColors.kDarkText,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message.time,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.kLightText, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// ORDER DETAILS — BOTTOM SHEET
// ════════════════════════════════════════════════════════════════════════
class _OrderDetailsSheet extends StatelessWidget {
  final OrderModel order;
  final ScrollController scrollController;
  final void Function(String text) onSendReply;

  const _OrderDetailsSheet({
    required this.order,
    required this.scrollController,
    required this.onSendReply,
  });

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.kLightText.withOpacity(0.8), letterSpacing: 0.8),
    );
  }

  Widget _priceRow(String label, double value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.kLightText, fontWeight: FontWeight.w500))),
          Text(
            '${isDiscount ? '-' : ''}₹${value.abs().toStringAsFixed(0)}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDiscount ? Colors.green.shade700 : AppColors.kDarkText),
          ),
        ],
      ),
    );
  }

  Widget _timelineStep(String label, {required bool done, required bool isLast, bool isCancelled = false}) {
    final color = isCancelled ? Colors.red : (done ? AppColors.kPrimary : AppColors.kBorder);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: done ? color : AppColors.kWhite,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: done ? Icon(isCancelled ? LucideIcons.x : LucideIcons.check, size: 12, color: Colors.white) : null,
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: done ? color.withOpacity(0.4) : AppColors.kBorder)),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: done ? AppColors.kDarkText : AppColors.kLightText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    const steps = ['Order Placed', 'Accepted', 'Preparing', 'Ready', 'Out For Delivery', 'Delivered'];

    if (order.status == OrderStatus.cancelled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _timelineStep('Order Placed', done: true, isLast: false),
          _timelineStep('Cancelled', done: true, isLast: true, isCancelled: true),
        ],
      );
    }

    int currentIndex;
    switch (order.status) {
      case OrderStatus.newOrder:
        currentIndex = 0;
        break;
      case OrderStatus.accepted:
        currentIndex = 1;
        break;
      case OrderStatus.preparing:
        currentIndex = 2;
        break;
      case OrderStatus.ready:
        currentIndex = 3;
        break;
      case OrderStatus.outForDelivery:
        currentIndex = 4;
        break;
      case OrderStatus.completed:
        currentIndex = 5;
        break;
      case OrderStatus.cancelled:
        currentIndex = 0;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        steps.length,
        (i) => _timelineStep(steps[i], done: i <= currentIndex, isLast: i == steps.length - 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = kStatusMeta[order.status]!;

    return Container(
      decoration: const BoxDecoration(color: AppColors.kWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 44, height: 5, decoration: BoxDecoration(color: AppColors.kBorder, borderRadius: BorderRadius.circular(4))),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(order.id, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.kDarkText)),
                    ),
                    _StatusBadge(label: meta.label, color: meta.color),
                  ],
                ),
                const SizedBox(height: 4),
                Text(order.time, style: const TextStyle(fontSize: 12.5, color: AppColors.kLightText, fontWeight: FontWeight.w500)),
                const SizedBox(height: 22),

                _sectionTitle('Customer Details'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.kPrimary.withOpacity(0.1),
                      child: Text(
                        order.customerName.isNotEmpty ? order.customerName[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppColors.kPrimary, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.customerName, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.kDarkText)),
                          const SizedBox(height: 2),
                          Text(order.customerPhone, style: const TextStyle(fontSize: 12.5, color: AppColors.kLightText, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    // Functional call button
                    GestureDetector(
                      onTap: () => _callNumber(context, order.customerPhone),
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.kPrimary, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(LucideIcons.phone, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),
                _sectionTitle('Delivery Address'),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.mapPin, size: 16, color: AppColors.kLightText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.address,
                        style: const TextStyle(fontSize: 13, color: AppColors.kDarkText, fontWeight: FontWeight.w500, height: 1.4),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),
                _sectionTitle('Order Items'),
                const SizedBox(height: 10),
                ...order.items.map(
                  (it) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: AppColors.kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                          child: Text('${it.quantity}x', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.kPrimary)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(it.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.kDarkText)),
                        ),
                        Text(
                          '₹${it.subtotal.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.kDarkText),
                        ),
                      ],
                    ),
                  ),
                ),
                if (order.hasPrescription)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(LucideIcons.fileText, size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 6),
                        Text('Prescription Attached', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.orange.shade700)),
                      ],
                    ),
                  ),

                const SizedBox(height: 22),
                _sectionTitle('Bill Details'),
                const SizedBox(height: 8),
                _priceRow('Item Total', order.itemTotal),
                if (order.deliveryCharge > 0) _priceRow('Delivery Charge', order.deliveryCharge),
                if (order.platformFee > 0) _priceRow('Platform Fee', order.platformFee),
                if (order.discount > 0) _priceRow('Discount', order.discount, isDiscount: true),
                const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Final Amount', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.kDarkText)),
                    ),
                    Text(
                      '₹${order.finalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.kPrimary),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    order.paymentMode,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: order.paymentMode == 'Paid Online' ? Colors.green.shade700 : Colors.orange.shade800,
                    ),
                  ),
                ),

                const SizedBox(height: 22),
                _sectionTitle('Order Status'),
                const SizedBox(height: 10),
                _buildStatusTimeline(),

                const SizedBox(height: 22),
                _sectionTitle('Customer Messages'),
                const SizedBox(height: 10),
                _OrderChatSection(order: order, onSendReply: onSendReply),
              ],
            ),
          ),
        ],
      ),
    );
  }
}