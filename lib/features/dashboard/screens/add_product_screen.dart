import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/safe_image_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AddProductScreen extends StatefulWidget {
  final String businessType;
  final String businessName; // NAYA: Auto-fill ke liye
  final Map<String, dynamic>? existingProduct;

  const AddProductScreen({
    Key? key,
    required this.businessType,
    required this.businessName, // Ensure you pass this from Layout!
    this.existingProduct,
  }) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();
  final TextEditingController _medFormController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  bool _isActive = true;
  bool _isBestseller = false;
  bool? _isVeg;

  double _finalPrice = 0.0;
  List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategory;
  String? _selectedSubcategory; // NAYA: Subcategory ke liye
  List<Map<String, dynamic>> _variants = [];

  String get itemName {
    if (widget.businessType == "restaurant") return "Menu Item";
    if (widget.businessType == "medical") return "Medicine";
    return "Product";
  }

  // ════════════════════════════════════════════════════════════════
  // CATEGORY → SUBCATEGORY DATA  (single source of truth)
  // Category select karte hi subcategory field neeche open hoga
  // ════════════════════════════════════════════════════════════════
  Map<String, List<String>> get _categoryMap {
    switch (widget.businessType) {
      case 'restaurant':
        return {
          'Recommended': ['Bestseller', 'Chef Special', "Today's Special"],
          'Veg': ['Starter', 'Main Course', 'Curry', 'Combo', 'Thali'],
          'Non Veg': ['Chicken', 'Mutton', 'Fish', 'Seafood', 'Egg Items', 'Non Veg Combo'],
          'North Indian': ['Paneer', 'Dal', 'Curry', 'Roti', 'Naan', 'Paratha', 'Thali'],
          'South Indian': ['Dosa', 'Idli', 'Vada', 'Uttapam', 'Upma', 'South Meals'],
          'Chinese': ['Noodles', 'Fried Rice', 'Manchurian', 'Momos', 'Soup', 'Spring Roll'],
          'Biryani': ['Veg Biryani', 'Chicken Biryani', 'Mutton Biryani', 'Egg Biryani', 'Family Pack'],
          'Pizza': ['Veg Pizza', 'Non Veg Pizza', 'Cheese Pizza', 'Premium Pizza'],
          'Burger & Sandwich': ['Veg Burger', 'Chicken Burger', 'Sandwich', 'Sub'],
          'Rolls & Wraps': ['Veg Roll', 'Egg Roll', 'Chicken Roll'],
          'Fast Food': ['Fries', 'Pasta', 'Maggie', 'Nuggets', 'Snacks'],
          'Street Food': ['Chaat', 'Pani Puri', 'Pav Bhaji', 'Samosa', 'Kachori'],
          'Tandoor & Grill': ['Tikka', 'Kebab', 'Grill Chicken', 'BBQ'],
          'Healthy Food': ['Salad', 'Diet Meal', 'Protein Meal', 'Vegan', 'Keto'],
          'Bakery': ['Cake', 'Pastry', 'Donut', 'Cookies'],
          'Dessert': ['Ice Cream', 'Sweet', 'Brownie', 'Pudding'],
          'Beverages': ['Tea', 'Coffee', 'Juice', 'Shake', 'Smoothie', 'Mocktail', 'Cold Drink'],
        };
      case 'medical':
        return {
          'Medicine': ['Prescription Medicine', 'OTC Medicine', 'Tablet', 'Capsule', 'Syrup', 'Injection', 'Drops', 'Ointment'],
          'Health Condition': ['Fever', 'Cold & Cough', 'Pain Relief', 'Allergy', 'Diabetes', 'Blood Pressure', 'Heart Care', 'Digestion', 'Eye Care', 'Ear Care'],
          'Ayurvedic': ['Herbal Medicine', 'Ayurvedic Tablet', 'Herbal Juice', 'Natural Care'],
          'Homeopathy': ['Homeopathy Medicine', 'Drops', 'Tablets'],
          'Vitamins & Nutrition': ['Multivitamin', 'Vitamin C', 'Vitamin D', 'Calcium', 'Protein', 'Immunity Booster'],
          'Fitness': ['Whey Protein', 'Weight Gain', 'Weight Loss', 'Energy Products'],
          'Personal Care': ['Skin Care', 'Hair Care', 'Oral Care', 'Bath Care', 'Hygiene'],
          'Baby Care': ['Baby Medicine', 'Baby Food', 'Diapers', 'Baby Skin Products'],
          'Women Care': ['Sanitary Products', 'Pregnancy Test Kit', 'Women Supplements'],
          'Medical Devices': ['Thermometer', 'BP Monitor', 'Glucometer', 'Oximeter', 'Nebulizer', 'Weighing Scale'],
          'First Aid': ['Bandage', 'Cotton', 'Antiseptic', 'Medical Tape', 'First Aid Box'],
          'Surgical': ['Gloves', 'Mask', 'Syringe', 'Dressing Items'],
          'Orthopedic': ['Knee Support', 'Belt Support', 'Neck Support'],
          'Elder Care': ['Adult Diaper', 'Walking Stick', 'Healthcare Equipment'],
          'Sexual Wellness': ['Condom', 'Lubricants'],
          'Covid Essentials': ['Mask', 'Sanitizer', 'Testing Kit'],
        };
      default: // grocery
        return {
          'Fruits & Vegetables': [
            'Fresh Fruits', 'Fresh Vegetables', 'Leafy Vegetables', 'Exotic Fruits',
            'Exotic Vegetables', 'Organic Fruits & Vegetables', 'Cut Fruits',
            'Cut Vegetables', 'Herbs', 'Sprouts', 'Flowers',
          ],
          'Dairy, Bread & Eggs': [
            'Milk', 'Curd', 'Paneer', 'Cheese', 'Butter', 'Ghee', 'Cream', 'Yogurt',
            'Milk Drinks', 'Bread', 'Buns', 'Bakery Items', 'Eggs',
          ],
          'Atta, Rice & Grains': [
            'Atta', 'Wheat', 'Rice', 'Basmati Rice', 'Brown Rice', 'Maida', 'Besan',
            'Sooji', 'Millets', 'Other Grains',
          ],
          'Dal & Pulses': [
            'Toor Dal', 'Moong Dal', 'Masoor Dal', 'Chana Dal', 'Urad Dal', 'Rajma',
            'Chole', 'Soya Products',
          ],
          'Oil & Ghee': [
            'Sunflower Oil', 'Mustard Oil', 'Groundnut Oil', 'Olive Oil',
            'Coconut Oil', 'Cooking Oil', 'Ghee',
          ],
          'Masala & Cooking Needs': [
            'Whole Spices', 'Powder Spices', 'Salt', 'Sugar', 'Jaggery',
            'Cooking Paste', 'Vinegar', 'Sauces', 'Pickles', 'Ready Masala',
          ],
          'Breakfast Food': [
            'Oats', 'Cornflakes', 'Muesli', 'Peanut Butter', 'Jam', 'Honey', 'Spreads',
          ],
          'Instant Food': [
            'Noodles', 'Pasta', 'Soup', 'Ready To Cook', 'Ready To Eat', 'Frozen Snacks',
          ],
          'Snacks': [
            'Chips', 'Namkeen', 'Biscuits', 'Cookies', 'Popcorn', 'Dry Snacks', 'Healthy Snacks',
          ],
          'Chocolate & Sweets': [
            'Chocolate', 'Candy', 'Indian Sweets', 'Dessert Mix', 'Ice Cream', 'Gift Packs',
          ],
          'Beverages': [
            'Tea', 'Coffee', 'Juice', 'Soft Drinks', 'Energy Drinks', 'Health Drinks', 'Water', 'Soda',
          ],
          'Dry Fruits': [
            'Almonds', 'Cashew', 'Raisins', 'Dates', 'Pistachio', 'Seeds',
          ],
          'Meat & Seafood': [
            'Chicken', 'Mutton', 'Fish', 'Prawns', 'Eggs', 'Frozen Meat',
          ],
          'Household Cleaning': [
            'Detergent', 'Dishwash', 'Floor Cleaner', 'Toilet Cleaner', 'Room Freshener',
            'Cleaning Tools', 'Garbage Bags', 'Pest Control',
          ],
          'Personal Care': [
            'Soap', 'Shampoo', 'Conditioner', 'Face Wash', 'Body Wash', 'Hair Oil',
            'Skin Care', 'Perfume', 'Deodorant', 'Men Grooming', 'Women Hygiene',
          ],
          'Baby Care': [
            'Baby Food', 'Baby Milk', 'Diapers', 'Wipes', 'Baby Soap', 'Baby Oil', 'Baby Cream',
          ],
          'Pet Care': [
            'Dog Food', 'Cat Food', 'Pet Treats', 'Pet Accessories', 'Pet Healthcare',
          ],
          'Home & Kitchen': [
            'Kitchen Tools', 'Storage Items', 'Cookware', 'Disposable Items',
            'Batteries', 'Bulbs', 'Small Appliances',
          ],
          'Stationery': [
            'Notebook', 'Pen', 'Pencil', 'Art Supplies', 'Office Items',
          ],
          'Pooja Needs': [
            'Agarbatti', 'Diya', 'Camphor', 'Puja Oil', 'Religious Items',
          ],
        };
    }
  }

  List<String> get _subcategoryOptions =>
      _selectedCategory != null ? (_categoryMap[_selectedCategory] ?? []) : [];

  @override
  void initState() {
    super.initState();
    if (widget.existingProduct != null) {
      final p = widget.existingProduct!;
      _nameController.text = p['name'] ?? '';
      _brandController.text = p['brand'] ?? p['restaurant'] ?? widget.businessName;
      _descriptionController.text = p['description'] ?? '';
      _originalPriceController.text = (p['originalPrice'] ?? '').toString();
      _discountController.text = (p['discountPercent'] ?? '').toString();
      _isActive = p['isActive'] ?? true;
      _isBestseller = p['isBestseller'] ?? false;
      _isVeg = p['isVeg'];
      _selectedCategory = p['category'];
      _selectedSubcategory = p['subcategory']; // NAYA

      if (widget.businessType == 'restaurant') _prepTimeController.text = p['time'] ?? '';
      if (widget.businessType == 'medical') _medFormController.text = p['form'] ?? '';

      if (p['variants'] != null) {
        _variants = List<Map<String, dynamic>>.from(p['variants']);
      }

      if (p['images'] != null && p['images'] is List) {
        List<String> savedPaths = List<String>.from(p['images']);
        _images = savedPaths.map((path) => XFile(path)).toList();
      } else if (p['image'] != null) {
        _images = [XFile(p['image'])];
      }

      _calculateSinglePriceDiscount();
    } else {
      // FIX: Auto-fill brand/restaurant name for new items!
      _brandController.text = widget.businessName;
    }

    _originalPriceController.addListener(_calculateSinglePriceDiscount);
    _discountController.addListener(_calculateSinglePriceDiscount);
  }

  void _calculateSinglePriceDiscount() {
    double original = double.tryParse(_originalPriceController.text) ?? 0.0;
    double discount = double.tryParse(_discountController.text) ?? 0.0;

    if (original > 0) {
      setState(() {
        _finalPrice = original - (original * (discount / 100));
      });
    } else {
      setState(() { _finalPrice = 0.0; });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> selectedImages = await _picker.pickMultiImage();
        if (selectedImages.isNotEmpty) setState(() { _images.addAll(selectedImages); });
      } else {
        final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
        if (photo != null) setState(() { _images.add(photo); });
      }
    } catch (e) {
      debugPrint("Image picking failed: $e");
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(LucideIcons.camera, color: AppColors.kPrimary), title: const Text('Take a Photo'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
            ListTile(leading: const Icon(LucideIcons.image, color: AppColors.kPrimary), title: const Text('Choose from Gallery'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
          ],
        ),
      ),
    );
  }

  void _addVariantModal() {
    final TextEditingController vWeight = TextEditingController();
    final TextEditingController vOriginal = TextEditingController();
    final TextEditingController vDiscount = TextEditingController();
    double vFinal = 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          void calc() {
            double orig = double.tryParse(vOriginal.text) ?? 0;
            double disc = double.tryParse(vDiscount.text) ?? 0;
            setModalState(() { vFinal = orig - (orig * (disc / 100)); });
          }
          vOriginal.addListener(calc);
          vDiscount.addListener(calc);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Add Variant", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: vWeight, decoration: const InputDecoration(labelText: "Weight/Size (e.g. 500g, 1 pc)", border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: vOriginal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Orig Price (₹)", border: OutlineInputBorder()))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: vDiscount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Discount (%)", border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 12),
                Text("Selling Price: ₹${vFinal.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.kPrimary)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (vWeight.text.isNotEmpty && vOriginal.text.isNotEmpty) {
                        setState(() {
                          _variants.add({'weight': vWeight.text, 'originalPrice': double.parse(vOriginal.text), 'price': vFinal});
                        });
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimary),
                    child: const Text("Add Variant", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _saveProduct() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product Name is required!")));
      return;
    }
    if (_variants.isEmpty && _originalPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add a price or variant!")));
      return;
    }

    String generatedId = widget.existingProduct?['id'] ?? '${widget.businessType[0]}${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    final savedProduct = {
      'id': generatedId,
      'businessType': widget.businessType, // NAYA: Save the business type to filter it later
      'name': _nameController.text,
      'brand': _brandController.text,
      'restaurant': _brandController.text, // Same as brand for restaurants
      'description': _descriptionController.text,
      'isActive': _isActive,
      'isBestseller': _isBestseller,
      'category': _selectedCategory,
      'subcategory': _selectedSubcategory, // NAYA
      'images': _images.map((e) => e.path).toList(),
      'variants': _variants,
    };

    if (widget.businessType == 'restaurant') {
      savedProduct['isVeg'] = _isVeg;
      savedProduct['time'] = _prepTimeController.text;
    } else if (widget.businessType == 'medical') {
      savedProduct['form'] = _medFormController.text;
    }

    if (_variants.isEmpty) {
      savedProduct['originalPrice'] = double.tryParse(_originalPriceController.text) ?? 0.0;
      savedProduct['discountPercent'] = double.tryParse(_discountController.text) ?? 0.0;
      savedProduct['price'] = _finalPrice;
    } else {
      savedProduct['price'] = _variants.first['price'];
      savedProduct['originalPrice'] = _variants.first['originalPrice'];
    }

    Navigator.pop(context, savedProduct);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _prepTimeController.dispose();
    _medFormController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.existingProduct != null;

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: AppColors.kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.kDarkText),
        title: Text(
          isEditing ? 'Edit $itemName' : 'Add New $itemName',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.kDarkText),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images
            const Text('Upload Images', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  GestureDetector(
                    onTap: _showImageSourceActionSheet,
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(color: AppColors.kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.kPrimary.withOpacity(0.5))),
                      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(LucideIcons.plus, color: AppColors.kPrimary), SizedBox(height: 4), Text('Add Photo', style: TextStyle(fontSize: 12, color: AppColors.kPrimary))]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ..._images.asMap().entries.map((entry) {
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.kPrimary.withOpacity(0.07),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SafeImageWidget(
                              imagePath: entry.value.path,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(right: 16, top: 4, child: GestureDetector(onTap: () { setState(() { _images.removeAt(entry.key); }); }, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white)))),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Basic Info
            _buildTextField("Name", _nameController, LucideIcons.tag),
            const SizedBox(height: 16),
            _buildTextField(widget.businessType == 'restaurant' ? "Restaurant Name" : "Brand Name", _brandController, LucideIcons.briefcase),
            const SizedBox(height: 16),

            // ════════════════════════════════════════════════════
            // Category Dropdown (Main Category)
            // ════════════════════════════════════════════════════
            const Text("Category", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.kDarkText)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.kBorder.withOpacity(0.5))),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  hint: const Text("Select Category"),
                  isExpanded: true,
                  items: _categoryMap.keys
                      .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setState(() {
                    _selectedCategory = val;
                    _selectedSubcategory = null; // category badalne par subcategory reset
                  }),
                ),
              ),
            ),

            // ════════════════════════════════════════════════════
            // Subcategory Dropdown — Category select hote hi yeh
            // field neeche open hota hai
            // ════════════════════════════════════════════════════
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: _selectedCategory == null
                  ? const SizedBox(width: double.infinity, height: 0)
                  : Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Subcategory", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.kDarkText)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.kBorder.withOpacity(0.5))),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSubcategory,
                                hint: const Text("Select Subcategory"),
                                isExpanded: true,
                                items: _subcategoryOptions
                                    .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (val) => setState(() => _selectedSubcategory = val),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Business Specific Details
            if (widget.businessType == 'restaurant') ...[
              _buildTextField("Preparation Time (e.g. 30 Mins)", _prepTimeController, LucideIcons.clock),
              const SizedBox(height: 16),

              // FIX: Veg / Non-Veg Layout Issue!
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isVeg = true),
                      child: Row(
                        children: [
                          Radio<bool>(value: true, groupValue: _isVeg, activeColor: Colors.green, onChanged: (v) => setState(() => _isVeg = v)),
                          const Text("Veg", style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isVeg = false),
                      child: Row(
                        children: [
                          Radio<bool>(value: false, groupValue: _isVeg, activeColor: Colors.red, onChanged: (v) => setState(() => _isVeg = v)),
                          const Flexible(child: Text("Non-Veg", overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (widget.businessType == 'medical') ...[
              _buildTextField("Medicine Form (e.g. Tablet, Syrup)", _medFormController, LucideIcons.pill),
              const SizedBox(height: 16),
            ],

            // Pricing & Variants
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pricing & Variants', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                TextButton.icon(onPressed: _addVariantModal, icon: const Icon(Icons.add, size: 16), label: const Text("Add Variant"))
              ],
            ),
            const SizedBox(height: 8),

            if (_variants.isEmpty) ...[
              Row(
                children: [
                  Expanded(child: _buildTextField("Orig Price (₹)", _originalPriceController, LucideIcons.indianRupee, isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("Discount (%)", _discountController, LucideIcons.percent, isNumber: true)),
                ],
              ),
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Selling Price:', style: TextStyle(fontWeight: FontWeight.w600)), Text('₹${_finalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.kPrimary))])),
            ] else ...[
              Column(
                children: _variants.asMap().entries.map((e) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.value['weight'], style: const TextStyle(fontWeight: FontWeight.bold)), Text("₹${e.value['price']} (Orig: ₹${e.value['originalPrice']})", style: const TextStyle(fontSize: 12, color: Colors.grey))]),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _variants.removeAt(e.key))),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),
            _buildTextField("Description", _descriptionController, LucideIcons.alignLeft, maxLines: 3),
            const SizedBox(height: 24),

            // Toggles
            SwitchListTile(title: const Text('Mark as Bestseller', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFB45309))), secondary: const Icon(LucideIcons.star, color: Color(0xFFF59E0B)), value: _isBestseller, activeColor: const Color(0xFFF59E0B), contentPadding: EdgeInsets.zero, onChanged: (val) { setState(() => _isBestseller = val); }),
            SwitchListTile(title: const Text('Mark as Active', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: const Text('Visible to customers'), value: _isActive, activeColor: AppColors.kPrimary, contentPadding: EdgeInsets.zero, onChanged: (val) { setState(() => _isActive = val); }),

            const SizedBox(height: 40),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveProduct, style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(isEditing ? "Update $itemName" : "Save $itemName", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)))),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.kDarkText)),
        const SizedBox(height: 8),
        TextField(controller: controller, keyboardType: isNumber ? TextInputType.number : TextInputType.text, maxLines: maxLines, decoration: InputDecoration(filled: true, fillColor: AppColors.kWhite, prefixIcon: maxLines == 1 ? Icon(icon, color: AppColors.kLightText) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.kBorder.withOpacity(0.5))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.kBorder.withOpacity(0.5))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kPrimary, width: 2)))),
      ],
    );
  }
}