import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// --- Theme Colors ---
const Color kNavyBlue = Color.fromARGB(255, 34, 53, 84);
const Color kBgColor = Color(0xFFF8F9FA);
const Color kStarColor = Color(0xFFF59E0B);

// --- Dummy Review Model ---
class ReviewModel {
  final String id;
  final String customerName;
  final double rating;
  final String date;
  final String comment;
  String? sellerReply;

  ReviewModel({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.date,
    required this.comment,
    this.sellerReply,
  });
}

class CustomerReviewsScreen extends StatefulWidget {
  final String businessName;

  const CustomerReviewsScreen({Key? key, required this.businessName}) : super(key: key);

  @override
  State<CustomerReviewsScreen> createState() => _CustomerReviewsScreenState();
}

class _CustomerReviewsScreenState extends State<CustomerReviewsScreen> {
  // Dummy Data for Reviews
  final List<ReviewModel> _reviews = [
    ReviewModel(
      id: 'REV001',
      customerName: 'Rahul Sharma',
      rating: 5.0,
      date: '2 hours ago',
      comment: 'Excellent service and very fresh products! Delivered on time. Will definitely order again.',
    ),
    ReviewModel(
      id: 'REV002',
      customerName: 'Priya Singh',
      rating: 4.0,
      date: '1 day ago',
      comment: 'Good quality items, but the delivery was slightly delayed. Otherwise, everything is perfect.',
      sellerReply: 'Thank you for your feedback, Priya. We apologize for the delay and will ensure faster delivery next time!',
    ),
    ReviewModel(
      id: 'REV003',
      customerName: 'Amit Patel',
      rating: 5.0,
      date: '2 days ago',
      comment: 'Loved the packaging. The UI of the app is also great.',
    ),
    ReviewModel(
      id: 'REV004',
      customerName: 'Neha Gupta',
      rating: 3.0,
      date: '3 days ago',
      comment: 'Some items were missing from my order. Had to request a refund.',
    ),
  ];

  // Quick Reply Templates
  final List<String> _quickReplies = [
    "Thank you for your amazing review! We're thrilled you liked our service.",
    "We appreciate your feedback and hope to serve you again soon!",
    "Sorry for the inconvenience. We'll work hard to improve this.",
    "Thank you for rating us! Let us know how we can make it a 5-star experience."
  ];

  void _openReplySheet(ReviewModel review) {
    final TextEditingController replyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
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
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Title
                  Row(
                    children: [
                      const Icon(LucideIcons.messageSquare, color: kNavyBlue),
                      const SizedBox(width: 10),
                      Text('Reply to ${review.customerName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavyBlue)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Customer Comment Preview
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kBgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: Text('"${review.comment}"', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87)),
                  ),
                  const SizedBox(height: 20),

                  // Quick Replies
                  const Text('Quick Replies', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickReplies.map((reply) {
                      return ActionChip(
                        label: Text(reply, maxLines: 1, overflow: TextOverflow.ellipsis),
                        labelStyle: const TextStyle(fontSize: 12, color: kNavyBlue),
                        backgroundColor: kNavyBlue.withOpacity(0.05),
                        side: BorderSide(color: kNavyBlue.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onPressed: () {
                          setSheetState(() {
                            replyController.text = reply;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Custom Message TextField
                  TextField(
                    controller: replyController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Type your custom reply here...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kNavyBlue, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Send Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kNavyBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        if (replyController.text.trim().isNotEmpty) {
                          setState(() {
                            review.sellerReply = replyController.text.trim();
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reply sent successfully!'), backgroundColor: Colors.green),
                          );
                        }
                      },
                      child: const Text('Send Reply', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: kNavyBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Customer Reviews', style: TextStyle(color: kNavyBlue, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: Column(
        children: [
          _buildRatingSummary(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _reviews.length,
              itemBuilder: (context, index) {
                return _buildReviewCard(_reviews[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Overall Rating', style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('4.9', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: kNavyBlue, height: 1)),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('/ 5.0', style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) => const Icon(LucideIcons.star, color: kStarColor, size: 20)),
              ),
              const SizedBox(height: 8),
              const Text('Based on 156 reviews', style: TextStyle(fontSize: 12, color: Colors.black45)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kStarColor.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(LucideIcons.star, color: kStarColor, size: 40),
          )
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    final bool hasReplied = review.sellerReply != null && review.sellerReply!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: kNavyBlue.withOpacity(0.1),
                    child: Text(review.customerName[0], style: const TextStyle(color: kNavyBlue, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Text(review.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                ],
              ),
              Text(review.date, style: const TextStyle(fontSize: 12, color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 12),
          
          // Stars
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < review.rating ? LucideIcons.star : LucideIcons.starOff,
                color: index < review.rating ? kStarColor : Colors.grey.shade300,
                size: 16,
              );
            }),
          ),
          const SizedBox(height: 10),
          
          // Comment
          Text(review.comment, style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4)),
          const SizedBox(height: 16),

          // Action Area (Reply Button OR Seller Reply View)
          if (hasReplied)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kBgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(LucideIcons.replyAll, size: 14, color: kNavyBlue),
                      SizedBox(width: 6),
                      Text('Your Reply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kNavyBlue)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(review.sellerReply!, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                ],
              ),
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _openReplySheet(review),
                icon: const Icon(LucideIcons.reply, size: 16, color: kNavyBlue),
                label: const Text('Reply', style: TextStyle(color: kNavyBlue, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  backgroundColor: kNavyBlue.withOpacity(0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}