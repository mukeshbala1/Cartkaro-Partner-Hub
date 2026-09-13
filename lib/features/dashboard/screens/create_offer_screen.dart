import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CreateOfferScreen extends StatefulWidget {
  final String businessType;

  const CreateOfferScreen({Key? key, required this.businessType}) : super(key: key);

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  final TextEditingController _offerCodeController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _minOrderController = TextEditingController();
  
  bool _isPercentage = true; // True for %, False for Flat ₹
  DateTime? _validTill;

  @override
  void dispose() {
    _offerCodeController.dispose();
    _discountController.dispose();
    _minOrderController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    if (picked != null && picked != _validTill) {
      setState(() {
        _validTill = picked;
      });
    }
  }

  void _saveOffer() {
    if (_offerCodeController.text.isEmpty || _discountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Offer Code and Discount are required!")));
      return;
    }
    // TODO: Save to database logic here
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Offer Created Successfully!")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: AppColors.kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.kDarkText),
        title: const Text('Create Offer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.kDarkText)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Header
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFFFFBEB), shape: BoxShape.circle),
                child: const Icon(LucideIcons.tags, size: 48, color: Color(0xFFF59E0B)),
              ),
            ),
            const SizedBox(height: 32),

            // Offer Code
            _buildTextField("Offer Code (e.g., SUMMER50)", _offerCodeController, LucideIcons.ticket),
            const SizedBox(height: 20),

            // Discount Type Toggle
            const Text('Discount Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.kDarkText)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isPercentage = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isPercentage ? AppColors.kPrimary : AppColors.kWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _isPercentage ? AppColors.kPrimary : AppColors.kBorder),
                      ),
                      child: Center(child: Text("Percentage (%)", style: TextStyle(fontWeight: FontWeight.bold, color: _isPercentage ? Colors.white : AppColors.kDarkText))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isPercentage = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isPercentage ? AppColors.kPrimary : AppColors.kWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: !_isPercentage ? AppColors.kPrimary : AppColors.kBorder),
                      ),
                      child: Center(child: Text("Flat Amount (₹)", style: TextStyle(fontWeight: FontWeight.bold, color: !_isPercentage ? Colors.white : AppColors.kDarkText))),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Discount Value & Min Order
            Row(
              children: [
                Expanded(child: _buildTextField(_isPercentage ? "Discount (%)" : "Discount (₹)", _discountController, LucideIcons.percent, isNumber: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField("Min Order (₹)", _minOrderController, LucideIcons.indianRupee, isNumber: true)),
              ],
            ),
            const SizedBox(height: 20),

            // Valid Till Date Picker
            const Text('Valid Till', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.kDarkText)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.kWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.kBorder.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.calendar, color: AppColors.kLightText),
                    const SizedBox(width: 12),
                    Text(
                      _validTill == null ? "Select Expiry Date" : "${_validTill!.day}/${_validTill!.month}/${_validTill!.year}",
                      style: TextStyle(fontSize: 16, color: _validTill == null ? AppColors.kLightText : AppColors.kDarkText),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Launch Offer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.kDarkText)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.kWhite,
            prefixIcon: Icon(icon, color: AppColors.kLightText),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.kBorder.withOpacity(0.5))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.kBorder.withOpacity(0.5))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kPrimary, width: 2)),
          ),
        ),
      ],
    );
  }
}