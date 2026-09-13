// ══════════════════════════════════════════════════════════════════
// business_settings_screen.dart  — v3 FINAL
//
// ALL FIXES:
//   ✅ Delivery Time slider crash fixed (safe clamping, static range)
//   ✅ Temporary Close: Today / 3 Days / 7 Days properly work
//   ✅ Delivery Availability: full day-selector sheet working
//   ✅ Out of Stock Management: proper options sheet
//   ✅ Stock Update Reminder: proper time-picker sheet
//   ✅ Selling Categories: new section (Grocery / Restaurant / Medical)
//   ✅ Update Images: camera + gallery with live preview
//   ✅ Update Address: geolocator + geocoding + manual fields
//
// DEPENDENCIES (pubspec.yaml):
//   image_picker: ^1.0.4
//   geolocator: ^10.1.0
//   geocoding: ^2.1.1
//   lucide_icons: ^0.0.27
// ══════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'document_manage_page.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/business_model.dart';

import '../../auth/screens/grocery_registration_screen.dart';
import '../../auth/screens/restaurant_registration_screen.dart';
import '../../auth/screens/medical_registration_screen.dart';
import '../../auth/screens/pin_login_screen.dart';
import '../../auth/screens/login_screen.dart';

import 'help_center_screen.dart';
import 'chat_support_screen.dart';
import 'call_support_screen.dart';
import 'faq_screen.dart';
import 'report_problem_screen.dart';
// ════════════════════════════════════════════════════════════════
// COLOUR HELPERS
// ════════════════════════════════════════════════════════════════
extension _C on BuildContext {
  Color get kP  => AppColors.kPrimary;
  Color get kPL => AppColors.kPrimary.withOpacity(0.10);
  Color get kPB => AppColors.kPrimary.withOpacity(0.22);
}

// ════════════════════════════════════════════════════════════════
// SELLING CATEGORY DATA  (single source of truth)
// ════════════════════════════════════════════════════════════════

class BusinessCategoryData {
  static List<Map<String, String>> getCategories(String businessType) {
    switch (businessType) {

      // 🔴 RESTAURANT
      case 'restaurant':
        return [
          {'id': 'recommended', 'name': 'Recommended', 'emoji': '⭐'},
          {'id': 'pure_veg', 'name': 'Pure Veg', 'emoji': '🥗'},
          {'id': 'non_veg', 'name': 'Non Veg', 'emoji': '🍗'},
          {'id': 'veg_nonveg', 'name': 'Veg & Non Veg', 'emoji': '🍱'},

          {'id': 'north_indian', 'name': 'North Indian', 'emoji': '🍛'},
          {'id': 'south_indian', 'name': 'South Indian', 'emoji': '🍚'},
          {'id': 'chinese', 'name': 'Chinese', 'emoji': '🍜'},
          {'id': 'italian', 'name': 'Italian', 'emoji': '🍝'},
          {'id': 'continental', 'name': 'Continental', 'emoji': '🍽️'},

          {'id': 'biryani', 'name': 'Biryani', 'emoji': '🥘'},
          {'id': 'pizza', 'name': 'Pizza', 'emoji': '🍕'},
          {'id': 'burger', 'name': 'Burger', 'emoji': '🍔'},
          {'id': 'sandwich', 'name': 'Sandwich', 'emoji': '🥪'},
          {'id': 'rolls', 'name': 'Rolls & Wraps', 'emoji': '🌯'},

          {'id': 'fast_food', 'name': 'Fast Food', 'emoji': '🍟'},
          {'id': 'street_food', 'name': 'Street Food', 'emoji': '🥟'},
          {'id': 'tandoor', 'name': 'Tandoor & Grill', 'emoji': '🍖'},

          {'id': 'breakfast', 'name': 'Breakfast', 'emoji': '🍳'},
          {'id': 'healthy_food', 'name': 'Healthy Food', 'emoji': '🥬'},
          {'id': 'seafood', 'name': 'Seafood', 'emoji': '🦐'},

          {'id': 'cafe', 'name': 'Cafe', 'emoji': '☕'},
          {'id': 'bakery', 'name': 'Bakery', 'emoji': '🎂'},
          {'id': 'desserts', 'name': 'Desserts', 'emoji': '🍨'},
          {'id': 'ice_cream', 'name': 'Ice Cream', 'emoji': '🍦'},
          {'id': 'beverages', 'name': 'Beverages', 'emoji': '🥤'},
        ];


      // 🔵 MEDICAL
      case 'medical':
        return [
          {'id': 'rx_medicines', 'name': 'Prescription Medicines', 'emoji': '💊'},
          {'id': 'otc_medicines', 'name': 'OTC Medicines', 'emoji': '💉'},
          {'id': 'ayurvedic', 'name': 'Ayurvedic Medicines', 'emoji': '🌿'},
          {'id': 'homeopathy', 'name': 'Homeopathy', 'emoji': '🍀'},

          {'id': 'health_condition', 'name': 'Health Conditions', 'emoji': '❤️'},
          {'id': 'diabetes', 'name': 'Diabetes Care', 'emoji': '💉'},
          {'id': 'heart_care', 'name': 'Heart Care', 'emoji': '❤️'},
          {'id': 'pain_relief', 'name': 'Pain Relief', 'emoji': '🤕'},

          {'id': 'supplements', 'name': 'Supplements', 'emoji': '🧪'},
          {'id': 'vitamins', 'name': 'Vitamins', 'emoji': '🍊'},
          {'id': 'fitness', 'name': 'Fitness Nutrition', 'emoji': '💪'},

          {'id': 'personal_care', 'name': 'Personal Care', 'emoji': '🧴'},
          {'id': 'skin_care', 'name': 'Skin Care', 'emoji': '✨'},
          {'id': 'hair_care', 'name': 'Hair Care', 'emoji': '💇'},

          {'id': 'baby_care', 'name': 'Baby Care', 'emoji': '👶'},
          {'id': 'women_care', 'name': 'Women Care', 'emoji': '🌸'},
          {'id': 'elder_care', 'name': 'Elder Care', 'emoji': '👴'},

          {'id': 'health_devices', 'name': 'Healthcare Devices', 'emoji': '🩺'},
          {'id': 'surgical', 'name': 'Surgical Items', 'emoji': '🏥'},
          {'id': 'ortho', 'name': 'Orthopedic Products', 'emoji': '🦴'},

          {'id': 'hygiene', 'name': 'Hygiene Products', 'emoji': '🧼'},
          {'id': 'first_aid', 'name': 'First Aid', 'emoji': '🚑'},
          {'id': 'eye_care', 'name': 'Eye Care', 'emoji': '👁'},
          {'id': 'dental', 'name': 'Dental Care', 'emoji': '🦷'},
          {'id': 'sexual_wellness', 'name': 'Sexual Wellness', 'emoji': '🛡️'},
          {'id': 'covid', 'name': 'Covid Essentials', 'emoji': '😷'},
        ];


      // 🟢 GROCERY
      default:
        return [
          {'id': 'fruits_veg', 'name': 'Fruits & Vegetables', 'emoji': '🥦'},
          {'id': 'dairy', 'name': 'Dairy Products', 'emoji': '🥛'},
          {'id': 'bakery', 'name': 'Bakery', 'emoji': '🍞'},
          {'id': 'eggs', 'name': 'Eggs', 'emoji': '🥚'},

          {'id': 'rice_grains', 'name': 'Rice & Grains', 'emoji': '🌾'},
          {'id': 'dal_pulses', 'name': 'Dal & Pulses', 'emoji': '🫘'},
          {'id': 'atta_flour', 'name': 'Atta & Flour', 'emoji': '🌾'},

          {'id': 'oil_ghee', 'name': 'Oil & Ghee', 'emoji': '🛢️'},
          {'id': 'masala', 'name': 'Masala & Spices', 'emoji': '🌶️'},

          {'id': 'breakfast', 'name': 'Breakfast Food', 'emoji': '🥣'},
          {'id': 'instant_food', 'name': 'Instant Food', 'emoji': '🍜'},
          {'id': 'frozen', 'name': 'Frozen Food', 'emoji': '❄️'},

          {'id': 'snacks', 'name': 'Snacks', 'emoji': '🍿'},
          {'id': 'sweets', 'name': 'Sweets & Chocolates', 'emoji': '🍫'},
          {'id': 'dry_fruits', 'name': 'Dry Fruits', 'emoji': '🥜'},

          {'id': 'beverages', 'name': 'Beverages', 'emoji': '🥤'},

          {'id': 'meat', 'name': 'Meat Products', 'emoji': '🥩'},
          {'id': 'seafood', 'name': 'Seafood', 'emoji': '🐟'},

          {'id': 'household', 'name': 'Household Items', 'emoji': '🏠'},
          {'id': 'cleaning', 'name': 'Cleaning Supplies', 'emoji': '🧹'},

          {'id': 'personal_care', 'name': 'Personal Care', 'emoji': '🧴'},
          {'id': 'baby_care', 'name': 'Baby Care', 'emoji': '🍼'},
          {'id': 'pet_care', 'name': 'Pet Care', 'emoji': '🐶'},

          {'id': 'home_kitchen', 'name': 'Home & Kitchen', 'emoji': '🍳'},
          {'id': 'stationery', 'name': 'Stationery', 'emoji': '✏️'},
          {'id': 'pooja', 'name': 'Pooja Needs', 'emoji': '🪔'},
        ];
    }
  }
}

// ════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.kWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.kBorder.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(color: context.kPL, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 15, color: context.kP)),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.kDarkText, letterSpacing: -0.3)),
            ]),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          child,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool destructive;
  const _Tile({required this.icon, required this.title, this.subtitle, this.trailing, this.onTap, this.showChevron = true, this.destructive = false});

  @override
  Widget build(BuildContext context) {
    final Color fg = destructive ? const Color(0xFFEF4444) : AppColors.kDarkText;
    final Color ic = destructive ? const Color(0xFFEF4444) : context.kP;
    final Color bg = destructive ? const Color(0xFFFEF2F2) : context.kPL;
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 17, color: ic)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: fg, letterSpacing: -0.1)),
            if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: TextStyle(fontSize: 11.5, color: AppColors.kLightText, fontWeight: FontWeight.w500))],
          ])),
          if (trailing != null) trailing! else if (showChevron) Icon(LucideIcons.chevronRight, size: 15, color: AppColors.kLightText),
        ]),
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  const _ValueTile({required this.icon, required this.title, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Tile(
      icon: icon, title: title, onTap: onTap,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: AppColors.kBackground, borderRadius: BorderRadius.circular(20)), child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.kDarkText))),
        const SizedBox(width: 4),
        Icon(LucideIcons.chevronRight, size: 14, color: AppColors.kLightText),
      ]),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.icon, required this.title, this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _Tile(
      icon: icon, title: title, subtitle: subtitle, showChevron: false,
      trailing: Transform.scale(scale: 0.82, child: Switch(value: value, onChanged: onChanged, activeColor: Colors.white, activeTrackColor: context.kP, inactiveTrackColor: Colors.grey.shade300, inactiveThumbColor: Colors.white, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Divider(height: 1, color: AppColors.kBorder.withOpacity(0.5)));
}

class _StatusBadge extends StatelessWidget {
  final BusinessStatus status;
  const _StatusBadge(this.status);
  @override
  Widget build(BuildContext context) {
    late Color fg, bg; late String label; late IconData icon;
    switch (status) {
      case BusinessStatus.approved: fg = const Color(0xFF16A34A); bg = const Color(0xFFDCFCE7); label = 'Approved'; icon = LucideIcons.checkCircle2; break;
      case BusinessStatus.rejected: fg = const Color(0xFFEF4444); bg = const Color(0xFFFEF2F2); label = 'Rejected'; icon = LucideIcons.xCircle; break;
      default: fg = const Color(0xFFF59E0B); bg = const Color(0xFFFFFBEB); label = 'Pending Review'; icon = LucideIcons.clock;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 11, color: fg), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg))]),
    );
  }
}

