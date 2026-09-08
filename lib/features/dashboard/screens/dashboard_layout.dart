import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/services/auth_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Ye 4 files import karna zaroori hai
import 'dashboard_screen.dart';
import 'add_product_screen.dart';
import '../../earnings/earnings_screen.dart'; // NAYA IMPORT
import '../../products/screens/products_management_screen.dart';
import '../../orders/orders_management_screen.dart';

class DashboardLayout extends StatefulWidget {
  final String? businessId; // Changed to businessId

  const DashboardLayout({
    Key? key,
    this.businessId,
  }) : super(key: key);

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  int _selectedIndex = 0;
  
  late String _currentBusinessType;
  List<Map<String, dynamic>> _itemsList = [];

  int get activeItemsCount => _itemsList.where((item) => item['isActive'] == true).length;

  @override
  void initState() {
    super.initState();
    _currentBusinessType = 'grocery'; // Default, will be updated by DashboardScreen
  }

  void _changeBusiness(String newType) {
    if (_currentBusinessType == newType) return;
    setState(() {
      _currentBusinessType = newType;
    });
  }

  String get itemName {
    if (_currentBusinessType == "restaurant") return "Menu";
    if (_currentBusinessType == "medical") return "Medicines";
    return "Products";
  }

  String get businessName {
    if (_currentBusinessType == "restaurant") return "Restaurant";
    if (_currentBusinessType == "medical") return "Medical";
    return "Store";
  }

  Future<void> _addNewItem() async {
    final newProduct = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(
          businessType: _currentBusinessType,
          businessName: businessName,
        ),
      ),
    );

    if (newProduct != null) {
      setState(() {
        _itemsList.insert(0, newProduct); 
        _selectedIndex = 1; 
      });
    }
  }

  Future<void> _editItem(int index, Map<String, dynamic> item) async {
    final updatedProduct = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(
          businessType: _currentBusinessType,
          businessName: businessName,
          existingProduct: item,
        ),
      ),
    );

    if (updatedProduct != null) {
      setState(() {
        _itemsList[index] = updatedProduct;
      });
    }
  }

  void _deleteItem(int index) {
    setState(() {
      _itemsList.removeAt(index);
    });
  }

  void _toggleItemStatus(int index, bool status) {
    setState(() {
      _itemsList[index]['isActive'] = status;
    });
  }

  // NAYE NAVIGATION FUNCTIONS
  void _navigateToOrders() => setState(() => _selectedIndex = 2);
  void _navigateToEarnings() => setState(() => _selectedIndex = 3);

  List<_NavItem> get _navItems => [
        const _NavItem(icon: LucideIcons.layoutDashboard, label: 'Home'),
        _NavItem(icon: LucideIcons.package, label: itemName),
        const _NavItem(icon: LucideIcons.clipboardList, label: 'Orders'),
        const _NavItem(icon: LucideIcons.wallet, label: 'Earnings'),
      ];

  List<Widget> get _pages => [
        // Home Tab
        DashboardScreen(
          businessId: widget.businessId,
          onBusinessChanged: _changeBusiness,
          activeCount: activeItemsCount,
          onAddProductTap: _addNewItem,
          onViewProductsTap: () => setState(() => _selectedIndex = 1), 
          onOrdersTap: _navigateToOrders, // Callbacks Pass Kiye
          onRevenueTap: _navigateToEarnings, // Callbacks Pass Kiye
        ),
        // Products Tab
        ProductsManagementScreen(
          businessType: _currentBusinessType,
          items: _itemsList,
          onToggleStatus: _toggleItemStatus,
          onDelete: _deleteItem,
          onEdit: _editItem,
          onAddNew: _addNewItem,
        ),
        // Orders Tab
        OrdersManagementScreen(
          businessType: _currentBusinessType,
        ),
        // Earnings Tab NAYA!
        EarningsScreen(
          businessType: _currentBusinessType,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    if (widget.businessId == null || widget.businessId!.isEmpty) {
      return _buildNoBusinessView();
    }

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: Responsive(
        mobile: Column(children: [Expanded(child: _pages[_selectedIndex])]),
        tablet: Row(children: [_buildSidebar(), Expanded(child: _pages[_selectedIndex])]),
        desktop: Row(children: [_buildSidebar(), Expanded(child: _pages[_selectedIndex])]),
      ),
      bottomNavigationBar: Responsive.isMobile(context) ? _buildPremiumBottomNav() : null,
    );
  }

  Widget _buildNoBusinessView() {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: AppColors.kBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: AppColors.kDarkText),
            onPressed: () async {
              final hasPin = await AuthService.isPinSet();
              if (hasPin) {
                if (mounted) context.go('/pin-login');
              } else {
                await FirebaseAuth.instance.signOut();
                if (mounted) context.go('/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEF5),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.kPrimary, width: 2.5),
                ),
                child: const Icon(LucideIcons.store, color: AppColors.kPrimary, size: 52),
              ),
              const SizedBox(height: 28),
              const Text(
                'No Business\nRegistered',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.kDarkText,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You haven\'t registered a business yet. Register your business to access the dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.kLightText, fontSize: 14, height: 1.55),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.go('/business-type');
                  },
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Register Business', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kWhite,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_navItems.length, (i) => _buildNavTab(i)),
          ),
        ),
      ),
    );
  }

  Widget _buildNavTab(int index) {
    final item = _navItems[index];
    final isActive = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: isActive ? 18 : 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.kPrimary.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(item.icon, key: ValueKey('$index-$isActive'), size: 20, color: isActive ? AppColors.kPrimary : AppColors.kLightText),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: isActive
                  ? Row(
                      children: [
                        const SizedBox(width: 7),
                        Text(item.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.kPrimary, letterSpacing: -0.2)),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppColors.kWhite,
        border: Border(right: BorderSide(color: AppColors.kBorder.withOpacity(0.7))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 36),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: AppColors.kPrimary, borderRadius: BorderRadius.circular(13)),
                  child: const Icon(LucideIcons.store, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My $businessName', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.kDarkText, letterSpacing: -0.3)),
                    const Text('Partner', style: TextStyle(fontSize: 12, color: AppColors.kLightText, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('MAIN MENU', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.kLightText.withOpacity(0.6), letterSpacing: 1.2)),
          ),
          const SizedBox(height: 8),
          ..._navItems.asMap().entries.map(
                (e) => _SidebarItem(
                  icon: e.value.icon,
                  title: e.value.label,
                  isSelected: _selectedIndex == e.key,
                  onTap: () => setState(() => _selectedIndex = e.key),
                ),
              ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({required this.icon, required this.title, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.kPrimary.withOpacity(0.09) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: isSelected ? AppColors.kPrimary.withOpacity(0.13) : AppColors.kBackground, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 17, color: isSelected ? AppColors.kPrimary : AppColors.kLightText),
            ),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? AppColors.kPrimary : AppColors.kDarkText, letterSpacing: -0.2)),
            if (isSelected) ...[
              const Spacer(),
              Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.kPrimary, shape: BoxShape.circle)),
            ],
          ],
        ),
      ),
    );
  }
}