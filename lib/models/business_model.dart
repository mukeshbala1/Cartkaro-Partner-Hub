// ═══════════════════════════════════════════════════════
// business_model.dart
// CartKaro Partner Hub
// ═══════════════════════════════════════════════════════

enum BusinessStatus { approved, pending, rejected }

enum BusinessType { grocery, restaurant, medical }

// ─────────────────────────────
// DOCUMENT MODEL
// ─────────────────────────────
class BusinessDocument {
  final String name;
  final String number;
  final String status;
  final String? filePath;
  final String? expiryDate;

  const BusinessDocument({
    required this.name,
    required this.number,
    required this.status,
    this.filePath,
    this.expiryDate,
  });

  // NEW: needed to update status/filePath after re-upload
  BusinessDocument copyWith({
    String? status,
    String? filePath,
  }) {
    return BusinessDocument(
      name: name,
      number: number,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      expiryDate: expiryDate,
    );
  }
}

// ─────────────────────────────
// BANK MODEL
// ─────────────────────────────
class BankAccount {
  final String bankName;
  final String accountNumberMasked;
  final String ifsc;
  final bool verified;

  const BankAccount({
    required this.bankName,
    required this.accountNumberMasked,
    required this.ifsc,
    required this.verified,
  });
}

// ─────────────────────────────
// BUSINESS MODEL
// ─────────────────────────────
class BusinessModel {
  final String id;
  final String name;

  final BusinessType type;
  final BusinessStatus status;

  final String logoUrl;
  final String bannerUrl;

  final String ownerName;
  final String mobileNumber;
  final String email;

  final String address;
  final double latitude;
  final double longitude;

  final List<String> sellingCategories;

  final bool isLive;

  final double todayRevenue;
  final double revenueGrowthPct;

  final int totalOrders;
  final int completedOrders;
  final int pendingOrders;

  final int activeItemCount;
  final double avgRating;

  
  final BankAccount bank;

  final List<BusinessDocument> documents;

