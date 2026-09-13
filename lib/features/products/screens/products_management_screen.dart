import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/safe_image_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProductsManagementScreen extends StatefulWidget {
  final String businessType;
  final List<Map<String, dynamic>> items;
  final Function(int index, bool status) onToggleStatus;
  final Function(int index) onDelete;
  final Function(int index, Map<String, dynamic> updatedItem) onEdit;
  final VoidCallback onAddNew;

  const ProductsManagementScreen({
    Key? key,
    required this.businessType,
    required this.items,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onEdit,
    required this.onAddNew,
  }) : super(key: key);

  @override
  State<ProductsManagementScreen> createState() => _ProductsManagementScreenState();
}

class _ProductsManagementScreenState extends State<ProductsManagementScreen> {
  // NAYA: Filter State ('Total', 'Active', 'Inactive')
  String _selectedFilter = 'Total';

  String get itemName {
    if (widget.businessType == "restaurant") return "Menu Items";
    if (widget.businessType == "medical") return "Medicines";
    return "Products";
  }

  @override
  Widget build(BuildContext context) {
    // 1. Sirf is business type ke items filter karo
    final businessItems = widget.items.where((item) => 
      item['businessType'] == widget.businessType || item['businessType'] == null
    ).toList();

    // 2. Count calculate karo summary ke liye
    final activeCount = businessItems.where((i) => i['isActive'] == true || i['isActive'] == null).length;
    final inactiveCount = businessItems.length - activeCount;

    // 3. Current filter ke hisaab se list dikhao
    final displayItems = businessItems.where((item) {
      final isActive = item['isActive'] ?? true;
      if (_selectedFilter == 'Active') return isActive;
      if (_selectedFilter == 'Inactive') return !isActive;
      return true; // If 'Total'
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: AppColors.kBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.kDarkText, size: 22),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manage', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.kLightText, letterSpacing: 0.3)),
            Text(itemName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.kDarkText, letterSpacing: -0.5)),
          ],
        ),
        toolbarHeight: 64,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: widget.onAddNew,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(color: AppColors.kPrimary, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: AppColors.kPrimary.withOpacity(0.30), blurRadius: 12, offset: const Offset(0, 4))]),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(LucideIcons.plus, color: Colors.white, size: 15), SizedBox(width: 6), Text('Add New', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))],
                ),
              ),
            ),
          ),
        ],
      ),
      body: businessItems.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                _buildSummaryStrip(businessItems.length, activeCount, inactiveCount),
                Expanded(
                  child: displayItems.isEmpty 
                    ? _buildFilterEmptyState() 
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        physics: const BouncingScrollPhysics(),
                        itemCount: displayItems.length,
                        itemBuilder: (context, index) {
                          final item = displayItems[index];
                          // Original list ka index chahiye delete/edit karne ke liye
                          final originalIndex = widget.items.indexOf(item); 
                          
                          return _ProductCard(
                            item: item,
                            index: originalIndex,
                            businessType: widget.businessType,
                            onToggleStatus: widget.onToggleStatus,
                            onDelete: widget.onDelete,
                            onEdit: widget.onEdit,
                          );
                        },
                      ),
                ),
              ],
            ),
    );
  }

  // ── FILTER SUMMARY STRIP ─────────────────────────────
  Widget _buildSummaryStrip(int total, int active, int inactive) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(color: AppColors.kWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.kBorder.withOpacity(0.5))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _summaryChip(
              label: 'Total', 
              value: '$total', 
              color: AppColors.kPrimary, 
              bgColor: AppColors.kPrimary.withOpacity(0.09),
              filterName: 'Total'
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _summaryChip(
              label: 'Active', 
              value: '$active', 
              color: const Color(0xFF16A34A), 
              bgColor: const Color(0xFFDCFCE7),
              filterName: 'Active'
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _summaryChip(
              label: 'Inactive', 
              value: '$inactive', 
              color: const Color(0xFF9CA3AF), 
              bgColor: const Color(0xFFF3F4F6),
              filterName: 'Inactive'
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip({required String label, required String value, required Color color, required Color bgColor, required String filterName}) {
    final bool isSelected = _selectedFilter == filterName;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filterName;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : bgColor.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : Colors.transparent, 
            width: 1.5
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isSelected ? color : color.withOpacity(0.8), letterSpacing: -0.3)), 
            const SizedBox(width: 4), 
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? color : color.withOpacity(0.75)))),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.kPrimary.withOpacity(0.08), shape: BoxShape.circle), child: Icon(LucideIcons.package, size: 34, color: AppColors.kPrimary.withOpacity(0.7))),
            const SizedBox(height: 20),
            Text('No $itemName yet', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.kDarkText, letterSpacing: -0.3)),
            const SizedBox(height: 8),
            const Text('Add your first item to start\nreceiving orders.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.kLightText, height: 1.5)),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: widget.onAddNew,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                decoration: BoxDecoration(color: AppColors.kPrimary, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppColors.kPrimary.withOpacity(0.28), blurRadius: 16, offset: const Offset(0, 6))]),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(LucideIcons.plus, color: Colors.white, size: 16), SizedBox(width: 8), Text('Add First Item', style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700))]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.filter, size: 48, color: AppColors.kLightText.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('No $_selectedFilter items found.', style: const TextStyle(fontSize: 15, color: AppColors.kLightText, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  final String businessType;
  final Function(int, bool) onToggleStatus;
  final Function(int) onDelete;
  final Function(int, Map<String, dynamic>) onEdit;

  const _ProductCard({
    required this.item,
    required this.index,
    required this.businessType,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  int _currentImageIndex = 0;
  Timer? _timer;
  List<String> _images = [];

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startTimerIfNeeded();
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    if (widget.item['image'] != null) {
      _images = [widget.item['image']];
    } else {
      _images = List<String>.from(widget.item['images'] ?? []);
    }
    _currentImageIndex = 0;
    if (_images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (mounted) setState(() => _currentImageIndex = (_currentImageIndex + 1) % _images.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showDeleteDialog(BuildContext context, int index, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Item"),
        content: Text("Are you sure you want to delete '$name'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { Navigator.pop(ctx); widget.onDelete(index); }, child: const Text("Delete", style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = _images.isNotEmpty;
    final bool isActive = widget.item['isActive'] ?? true;
    final String id = widget.item['id'] ?? '#000';
    final String name = widget.item['name'] ?? '';
    final String brand = widget.item['brand'] ?? widget.item['restaurant'] ?? '';
    final bool isBestseller = widget.item['isBestseller'] == true;
    final bool? isVeg = widget.item['isVeg'];
    final String prepTime = widget.item['time'] ?? '';
    final String medForm = widget.item['form'] ?? '';
    final List<dynamic> variants = widget.item['variants'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: AppColors.kWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color: isActive ? AppColors.kBorder.withOpacity(0.5) : AppColors.kBorder.withOpacity(0.8)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))]),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageStack(hasImage),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FIX OVERFLOW: Top Row layout restructured
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                Text('ID: $id', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                if (isBestseller)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                                    decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3))), 
                                    child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(LucideIcons.star, size: 10, color: Color(0xFFF59E0B)), SizedBox(width: 3), Text('Bestseller', style: TextStyle(fontSize: 9, color: Color(0xFFB45309), fontWeight: FontWeight.bold))])
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Active Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(20)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 5, height: 5, decoration: BoxDecoration(color: isActive ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF), shape: BoxShape.circle)), const SizedBox(width: 4), Text(isActive ? 'Active' : 'Off', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: isActive ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF)))]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Name and Veg/Non-veg
                      Row(
                        children: [
                          if (widget.businessType == 'restaurant' && isVeg != null) ...[Icon(Icons.stop_circle_outlined, color: isVeg ? Colors.green : Colors.red, size: 16), const SizedBox(width: 6)],
                          Expanded(child: Text(name, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.kDarkText, letterSpacing: -0.3, height: 1.2))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (brand.isNotEmpty) Flexible(child: Text(brand, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.kLightText, fontWeight: FontWeight.w600))),
                          if (widget.businessType == 'restaurant' && prepTime.isNotEmpty) ...[const Text(' • ', style: TextStyle(color: Colors.grey)), Icon(LucideIcons.clock, size: 12, color: Colors.grey.shade600), const SizedBox(width: 2), Text(prepTime, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500))],
                          if (widget.businessType == 'medical' && medForm.isNotEmpty) ...[const Text(' • ', style: TextStyle(color: Colors.grey)), Icon(LucideIcons.pill, size: 12, color: Colors.grey.shade600), const SizedBox(width: 2), Text(medForm, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500))],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // MOVED: Variants ab image+details row ke neeche, FULL CARD WIDTH mein hain
          // taaki lamba naam/price/discount badge kabhi bhi overflow na ho.
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: variants.isNotEmpty
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: variants.map((v) => _buildVariantRow(v)).toList())
                : (widget.item['price'] != null
                    ? _buildVariantRow({'weight': widget.item['weight'] ?? '1 Unit', 'price': widget.item['price'], 'originalPrice': widget.item['originalPrice']})
                    : const SizedBox.shrink()),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: Row(
              children: [
                Text(isActive ? 'Visible to customers' : 'Hidden from listing', style: TextStyle(fontSize: 11.5, color: isActive ? const Color(0xFF16A34A) : AppColors.kLightText, fontWeight: FontWeight.w600)),
                const Spacer(),
                Transform.scale(scale: 0.82, alignment: Alignment.centerRight, child: Switch(value: isActive, onChanged: (val) => widget.onToggleStatus(widget.index, val), activeColor: Colors.white, activeTrackColor: const Color(0xFF16A34A), inactiveTrackColor: Colors.grey.shade300, inactiveThumbColor: Colors.white, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(color: AppColors.kBackground, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                if (_images.length > 1) Row(children: [const Icon(LucideIcons.image, size: 13, color: AppColors.kLightText), const SizedBox(width: 4), Text('${_images.length} photos', style: const TextStyle(fontSize: 11.5, color: AppColors.kLightText, fontWeight: FontWeight.w500))]),
                const Spacer(),
                _ActionBtn(icon: LucideIcons.trash2, label: 'Delete', color: const Color(0xFFEF4444), bgColor: const Color(0xFFFEF2F2), onTap: () => _showDeleteDialog(context, widget.index, widget.item['name'] ?? '')),
                const SizedBox(width: 8),
                _ActionBtn(icon: LucideIcons.pencil, label: 'Edit', color: AppColors.kPrimary, bgColor: AppColors.kPrimary.withOpacity(0.09), onTap: () => widget.onEdit(widget.index, widget.item)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantRow(Map<String, dynamic> variant) {
    final double price = (variant['price'] as num?)?.toDouble() ?? 0;
    final double? origPrice = (variant['originalPrice'] as num?)?.toDouble();
    final bool hasDiscount = origPrice != null && origPrice > price;
    final double discountPct = hasDiscount ? ((origPrice - price) / origPrice * 100) : 0;
    final String weight = variant['weight'] ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: AppColors.kBackground, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          if (weight.isNotEmpty)
            Text(weight, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text('₹${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.kPrimary)),
          if (hasDiscount) ...[
            Text('₹${origPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, decoration: TextDecoration.lineThrough, color: AppColors.kLightText, fontWeight: FontWeight.w500)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(4)),
              child: Text('${discountPct.toStringAsFixed(0)}% OFF', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFEA580C))),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageStack(bool hasImage) {
    return Stack(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(color: AppColors.kPrimary.withOpacity(0.07), borderRadius: BorderRadius.circular(16)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: hasImage
                ? AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: SafeImageWidget(
                      imageKey: ValueKey<String>(_images[_currentImageIndex]),
                      imagePath: _images[_currentImageIndex],
                      fit: BoxFit.cover,
                      width: 84,
                      height: 84,
                    ),
                  )
                : Icon(LucideIcons.image, color: AppColors.kPrimary.withOpacity(0.4), size: 28),
          ),
        ),
        if (_images.length > 1)
          Positioned(
            bottom: 7,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_images.length, (i) => AnimatedContainer(duration: const Duration(milliseconds: 300), width: i == _currentImageIndex ? 12 : 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: i == _currentImageIndex ? Colors.white : Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(3), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 3)]))),
            ),
          ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.label, required this.color, required this.bgColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(22)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: color), const SizedBox(width: 5), Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.1))]),
      ),
    );
  }
}