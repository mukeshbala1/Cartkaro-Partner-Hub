import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/auth_service.dart';

class BusinessSelectorScreen extends StatefulWidget {
  const BusinessSelectorScreen({Key? key}) : super(key: key);

  @override
  State<BusinessSelectorScreen> createState() => _BusinessSelectorScreenState();
}

class _BusinessSelectorScreenState extends State<BusinessSelectorScreen> {
  final user = FirebaseAuth.instance.currentUser;

  IconData _getIconForType(String type) {
    switch (type) {
      case 'grocery': return LucideIcons.shoppingCart;
      case 'restaurant': return LucideIcons.utensilsCrossed;
      case 'medical': return LucideIcons.pill;
      default: return LucideIcons.store;
    }
  }

  String _getLabelForType(String type) {
    switch (type) {
      case 'grocery': return 'Grocery Store';
      case 'restaurant': return 'Restaurant';
      case 'medical': return 'Medical Store';
      default: return 'Store';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.kDarkText),
          onPressed: () async {
            final hasPin = await AuthService.isPinSet();
            if (hasPin) {
              if (context.mounted) context.go('/pin-login');
            } else {
              if (context.mounted) context.go('/login');
            }
          },
        ),
        title: const Text('Select Business', style: TextStyle(color: AppColors.kDarkText, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: user == null
            ? const Center(child: Text("Not logged in"))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('businesses')
                    .where('ownerUid', isEqualTo: user!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  
                  final docs = snapshot.data?.docs ?? [];
                  
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome Back!",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kDarkText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "You have multiple businesses. Please select one to continue to its dashboard.",
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.kLightText,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Expanded(
                          child: ListView.separated(
                            itemCount: docs.length + 1, // +1 for "Add new"
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              if (index == docs.length) {
                                return _buildAddNewButton();
                              }
                              
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final type = data['businessType'] ?? 'grocery';
                              final name = data['storeName'] ?? data['restaurantName'] ?? data['medicalName'] ?? 'Unnamed Business';
                              
                              return _buildBusinessCard(
                                name: name,
                                type: type,
                                onTap: () => context.go('/dashboard', extra: doc.id),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildBusinessCard({required String name, required String type, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.kBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.kPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_getIconForType(type), color: AppColors.kPrimary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.kDarkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getLabelForType(type),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.kLightText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.kLightText),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewButton() {
    return GestureDetector(
      onTap: () => context.go('/business-type'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.kPrimary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.kPrimary.withOpacity(0.2), style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.plusCircle, color: AppColors.kPrimary),
            const SizedBox(width: 12),
            const Text(
              "Register New Business",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