class _VerifyNotice extends StatelessWidget {
  const _VerifyNotice();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(14, 6, 14, 10),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFDE68A))),
    child: Row(children: [
      const Icon(LucideIcons.shieldAlert, size: 13, color: Color(0xFFF59E0B)),
      const SizedBox(width: 8),
      Expanded(child: Text('Verification required (24–48 hours) for important changes', style: TextStyle(fontSize: 11, color: const Color(0xFF92400E).withOpacity(0.9), fontWeight: FontWeight.w600, height: 1.3))),
    ]),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
    child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.kLightText.withOpacity(0.7), letterSpacing: 0.9)),
  );
}

class _SheetScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final bool scrollable;
  const _SheetScaffold({required this.title, required this.child, this.scrollable = false});

  @override
  Widget build(BuildContext context) {
    final inner = Column(
      mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Container(margin: const EdgeInsets.only(top: 12), width: 36, height: 4, decoration: BoxDecoration(color: AppColors.kBorder, borderRadius: BorderRadius.circular(2)))),
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0), child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.kDarkText, letterSpacing: -0.3))),
        child,
      ],
    );
    return Container(
      decoration: const BoxDecoration(color: AppColors.kWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: scrollable ? SingleChildScrollView(child: inner) : inner,
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? hint;
  final int maxLines;
  const _LabeledField({required this.label, required this.controller, this.keyboardType, this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.kLightText)),
        const SizedBox(height: 6),
        TextField(
          controller: controller, keyboardType: keyboardType, maxLines: maxLines,
          style: const TextStyle(fontSize: 13.5, color: AppColors.kDarkText),
          decoration: InputDecoration(
            hintText: hint, hintStyle: TextStyle(color: AppColors.kLightText, fontSize: 13),
            filled: true, fillColor: AppColors.kBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.kP, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          ),
        ),
      ]),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(color: context.kP, borderRadius: BorderRadius.circular(13)),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    ),
  );
}

void _snack(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

// ════════════════════════════════════════════════════════════════
// BUSINESS TYPE SCREEN
// ════════════════════════════════════════════════════════════════

class BusinessTypeScreen extends StatelessWidget {
  const BusinessTypeScreen({Key? key}) : super(key: key);

  void _go(BuildContext context, String type) {
    Widget screen;
    switch (type) {
      case 'restaurant': screen = const RestaurantRegistrationScreen(); break;
      case 'medical':    screen = const MedicalRegistrationScreen(); break;
      default:           screen = const GroceryRegistrationScreen();
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: AppColors.kBackground, elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.kDarkText, size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text('Add New Business', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.kDarkText)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Choose business type to start registration', style: TextStyle(fontSize: 13, color: AppColors.kLightText)),
          const SizedBox(height: 20),
          _card(context, LucideIcons.shoppingCart,    'Grocery Store',  'Sell daily essentials & groceries',  'grocery'),
          const SizedBox(height: 12),
          _card(context, LucideIcons.utensilsCrossed, 'Restaurant',     'Sell food & manage your menu',        'restaurant'),
          const SizedBox(height: 12),
          _card(context, LucideIcons.pill,            'Medical Store',  'Sell medicines & healthcare items',   'medical'),
        ]),
      ),
    );
  }

  Widget _card(BuildContext ctx, IconData icon, String title, String sub, String type) {
    return GestureDetector(
      onTap: () => _go(ctx, type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.kWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.kBorder.withOpacity(0.6)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
        child: Row(children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.kPrimary.withOpacity(0.10), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: AppColors.kPrimary, size: 21)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.kDarkText)),
            const SizedBox(height: 3),
            Text(sub, style: TextStyle(fontSize: 12, color: AppColors.kLightText)),
          ])),
          Icon(LucideIcons.chevronRight, size: 16, color: AppColors.kLightText),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// UPDATE IMAGES SHEET (camera + gallery + live preview)
// Banner • Logo • Profile Photo — sab two-way state se sync
// ════════════════════════════════════════════════════════════════

class _UpdateImagesSheet extends StatefulWidget {
  final File? initialBanner;
  final File? initialLogo;
  final File? initialProfilePhoto;
  final void Function(File? banner, File? logo, File? profilePhoto) onSaved;
  const _UpdateImagesSheet({
    this.initialBanner,
    this.initialLogo,
    this.initialProfilePhoto,
    required this.onSaved,
  });
  @override
  State<_UpdateImagesSheet> createState() => _UpdateImagesSheetState();
}

class _UpdateImagesSheetState extends State<_UpdateImagesSheet> {
  File? _banner;
  File? _logo;
  File? _profilePhoto;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _banner = widget.initialBanner;
    _logo = widget.initialLogo;
    _profilePhoto = widget.initialProfilePhoto;
  }

  Future<void> _pick(String type) async {
    final String label = type == 'banner' ? 'Banner Photo' : (type == 'logo' ? 'Logo' : 'Profile Photo');
    await showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: AppColors.kWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.kBorder, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Update $label', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.kDarkText)),
          const SizedBox(height: 16),
          _pickOption(ctx, LucideIcons.camera, 'Take Photo',          () => _fromSource(ImageSource.camera,  type, ctx)),
          const SizedBox(height: 10),
          _pickOption(ctx, LucideIcons.image,  'Choose from Gallery', () => _fromSource(ImageSource.gallery, type, ctx)),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _pickOption(BuildContext ctx, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(color: AppColors.kBackground, borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.kBorder.withOpacity(0.6))),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.kPrimary.withOpacity(0.10), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppColors.kPrimary, size: 17)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.kDarkText)),
          const Spacer(),
          Icon(LucideIcons.chevronRight, size: 15, color: AppColors.kLightText),
        ]),
      ),
    );
  }

  Future<void> _fromSource(ImageSource source, String type, BuildContext sheetCtx) async {
    Navigator.pop(sheetCtx);
    try {
      final XFile? picked = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1200);
      if (picked != null) {
        setState(() {
          if (type == 'banner') {
            _banner = File(picked.path);
          } else if (type == 'logo') {
            _logo = File(picked.path);
          } else {
            _profilePhoto = File(picked.path);
          }
        });
      }
    } catch (e) {
      _snack(context, 'Could not pick image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Update Images',
      scrollable: true,
      child: Column(children: [
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            // Banner
            GestureDetector(
              onTap: () => _pick('banner'),
              child: Container(
                height: 120, width: double.infinity,
                decoration: BoxDecoration(color: AppColors.kBackground, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.kBorder)),
                clipBehavior: Clip.antiAlias,
                child: _banner != null
                    ? Stack(fit: StackFit.expand, children: [
                        Image.file(_banner!, fit: BoxFit.cover),
                        Positioned(bottom: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.pencil, size: 12, color: Colors.white), const SizedBox(width: 4), const Text('Change', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600))]))),
                      ])
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(LucideIcons.imagePlus, size: 28, color: context.kP.withOpacity(0.5)),
                        const SizedBox(height: 8),
                        Text('Tap to upload Banner', style: TextStyle(fontSize: 12.5, color: AppColors.kLightText)),
                        Text('Recommended: 1200 × 400 px', style: TextStyle(fontSize: 11, color: AppColors.kLightText.withOpacity(0.7))),
                      ]),
              ),
            ),
            const SizedBox(height: 12),
            // Logo
            GestureDetector(
              onTap: () => _pick('logo'),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.kBackground, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.kBorder)),
                child: Row(children: [
                  Container(width: 60, height: 60, decoration: BoxDecoration(color: context.kPL, borderRadius: BorderRadius.circular(14)), clipBehavior: Clip.antiAlias,
                    child: _logo != null ? Image.file(_logo!, fit: BoxFit.cover) : Icon(LucideIcons.store, color: context.kP, size: 24)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Business Logo', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.kDarkText)),
                    const SizedBox(height: 2),
                    Text('Recommended: 400 × 400 px', style: TextStyle(fontSize: 11.5, color: AppColors.kLightText)),
                  ])),
                  Icon(LucideIcons.upload, size: 16, color: context.kP),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            // Profile Photo
            GestureDetector(
              onTap: () => _pick('profile'),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.kBackground, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.kBorder)),
                child: Row(children: [
                  Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: context.kPL), clipBehavior: Clip.antiAlias,
                    child: _profilePhoto != null ? Image.file(_profilePhoto!, fit: BoxFit.cover) : Icon(LucideIcons.user, color: context.kP, size: 24)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Profile Photo', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.kDarkText)),
                    const SizedBox(height: 2),
                    Text('Owner display picture', style: TextStyle(fontSize: 11.5, color: AppColors.kLightText)),
                  ])),
                  Icon(LucideIcons.upload, size: 16, color: context.kP),
                ]),
              ),
            ),
          ]),
        ),
        _PrimaryBtn(label: 'Upload Images', onTap: () {
          widget.onSaved(_banner, _logo, _profilePhoto);
          Navigator.pop(context);
          _snack(context, 'Images uploaded successfully');
        }),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// UPDATE ADDRESS SHEET (geolocator + geocoding + manual)
// ════════════════════════════════════════════════════════════════

class _UpdateAddressSheet extends StatefulWidget {
  final BusinessModel business;
  const _UpdateAddressSheet({required this.business});
  @override
  State<_UpdateAddressSheet> createState() => _UpdateAddressSheetState();
}

