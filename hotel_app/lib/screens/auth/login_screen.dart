import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/slots_provider.dart';
import '../../utils/validators.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sign In Role Toggle: true = Restaurant Owner, false = Executive Manager
  bool _isOwnerMode = true;

  // Cached saved credentials from SharedPreferences
  String? _savedOwnerEmail;
  String? _savedManagerEmail;
  String? _savedManagerPassword;

  // Login Controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
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
    _signupPasswordController.addListener(() {
      if (mounted) setState(() {});
    });
    _signupEmailController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ownerEmail = prefs.getString('last_owner_email');
      final mgrEmail = prefs.getString('last_manager_email');
      final mgrPass = prefs.getString('last_manager_password');

      if (!mounted) return;
      setState(() {
        _savedOwnerEmail = ownerEmail;
        _savedManagerEmail = mgrEmail;
        _savedManagerPassword = mgrPass;

        if (_loginEmailController.text.isEmpty) {
          if (_isOwnerMode && ownerEmail != null && ownerEmail.isNotEmpty) {
            _loginEmailController.text = ownerEmail;
          } else if (!_isOwnerMode && mgrEmail != null && mgrEmail.isNotEmpty) {
            _loginEmailController.text = mgrEmail;
            if (mgrPass != null && mgrPass.isNotEmpty) {
              _loginPasswordController.text = mgrPass;
            }
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  void _switchRole(bool isOwner) {
    HapticFeedback.selectionClick();
    setState(() {
      _isOwnerMode = isOwner;
      if (isOwner) {
        if (_savedOwnerEmail != null && _savedOwnerEmail!.isNotEmpty) {
          _loginEmailController.text = _savedOwnerEmail!;
        }
      } else {
        if (_savedManagerEmail != null && _savedManagerEmail!.isNotEmpty) {
          _loginEmailController.text = _savedManagerEmail!;
          if (_savedManagerPassword != null && _savedManagerPassword!.isNotEmpty) {
            _loginPasswordController.text = _savedManagerPassword!;
          }
        } else if (_savedOwnerEmail != null && _savedOwnerEmail!.isNotEmpty) {
          _loginEmailController.text = _savedOwnerEmail!;
        }
      }
    });
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

  Future<void> _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text.trim();

    final emailErr = FormValidators.validateEmail(email);
    if (emailErr != null) {
      _showErrorSnackBar(emailErr);
      return;
    }

    if (password.isEmpty) {
      _showErrorSnackBar('Please enter your password.');
      return;
    }

    HapticFeedback.mediumImpact();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final slotsProvider = Provider.of<SlotsProvider>(context, listen: false);

    final success = await authProvider.login(
      email,
      password,
      intendedRole: _isOwnerMode ? UserRole.owner : UserRole.manager,
    );

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
    final password = _signupPasswordController.text;
    final restName = _restaurantNameController.text.trim();
    final address = _addressController.text.trim();
    final fssai = _fssaiController.text.trim();
    final upi = _upiController.text.trim();
    final cost = int.tryParse(_costForTwoController.text.trim()) ?? 1200;

    if (ownerName.isEmpty || restName.isEmpty) {
      _showErrorSnackBar('Please fill in Owner Name and Restaurant Name.');
      return;
    }

    final emailErr = FormValidators.validateEmail(email);
    if (emailErr != null) {
      _showErrorSnackBar(emailErr);
      return;
    }

    final passwordErr = FormValidators.validatePassword(password);
    if (passwordErr != null) {
      _showErrorSnackBar(passwordErr);
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
    final mgrEmail = creds['email']?.toString() ?? 'manager@booknbytes.app';
    final mgrPass = creds['default_password']?.toString() ?? 'Mgr@2026!';

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Restaurant & Manager Activated',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your restaurant registration is complete! Dedicated Executive Manager credentials have been provisioned for your floor team:',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4),
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
                  const Row(
                    children: [
                      Icon(Icons.badge_rounded, size: 15, color: Color(0xFF2563EB)),
                      SizedBox(width: 6),
                      Text(
                        'EXECUTIVE MANAGER CREDENTIALS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2563EB),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Manager Login ID:', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                            Text(mgrEmail, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF0F172A))),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF64748B)),
                        tooltip: 'Copy Manager ID',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: mgrEmail));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Manager ID copied to clipboard'), duration: Duration(seconds: 2)),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Default Password:', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                            Text(mgrPass, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF059669))),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF64748B)),
                        tooltip: 'Copy Password',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: mgrPass));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password copied to clipboard'), duration: Duration(seconds: 2)),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF059669), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can also log in to Executive Manager mode anytime using your Owner email & password.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF065F46), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
            const SizedBox(height: 20),
            // Bespoke Brand Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF1E293B)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.table_restaurant_rounded,
                        color: Color(0xFF00E599),
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'BookNBytes Restaurant',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Dining Operations & Table Console',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

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
                      color: Color(0x0C0F172A),
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
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
      children: [
        // Role Segmented Switch
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _switchRole(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isOwnerMode ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: _isOwnerMode
                          ? const [
                              BoxShadow(
                                color: Color(0x0C0F172A),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 16,
                          color: _isOwnerMode ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Restaurant Owner',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _isOwnerMode ? FontWeight.w800 : FontWeight.w600,
                            color: _isOwnerMode ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _switchRole(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_isOwnerMode ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: !_isOwnerMode
                          ? const [
                              BoxShadow(
                                color: Color(0x0C0F172A),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.badge_rounded,
                          size: 16,
                          color: !_isOwnerMode ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Executive Manager',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: !_isOwnerMode ? FontWeight.w800 : FontWeight.w600,
                            color: !_isOwnerMode ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Sign In Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 16,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _isOwnerMode ? const Color(0xFF059669) : const Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isOwnerMode ? 'EXECUTIVE ACCESS' : 'OPERATIONAL MANAGEMENT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: _isOwnerMode ? const Color(0xFF059669) : const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _isOwnerMode ? 'Restaurant Owner Sign In' : 'Executive Manager Sign In',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isOwnerMode
                    ? 'Complete access to table reservations, live floor slots, and promo offers.'
                    : 'Operational floor console: manage guest turnarounds, table reservations, and live seating.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
              ),

              if (!_isOwnerMode) ...[
                Container(
                  margin: const EdgeInsets.only(top: 14, bottom: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Sign In with Owner or Manager Credentials',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Text(
                        'You can log in to Executive Manager mode using your registered Owner email & password, OR use your dedicated Executive Manager credentials.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],

              if ((_savedManagerEmail != null && _savedManagerEmail!.isNotEmpty) ||
                  (_savedOwnerEmail != null && _savedOwnerEmail!.isNotEmpty)) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (!_isOwnerMode && _savedManagerEmail != null && _savedManagerEmail!.isNotEmpty)
                      ActionChip(
                        avatar: const Icon(Icons.flash_on_rounded, size: 14, color: Color(0xFF2563EB)),
                        label: Text(
                          'Fill Manager ID: ${_savedManagerEmail!.split("@").first}',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                        ),
                        backgroundColor: const Color(0xFFEFF6FF),
                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                        onPressed: () {
                          setState(() {
                            _loginEmailController.text = _savedManagerEmail!;
                            if (_savedManagerPassword != null && _savedManagerPassword!.isNotEmpty) {
                              _loginPasswordController.text = _savedManagerPassword!;
                            }
                          });
                        },
                      ),
                    if (_savedOwnerEmail != null && _savedOwnerEmail!.isNotEmpty)
                      ActionChip(
                        avatar: const Icon(Icons.person_rounded, size: 14, color: Color(0xFF059669)),
                        label: Text(
                          'Fill Owner: ${_savedOwnerEmail!.split("@").first}',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                        ),
                        backgroundColor: const Color(0xFFECFDF5),
                        side: const BorderSide(color: Color(0xFFA7F3D0)),
                        onPressed: () {
                          setState(() {
                            _loginEmailController.text = _savedOwnerEmail!;
                          });
                        },
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 18),

              // Email Input
              _buildFieldLabel(_isOwnerMode ? 'OWNER EMAIL *' : 'MANAGER EMAIL OR REGISTERED OWNER EMAIL *'),
              TextField(
                controller: _loginEmailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                decoration: _inputDecoration(
                  _isOwnerMode ? 'owner@restaurant.com' : 'manager.outlet@booknbytes.app or owner email',
                  Icons.alternate_email_rounded,
                ),
              ),

              const SizedBox(height: 16),

              // Password Input
              _buildFieldLabel('PASSWORD *'),
              TextField(
                controller: _loginPasswordController,
                obscureText: _obscureLoginPassword,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                decoration: _inputDecoration('Enter your password', Icons.lock_outline_rounded).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureLoginPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF94A3B8),
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Sign In Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: auth.isLoading ? null : _handleLogin,
                  child: auth.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isOwnerMode ? 'Sign In as Owner' : 'Sign In as Executive Manager',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 16),
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

  Widget _buildSignUpTab(AuthProvider auth) {
    final passwordVal = _signupPasswordController.text;
    final hasLen = FormValidators.hasMinLength(passwordVal);
    final hasUpper = FormValidators.hasUppercase(passwordVal);
    final hasLower = FormValidators.hasLowercase(passwordVal);
    final hasSpecial = FormValidators.hasSpecialChar(passwordVal);

    final emailVal = _signupEmailController.text;
    final emailHasAt = emailVal.contains('@');
    final emailValid = FormValidators.isEmailValid(emailVal);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 16,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF059669),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'RESTAURANT ONBOARDING',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF059669), letterSpacing: 0.8),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Register New Restaurant',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.2),
              ),
              const SizedBox(height: 4),
              const Text(
                'Establishes owner access and creates manager credentials for your floor team.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 20),

              // Owner Full Name
              _buildFieldLabel('OWNER FULL NAME *'),
              TextField(
                controller: _ownerNameController,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                decoration: _inputDecoration('e.g. Vikram Malhotra', Icons.person_outline_rounded),
              ),
              const SizedBox(height: 14),

              // Email
              _buildFieldLabel('BUSINESS EMAIL * (MUST CONTAIN @)'),
              TextField(
                controller: _signupEmailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                decoration: _inputDecoration('e.g. owner@myrestaurant.com', Icons.alternate_email_rounded).copyWith(
                  suffixIcon: emailVal.isNotEmpty
                      ? Icon(
                          emailValid ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          size: 18,
                          color: emailValid ? const Color(0xFF059669) : const Color(0xFFD97706),
                        )
                      : null,
                ),
              ),
              if (emailVal.isNotEmpty && !emailHasAt)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    'Must include "@" (e.g. name@domain.com)',
                    style: TextStyle(fontSize: 10.5, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 14),

              // Phone
              _buildFieldLabel('CONTACT MOBILE NUMBER *'),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                decoration: _inputDecoration('e.g. +91 98765 43210', Icons.phone_outlined),
              ),
              const SizedBox(height: 14),

              // Password
              _buildFieldLabel('PASSWORD *'),
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

              // Interactive Password Criteria Bar
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PASSWORD REQUIREMENTS',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.6),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildRequirementChip('At least 6 chars', hasLen),
                        _buildRequirementChip('Uppercase (A-Z)', hasUpper),
                        _buildRequirementChip('Lowercase (a-z)', hasLower),
                        _buildRequirementChip('Special char (!@#...)', hasSpecial),
                      ],
                    ),
                  ],
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
                decoration: _inputDecoration('e.g. The Coastal Curry House', Icons.storefront_rounded),
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
              _buildFieldLabel('14-DIGIT FSSAI NUMBER'),
              TextField(
                controller: _fssaiController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                decoration: _inputDecoration('e.g. 11521034000123', Icons.verified_user_outlined),
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
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: auth.isLoading ? null : _handleSignup,
                  child: auth.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Register & Generate Credentials', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                            SizedBox(width: 8),
                            Icon(Icons.check_circle_outline_rounded, size: 16),
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

  Widget _buildRequirementChip(String label, bool isSatisfied) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSatisfied ? const Color(0xFFECFDF5) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSatisfied ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSatisfied ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 12,
            color: isSatisfied ? const Color(0xFF059669) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isSatisfied ? const Color(0xFF065F46) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.6),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
      ),
    );
  }
}
