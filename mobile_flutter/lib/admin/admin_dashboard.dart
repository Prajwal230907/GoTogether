import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  void _reviewVerification(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final driverId = doc.id;
    final name = data['name'] ?? 'Unknown';
    final vehicleModel = data['vehicleModel'] ?? 'Unknown';
    final plateNumber = data['plateNumber'] ?? 'Unknown';
    final collegeIdUrl = data['collegeIdUrl'] ?? '';
    final licenseUrl = data['licenseUrl'] ?? '';
    final rcUrl = data['rcUrl'] ?? '';
    final selfieUrl = data['selfieUrl'] ?? '';
    final vehicleUrl = data['vehicleUrl'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF171C26),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return _VerificationReviewModal(
          docId: driverId,
          name: name,
          vehicleModel: vehicleModel,
          plateNumber: plateNumber,
          collegeIdUrl: collegeIdUrl,
          licenseUrl: licenseUrl,
          rcUrl: rcUrl,
          selfieUrl: selfieUrl,
          vehicleUrl: vehicleUrl,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A120B),
      appBar: AppBar(
        title: Text('Admin Verification Panel', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF171C26),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('verifications')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading verifications', style: TextStyle(color: Colors.redAccent)));
          }

          final finalDocs = snapshot.data?.docs ?? [];
          if (finalDocs.isEmpty) {
            return const Center(child: Text('No pending verifications', style: TextStyle(color: Colors.white54, fontSize: 16)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: finalDocs.length,
            itemBuilder: (context, index) {
              final doc = finalDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              return Card(
                color: const Color(0xFF171C26),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(data['name'] ?? 'Unknown Driver', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text("${data['college'] ?? 'N/A'}\n${data['vehicleModel'] ?? ''} - ${data['plateNumber'] ?? ''}", style: const TextStyle(color: Colors.white70)),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                    onPressed: () => _reviewVerification(context, doc),
                    child: const Text('Review', style: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _VerificationReviewModal extends StatefulWidget {
  final String docId;
  final String name;
  final String vehicleModel;
  final String plateNumber;
  final String collegeIdUrl;
  final String licenseUrl;
  final String rcUrl;
  final String selfieUrl;
  final String vehicleUrl;

  const _VerificationReviewModal({
    required this.docId,
    required this.name,
    required this.vehicleModel,
    required this.plateNumber,
    required this.collegeIdUrl,
    required this.licenseUrl,
    required this.rcUrl,
    required this.selfieUrl,
    required this.vehicleUrl,
  });

  @override
  State<_VerificationReviewModal> createState() => _VerificationReviewModalState();
}

class _VerificationReviewModalState extends State<_VerificationReviewModal> {
  bool _isProcessing = false;
  final _remarksController = TextEditingController();

  Future<void> _processVerification(bool isApproved) async {
    setState(() => _isProcessing = true);
    try {
      final docId = widget.docId;
      
      // Update verifications collection
      await FirebaseFirestore.instance.collection('verifications').doc(docId).update({
        'status': isApproved ? 'approved' : 'rejected',
        'verifiedAt': FieldValue.serverTimestamp(),
        'adminRemarks': isApproved ? '' : _remarksController.text.trim(),
      });

      // Sync verified status back to users collection
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'isVerified': isApproved,
        'driverVerificationStatus': isApproved ? 'verified' : 'rejected',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isApproved ? 'Driver Approved Successfully' : 'Driver Rejected'),
          backgroundColor: isApproved ? Colors.green : Colors.red,
        ));
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
       }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildDocImage(String title, String url) {
    if (url.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.error, color: Colors.white54))),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Review: ${widget.name}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
            ],
          ),
          Text('${widget.vehicleModel} • ${widget.plateNumber}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const Divider(color: Colors.white24, height: 32),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDocImage('Driver Selfie', widget.selfieUrl),
                  _buildDocImage('Driving License', widget.licenseUrl),
                  _buildDocImage('Vehicle RC', widget.rcUrl),
                  _buildDocImage('Vehicle Photo', widget.vehicleUrl),
                  _buildDocImage('College ID', widget.collegeIdUrl),
                  
                  const Text('Admin Rejection Remarks (Optional)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _remarksController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black26,
                      hintText: 'e.g., Blurry license photo',
                      hintStyle: const TextStyle(color: Colors.white30),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          if (_isProcessing)
             const Center(child: CircularProgressIndicator(color: Colors.white))
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _processVerification(false),
                    child: const Text('Reject', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _processVerification(true),
                    child: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