class _UpdateAddressSheetState extends State<_UpdateAddressSheet> {
  final _street = TextEditingController();
  final _city   = TextEditingController();
  final _state  = TextEditingController();
  final _pin    = TextEditingController();
  final _lat    = TextEditingController();
  final _lng    = TextEditingController();
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _street.text = widget.business.address;
    _lat.text    = widget.business.latitude.toString();
    _lng.text    = widget.business.longitude.toString();
  }

  @override
  void dispose() {
    _street.dispose(); _city.dispose(); _state.dispose();
    _pin.dispose(); _lat.dispose(); _lng.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Location Disabled', style: TextStyle(fontWeight: FontWeight.w800)),
            content: const Text('Please enable location services to auto-fill your address.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(onPressed: () async { Navigator.pop(context); await Geolocator.openLocationSettings(); }, child: Text('Enable', style: TextStyle(color: AppColors.kPrimary, fontWeight: FontWeight.w700))),
            ],
          ),
        );
        if (mounted) setState(() => _locating = false);
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        if (mounted) { _snack(context, 'Location permission denied'); setState(() => _locating = false); }
        return;
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) { _snack(context, 'Location permanently denied — enable in Settings'); setState(() => _locating = false); await Geolocator.openAppSettings(); }
        return;
      }

      final Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        setState(() {
          _street.text = [p.street, p.subLocality].where((s) => s != null && s!.isNotEmpty).join(', ');
          _city.text   = p.locality         ?? '';
          _state.text  = p.administrativeArea ?? '';
          _pin.text    = p.postalCode        ?? '';
          _lat.text    = pos.latitude.toStringAsFixed(6);
          _lng.text    = pos.longitude.toStringAsFixed(6);
        });
      }
    } catch (e) {
      if (mounted) _snack(context, 'Could not get location: $e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Update Address', scrollable: true,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: GestureDetector(
            onTap: _locating ? null : _getCurrentLocation,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: context.kPL, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.kPB)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_locating) SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: context.kP))
                else Icon(LucideIcons.mapPin, size: 15, color: context.kP),
                const SizedBox(width: 8),
                Text(_locating ? 'Getting your location...' : 'Use Current Location', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.kP)),
              ]),
            ),
          ),
        ),
        _LabeledField(label: 'Street / Building / Area', controller: _street),
        _LabeledField(label: 'City', controller: _city),
        _LabeledField(label: 'State', controller: _state),
        _LabeledField(label: 'PIN Code', controller: _pin, keyboardType: TextInputType.number),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Latitude', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.kLightText)),
              const SizedBox(height: 6),
              TextField(controller: _lat, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), style: const TextStyle(fontSize: 13, color: AppColors.kDarkText),
                decoration: InputDecoration(filled: true, fillColor: AppColors.kBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.kBorder)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.kBorder)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.kP, width: 1.5)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Longitude', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.kLightText)),
              const SizedBox(height: 6),
              TextField(controller: _lng, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), style: const TextStyle(fontSize: 13, color: AppColors.kDarkText),
                decoration: InputDecoration(filled: true, fillColor: AppColors.kBackground, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.kBorder)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.kBorder)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.kP, width: 1.5)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
            ])),
          ]),
        ),
        const _VerifyNotice(),
        _PrimaryBtn(label: 'Update Address', onTap: () { Navigator.pop(context); _snack(context, 'Address updated — verification pending'); }),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// FIX — TEMPORARY CLOSE SHEET (Custom Date picker)
// ════════════════════════════════════════════════════════════════

class _TempCloseSheet extends StatefulWidget {
  const _TempCloseSheet();
  @override
  State<_TempCloseSheet> createState() => _TempCloseSheetState();
}

class _TempCloseSheetState extends State<_TempCloseSheet> {
  DateTime? _from;
  DateTime? _to;

  Future<void> _pick(bool isFrom) async {
    final DateTime now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? now : (_from ?? now).add(const Duration(days: 1)),
      firstDate: now, lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: context.kP)), child: child!),
    );
    if (picked != null) setState(() => isFrom ? _from = picked : _to = picked);
  }

  String _fmtDate(DateTime? d) => d == null ? 'Select Date' : '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Custom Close Period',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Expanded(child: _datePicker('From Date', _fmtDate(_from), () => _pick(true))),
            const SizedBox(width: 12),
            Expanded(child: _datePicker('To Date', _fmtDate(_to), () => _pick(false))),
          ]),
        ),
        _PrimaryBtn(label: 'Confirm Close', onTap: () {
          if (_from == null || _to == null) { _snack(context, 'Please select both dates'); return; }
          Navigator.pop(context);
          _snack(context, 'Business closed from ${_fmtDate(_from)} to ${_fmtDate(_to)}');
        }),
      ]),
    );
  }

  Widget _datePicker(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(color: AppColors.kBackground, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.kBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.kLightText)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.kDarkText)),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// FIX — DELIVERY AVAILABILITY SHEET (Day selector)
// ════════════════════════════════════════════════════════════════

class _DeliveryAvailabilitySheet extends StatefulWidget {
  final Map<String, bool> initialDays;
  final ValueChanged<Map<String, bool>> onSaved;
  const _DeliveryAvailabilitySheet({required this.initialDays, required this.onSaved});
  @override
  State<_DeliveryAvailabilitySheet> createState() => _DeliveryAvailabilitySheetState();
}

class _DeliveryAvailabilitySheetState extends State<_DeliveryAvailabilitySheet> {
  late Map<String, bool> _days;

  @override
  void initState() {
    super.initState();
    _days = Map<String, bool>.from(widget.initialDays);
  }

  bool get _allOn => _days.values.every((v) => v);

  void _toggleAll() => setState(() => _days.updateAll((_, __) => !_allOn));

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Delivery Availability',
      child: Column(children: [
        const SizedBox(height: 10),
        // All days toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: GestureDetector(
            onTap: _toggleAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(color: _allOn ? context.kPL : AppColors.kBackground, borderRadius: BorderRadius.circular(12), border: Border.all(color: _allOn ? context.kPB : AppColors.kBorder)),
              child: Row(children: [
                Container(width: 22, height: 22,
                  decoration: BoxDecoration(color: _allOn ? context.kP : Colors.transparent, borderRadius: BorderRadius.circular(6), border: Border.all(color: _allOn ? context.kP : AppColors.kBorder, width: 1.5)),
                  child: _allOn ? const Icon(Icons.check, size: 14, color: Colors.white) : null),
                const SizedBox(width: 12),
                Text('All Days (Mon – Sun)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _allOn ? context.kP : AppColors.kDarkText)),
              ]),
            ),
          ),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6), child: Row(children: [Expanded(child: Divider(color: AppColors.kBorder)), Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('or select specific days', style: TextStyle(fontSize: 11, color: AppColors.kLightText))), Expanded(child: Divider(color: AppColors.kBorder))])),
        ..._days.entries.map((e) {
          final bool isOn = e.value;
          return Column(children: [
            GestureDetector(
              onTap: () => setState(() => _days[e.key] = !isOn),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(children: [
                  Container(width: 22, height: 22,
                    decoration: BoxDecoration(color: isOn ? context.kP : Colors.transparent, borderRadius: BorderRadius.circular(6), border: Border.all(color: isOn ? context.kP : AppColors.kBorder, width: 1.5)),
                    child: isOn ? const Icon(Icons.check, size: 14, color: Colors.white) : null),
                  const SizedBox(width: 12),
                  Expanded(child: Text(e.key, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: isOn ? AppColors.kDarkText : AppColors.kLightText))),
                  if (e.key == 'Saturday' || e.key == 'Sunday')
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFDE68A))), child: const Text('Weekend', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFB45309)))),
                ]),
              ),
            ),
            if (e.key != _days.keys.last) Divider(height: 1, indent: 20, endIndent: 20, color: AppColors.kBorder.withOpacity(0.5)),
          ]);
        }),
        _PrimaryBtn(label: 'Save Delivery Days', onTap: () {
          if (!_days.values.any((v) => v)) { _snack(context, 'Select at least one day'); return; }
          widget.onSaved(_days);
          Navigator.pop(context);
        }),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// FIX — DELIVERY TIME SHEET  (CRASH FIXED: static slider ranges)
// The crash "value >= min && value <= max" happened because
// _max slider's min was dynamic (_min + 10), but the stored _max
// value could fall below that when _min was dragged up.
// Solution: use FIXED ranges for both sliders + clamp on change.
// ════════════════════════════════════════════════════════════════

class _DeliveryTimeSheet extends StatefulWidget {
  final String currentTime;
  final ValueChanged<String> onSaved;
  const _DeliveryTimeSheet({required this.currentTime, required this.onSaved});
  @override
  State<_DeliveryTimeSheet> createState() => _DeliveryTimeSheetState();
}

class _DeliveryTimeSheetState extends State<_DeliveryTimeSheet> {
  // Fixed ranges — no dynamic min/max that can cause assertion errors
  static const double _minLow  = 10;
  static const double _minHigh = 120;
  static const double _maxLow  = 20;
  static const double _maxHigh = 180;

  late double _min;
  late double _max;

  @override
  void initState() {
    super.initState();
    // Parse "30–40 mins" → 30, 40
    try {
      final parts = widget.currentTime.replaceAll(' mins', '').split('–');
      if (parts.length == 2) {
        _min = (double.tryParse(parts[0].trim()) ?? 30).clamp(_minLow, _minHigh);
        _max = (double.tryParse(parts[1].trim()) ?? 40).clamp(_maxLow, _maxHigh);
      } else {
        _min = 30; _max = 40;
      }
    } catch (_) { _min = 30; _max = 40; }
    // Guarantee max > min
    if (_max <= _min) _max = (_min + 10).clamp(_maxLow, _maxHigh);
  }

  String _label(double v) {
    final int m = v.toInt();
    if (m >= 60) {
      final int h = m ~/ 60; final int rem = m % 60;
      return rem == 0 ? '${h}h' : '${h}h ${rem}m';
    }
    return '${m} min';
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Delivery Time',
      child: Column(children: [
        const SizedBox(height: 20),
        // Display
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: context.kPL, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.kPB)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Column(children: [
              Text('Minimum', style: TextStyle(fontSize: 11, color: context.kP.withOpacity(0.7))),
              const SizedBox(height: 4),
              Text(_label(_min), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: context.kP)),
            ]),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text('–', style: TextStyle(fontSize: 22, color: context.kP.withOpacity(0.4), fontWeight: FontWeight.w300))),
            Column(children: [
              Text('Maximum', style: TextStyle(fontSize: 11, color: context.kP.withOpacity(0.7))),
              const SizedBox(height: 4),
              Text(_label(_max), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: context.kP)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        // Min slider — FIXED range _minLow.._minHigh (no dynamic min)
        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 0), child: Row(children: [
          Text('Min time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.kLightText)),
          const Spacer(),
          Text(_label(_min), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.kDarkText)),
        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(activeTrackColor: context.kP, thumbColor: context.kP, inactiveTrackColor: context.kPL),
            child: Slider(
              value: _min.clamp(_minLow, _minHigh),
              min: _minLow, max: _minHigh, divisions: ((_minHigh - _minLow) / 5).round(),
              onChanged: (v) => setState(() {
                _min = v;
                // If max is now <= min, push max up — but clamp to valid range
                if (_max <= _min + 10) _max = (_min + 10).clamp(_maxLow, _maxHigh);
              }),
            ),
          ),
        ),
        // Max slider — FIXED range _maxLow.._maxHigh (no dynamic min)
        Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 0), child: Row(children: [
          Text('Max time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.kLightText)),
          const Spacer(),
          Text(_label(_max), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.kDarkText)),
        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(activeTrackColor: context.kP, thumbColor: context.kP, inactiveTrackColor: context.kPL),
            child: Slider(
              value: _max.clamp(_maxLow, _maxHigh),
              min: _maxLow, max: _maxHigh, divisions: ((_maxHigh - _maxLow) / 5).round(),
              onChanged: (v) => setState(() {
                _max = v;
                // If min is now >= max, pull min down
                if (_min >= _max - 10) _min = (_max - 10).clamp(_minLow, _minHigh);
              }),
            ),
          ),
        ),
        // Quick presets
        const _SectionLabel('QUICK PRESETS'),
        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 0), child: Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            _preset(context, '15–25 min', 15, 25),
            _preset(context, '20–35 min', 20, 35),
            _preset(context, '30–45 min', 30, 45),
            _preset(context, '45–60 min', 45, 60),
            _preset(context, '1–1.5 hr',  60, 90),
          ],
        )),
        _PrimaryBtn(label: 'Save Delivery Time', onTap: () {
          widget.onSaved('${_min.toInt()}–${_max.toInt()} mins');
          Navigator.pop(context);
        }),
      ]),
    );
  }

  Widget _preset(BuildContext context, String label, int mn, int mx) {
    final bool sel = _min.toInt() == mn && _max.toInt() == mx;
    return GestureDetector(
      onTap: () => setState(() { _min = mn.toDouble(); _max = mx.toDouble(); }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: sel ? context.kP : AppColors.kBackground, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? context.kP : AppColors.kBorder)),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? Colors.white : AppColors.kDarkText)),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// FIX — OUT OF STOCK MANAGEMENT SHEET
