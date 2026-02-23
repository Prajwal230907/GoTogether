import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();
  
  String? _verificationId;
  bool _codeSent = false;
  bool _isLoading = false;
  bool _isDriver = false;
  bool _showPhoneLogin = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhone() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter phone number')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91${_phoneController.text.trim()}',
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          _checkUserExists();
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Verification Failed')));
          setState(() => _isLoading = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _signInWithOTP() async {
    setState(() => _isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      _checkUserExists();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP')));
    }
  }

  Future<void> _checkUserExists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
            final newRole = _isDriver ? 'driver' : 'passenger';
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'role': newRole});
            if (mounted) {
               if (_isDriver) {
                   context.go('/driver_home');
               } else {
                   context.go('/home'); // AuthRouter handles fallback
               }
            }
        } else {
            if (mounted) context.go('/register');
        }
      } else {
        if (mounted) context.go('/register');
      }
    } catch (e) {
       setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1723) : const Color(0xFFF5F6F8);
    final textColor = isDark ? Colors.white : const Color(0xFF0F1723);
    
    final primaryColor = _isDriver ? const Color(0xFFA855F7) : const Color(0xFF2E7EFF);
    final primaryColorLight = _isDriver ? const Color(0xFFEC4899) : const Color(0xFF00D2FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Role Toggle
                    Center(child: _buildRoleToggle(isDark)),
                    
                    const SizedBox(height: 32),
                    
                    // Logo Area
                    _buildLogoArea(primaryColor, primaryColorLight),
                    
                    const SizedBox(height: 48),

                    if (_isLoading)
                      Expanded(child: Center(child: CircularProgressIndicator(color: primaryColor)))
                    else if (_showPhoneLogin)
                      Expanded(child: _codeSent ? _buildOTPForm(primaryColor) : _buildPhoneForm(primaryColor))
                    else
                      Expanded(child: _buildMainForm(primaryColor, isDark)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleToggle(bool isDark) {
    return Container(
      width: 280,
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _isDriver ? 134 : 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 136,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: _isDriver 
                    ? [const Color(0xFFA855F7), const Color(0xFFEC4899)]
                    : [const Color(0xFF2E7EFF), const Color(0xFF00D2FF)],
                ),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() { _isDriver = false; _showPhoneLogin = false; }),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Passenger',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _isDriver ? (isDark ? Colors.white70 : Colors.black87) : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() { _isDriver = true; _showPhoneLogin = false; }),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Driver',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: !_isDriver ? (isDark ? Colors.white70 : Colors.black87) : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoArea(Color primaryColor, Color primaryColorLight) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned(
          top: -20,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(0.1),
            ),
          ),
        ),
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Icon(Icons.commute, size: 40, color: primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'GoTogether',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'College-exclusive ride sharing',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainForm(Color primaryColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // College Email Input
        Text(
          '   College Email',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 24),
              Expanded(
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'name@university.edu',
                    border: InputBorder.none,
                    hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Simulate email logic -> fallback to phone login flow or next step
                  setState(() { _showPhoneLogin = true; });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),

        if (_isDriver) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: const Border(left: BorderSide(color: Color(0xFFA855F7), width: 4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.directions_car, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle Verification Required',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "To start driving, you'll need to upload your registration and insurance documents.",
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],

        const SizedBox(height: 32),
        // Or Divider
        Row(
          children: [
            Expanded(child: Container(height: 1, color: isDark ? Colors.white12 : Colors.black12)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('OR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),
            ),
            Expanded(child: Container(height: 1, color: isDark ? Colors.white12 : Colors.black12)),
          ],
        ),
        const SizedBox(height: 24),

        // Social Buttons
        Row(
          children: [
            Expanded(
              child: _buildSocialButton('Google', Icons.g_mobiledata, isDark),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSocialButton('Phone OTP', Icons.smartphone, isDark, primaryColor: primaryColor, onTap: () {
                setState(() => _showPhoneLogin = true);
              }),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        // Scan ID
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.badge, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scan Student ID', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Verified campus access only', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Icon(Icons.qr_code_scanner, color: primaryColor.withOpacity(0.5)),
            ],
          ),
        ),

        const Spacer(),
        // Footer
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0, top: 16.0),
          child: Column(
            children: [
              Text(
                'PREMIUM COLLEGE RIDESHARE NETWORK',
                style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Terms', style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w600)),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('•', style: TextStyle(color: Colors.grey))),
                  Text('Privacy', style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w600)),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(String text, IconData icon, bool isDark, {Color? primaryColor, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isDark ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: primaryColor ?? (isDark ? Colors.white : Colors.black87)),
            const SizedBox(width: 8),
            Text(text, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneForm(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _showPhoneLogin = false),
            ),
            const Text('Enter Phone Number', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: '9876543210',
            prefixIcon: const Icon(Icons.phone),
            prefixText: '+91 ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _verifyPhone,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Send OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildOTPForm(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
         Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _codeSent = false),
            ),
            const Text('Verify OTP', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Code sent to +91 ${_phoneController.text}',
          style: const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _otpController,
          decoration: InputDecoration(
            labelText: 'Enter OTP',
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
          ),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, letterSpacing: 2, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _signInWithOTP,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Verify & Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
