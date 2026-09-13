import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../../models/business_model.dart';

enum _DocAction { upload, update }

class DocumentManagePage extends StatefulWidget {
  final BusinessModel business;

  const DocumentManagePage({
    super.key,
    required this.business,
  });

  @override
  State<DocumentManagePage> createState() => _DocumentManagePageState();
}

class _DocumentManagePageState extends State<DocumentManagePage> {
  late BusinessModel _business;
  _DocAction? _action;
  bool _hasChanges = false;
  String? _processingDoc;

  // STRICTLY YOUR NAVY BLUE COLOR
  static const Color kPrimary = Color.fromARGB(255, 34, 53, 84);
  static const Color kBg = Color(0xFFF5F6F8);

  @override
  void initState() {
    super.initState();
    _business = widget.business;
  }

  void _goBack() {
    if (_action != null) {
      setState(() {
        _action = null;
      });
    } else {
      Navigator.pop(context, _hasChanges);
    }
  }

  // ------------------------------------------------
  // DOCUMENT FORM
  // ------------------------------------------------
  Future<void> _openDocumentForm(BusinessDocument doc) async {
    final numberController = TextEditingController(text: doc.number);
    String? selectedPath;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 12,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Text(
                    doc.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: kPrimary, // Changed to your Navy Blue
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: numberController,
                    maxLength: _docLength(doc.name),
                    keyboardType: _numberOnly(doc.name)
                        ? TextInputType.number
                        : TextInputType.text,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(fontWeight: FontWeight.w500, color: kPrimary),
                    decoration: InputDecoration(
                      labelText: "${doc.name} Number",
                      labelStyle: TextStyle(color: Colors.grey.shade600),
                      filled: true,
                      fillColor: kBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: kPrimary, width: 1.5),
                      ),
                      counterText: "",
                    ),
                  ),
                  const SizedBox(height: 20),
                  _uploadOption(
                    icon: LucideIcons.camera,
                    title: "Take Photo",
                    subtitle: "Use camera to scan document",
                    onTap: () async {
                      final picker = ImagePicker();
                      final file = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 80,
                      );
                      setSheet(() {
                        selectedPath = file?.path;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _uploadOption(
                    icon: LucideIcons.file,
                    title: "Choose from File",
                    subtitle: "Upload PDF or Image from gallery",
                    onTap: () async {
                      final result = await FilePicker.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                      );
                      setSheet(() {
                        selectedPath = result?.files.single.path;
                      });
                    },
                  ),
                  if (selectedPath != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.checkCircle2, color: Colors.green.shade600, size: 20),
                          const SizedBox(width: 10),
                          const Text(
                            "Document selected successfully",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary, // Your Navy Blue
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        if (!_validateDoc(doc.name, numberController.text)) {
                          _toast("Invalid ${doc.name} number");
                          return;
                        }
                        if (selectedPath == null) {
                          _toast("Please upload a document");
                          return;
                        }
                        Navigator.pop(ctx);
                        _submitDocument(doc, selectedPath!);
                      },
                      child: const Text(
                        "Submit for Verification",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------
  // Upload option card
  // ------------------------------------------------
  Widget _uploadOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1), // Navy Blue with opacity
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: kPrimary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: kPrimary, // Changed to Navy Blue
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------
  // Submit Document
  // ------------------------------------------------
  Future<void> _submitDocument(BusinessDocument doc, String filePath) async {
    final oldStatus = doc.status;

    setState(() {
      _processingDoc = doc.name;
      _business = _business.copyWith(
        documents: _business.documents.map((d) {
          return d.name == doc.name
              ? d.copyWith(status: "pending", filePath: filePath)
              : d;
        }).toList(),
      );
      _hasChanges = true;
    });

    await Future.delayed(const Duration(seconds: 2));
    final ok = true; // In a real app, update via API/Firestore

    if (!mounted) return;

    if (!ok) {
      setState(() {
        _business = _business.copyWith(
          documents: _business.documents.map((d) {
            return d.name == doc.name ? d.copyWith(status: oldStatus) : d;
          }).toList(),
        );
        _processingDoc = null;
      });
      _toast("Upload failed");
      return;
    }

    setState(() {
      _processingDoc = null;
    });
    _toast("${doc.name} submitted for verification");
  }

  // ------------------------------------------------
  // Toast
  // ------------------------------------------------
  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: kPrimary, // Changed to Navy Blue
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ------------------------------------------------
  // Build
  // ------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: kPrimary), // Navy Blue Icon
          onPressed: _goBack,
        ),
        title: Text(
          _action == null
              ? "Manage Documents"
              : _action == _DocAction.upload
                  ? "Upload Document"
                  : "Update Document",
          style: const TextStyle(
            color: kPrimary, // Navy Blue Title
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: _action == null ? _buildActionChoice() : _buildDocumentList(),
    );
  }

  Widget _buildActionChoice() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        _actionCard(
          icon: LucideIcons.uploadCloud,
          title: "Upload New Document",
          subtitle: "Submit a brand new document for verification",
          onTap: () {
            setState(() {
              _action = _DocAction.upload;
            });
          },
        ),
        const SizedBox(height: 16),
        _actionCard(
          icon: LucideIcons.refreshCw,
          title: "Update Existing Document",
          subtitle: "Replace a rejected or expired document",
          onTap: () {
            setState(() {
              _action = _DocAction.update;
            });
          },
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.05), // Soft Navy Blue Shadow
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1), // Navy Blue with opacity
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: kPrimary, size: 24), // Navy Blue Icon
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: kPrimary, // Navy Blue Text
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 20, color: Colors.grey.shade400)
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------
  // Document List
  // ------------------------------------------------
  Widget _buildDocumentList() {
    final docs = _business.documents;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: docs.length + 1,
      itemBuilder: (ctx, i) {
        if (i == docs.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 40),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary, // Navy Blue Button
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context, _hasChanges);
                },
                child: const Text(
                  "Done",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }

        final doc = docs[i];
        final loading = _processingDoc == doc.name;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withOpacity(0.04), // Soft Navy Blue Shadow
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: loading ? null : () => _openDocumentForm(doc),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.08), // Navy Blue very light background
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_docIcon(doc.name), color: kPrimary, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: kPrimary, // Navy Blue Text
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            doc.number.isEmpty ? "Not Provided" : doc.number,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                          )
                        : _statusBadge(doc.status),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------
  // Validation
  // ------------------------------------------------
  int _docLength(String name) {
    if (name.contains("Aadhaar")) return 12;
    if (name.contains("PAN")) return 10;
    if (name.contains("GST")) return 15;
    if (name.contains("FSSAI")) return 14;
    return 30;
  }

  bool _numberOnly(String name) {
    return name.contains("Aadhaar") || name.contains("FSSAI");
  }

  bool _validateDoc(String name, String value) {
    if (name.contains("Aadhaar")) return value.length == 12;
    if (name.contains("PAN")) return value.length == 10;
    if (name.contains("GST")) return value.length == 15;
    if (name.contains("FSSAI")) return value.length == 14;
    return value.length >= 5;
  }

  IconData _docIcon(String name) {
    if (name.contains("PAN")) return LucideIcons.creditCard;
    if (name.contains("Aadhaar")) return LucideIcons.badgeCheck;
    if (name.contains("GST")) return LucideIcons.receipt;
    if (name.contains("Drug")) return LucideIcons.pill;
    if (name.contains("FSSAI")) return LucideIcons.award;
    return LucideIcons.fileBadge;
  }

  // ------------------------------------------------
  // Status Badge
  // ------------------------------------------------
  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    String text;

    switch (status.toLowerCase()) {
      case "verified":
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        text = "Verified";
        break;
      case "rejected":
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        text = "Rejected";
        break;
      default:
        // Changed to a vibrant orange
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        text = "Pending";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}