// ════════════════════════════════════════════════════════════════

class _OutOfStockSheet extends StatefulWidget {
  const _OutOfStockSheet();
  @override
  State<_OutOfStockSheet> createState() => _OutOfStockSheetState();
}

class _OutOfStockSheetState extends State<_OutOfStockSheet> {
  String _selected = 'hide';

  final List<Map<String, dynamic>> _options = [
    {'id': 'hide',     'icon': LucideIcons.eyeOff,      'title': 'Auto-hide items',      'subtitle': 'Out-of-stock items disappear from store'},
    {'id': 'mark',     'icon': LucideIcons.tag,          'title': 'Mark as unavailable',  'subtitle': 'Show items but mark them as sold out'},
    {'id': 'preorder', 'icon': LucideIcons.calendarPlus, 'title': 'Allow pre-order',      'subtitle': 'Let customers order in advance'},
    {'id': 'notify',   'icon': LucideIcons.bellRing,     'title': 'Notify when available','subtitle': 'Send alert when item is restocked'},
  ];

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Out of Stock Management',
      child: Column(children: [
        const SizedBox(height: 12),
        ..._options.map((opt) {
          final bool sel = _selected == opt['id'];
          return GestureDetector(
            onTap: () => setState(() => _selected = opt['id'] as String),
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: sel ? context.kPL : AppColors.kBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sel ? context.kPB : AppColors.kBorder, width: sel ? 1.5 : 1),
              ),
              child: Row(children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: sel ? context.kP : AppColors.kBorder.withOpacity(0.3), borderRadius: BorderRadius.circular(11)), child: Icon(opt['icon'] as IconData, size: 18, color: sel ? Colors.white : AppColors.kLightText)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(opt['title'] as String, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: sel ? context.kP : AppColors.kDarkText)),
                  const SizedBox(height: 2),
                  Text(opt['subtitle'] as String, style: TextStyle(fontSize: 11.5, color: AppColors.kLightText)),
                ])),
                if (sel) Icon(LucideIcons.checkCircle2, size: 16, color: context.kP),
              ]),
            ),
          );
        }),
        _PrimaryBtn(label: 'Save Settings', onTap: () {
          Navigator.pop(context);
          _snack(context, 'Out of stock preference saved');
        }),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// FIX — STOCK UPDATE REMINDER SHEET
// ════════════════════════════════════════════════════════════════

class _StockReminderSheet extends StatefulWidget {
  const _StockReminderSheet();
  @override
  State<_StockReminderSheet> createState() => _StockReminderSheetState();
}

class _StockReminderSheetState extends State<_StockReminderSheet> {
  bool _enabled = true;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  String _freq = 'daily';

  final List<Map<String, String>> _freqs = [
    {'id': 'daily',   'label': 'Every Day'},
    {'id': 'weekday', 'label': 'Weekdays Only'},
    {'id': 'weekly',  'label': 'Once a Week'},
  ];

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context, initialTime: _time,
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: context.kP)), child: child!),
    );
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Stock Update Reminder',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        // Enable toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(color: AppColors.kBackground, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.kBorder)),
            child: Row(children: [
              Icon(LucideIcons.bellRing, size: 18, color: _enabled ? context.kP : AppColors.kLightText),
              const SizedBox(width: 12),
              Expanded(child: Text('Enable Daily Reminder', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _enabled ? AppColors.kDarkText : AppColors.kLightText))),
              Transform.scale(scale: 0.82, child: Switch(value: _enabled, onChanged: (v) => setState(() => _enabled = v), activeColor: Colors.white, activeTrackColor: context.kP, inactiveTrackColor: Colors.grey.shade300, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
            ]),
          ),
        ),
        if (_enabled) ...[
          const _SectionLabel('REMINDER TIME'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: context.kPL, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.kPB)),
                child: Row(children: [
                  Icon(LucideIcons.clock, size: 18, color: context.kP),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_time.format(context), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.kP))),
                  Icon(LucideIcons.chevronRight, size: 15, color: context.kP),
                ]),
              ),
            ),
          ),
          const _SectionLabel('FREQUENCY'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: _freqs.map((f) {
              final bool sel = _freq == f['id'];
              return Expanded(child: GestureDetector(
                onTap: () => setState(() => _freq = f['id']!),
                child: Container(
                  margin: EdgeInsets.only(right: f['id'] != _freqs.last['id'] ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: sel ? context.kP : AppColors.kBackground, borderRadius: BorderRadius.circular(10), border: Border.all(color: sel ? context.kP : AppColors.kBorder)),
                  child: Text(f['label']!, textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: sel ? Colors.white : AppColors.kDarkText)),
                ),
              ));
            }).toList()),
          ),
        ],
        _PrimaryBtn(label: 'Save Reminder', onTap: () {
          Navigator.pop(context);
          _snack(context, _enabled ? 'Reminder set for ${_time.format(context)}' : 'Reminder disabled');
        }),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// SELLING CATEGORIES SHEET (Edit categories)
// ════════════════════════════════════════════════════════════════

class _SellingCategoriesSheet extends StatefulWidget {
  final String businessType;
  final List<String> selectedCategoryIds;
  final ValueChanged<List<String>> onSaved;
  const _SellingCategoriesSheet({required this.businessType, required this.selectedCategoryIds, required this.onSaved});
  @override
  State<_SellingCategoriesSheet> createState() => _SellingCategoriesSheetState();
}

class _SellingCategoriesSheetState extends State<_SellingCategoriesSheet> {
  late Set<String> _selected;
  late List<Map<String, String>> _allCategories;

  @override
  void initState() {
    super.initState();
    _allCategories = BusinessCategoryData.getCategories(widget.businessType);
    _selected = Set<String>.from(widget.selectedCategoryIds);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.kWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(margin: const EdgeInsets.only(top: 12), width: 36, height: 4, decoration: BoxDecoration(color: AppColors.kBorder, borderRadius: BorderRadius.circular(2)))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(children: [
            Expanded(child: Text('Manage Selling Categories', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.kDarkText))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: context.kPL, borderRadius: BorderRadius.circular(20)), child: Text('${_selected.length} selected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.kP))),
          ]),
        ),
        Text('  Select the categories you want to sell in your store', style: TextStyle(fontSize: 12, color: AppColors.kLightText), textAlign: TextAlign.start),
        const SizedBox(height: 8),
        Divider(height: 1, color: AppColors.kBorder.withOpacity(0.5)),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: _allCategories.map((cat) {
                final bool sel = _selected.contains(cat['id']);
                return GestureDetector(
                  onTap: () => setState(() => sel ? _selected.remove(cat['id']) : _selected.add(cat['id']!)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? context.kP : AppColors.kBackground,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: sel ? context.kP : AppColors.kBorder, width: sel ? 1.5 : 1),
                      boxShadow: sel ? [BoxShadow(color: context.kP.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))] : [],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(cat['emoji']!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 7),
                      Text(cat['name']!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: sel ? Colors.white : AppColors.kDarkText)),
                      if (sel) ...[const SizedBox(width: 6), Icon(LucideIcons.check, size: 13, color: Colors.white)],
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (_selected.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFECACA))),
              child: Row(children: [
                const Icon(LucideIcons.alertTriangle, size: 13, color: Color(0xFFEF4444)),
                const SizedBox(width: 8),
                Text('Select at least one category', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
              ]),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: GestureDetector(
            onTap: () {
              if (_selected.isEmpty) { _snack(context, 'Please select at least one category'); return; }
              widget.onSaved(_selected.toList());
              Navigator.pop(context);
            },
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(color: _selected.isEmpty ? AppColors.kLightText.withOpacity(0.3) : context.kP, borderRadius: BorderRadius.circular(13)),
              alignment: Alignment.center,
              child: const Text('Update Categories', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// SELLING CATEGORIES SECTION
// ════════════════════════════════════════════════════════════════

class _SellingCategoriesSection extends StatefulWidget {
  final BusinessModel business;
  const _SellingCategoriesSection({required this.business});
  @override
  State<_SellingCategoriesSection> createState() => _SellingCategoriesSectionState();
}

class _SellingCategoriesSectionState extends State<_SellingCategoriesSection> {
  late List<String> _selectedIds;
  late List<Map<String, String>> _allCats;
  bool _hasHiddenItems = false;

  @override
  void initState() {
    super.initState();
    _allCats = BusinessCategoryData.getCategories(widget.business.businessType);
    // Use model's sellingCategories if available, else default to first 3
    _selectedIds =
    widget.business.sellingCategories.isNotEmpty
        ? List<String>.from(widget.business.sellingCategories)
        : _allCats.take(3).map((c) => c['id']!).toList();
  }

  List<Map<String, String>> get _selectedCats =>
      _allCats.where((c) => _selectedIds.contains(c['id'])).toList();

  String get _itemLabel {
    switch (widget.business.businessType) {
      case 'restaurant': return 'Menu Items';
      case 'medical':    return 'Medicines';
      default:           return 'Products';
    }
  }

  void _openEditSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _SellingCategoriesSheet(
        businessType: widget.business.businessType,
        selectedCategoryIds: _selectedIds,
        onSaved: (newIds) {
          final removed = _selectedIds.where((id) => !newIds.contains(id)).toList();
          setState(() {
            _selectedIds = newIds;
            _hasHiddenItems = removed.isNotEmpty;
          });
          _snack(context, 'Categories updated successfully');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Selling Categories',
      icon: LucideIcons.layoutGrid,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionLabel('YOU SELL'),
        // Selected category chips
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: _selectedCats.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.kBackground, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(LucideIcons.alertCircle, size: 15, color: AppColors.kLightText),
                    const SizedBox(width: 8),
                    Text('No categories selected', style: TextStyle(fontSize: 13, color: AppColors.kLightText)),
                  ]),
                )
              : Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _selectedCats.map((cat) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: context.kPL, borderRadius: BorderRadius.circular(24), border: Border.all(color: context.kPB)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(cat['emoji']!, style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 6),
                      Text(cat['name']!, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.kP)),
                    ]),
                  )).toList(),
                ),
        ),
        // Hidden items notice
        if (_hasHiddenItems) ...[
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFDE68A))),
            child: Row(children: [
              const Icon(LucideIcons.eyeOff, size: 13, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              Expanded(child: Text('Some $_itemLabel are hidden because their category is disabled', style: TextStyle(fontSize: 11, color: const Color(0xFF92400E).withOpacity(0.9), fontWeight: FontWeight.w600, height: 1.3))),
            ]),
          ),
        ],
        const _TileDivider(),
        // Stats row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            _stat(context, '${_selectedCats.length}', 'Active'),
            Container(width: 1, height: 28, color: AppColors.kBorder),
            _stat(context, '${_allCats.length - _selectedCats.length}', 'Inactive'),
            Container(width: 1, height: 28, color: AppColors.kBorder),
            _stat(context, '${_allCats.length}', 'Total'),
          ]),
        ),
        const _TileDivider(),
        // Edit button
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: GestureDetector(
            onTap: _openEditSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: context.kPL, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.kPB)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(LucideIcons.pencil, size: 14, color: context.kP),
                const SizedBox(width: 7),
                Text('Edit Selling Categories', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.kP)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _stat(BuildContext context, String value, String label) => Expanded(child: Column(children: [
    Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.kP)),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(fontSize: 11, color: AppColors.kLightText)),
  ]));
}