  const BusinessModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.logoUrl,
    required this.bannerUrl,
    required this.ownerName,
    required this.mobileNumber,
    required this.email,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.sellingCategories,
    required this.isLive,
    required this.todayRevenue,
    required this.revenueGrowthPct,
    required this.totalOrders,
    required this.completedOrders,
    required this.pendingOrders,
    required this.activeItemCount,
    required this.avgRating,
    required this.bank,
    required this.documents,
  });

  String get businessType {
    switch (type) {
      case BusinessType.restaurant:
        return "restaurant";
      case BusinessType.medical:
        return "medical";
      case BusinessType.grocery:
        return "grocery";
    }
  }

  String get businessTypeLabel {
    switch (type) {
      case BusinessType.restaurant:
        return "Restaurant";
      case BusinessType.medical:
        return "Medical Store";
      case BusinessType.grocery:
        return "Grocery Store";
    }
  }

  String get itemName {
    switch (type) {
      case BusinessType.restaurant:
        return "Menu Items";
      case BusinessType.medical:
        return "Medicines";
      case BusinessType.grocery:
        return "Products";
    }
  }

  String get displayName => name;

  factory BusinessModel.empty({
    String? id,
    String? name,
    BusinessType? type,
    BusinessStatus? status,
    String? ownerName,
    String? mobileNumber,
  }) {
    return BusinessModel(
      id: id ?? '',
      name: name ?? 'My Restaurant',
      type: type ?? BusinessType.restaurant,
      status: status ?? BusinessStatus.pending,
      logoUrl: '',
      bannerUrl: '',
      ownerName: ownerName ?? 'Store Partner',
      mobileNumber: mobileNumber ?? '',
      email: '',
      address: 'Address not set',
      latitude: 0.0,
      longitude: 0.0,
      sellingCategories: const [],
      isLive: false,
      todayRevenue: 0.0,
      revenueGrowthPct: 0.0,
      totalOrders: 0,
      completedOrders: 0,
      pendingOrders: 0,
      activeItemCount: 0,
      avgRating: 0.0,
      bank: const BankAccount(
        bankName: 'Bank Account',
        accountNumberMasked: '',
        ifsc: '',
        verified: false,
      ),
      documents: const [],
    );
  }

  factory BusinessModel.fromFirestore(Map<String, dynamic> data, String id) {
    // Parse business type
    final typeStr = (data['businessType'] as String?)?.toLowerCase();
    BusinessType type = BusinessType.grocery;
    if (typeStr == 'restaurant' || typeStr == 'cafe') type = BusinessType.restaurant;
    if (typeStr == 'medical' || typeStr == 'pharmacy') type = BusinessType.medical;

    // Parse status
    final statusStr = (data['status'] as String?)?.toLowerCase();
    BusinessStatus status = BusinessStatus.approved;
    if (statusStr == 'pending' ||
        statusStr == 'under_verification' ||
        statusStr == 'in_review' ||
        statusStr == 'verification_pending') {
      status = BusinessStatus.pending;
    } else if (statusStr == 'rejected') {
      status = BusinessStatus.rejected;
    } else if (statusStr == 'approved' || statusStr == 'verified' || statusStr == 'active') {
      status = BusinessStatus.approved;
    }

    // Parse documents
    List<BusinessDocument> docs = [];
    if (data['fssaiNumber'] != null && data['fssaiNumber'].toString().trim().isNotEmpty) {
      docs.add(BusinessDocument(
        name: "FSSAI Certificate",
        number: data['fssaiNumber'].toString().trim(),
        status: "verified",
        filePath: data['fssaiCertPath'] as String?,
      ));
    }
    if (data['gstNumber'] != null && data['gstNumber'].toString().trim().isNotEmpty) {
      docs.add(BusinessDocument(
        name: "GST Certificate",
        number: data['gstNumber'].toString().trim(),
        status: "verified",
        filePath: data['gstCertPath'] as String?,
      ));
    }
    if (data['pan'] != null && data['pan'].toString().trim().isNotEmpty) {
      docs.add(BusinessDocument(
        name: "PAN Card",
        number: data['pan'].toString().trim(),
        status: "verified",
        filePath: data['panDocPath'] as String?,
      ));
    }
    if (data['drugLicense'] != null && data['drugLicense'].toString().trim().isNotEmpty) {
      docs.add(BusinessDocument(
        name: "Drug License",
        number: data['drugLicense'].toString().trim(),
        status: "verified",
        filePath: data['drugLicenseCertPath'] as String?,
      ));
    }
    if (data['pharmacistReg'] != null && data['pharmacistReg'].toString().trim().isNotEmpty) {
      docs.add(BusinessDocument(
        name: "Pharmacist Registration",
        number: data['pharmacistReg'].toString().trim(),
        status: "verified",
        filePath: data['pharmacistCertPath'] as String?,
      ));
    }
    if (data['tradeLicense'] != null && data['tradeLicense'].toString().trim().isNotEmpty) {
      docs.add(BusinessDocument(
        name: "Trade License",
        number: data['tradeLicense'].toString().trim(),
        status: "verified",
        filePath: data['tradeLicensePath'] as String?,
      ));
    }

    final realName = (data['name'] ?? data['storeName'] ?? data['restaurantName'] ?? data['medicalName'] ?? 'My Store').toString();
    final realAddress = (data['address'] ?? data['restaurantAddress'] ?? data['storeAddress'] ?? data['medicalAddress'] ?? data['area'] ?? '').toString();
    final realLogo = (data['logoUrl'] ?? data['restaurantLogoPath'] ?? data['storeLogoPath'] ?? data['medicalLogo'] ?? '').toString();
    final realBanner = (data['bannerUrl'] ?? data['restaurantBannerPath'] ?? data['storeBannerPath'] ?? data['medicalBanner'] ?? '').toString();
    final realMobile = (data['mobile'] ?? data['phoneNumber'] ?? data['altMobile'] ?? '').toString();
    final realOwner = (data['ownerName'] ?? '').toString();
    final realEmail = (data['email'] ?? '').toString();

    return BusinessModel(
      id: id,
      name: realName.isNotEmpty ? realName : 'My Store',
      type: type,
      status: status,
      logoUrl: realLogo,
      bannerUrl: realBanner,
      ownerName: realOwner.isNotEmpty ? realOwner : 'Partner Owner',
      mobileNumber: realMobile,
      email: realEmail,
      address: realAddress.isNotEmpty ? realAddress : 'No Address Provided',
      latitude: double.tryParse(data['lat']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(data['lng']?.toString() ?? '0') ?? 0.0,
      sellingCategories: (data['categories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isLive: data['isLive'] == true,
      todayRevenue: double.tryParse(data['todayRevenue']?.toString() ?? '0') ?? 0.0,
      revenueGrowthPct: double.tryParse(data['revenueGrowthPct']?.toString() ?? '0') ?? 0.0,
      totalOrders: int.tryParse(data['totalOrders']?.toString() ?? '0') ?? 0,
      completedOrders: int.tryParse(data['completedOrders']?.toString() ?? '0') ?? 0,
      pendingOrders: int.tryParse(data['pendingOrders']?.toString() ?? '0') ?? 0,
      activeItemCount: int.tryParse(data['activeItemCount']?.toString() ?? '0') ?? 0,
      avgRating: double.tryParse(data['avgRating']?.toString() ?? '0') ?? 0.0,
      bank: BankAccount(
        bankName: data['bank'] ?? 'Bank Account',
        accountNumberMasked: (data['accountNumber']?.toString() ?? '').length > 4 
            ? 'XXXXXX${data['accountNumber'].toString().substring(data['accountNumber'].toString().length - 4)}'
            : (data['accountNumber']?.toString() ?? 'Not Set'),
        ifsc: data['ifsc'] ?? '',
        verified: true,
      ),
      documents: docs,
    );
  }

  BusinessModel copyWith({
    String? id,
    String? name,
    BusinessType? type,
    BusinessStatus? status,
    String? ownerName,
    bool? isLive,
    List<String>? sellingCategories,
    List<BusinessDocument>? documents,
  }) {
    return BusinessModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      logoUrl: logoUrl,
      bannerUrl: bannerUrl,
      ownerName: ownerName ?? this.ownerName,
      mobileNumber: mobileNumber,
      email: email,
      address: address,
      latitude: latitude,
      longitude: longitude,
      sellingCategories: sellingCategories ?? this.sellingCategories,
      isLive: isLive ?? this.isLive,
      todayRevenue: todayRevenue,
      revenueGrowthPct: revenueGrowthPct,
      totalOrders: totalOrders,
      completedOrders: completedOrders,
      pendingOrders: pendingOrders,
      activeItemCount: activeItemCount,
      avgRating: avgRating,
      bank: bank,
      documents: documents ?? this.documents,
    );
  }
}