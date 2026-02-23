import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColorsLight.background;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = isDark ? AppColorsDark.primary : AppColorsLight.primary;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.account_balance_wallet, color: primaryColor),
                          ),
                          const SizedBox(width: 12),
                          Text('Wallet', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                        ],
                      ),
                      CircleAvatar(
                        backgroundColor: isDark ? const Color(0xFF171C26) : Colors.white,
                        child: Icon(Icons.notifications_none, color: textColor),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Virtual Card
                        _buildVirtualCard(context),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(child: _buildActionButton(context, Icons.add_circle, 'Add Money', true)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildActionButton(context, Icons.shortcut, 'Withdraw', false)),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Linked Accounts
                        _buildSectionHeader('Linked Accounts', 'See All'),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          child: Row(
                            children: [
                              _buildAccountCard(context, Icons.qr_code_2, 'UPI ID', 'alex@gpay', true),
                              const SizedBox(width: 16),
                              _buildAccountCard(context, Icons.credit_card, 'Visa Classic', '•••• 8829', false),
                              const SizedBox(width: 16),
                              _buildAddAccountCard(context),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Recent Activities
                        _buildSectionHeader('Recent Activities', 'History'),
                        const SizedBox(height: 16),
                        _buildTransactionItem(context, 'Ride to Campus', 'Today, 10:45 AM', '-\$12.00', 'Success', Colors.red),
                        _buildTransactionItem(context, 'Split with Sarah', 'Yesterday, 08:20 PM', '+\$24.50', 'Pending', Colors.orange),
                        _buildTransactionItem(context, 'Campus Coffee Co.', 'May 12, 11:30 AM', '-\$4.75', 'Success', Colors.red),
                        _buildTransactionItem(context, 'Wallet Top-up', 'May 10, 09:00 AM', '+\$100.00', 'Success', Colors.green),
                        const SizedBox(height: 100), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Back Button (Since it's likely pushed)
          Positioned(
            bottom: 24, left: 0, right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: () => context.pop(),
                backgroundColor: primaryColor,
                child: const Icon(Icons.arrow_back),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVirtualCard(BuildContext context) {
     return AspectRatio(
       aspectRatio: 1.6,
       child: Container(
         decoration: BoxDecoration(
           borderRadius: BorderRadius.circular(24),
           gradient: const LinearGradient(
             colors: [Color(0xFF2E7EFF), Color(0xFF00C6FF)],
             begin: Alignment.topLeft,
             end: Alignment.bottomRight,
           ),
           boxShadow: [
             BoxShadow(color: const Color(0xFF2E7EFF).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
           ],
         ),
         child: Stack(
           children: [
             // Decorative Circles
             Positioned(right: -30, top: -30, child: Container(width: 150, height: 150, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle))),
             Positioned(left: -20, bottom: -20, child: Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), shape: BoxShape.circle))),
             
             Padding(
               padding: const EdgeInsets.all(24.0),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text('TOTAL BALANCE', style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 10)),
                           const SizedBox(height: 4),
                           const Row(
                             children: [
                               Text('\$248.50', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                               SizedBox(width: 8),
                               Icon(Icons.visibility_outlined, color: Colors.white30, size: 20),
                             ],
                           ),
                         ],
                       ),
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.end,
                         children: [
                           const Text('GoTogether', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                           Text('PREMIUM MEMBER', style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold)),
                         ],
                       ),
                     ],
                   ),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     crossAxisAlignment: CrossAxisAlignment.end,
                     children: [
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text('ALEX RIVERA', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600)),
                           const SizedBox(height: 4),
                           Text('•••• 4821', style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 12)),
                         ],
                       ),
                       const Icon(Icons.nfc, color: Colors.white54, size: 32),
                     ],
                   ),
                 ],
               ),
             ),
           ],
         ),
       ),
     );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, bool isPrimary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColorsDark.primary : AppColorsLight.primary;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isPrimary ? primaryColor : (isDark ? primaryColor.withOpacity(0.2) : primaryColor.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(28),
        border: isPrimary ? null : Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isPrimary ? Colors.white : primaryColor),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: isPrimary ? Colors.white : primaryColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(action, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue)),
      ],
    );
  }

  Widget _buildAccountCard(BuildContext context, IconData icon, String label, String details, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171C26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[100], shape: BoxShape.circle),
            child: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(details, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildAddAccountCard(BuildContext context) {
    return Container(
      width: 140,
      height: 110,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3), style: BorderStyle.solid), // Dashed border not easy in standard container, using solid
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, color: Colors.grey),
          SizedBox(height: 8),
          Text('Add New', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, String title, String date, String amount, String status, Color amountColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color statusColor = status == 'Success' ? Colors.green : Colors.orange;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
            child: Icon(Icons.receipt_long, color: isDark ? Colors.white70 : Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: amountColor)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(status.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