// ════════════════════════════════════════════════════════════════
// OTHER SHEETS (unchanged)
// ════════════════════════════════════════════════════════════════

class _EditProfileSheet extends StatefulWidget {
  final BusinessModel business;
  const _EditProfileSheet({required this.business});
  @override State<_EditProfileSheet> createState() => _EditProfileSheetState();
}
class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _name, _email;
  @override void initState() { super.initState(); _name = TextEditingController(text: widget.business.name); _email = TextEditingController(text: widget.business.email); }
  @override void dispose() { _name.dispose(); _email.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => _SheetScaffold(
    title: 'Edit Profile',
    child: Column(children: [
      _LabeledField(label: 'Business Name', controller: _name),
      _LabeledField(label: 'Email', controller: _email, keyboardType: TextInputType.emailAddress),
      const _VerifyNotice(),
      _PrimaryBtn(label: 'Save Changes', onTap: () { Navigator.pop(context); _snack(context, 'Profile updated — verification pending'); }),
    ]),
  );
}

class _BreakTimeSheet extends StatefulWidget {
  final String currentBreak;
  final ValueChanged<String> onSaved;
  const _BreakTimeSheet({required this.currentBreak, required this.onSaved});
  @override State<_BreakTimeSheet> createState() => _BreakTimeSheetState();
}
class _BreakTimeSheetState extends State<_BreakTimeSheet> {
  TimeOfDay _start = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _end   = const TimeOfDay(hour: 15, minute: 0);
  String _fmt(TimeOfDay t) => t.format(context);

  Future<void> _pick(bool isStart) async {
    final picked = await showTimePicker(context: context, initialTime: isStart ? _start : _end,
        builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: context.kP)), child: child!));
    if (picked != null) setState(() => isStart ? _start = picked : _end = picked);
  }

  @override
  Widget build(BuildContext context) => _SheetScaffold(
    title: 'Set Break Time',
    child: Column(children: [
      const SizedBox(height: 16),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
        Expanded(child: _tp('Break Start', _fmt(_start), () => _pick(true))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('→', style: TextStyle(color: AppColors.kLightText, fontSize: 16))),
        Expanded(child: _tp('Break End', _fmt(_end), () => _pick(false))),
      ])),
      _PrimaryBtn(label: 'Save Break Time', onTap: () { widget.onSaved('${_fmt(_start)} – ${_fmt(_end)}'); Navigator.pop(context); }),
    ]),
  );

  Widget _tp(String label, String value, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: AppColors.kBackground, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.kBorder)),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.kLightText)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.kDarkText)),
      ]),
    ),
  );
}

class _SliderSheet extends StatefulWidget {
  final String title; final double value, min, max, step;
  final String prefix, suffix; final ValueChanged<double> onSaved;
  const _SliderSheet({required this.title, required this.value, required this.min, required this.max, required this.step, this.prefix = '', this.suffix = '', required this.onSaved});
  @override State<_SliderSheet> createState() => _SliderSheetState();
}
class _SliderSheetState extends State<_SliderSheet> {
  late double _cur;
  @override void initState() { super.initState(); _cur = widget.value.clamp(widget.min, widget.max); }
  @override
  Widget build(BuildContext context) => _SheetScaffold(
    title: widget.title,
    child: Column(children: [
      const SizedBox(height: 20),
      Text('${widget.prefix}${_cur.toInt()}${widget.suffix}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: context.kP, letterSpacing: -1)),
      const SizedBox(height: 14),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SliderTheme(data: SliderTheme.of(context).copyWith(activeTrackColor: context.kP, thumbColor: context.kP, inactiveTrackColor: context.kPL),
          child: Slider(value: _cur.clamp(widget.min, widget.max), min: widget.min, max: widget.max, divisions: ((widget.max - widget.min) / widget.step).round(), onChanged: (v) => setState(() => _cur = v)))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${widget.prefix}${widget.min.toInt()}${widget.suffix}', style: TextStyle(fontSize: 11, color: AppColors.kLightText)),
          Text('${widget.prefix}${widget.max.toInt()}${widget.suffix}', style: TextStyle(fontSize: 11, color: AppColors.kLightText)),
        ])),
      _PrimaryBtn(label: 'Save', onTap: () { widget.onSaved(_cur); Navigator.pop(context); }),
    ]),
  );
}

class _AvailabilitySheet extends StatefulWidget {
  final String businessType;
  const _AvailabilitySheet({required this.businessType});
  @override State<_AvailabilitySheet> createState() => _AvailabilitySheetState();
}
class _AvailabilitySheetState extends State<_AvailabilitySheet> {
  final Map<String, bool> _items = {'Item 1': true, 'Item 2': true, 'Item 3': false, 'Item 4': true, 'Item 5': false};
  @override
  Widget build(BuildContext context) => _SheetScaffold(
    title: '${widget.businessType == "medical" ? "Medicine" : "Product"} Availability',
    child: Column(children: [
      ..._items.entries.map((e) => ListTile(dense: true,
        title: Text(e.key, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
        trailing: Transform.scale(scale: 0.82, child: Switch(value: e.value, onChanged: (v) => setState(() => _items[e.key] = v), activeTrackColor: context.kP, activeColor: Colors.white, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
      )),
      _PrimaryBtn(label: 'Save', onTap: () { Navigator.pop(context); _snack(context, 'Availability updated'); }),
    ]),
  );
}

class _ChangeBankSheet extends StatefulWidget {
  const _ChangeBankSheet();
  @override State<_ChangeBankSheet> createState() => _ChangeBankSheetState();
}
class _ChangeBankSheetState extends State<_ChangeBankSheet> {
  final _holder = TextEditingController(); final _acc = TextEditingController();
  final _confirm = TextEditingController(); final _ifsc = TextEditingController();
  final _bank = TextEditingController();
  @override void dispose() { _holder.dispose(); _acc.dispose(); _confirm.dispose(); _ifsc.dispose(); _bank.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => _SheetScaffold(
    title: 'Change Bank Account', scrollable: true,
    child: Column(children: [
      _LabeledField(label: 'Account Holder Name', controller: _holder),
      _LabeledField(label: 'Account Number', controller: _acc, keyboardType: TextInputType.number),
      _LabeledField(label: 'Confirm Account Number', controller: _confirm, keyboardType: TextInputType.number),
      _LabeledField(label: 'IFSC Code', controller: _ifsc),
      _LabeledField(label: 'Bank Name', controller: _bank),
      const _VerifyNotice(),
      _PrimaryBtn(label: 'Submit for Verification', onTap: () { Navigator.pop(context); _snack(context, 'Bank details submitted'); }),
    ]),
  );
}

class _ChangePinSheet extends StatefulWidget {
  const _ChangePinSheet();
  @override State<_ChangePinSheet> createState() => _ChangePinSheetState();
}
class _ChangePinSheetState extends State<_ChangePinSheet> {
  final _cur = TextEditingController(); final _nw = TextEditingController(); final _cf = TextEditingController();
  @override void dispose() { _cur.dispose(); _nw.dispose(); _cf.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => _SheetScaffold(
    title: 'Change Login PIN',
    child: Column(children: [
      _LabeledField(label: 'Current PIN', controller: _cur, keyboardType: TextInputType.number, hint: '••••'),
      _LabeledField(label: 'New PIN', controller: _nw, keyboardType: TextInputType.number, hint: '••••'),
      _LabeledField(label: 'Confirm New PIN', controller: _cf, keyboardType: TextInputType.number, hint: '••••'),
      _PrimaryBtn(label: 'Update PIN', onTap: () { Navigator.pop(context); _snack(context, 'PIN updated successfully'); }),
    ]),
  );
}

class _DeliveryRadiusSheet extends StatefulWidget {
  final double cur; final ValueChanged<double> onSaved;
  const _DeliveryRadiusSheet({required this.cur, required this.onSaved});
  @override State<_DeliveryRadiusSheet> createState() => _DeliveryRadiusSheetState();
}
class _DeliveryRadiusSheetState extends State<_DeliveryRadiusSheet> {
  late double _r;
  @override void initState() { super.initState(); _r = widget.cur.clamp(1.0, 20.0); }
  @override
  Widget build(BuildContext context) => _SheetScaffold(
    title: 'Delivery Radius',
    child: Column(children: [
      const SizedBox(height: 20),
      Text('${_r.toInt()} km', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: context.kP)),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: SliderTheme(data: SliderTheme.of(context).copyWith(activeTrackColor: context.kP, thumbColor: context.kP, inactiveTrackColor: context.kPL),
          child: Slider(value: _r, min: 1, max: 20, divisions: 19, onChanged: (v) => setState(() => _r = v)))),
      _PrimaryBtn(label: 'Save', onTap: () { widget.onSaved(_r); Navigator.pop(context); }),
    ]),
  );
}

// ════════════════════════════════════════════════════════════════
// SECTION WIDGETS
// ════════════════════════════════════════════════════════════════

// ── Business Profile ─────────────────────────────────────────────
class _BusinessProfileSection extends StatefulWidget {
  final BusinessModel business;
  const _BusinessProfileSection({required this.business});
  @override
  State<_BusinessProfileSection> createState() => _BusinessProfileSectionState();
}

class _BusinessProfileSectionState extends State<_BusinessProfileSection> {
  File? _banner;
  File? _logo;
  File? _profilePhoto;

  @override
  Widget build(BuildContext context) {
    final business = widget.business;
    return _SectionCard(
      title: 'Business Profile', icon: LucideIcons.store,
      child: Column(children: [
        _buildBannerLogo(context, business),
        _profilePhotoRow(context),
        const _TileDivider(),
        _info(LucideIcons.user,   'Owner Name',    business.ownerName),
        const _TileDivider(),
        _info(LucideIcons.phone,  'Mobile Number', business.mobileNumber),
        const _TileDivider(),
        _info(LucideIcons.mail,   'Email',         business.email),
        const _TileDivider(),
        _info(LucideIcons.mapPin, 'Address',       business.address),
        const _TileDivider(),
        _info(LucideIcons.map,    'Coordinates',   '${business.latitude.toStringAsFixed(4)}, ${business.longitude.toStringAsFixed(4)}'),
        const SizedBox(height: 10),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Row(children: [
          Expanded(child: _btn(context, LucideIcons.pencil, 'Edit Profile', true, () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _EditProfileSheet(business: business)))),
          const SizedBox(width: 10),
          Expanded(child: _btn(context, LucideIcons.image, 'Update Images', false, () => showModalBottomSheet(
            context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
            builder: (_) => _UpdateImagesSheet(
              initialBanner: _banner,
              initialLogo: _logo,
              initialProfilePhoto: _profilePhoto,
              onSaved: (banner, logo, profilePhoto) => setState(() {
                _banner = banner;
                _logo = logo;
                _profilePhoto = profilePhoto;
              }),
            ),
          ))),
        ])),
        const SizedBox(height: 8),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: _btn(context, LucideIcons.navigation, 'Update Address', false, () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _UpdateAddressSheet(business: business)), fullWidth: true)),
        const SizedBox(height: 6),
        const _VerifyNotice(),
      ]),
    );
  }

  Widget _profilePhotoRow(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: 46, height: 46,
        decoration: BoxDecoration(shape: BoxShape.circle, color: context.kPL, border: Border.all(color: AppColors.kWhite, width: 2)),
        clipBehavior: Clip.antiAlias,
        child: _profilePhoto != null
            ? Image.file(_profilePhoto!, fit: BoxFit.cover)
            : Icon(LucideIcons.user, color: context.kP, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Profile Photo', style: TextStyle(fontSize: 11, color: AppColors.kLightText, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(_profilePhoto != null ? 'Photo added' : 'Not set', style: const TextStyle(fontSize: 13, color: AppColors.kDarkText, fontWeight: FontWeight.w600, height: 1.3)),
      ])),
    ]),
  );

  // Banner aur Logo — ab actual uploaded image dikhega, placeholder nahi
  Widget _buildBannerLogo(BuildContext context, BusinessModel business) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
    child: Column(children: [
      Container(
        height: 100, width: double.infinity,
        decoration: BoxDecoration(color: context.kPL, borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: _banner != null
            ? Image.file(_banner!, fit: BoxFit.cover)
            : Center(child: Icon(LucideIcons.imagePlus, size: 28, color: context.kP.withOpacity(0.4))),
      ),
      const SizedBox(height: 12),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: context.kPL, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.kWhite, width: 2)),
          clipBehavior: Clip.antiAlias,
          child: _logo != null
              ? Image.file(_logo!, fit: BoxFit.cover)
              : Icon(LucideIcons.store, color: context.kP, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(business.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.kDarkText, letterSpacing: -0.3)),
          const SizedBox(height: 5),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.kBackground, borderRadius: BorderRadius.circular(20)), child: Text(business.businessTypeLabel, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.kDarkText))),
            const SizedBox(width: 6),
            _StatusBadge(business.status),
          ]),
        ])),
      ]),
    ]),
  );

  Widget _info(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.kBackground, borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 14, color: AppColors.kLightText)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.kLightText, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, color: AppColors.kDarkText, fontWeight: FontWeight.w600, height: 1.3)),
      ])),
    ]),
  );

  Widget _btn(BuildContext context, IconData icon, String label, bool filled, VoidCallback onTap, {bool fullWidth = false}) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: fullWidth ? double.infinity : null, padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: filled ? context.kP : context.kPL, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 14, color: filled ? Colors.white : context.kP),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: filled ? Colors.white : context.kP)),
      ]),
    ),
  );
}

