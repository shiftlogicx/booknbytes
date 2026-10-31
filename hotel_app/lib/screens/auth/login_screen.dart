import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/slots_provider.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login Controllers
  final _loginEmailController = TextEditingController(text: 'owner@bombaybrasserie.com');
  final _loginPasswordController = TextEditingController(text: 'AmitYashLogic@1999');
  bool _obscureLoginPassword = true;

  // Signup Controllers
  final _ownerNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _restaurantNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _fssaiController = TextEditingController();
  final _upiController = TextEditingController();
  final _costForTwoController = TextEditingController(text: '1200');
  bool _obscureSignupPassword = true;

  final List<String> _availableCuisines = [
    'North Indian',
    'South Indian',
    'Mughlai',
    'Biryani',
    'Chinese',
    'Continental',
    'Seafood',
    'Italian',
  ];
  final Set<String> _selectedCuisines = {'North Indian', 'Biryani'};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _ownerNameController.dispose();
    _signupEmailController.dispose();
    _phoneController.dispose();
    _signupPasswordController.dispose();
    _restaurantNameController.dispose();
    _addressController.dispose();
    _fssaiController.dispose();
    _upiController.dispose();
    _costForTwoController.dispose();
    super.dispose();
  }

  void _fillQuickLogin(String email, String password) {
    HapticFeedback.selectionClick();
    setState(() {
      _loginEmailController.text = email;
      _loginPasswordController.text = password;
    });
  }

  Future<void> _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Please enter both email and password.');
      return;
    }

    HapticFeedback.mediumImpact();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final slotsProvider = Provider.of<SlotsProvider>(context, listen: false);

    final success = await authProvider.login(email, password);

    if (!mounted) return;

    if (success) {
      bookingProvider.initForRestaurant(authProvider.currentRestaurantId);
      slotsProvider.loadSlots(authProvider.currentRestaurantId);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      _showErrorSnackBar(authProvider.errorMessage ?? 'Login failed. Please check credentials.');
    }
  }

  Future<void> _handleSignup() async {
    final ownerName = _ownerNameController.text.trim();
    final email = _signupEmailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _signupPasswordController.text.trim();
    final restName = _restaurantNameController.text.trim();
    final address = _addressController.text.trim();
    final fssai = _fssaiController.text.trim();
    final upi = _upiController.text.trim();
    final cost = int.tryParse(_costForTwoController.text.trim()) ?? 1200;

    if (ownerName.isEmpty || email.isEmpty || password.isEmpty || restName.isEmpty) {
      _showErrorSnackBar('Please fill in all required fields (Name, Email, Password, Restaurant).');
      return;
    }

    if (password.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters.');
      return;
    }

    HapticFeedback.heavyImpact();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final slotsProvider = Provider.of<SlotsProvider>(context, listen: false);

    final success = await authProvider.signupOwnerAndRegisterRestaurant(
      ownerName: ownerName,
      email: email,
      password: password,
      phone: phone.isNotEmpty ? phone : '+91 98765 00000',
      restaurantName: restName,
      address: address.isNotEmpty ? address : 'Main Road, Pune',
      fssaiNumber: fssai.isNotEmpty ? fssai : '11521034000123',
      upiId: upi.isNotEmpty ? upi : '${restName.toLowerCase().replaceAll(' ', '')}@upi',
      costForTwo: cost,
      cuisines: _selectedCuisines.toList(),
    );

    if (!mounted) return;

    if (success) {
      bookingProvider.initForRestaurant(authProvider.currentRestaurantId);
      slotsProvider.loadSlots(authProvider.currentRestaurantId);

      // Show dialog with generated credentials if available
      final creds = authProvider.generatedManagerCredentials;
      if (creds != null) {
        await _showCredentialsDialog(creds);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      _showErrorSnackBar(authProvider.errorMessage ?? 'Signup failed. Please try again.');
    }
  }

  Future<void> _showCredentialsDialog(Map<String, dynamic> creds) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 28),
            SizedBox(width: 10),
            Text(
              'Restaurant Activated! 🚀',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your restaurant manager credentials have been generated and activated:',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manager ID: ${creds['email'] ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  Text('Password: ${creds['default_password'] ?? 'AmitYashLogic@1999'}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF059669))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You can reuse these credentials or your owner credentials anytime to log in.',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Proceed to Dashboard', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Brand Logo & Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF047857)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'BookNBytes Restaurant',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Powered by Supabase Edge Functions & Live DB',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Tab Bar (Sign In / Register)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A0F172A),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: const Color(0xFF0F172A),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                tabs: const [
                  Tab(text: 'Sign In'),
                  Tab(text: 'Register Restaurant'),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSignInTab(auth),
                  _buildSignUpTab(auth),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInTab(AuthProvider auth) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome Back',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sign in with your Owner or Manager credentials',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),

              // Email Input
              const Text('EMAIL OR MANAGER ID',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
              const SizedBox(height: 6),
              TextField(
                controller: _loginEmailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF059669), size: 18),
                  hintText: 'e.g. owner@bombaybrasserie.com',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5)),
                ),
              ),

              const SizedBox(height: 16),

              // Password Input
              const Text('PASSWORD',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
              const SizedBox(height: 6),
              TextField(
                controller: _loginPasswordController,
                obscureText: _obscureLoginPassword,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF059669), size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureLoginPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF94A3B8),
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
                  ),
                  hintText: 'Enter your password',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5)),
                ),
              ),

              const SizedBox(height: 24),

              // Sign In Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: auth.isLoading ? null : _handleLogin,
                  child: auth.isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Sign In to Live Floor', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // Quick One-Tap Demo Credentials
        const Text(
          'ONE-TAP VERIFIED DB ACCOUNTS',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.8),
        ),
        const SizedBox(height: 10),

        _buildQuickAccountCard(
          restaurantName: 'The Bombay Brasserie (Bengaluru)',
          role: 'Restaurant Owner',
          email: 'owner@bombaybrasserie.com',
          password: 'AmitYashLogic@1999',
        ),
        _buildQuickAccountCard(
          restaurantName: 'Punjabi Dhaba Express',
          role: 'Restaurant Manager',
          email: 'manager.respunjabidhabatest@booknbytes.app',
          password: 'AmitYashLogic@1999',
        ),
        _buildQuickAccountCard(
          restaurantName: 'The Taj Bistro (New Delhi)',
          role: 'Restaurant Partner',
          email: 'partner@tajcafe.com',
          password: 'AmitYashLogic@1999',
        ),
      ],
    );
  }

  Widget _buildQuickAccountCard({
    required String restaurantName,
    required String role,
    required String email,
    required String password,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.vpn_key_rounded, color: Color(0xFF059669), size: 16),
        ),
        title: Text(restaurantName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
        subtitle: Text('$role · $email', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        trailing: TextButton(
          onPressed: () => _fillQuickLogin(email, password),
          child: const Text('Use', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF059669), fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildSignUpTab(AuthProvider auth) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Text('SUPABASE EDGE ENGINE',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF059669), letterSpacing: 0.5)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Register New Restaurant',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Creates owner account & automatically generates manager credentials',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),

              // Owner Full Name
              _buildFieldLabel('OWNER FULL NAME *'),
              TextField(
                controller: _ownerNameController,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                decoration: _inputDecoration('e.g. Vikram Malhotra', Icons.person_outline_rounded),
              ),
              const SizedBox(height: 14),

              // Email
              _buildFieldLabel('OWNER EMAIL *'),
              TextField(
                controller: _signupEmailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                decoration: _inputDecoration('e.g. owner@myrestaurant.com', Icons.email_outlined),
              ),
              const SizedBox(height: 14),

              // Phone
              _buildFieldLabel('OWNER MOBILE NUMBER *'),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                decoration: _inputDecoration('e.g. +91 98765 43210', Icons.phone_outlined),
              ),
              const SizedBox(height: 14),

              // Password
              _buildFieldLabel('PASSWORD * (MIN 6 CHARS)'),
              TextField(
                controller: _signupPasswordController,
                obscureText: _obscureSignupPassword,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                decoration: _inputDecoration('Enter secure password', Icons.lock_outline_rounded).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureSignupPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF94A3B8),
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscureSignupPassword = !_obscureSignupPassword),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 14),

              // Restaurant Name
              _buildFieldLabel('RESTAURANT NAME *'),
              TextField(
                controller: _restaurantNameController,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                decoration: _inputDecoration('e.g. The Coastal Curry House', Icons.restaurant_rounded),
              ),
              const SizedBox(height: 14),

              // Address
              _buildFieldLabel('OUTLET ADDRESS *'),
              TextField(
                controller: _addressController,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                decoration: _inputDecoration('e.g. Plot 14, High Street, Pune', Icons.location_on_outlined),
              ),
              const SizedBox(height: 14),

              // FSSAI
              _buildFieldLabel('14-DIGIT FSSAI LICENSE NUMBER'),
              TextField(
                controller: _fssaiController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                decoration: _inputDecoration('e.g. 11521034000123', Icons.verified_user_outlined),
              ),
              const SizedBox(height: 14),

              // UPI ID
              _buildFieldLabel('SETTLEMENT UPI VPA ID (0% COMMISSION)'),
              TextField(
                controller: _upiController,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                decoration: _inputDecoration('e.g. coastalcurry@sbi', Icons.account_balance_outlined),
              ),
              const SizedBox(height: 14),

              // Cost For Two
              _buildFieldLabel('APPROX COST FOR TWO (₹)'),
              TextField(
                controller: _costForTwoController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                decoration: _inputDecoration('1200', Icons.currency_rupee_rounded),
              ),
              const SizedBox(height: 16),

              // Cuisines Multi-Select
              _buildFieldLabel('CUISINES'),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _availableCuisines.map((c) {
                  final isSel = _selectedCuisines.contains(c);
                  return FilterChip(
                    label: Text(c),
                    selected: isSel,
                    selectedColor: const Color(0xFFECFDF5),
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: BorderSide(color: isSel ? const Color(0xFF059669) : const Color(0xFFE2E8F0)),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSel ? const Color(0xFF059669) : const Color(0xFF475569),
                    ),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedCuisines.add(c);
                        } else {
                          _selectedCuisines.remove(c);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Signup Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: auth.isLoading ? null : _handleSignup,
                  child: auth.isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Register & Generate Credentials', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            SizedBox(width: 8),
                            Icon(Icons.check_circle_outline_rounded, size: 18),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF059669), size: 18),
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5)),
    );
  }
}