// ── Manage Businesses ────────────────────────────────────────────
class _ManageBusinessSection extends StatelessWidget {
  final BusinessModel current;
  final List<BusinessModel> others;
  final ValueChanged<BusinessModel> onSwitch;
  final VoidCallback onAddNew;
  const _ManageBusinessSection({required this.current, required this.others, required this.onSwitch, required this.onAddNew});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Manage Businesses', icon: LucideIcons.layoutGrid,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionLabel('CURRENT BUSINESS'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(color: context.kPL, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.kPB)),
            child: Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.kWhite, borderRadius: BorderRadius.circular(12)), child: Icon(LucideIcons.store, color: context.kP, size: 19)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(current.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.kDarkText)),
                const SizedBox(height: 2),
                Text(current.businessTypeLabel, style: TextStyle(fontSize: 11.5, color: AppColors.kLightText)),
                const SizedBox(height: 5),
                _StatusBadge(current.status),
              ])),
            ]),
          ),
        ),
        if (others.isNotEmpty) ...[
          const _SectionLabel('OTHER BUSINESSES'),
          ...others.asMap().entries.map((e) {
            final b = e.value; final bool can = b.status == BusinessStatus.approved;
            return Column(children: [
              InkWell(
                onTap: can ? () => onSwitch(b) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.kBackground, borderRadius: BorderRadius.circular(11)), child: Icon(LucideIcons.store, size: 17, color: can ? context.kP : AppColors.kLightText)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: can ? AppColors.kDarkText : AppColors.kLightText)),
                      const SizedBox(height: 3),
                      Row(children: [Text(b.businessTypeLabel, style: TextStyle(fontSize: 11, color: AppColors.kLightText)), const SizedBox(width: 6), _StatusBadge(b.status)]),
                    ])),
                    if (can) Icon(LucideIcons.repeat, size: 14, color: context.kP) else Icon(LucideIcons.lock, size: 13, color: AppColors.kLightText.withOpacity(0.5)),
                  ]),
                ),
              ),
              if (e.key < others.length - 1) const _TileDivider(),
            ]);
          }),
        ],
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: GestureDetector(
            onTap: onAddNew,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(border: Border.all(color: context.kPB, width: 1.3), borderRadius: BorderRadius.circular(13)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(LucideIcons.plusCircle, size: 15, color: context.kP),
                const SizedBox(width: 7),
                Text('Add New Business', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.kP)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ]),
    );
  }
}

// ── Business Hours ───────────────────────────────────────────────
class _BusinessHoursSection extends StatefulWidget {
  const _BusinessHoursSection();
  @override State<_BusinessHoursSection> createState() => _BusinessHoursSectionState();
}
class _BusinessHoursSectionState extends State<_BusinessHoursSection> {
  final List<Map<String, dynamic>> _days = [
    {'day': 'Monday', 'open': true}, {'day': 'Tuesday', 'open': true},
    {'day': 'Wednesday', 'open': true}, {'day': 'Thursday', 'open': true},
    {'day': 'Friday', 'open': true}, {'day': 'Saturday', 'open': true},
    {'day': 'Sunday', 'open': false},
  ];
  String _breakTime = '2:00 PM – 3:00 PM';

  // ── FIX: Today/3 Days/7 Days — all compute real dates and show snackbar ──
  void _closeFor(BuildContext context, int days) {
    final DateTime today = DateTime.now();
    if (days == 0) {
      _snack(context, 'Business closed for today only. Will reopen tomorrow.');
    } else {
      final DateTime reopen = today.add(Duration(days: days));
      final String fmt = '${reopen.day}/${reopen.month}/${reopen.year}';
      _snack(context, 'Business closed for $days days. Reopens on $fmt');
    }
    // In production: push to backend/state-management here
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Business Hours', icon: LucideIcons.clock4,
      child: Column(children: [
        const _SectionLabel('WEEKLY TIMING'),
        ..._days.asMap().entries.map((e) {
          final i = e.key; final d = e.value;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Row(children: [
                SizedBox(width: 82, child: Text(d['day'], style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: d['open'] ? AppColors.kDarkText : AppColors.kLightText))),
                Expanded(child: d['open']
                    ? GestureDetector(onTap: () => _snack(context, 'Time picker for ${d['day']}'), child: Row(children: [_tc('9:00 AM'), Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: Icon(LucideIcons.arrowRight, size: 10, color: AppColors.kLightText)), _tc('9:00 PM')]))
                    : Text('Closed', style: TextStyle(fontSize: 12, color: AppColors.kLightText.withOpacity(0.7)))),
                Transform.scale(scale: 0.78, child: Switch(value: d['open'], onChanged: (v) => setState(() => _days[i]['open'] = v), activeColor: Colors.white, activeTrackColor: context.kP, inactiveTrackColor: Colors.grey.shade300, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
              ]),
            ),
            if (i < _days.length - 1) const _TileDivider(),
          ]);
        }),
        const _TileDivider(),
        _ValueTile(icon: LucideIcons.coffee, title: 'Break Time', value: _breakTime,
          onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
              builder: (_) => _BreakTimeSheet(currentBreak: _breakTime, onSaved: (v) => setState(() => _breakTime = v)))),
        const _SectionLabel('TEMPORARY CLOSE'),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            _chip(context, 'Today',       () => _closeFor(context, 0)),
            _chip(context, '3 Days',      () => _closeFor(context, 3)),
            _chip(context, '7 Days',      () => _closeFor(context, 7)),
            _chip(context, 'Custom Date', () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const _TempCloseSheet()), icon: LucideIcons.calendar),
          ]),
        ),
      ]),
    );
  }

  Widget _tc(String t) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.kBackground, borderRadius: BorderRadius.circular(8)), child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.kDarkText)));

  Widget _chip(BuildContext context, String label, VoidCallback onTap, {IconData? icon}) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(color: context.kPL, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.kPB)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12, color: context.kP), const SizedBox(width: 4)],
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.kP)),
      ]),
    ),
  );
}

// ── Business Specific Section ────────────────────────────────────
class _BusinessSpecificSection extends StatefulWidget {
  final String businessType;
  const _BusinessSpecificSection({required this.businessType});
  @override State<_BusinessSpecificSection> createState() => _BusinessSpecificSectionState();
}
class _BusinessSpecificSectionState extends State<_BusinessSpecificSection> {
  bool _autoAccept = true, _lowStock = true, _inventory = false;
  bool _vegNonVeg = true, _scheduled = false, _tableBooking = false;
  bool _prescRequired = true, _prescVerif = true, _substitute = false, _medStock = true;
  String _minOrder = '₹199', _packTime = '10 mins', _prepTime = '20 mins';

  void _slider(BuildContext ctx, {required String title, required double val, required double min, required double max, required double step, required String prefix, required String suffix, required ValueChanged<double> onSaved}) =>
      showModalBottomSheet(context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _SliderSheet(title: title, value: val, min: min, max: max, step: step, prefix: prefix, suffix: suffix, onSaved: onSaved));

  @override
  Widget build(BuildContext context) {
    switch (widget.businessType) {
      case 'restaurant': return _restaurant(context);
      case 'medical':    return _medical(context);
      default:           return _grocery(context);
    }
  }

  Widget _grocery(BuildContext context) => _SectionCard(
    title: 'Store Preferences', icon: LucideIcons.shoppingCart,
    child: Column(children: [
      _ValueTile(icon: LucideIcons.indianRupee, title: 'Minimum Order Amount', value: _minOrder, onTap: () => _slider(context, title: 'Minimum Order', val: 199, min: 0, max: 500, step: 10, prefix: '₹', suffix: '', onSaved: (v) => setState(() => _minOrder = '₹${v.toInt()}'))),
      const _TileDivider(),
      _ValueTile(icon: LucideIcons.packageCheck, title: 'Packing Time', value: _packTime, onTap: () => _slider(context, title: 'Packing Time', val: 10, min: 5, max: 60, step: 5, prefix: '', suffix: ' mins', onSaved: (v) => setState(() => _packTime = '${v.toInt()} mins'))),
      const _TileDivider(),
      _SwitchTile(icon: LucideIcons.checkCheck, title: 'Auto Accept Orders', subtitle: 'Accept new orders automatically', value: _autoAccept, onChanged: (v) => setState(() => _autoAccept = v)),
      const _TileDivider(),
      _SwitchTile(icon: LucideIcons.alertTriangle, title: 'Low Stock Alert', subtitle: 'Notify when stock runs low', value: _lowStock, onChanged: (v) => setState(() => _lowStock = v)),
      const _TileDivider(),
      _SwitchTile(icon: LucideIcons.boxes, title: 'Inventory Alert', subtitle: 'Daily inventory summary', value: _inventory, onChanged: (v) => setState(() => _inventory = v)),
      const _TileDivider(),
      _Tile(icon: LucideIcons.listChecks, title: 'Product Availability', subtitle: 'Manage in/out of stock', onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const _AvailabilitySheet(businessType: 'grocery'))),
      const _TileDivider(),
      // FIX: Out of Stock Management — full options sheet
      _Tile(icon: LucideIcons.packageX, title: 'Out Of Stock Management', subtitle: 'Auto-hide or mark unavailable', onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const _OutOfStockSheet())),
      const _TileDivider(),
      // FIX: Stock Update Reminder — time + frequency picker
      _Tile(icon: LucideIcons.bellRing, title: 'Stock Update Reminder', subtitle: 'Daily reminder to update stock', onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const _StockReminderSheet())),
    ]),
  );

  Widget _restaurant(BuildContext context) => _SectionCard(
    title: 'Restaurant Preferences', icon: LucideIcons.utensilsCrossed,
    child: Column(children: [
      _ValueTile(icon: LucideIcons.timer, title: 'Food Preparation Time', value: _prepTime, onTap: () => _slider(context, title: 'Preparation Time', val: 20, min: 5, max: 90, step: 5, prefix: '', suffix: ' mins', onSaved: (v) => setState(() => _prepTime = '${v.toInt()} mins'))),
      const _TileDivider(),
      _SwitchTile(icon: LucideIcons.checkCheck, title: 'Auto Accept Orders', subtitle: 'Accept orders automatically', value: _autoAccept, onChanged: (v) => setState(() => _autoAccept = v)),
      const _TileDivider(),
      _SwitchTile(icon: LucideIcons.calendarClock, title: 'Scheduled Orders', subtitle: 'Allow customers to pre-book', value: _scheduled, onChanged: (v) => setState(() => _scheduled = v)),
      const _TileDivider(),
      _SwitchTile(icon: LucideIcons.leaf, title: 'Veg / Non-Veg Option', subtitle: 'Show diet filters on menu', value: _vegNonVeg, onChanged: (v) => setState(() => _vegNonVeg = v)),
      const _TileDivider(),
      _Tile(icon: LucideIcons.soup, title: 'Cuisine Management', subtitle: 'Add or edit cuisine tags', onTap: () => _snack(context, 'Cuisine manager opened')),
      const _TileDivider(),
      _Tile(icon: LucideIcons.bookOpen, title: 'Menu Availability', subtitle: 'Time-based menu visibility', onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const _AvailabilitySheet(businessType: 'restaurant'))),
      const _TileDivider(),
      _SwitchTile(icon: LucideIcons.armchair, title: 'Table Booking', subtitle: 'Allow dine-in reservations', value: _tableBooking, onChanged: (v) => setState(() => _tableBooking = v)),
      const _TileDivider(),
      _Tile(icon: LucideIcons.messageSquare, title: 'Special Instructions', subtitle: 'Customer note preferences', onTap: () => _snack(context, 'Special instructions settings opened')),
    ]),
  );

  Widget _medical(BuildContext context) => _SectionCard(
    title: 'Pharmacy Preferences', icon: LucideIcons.pill,
    child: Column(children: [
      _SwitchTile(icon: LucideIcons.fileText, title: 'Prescription Required', subtitle: 'Require Rx for scheduled drugs', value: _prescRequired, onChanged: (v) => setState(() => _prescRequired = v)),
      const _TileDivider(),
      _SwitchTile(icon: LucideIcons.shieldCheck, title: 'Prescription Verification', subtitle: 'Manual pharmacist verification', value: _prescVerif, onChanged: (v) => setState(() => _prescVerif = v)),
      const _TileDivider(),
      _SwitchTile(icon: LucideIcons.refreshCw, title: 'Allow Substitute Medicine', subtitle: 'Suggest generic alternatives', value: _substitute, onChanged: (v) => setState(() => _substitute = v)),
      const _TileDivider(),
      _Tile(icon: LucideIcons.listChecks, title: 'Medicine Availability', subtitle: 'Manage in/out of stock', onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const _AvailabilitySheet(businessType: 'medical'))),
      const _TileDivider(),
      _SwitchTile(icon: LucideIcons.alertTriangle, title: 'Medicine Stock Alert', subtitle: 'Notify when stock runs low', value: _medStock, onChanged: (v) => setState(() => _medStock = v)),
      const _TileDivider(),
      _Tile(icon: LucideIcons.userCog, title: 'Pharmacist Details', subtitle: 'Registered pharmacist on record', onTap: () => _snack(context, 'Pharmacist details opened')),
      const _TileDivider(),
      _Tile(icon: LucideIcons.fileCheck, title: 'Drug License Information', subtitle: 'View / update license details', onTap: () => _snack(context, 'Drug license info opened')),
    ]),
  );
}

// ── Delivery Settings ─────────────────────────────────────────────
class _DeliverySettingsSection extends StatefulWidget {
  const _DeliverySettingsSection();
  @override State<_DeliverySettingsSection> createState() => _DeliverySettingsSectionState();
}
class _DeliverySettingsSectionState extends State<_DeliverySettingsSection> {
  bool _cartKaro = true;
  double _radius = 5;
  String _charges = '₹25 flat';
  String _deliveryTime = '30–40 mins';

  // FIX: day map passed into sheet and returned back
  Map<String, bool> _availabilityDays = {
    'Monday': true, 'Tuesday': true, 'Wednesday': true, 'Thursday': true,
    'Friday': true, 'Saturday': true, 'Sunday': false,
  };

  String get _availabilityLabel {
    final on = _availabilityDays.entries.where((e) => e.value).toList();
    if (on.length == 7) return 'All days';
    if (on.isEmpty) return 'Not set';
    if (on.length <= 3) return on.map((e) => e.key.substring(0, 3)).join(', ');
    return '${on.length} days';
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Delivery Settings', icon: LucideIcons.bike,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppColors.kBackground, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Expanded(child: _seg(context, 'CartKaro Delivery', LucideIcons.truck, true)),
              Expanded(child: _seg(context, 'Self Delivery', LucideIcons.userCheck, false)),
            ]),
          ),
        ),
        const _TileDivider(),
        _ValueTile(icon: LucideIcons.radar, title: 'Delivery Radius', value: '${_radius.toInt()} km',
            onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                builder: (_) => _DeliveryRadiusSheet(cur: _radius, onSaved: (v) => setState(() => _radius = v)))),
        const _TileDivider(),
        _ValueTile(icon: LucideIcons.indianRupee, title: 'Delivery Charges', value: _charges,
            onTap: () async {
              final ctrl = TextEditingController(text: '25');
              await showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                  builder: (ctx) => _SheetScaffold(title: 'Delivery Charges',
                      child: Column(children: [
                        _LabeledField(label: 'Amount (₹)', controller: ctrl, keyboardType: TextInputType.number),
                        _PrimaryBtn(label: 'Save', onTap: () { setState(() => _charges = '₹${ctrl.text} flat'); Navigator.pop(ctx); }),
                      ])));
            }),
        const _TileDivider(),
        // FIX: Delivery Availability — passes current state, gets updated state back
        _ValueTile(icon: LucideIcons.calendarCheck2, title: 'Delivery Availability', value: _availabilityLabel,
            onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                builder: (_) => _DeliveryAvailabilitySheet(
                  initialDays: _availabilityDays,
                  onSaved: (updated) => setState(() => _availabilityDays = updated),
                ))),
        const _TileDivider(),
        // FIX: Delivery Time — crash-safe slider with fixed ranges
        _ValueTile(icon: LucideIcons.clock, title: 'Delivery Time', value: _deliveryTime,
            onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                builder: (_) => _DeliveryTimeSheet(currentTime: _deliveryTime, onSaved: (v) => setState(() => _deliveryTime = v)))),
      ]),
    );
  }

  Widget _seg(BuildContext context, String label, IconData icon, bool isCartKaro) {
    final bool sel = _cartKaro == isCartKaro;
    return GestureDetector(
      onTap: () => setState(() => _cartKaro = isCartKaro),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: sel ? AppColors.kWhite : Colors.transparent, borderRadius: BorderRadius.circular(9), boxShadow: sel ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 5, offset: const Offset(0, 2))] : null),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 13, color: sel ? context.kP : AppColors.kLightText),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? context.kP : AppColors.kLightText)),
        ]),
      ),
    );
  }
}

// ── Your Account  ──────────────────────────────────────────
class _PaymentsSection extends StatelessWidget {
  final BusinessModel business;
  const _PaymentsSection({required this.business});
  String _fmt(double v) => '₹${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Your Account', icon: LucideIcons.wallet,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
             
        const _SectionLabel('BANK ACCOUNT'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.kBackground, borderRadius: BorderRadius.circular(13)),
            child: Column(children: [
              Row(children: [
                Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.kWhite, borderRadius: BorderRadius.circular(10)), child: Icon(LucideIcons.landmark, size: 15, color: context.kP)),
                const SizedBox(width: 10),
                Expanded(child: Text(business.bank.bankName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.kDarkText))),
                Icon(business.bank.verified ? LucideIcons.checkCircle2 : LucideIcons.clock, size: 13, color: business.bank.verified ? const Color(0xFF16A34A) : const Color(0xFFF59E0B)),
                const SizedBox(width: 4),
                Text(business.bank.verified ? 'Verified' : 'Pending', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: business.bank.verified ? const Color(0xFF16A34A) : const Color(0xFFF59E0B))),
              ]),
              const SizedBox(height: 10),
              _bRow('Account Number', business.bank.accountNumberMasked),
              const SizedBox(height: 5),
              _bRow('IFSC Code', business.bank.ifsc),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: GestureDetector(
            onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const _ChangeBankSheet()),
            child: Row(children: [Icon(LucideIcons.repeat, size: 13, color: context.kP), const SizedBox(width: 6), Text('Change Bank Account', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.kP))]),
          ),
        ),
        const _VerifyNotice(),
      ]),
    );
  }

  Widget _wStat(String label, String value) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white)),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(0.7))),
  ])));

  Widget _wBtn(BuildContext context, IconData icon, String label, bool filled, VoidCallback onTap, {bool fullWidth = false}) => GestureDetector(
    onTap: onTap,
    child: Container(width: fullWidth ? double.infinity : null, padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: filled ? context.kP : context.kPL, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 14, color: filled ? Colors.white : context.kP), const SizedBox(width: 6), Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: filled ? Colors.white : context.kP))])),
  );

  Widget _bRow(String label, String value) => Row(children: [
    Text(label, style: TextStyle(fontSize: 12, color: AppColors.kLightText)), const Spacer(),
    Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.kDarkText)),
  ]);
}

// ── Legal & Verification ─────────────────────────────────────────
class _LegalSection extends StatelessWidget {
  final BusinessModel business;
  final VoidCallback? onDocumentsChanged; // NEW
  const _LegalSection({required this.business, this.onDocumentsChanged});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Legal & Verification', icon: LucideIcons.fileBadge,
      child: Column(children: [
        ...business.documents.asMap().entries.map((e) {
          final i = e.key; final doc = e.value;
          return Column(children: [
            _Tile(
              icon: _docIcon(doc.name), title: doc.name,
              subtitle: '${doc.number}${doc.expiryDate != null ? " · Expires ${doc.expiryDate}" : ""}',
              trailing: _badge(doc.status), // chevron hata diya — sirf status badge
              onTap: null, // individual document tile click nahi karega
            ),
            if (i < business.documents.length - 1) const _TileDivider(),
          ]);
        }),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: GestureDetector(
            onTap: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => DocumentManagePage(business: business)),
              );
              if (updated == true) {
                onDocumentsChanged?.call();
                _snack(context, 'Documents updated');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(color: context.kPL, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.kPB)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(LucideIcons.upload, size: 14, color: context.kP), const SizedBox(width: 7), Text('Upload / Update Documents',
               style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.kP))]),
            ),
          ),
        ),
      ]),
    );
  }

  IconData _docIcon(String name) {
    if (name.contains('PAN')) return LucideIcons.creditCard;
    if (name.contains('Aadhaar')) return LucideIcons.badgeCheck;
    if (name.contains('GST')) return LucideIcons.receipt;
    if (name.contains('Drug') || name.contains('Pharma')) return LucideIcons.pill;
    if (name.contains('FSSAI')) return LucideIcons.award;
    return LucideIcons.fileBadge;
  }

  Widget _badge(String status) {
    late Color fg, bg; late String label;
    switch (status) {
      case 'verified': fg = const Color(0xFF16A34A); bg = const Color(0xFFDCFCE7); label = 'Verified'; break;
      case 'rejected':  fg = const Color(0xFFEF4444); bg = const Color(0xFFFEF2F2); label = 'Rejected';  break;
      default:         fg = const Color(0xFFF59E0B); bg = const Color(0xFFFFFBEB); label = 'Pending';
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)), child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)));
  }
}

// ── Notifications ─────────────────────────────────────────────────
class _NotificationsSection extends StatefulWidget {
  const _NotificationsSection();
  @override State<_NotificationsSection> createState() => _NotificationsSectionState();

}
class _NotificationsSectionState extends State<_NotificationsSection> {
  bool _sound = true, _updates = true, _payment = true, _msgs = true, _stock = false, _offers = false;
  @override
  Widget build(BuildContext context) => _SectionCard(
    title: 'Notifications', icon: LucideIcons.bell,
    child: Column(children: [
      _SwitchTile(icon: LucideIcons.volume2,       title: 'New Order Sound',    subtitle: 'Play sound on new orders',        value: _sound,   onChanged: (v) => setState(() => _sound   = v)),
      const _TileDivider(),
      _SwitchTile(icon: LucideIcons.packageSearch, title: 'Order Updates',      subtitle: 'Status change notifications',     value: _updates, onChanged: (v) => setState(() => _updates = v)),
      const _TileDivider(),
      _SwitchTile(icon: LucideIcons.indianRupee,   title: 'Payment Alerts',     subtitle: 'Settlements & payouts',           value: _payment, onChanged: (v) => setState(() => _payment = v)),
      const _TileDivider(),
      _SwitchTile(icon: LucideIcons.messageCircle, title: 'Customer Messages',  subtitle: 'Chat messages from customers',    value: _msgs,    onChanged: (v) => setState(() => _msgs    = v)),
      const _TileDivider(),
      _SwitchTile(icon: LucideIcons.alertTriangle, title: 'Low Stock Alerts',   subtitle: 'Inventory running low',           value: _stock,   onChanged: (v) => setState(() => _stock   = v)),
      const _TileDivider(),
      _SwitchTile(icon: LucideIcons.tags,          title: 'Offer Notifications',subtitle: 'Promotions & deals updates',      value: _offers,  onChanged: (v) => setState(() => _offers  = v)),
    ]),
  );
}

// ── Security ──────────────────────────────────────────────────────
class _SecuritySection extends StatefulWidget {
  const _SecuritySection();
  @override State<_SecuritySection> createState() => _SecuritySectionState();
}
class _SecuritySectionState extends State<_SecuritySection> {
  bool _fp = false;

  // ════════════════════════════════════════════════════════════════
  // LOGOUT — confirm karega, fir PIN login route par navigate karega
  // ════════════════════════════════════════════════════════════════
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.kDarkText)),
        content: const Text('Are you sure you want to logout from this device?', style: TextStyle(fontSize: 13.5, color: AppColors.kLightText, height: 1.4)),
        actionsPadding: const EdgeInsets.fromLTRB(8, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.kLightText, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // dialog band karo
              _performLogout();
            },
            child: const Text('Logout', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _performLogout() {
    // TODO: yahan apna session/token clear karne wala logic daalo (SharedPreferences, etc.)
    // ⚠️ Apna actual PIN-login route path yaha confirm karke daalo
    context.go('/pin-login');
  }

  // ════════════════════════════════════════════════════════════════
  // DELETE ACCOUNT — confirm karega, fir Login route par navigate karega
  // ════════════════════════════════════════════════════════════════
  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
        content: const Text(
          'This action is permanent and cannot be undone. All your business data, orders, and account information will be permanently deleted.\n\nAre you sure you want to continue?',
          style: TextStyle(fontSize: 13.5, color: AppColors.kLightText, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(8, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.kLightText, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // dialog band karo
              _performDeleteAccount();
            },
            child: const Text('Delete Forever', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _performDeleteAccount() {
    // TODO: yahan backend API call karo account delete karne ke liye
    // ⚠️ Apna actual Login screen ka route path yaha confirm karke daalo
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: 'Security', icon: LucideIcons.shield,
    child: Column(children: [
      _Tile(
        icon: LucideIcons.keyRound,
        title: 'Change Login PIN',
        subtitle: 'Update your 4-digit PIN',
        onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const _ChangePinSheet()),
      ),
      const _TileDivider(),
      _Tile(
        icon: LucideIcons.logOut,
        title: 'Logout',
        subtitle: 'Sign out of this device',
        onTap: _confirmLogout,
      ),
      const _TileDivider(),
      _Tile(
        icon: LucideIcons.userX,
        title: 'Delete Account',
        subtitle: 'Permanently remove your account',
        destructive: true,
        onTap: _confirmDeleteAccount,
      ),
    ]),
  );
}

// ── Help & Support ────────────────────────────────────────────────
class _HelpSection extends StatelessWidget {
  const _HelpSection();

  @override
  Widget build(BuildContext context) => _SectionCard(
        title: 'Help & Support',
        icon: LucideIcons.lifeBuoy,
        child: Column(children: [
          _Tile(
            icon: LucideIcons.helpCircle,
            title: 'Help Center',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpCenterScreen())),
          ),
          const _TileDivider(),
          _Tile(
            icon: LucideIcons.messageSquare,
            title: 'Chat Support',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatSupportScreen())),
          ),
          const _TileDivider(),
          _Tile(
            icon: LucideIcons.phone,
            title: 'Call Support',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CallSupportScreen())),
          ),
          const _TileDivider(),
          _Tile(
            icon: LucideIcons.bookOpen,
            title: 'FAQs',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FaqScreen())),
          ),
          const _TileDivider(),
          _Tile(
            icon: LucideIcons.flag,
            title: 'Report a Problem',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportProblemScreen())),
          ),
        ]),
      );
}

// ════════════════════════════════════════════════════════════════
// BUSINESS MODEL EXTENSION
// Add this field to BusinessModel and MockData:
//   final List<String> sellingCategories;
// Example default in MockData:
//   sellingCategories: ['fruits_veg', 'dairy', 'snacks'],
// ════════════════════════════════════════════════════════════════

// ════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ════════════════════════════════════════════════════════════════

class BusinessSettingsScreen extends StatefulWidget {

  final BusinessModel business;


  const BusinessSettingsScreen({
    super.key,
    required this.business,
  });


  @override
  State<BusinessSettingsScreen> createState()
      => _BusinessSettingsScreenState();

}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  late BusinessModel _active;

  @override
  void initState() {
    super.initState();
    _active = widget.business;
  }

@override
void didUpdateWidget(
    covariant BusinessSettingsScreen oldWidget) {
  super.didUpdateWidget(oldWidget);

  if (oldWidget.business.id != widget.business.id) {
    setState(() {
      _active = widget.business;
    });
  }
}


void _switchBusiness(BusinessModel b) {
  if (b.status != BusinessStatus.approved) return;

  setState(() => _active = b);
}

  void _addNewBusiness() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessTypeScreen()))
        .then((_) => setState(() {}));
  }

void _refreshActiveBusiness() {
  setState(() {
    // Should fetch from firestore here
  });
}
  @override
  Widget build(BuildContext context) {
    final others = <BusinessModel>[]; // In real app, fetch from Firestore or pass from Dashboard

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: AppColors.kBackground, elevation: 0,
        surfaceTintColor: Colors.transparent, titleSpacing: 18, toolbarHeight: 60,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Manage', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.kLightText, letterSpacing: 0.2)),
          const Text('Settings', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.kDarkText, letterSpacing: -0.4)),
        ]),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 6, bottom: 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(color: context.kPL, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(LucideIcons.store, size: 13, color: context.kP),
                const SizedBox(width: 7),
                Expanded(child: Text.rich(TextSpan(children: [
                  TextSpan(text: 'Editing settings for ', style: TextStyle(fontSize: 12, color: context.kP.withOpacity(0.8))),
                  TextSpan(text: _active.name, style: TextStyle(fontSize: 12, color: context.kP, fontWeight: FontWeight.w800)),
                ]))),
              ]),
            ),
            _BusinessProfileSection(business: _active),
            _ManageBusinessSection(current: _active, others: others, onSwitch: _switchBusiness, onAddNew: _addNewBusiness),
            const _BusinessHoursSection(),
            // ── NEW: Selling Categories section ────────────────
            _SellingCategoriesSection(business: _active),
            _BusinessSpecificSection(businessType: _active.businessType),
            const _DeliverySettingsSection(),
            _PaymentsSection(business: _active),
            _LegalSection(business: _active, onDocumentsChanged: _refreshActiveBusiness),
            const _NotificationsSection(),
            const _SecuritySection(),
            const _HelpSection(),
          ]),
        ),
      ),
    );
  }
}