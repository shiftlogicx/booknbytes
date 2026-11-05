import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/brand_logo.dart';
import '../auth/login_screen.dart';

class RestaurantProfileScreen extends StatefulWidget {
  const RestaurantProfileScreen({super.key});

  @override
  State<RestaurantProfileScreen> createState() => _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends State<RestaurantProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingMedia = false;
  String _uploadStatusMessage = '';

  late TextEditingController _nameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _upiIdController;
  late TextEditingController _fssaiController;
  late TextEditingController _addressController;
  late TextEditingController _costForTwoController;

  late List<String> _selectedCuisines;
  late String _breakfastOpen;
  late String _breakfastClose;
  late String _lunchOpen;
  late String _lunchClose;
  late String _dinnerOpen;
  late String _dinnerClose;
  late bool _isVegOnly;
  late bool _hasBar;
  late bool _isAc;
  late bool _parkingAvailable;

  final List<String> _availableCuisines = [
    'Seafood',
    'Mangalorean',
    'North Indian',
    'South Indian',
    'Coastal Curries',
    'Mughlai',
    'Chinese',
    'Continental',
    'Italian',
    'Pan-Asian',
    'Biryani',
    'Fast Food',
    'Desserts',
    'Bar Food & Grills',
  ];

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<AuthProvider>(context, listen: false).profile;

    _nameController = TextEditingController(text: profile.name);
    _ownerNameController = TextEditingController(text: profile.ownerName);
    _phoneController = TextEditingController(text: profile.phone);
    _emailController = TextEditingController(text: profile.email);
    _upiIdController = TextEditingController(text: profile.upiId);
    _fssaiController = TextEditingController(text: profile.fssaiNumber);
    _addressController = TextEditingController(text: profile.address);
    _costForTwoController = TextEditingController(text: profile.costForTwo.toString());

    _selectedCuisines = List.from(profile.cuisines);
    _breakfastOpen = profile.breakfastOpen;
    _breakfastClose = profile.breakfastClose;
    _lunchOpen = profile.lunchOpen;
    _lunchClose = profile.lunchClose;
    _dinnerOpen = profile.dinnerOpen;
    _dinnerClose = profile.dinnerClose;
    _isVegOnly = profile.isVegOnly;
    _hasBar = profile.hasBar;
    _isAc = profile.isAc;
    _parkingAvailable = profile.parkingAvailable;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _upiIdController.dispose();
    _fssaiController.dispose();
    _addressController.dispose();
    _costForTwoController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(BuildContext context, String current, ValueChanged<String> onSelected) async {
    HapticFeedback.selectionClick();
    TimeOfDay initial = const TimeOfDay(hour: 12, minute: 0);
    try {
      final parts = current.split(' ');
      final timeParts = parts[0].split(':');
      int h = int.parse(timeParts[0]);
      int m = int.parse(timeParts[1]);
      if (parts.length > 1 && parts[1].toUpperCase() == 'PM' && h != 12) h += 12;
      if (parts.length > 1 && parts[1].toUpperCase() == 'AM' && h == 12) h = 0;
      initial = TimeOfDay(hour: h, minute: m);
    } catch (_) {}

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00E599),
              surface: Color(0xFF131726),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      final formatted = '${hour.toString().padLeft(2, '0')}:$minute $period';
      setState(() => onSelected(formatted));
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444)),
              SizedBox(width: 10),
              Text('Please fill all mandatory fields properly.'),
            ],
          ),
          backgroundColor: const Color(0xFF101420),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final updated = authProvider.profile.copyWith(
      name: _nameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      upiId: authProvider.canViewUpi ? _upiIdController.text.trim() : authProvider.profile.upiId,
      fssaiNumber: _fssaiController.text.trim(),
      address: _addressController.text.trim(),
      costForTwo: int.tryParse(_costForTwoController.text.trim()) ?? 1200,
      cuisines: _selectedCuisines,
      breakfastOpen: _breakfastOpen,
      breakfastClose: _breakfastClose,
      lunchOpen: _lunchOpen,
      lunchClose: _lunchClose,
      dinnerOpen: _dinnerOpen,
      dinnerClose: _dinnerClose,
      isVegOnly: _isVegOnly,
      hasBar: _hasBar,
      isAc: _isAc,
      parkingAvailable: _parkingAvailable,
    );

    await authProvider.updateProfile(updated);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF00E599), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Restaurant Profile & Shifts successfully saved!',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF101420),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF00E599), width: 1),
        ),
      ),
    );

    Navigator.of(context).pop();
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 10),
            Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out from ${auth.currentRestaurantName}? You will need your credentials to log back in.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await auth.logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restaurant Profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Mandatory Merchant Details & Operational Shifts',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded, size: 20, color: Color(0xFFDC2626)),
            onPressed: () => _confirmSignOut(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // Header Badge Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (auth.profile.hasMainPhoto)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: auth.profile.mainPhoto,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const PremiumBrandLogo(size: 56),
                          errorWidget: (_, __, ___) => const PremiumBrandLogo(size: 56),
                        ),
                      )
                    else
                      const PremiumBrandLogo(size: 56),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.currentRestaurantName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'ID: ${auth.currentRestaurantId} · Verified Merchant',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 12, color: Color(0xFF059669)),
                                SizedBox(width: 4),
                                Text(
                                  'GOVT FSSAI COMPLIANT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF059669),
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              const SizedBox(height: 22),

              // Section 1: Mandatory Legal & Contact Info
              _buildSectionHeader('MANDATORY MERCHANT IDENTIFIERS'),
              const SizedBox(height: 10),

              _buildTextField(
                controller: _nameController,
                label: 'Restaurant Registered Trade Name *',
                hint: 'e.g. Mahesh Lunch Home',
                icon: Icons.storefront_rounded,
                validator: (val) => val == null || val.trim().isEmpty ? 'Restaurant Name is mandatory' : null,
              ),

              _buildTextField(
                controller: _ownerNameController,
                label: 'Owner / General Manager Name *',
                hint: 'e.g. Mahesh Shetty',
                icon: Icons.person_rounded,
                validator: (val) => val == null || val.trim().isEmpty ? 'Owner name is mandatory' : null,
              ),

              _buildTextField(
                controller: _phoneController,
                label: 'Contact Phone *',
                hint: '+91 98200 87654',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.length < 8 ? 'Valid phone required' : null,
              ),

              _buildTextField(
                controller: _emailController,
                label: 'Business Email *',
                hint: 'contact@restaurant.com',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val == null || !val.contains('@') ? 'Valid email required' : null,
              ),

              _buildTextField(
                controller: _fssaiController,
                label: '14-Digit FSSAI License Number *',
                hint: '11521034000123',
                icon: Icons.verified_user_rounded,
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.trim().length != 14 ? 'FSSAI must be 14 digits' : null,
              ),

              _buildTextField(
                controller: _addressController,
                label: 'Full Physical Outlet Address *',
                hint: 'Plot No. 12, Camp, Pune, Maharashtra - 411001',
                icon: Icons.location_on_rounded,
                maxLines: 2,
                validator: (val) => val == null || val.trim().length < 5 ? 'Full address is mandatory' : null,
              ),

              const SizedBox(height: 18),

              // Section 2: Dining Cost & Preset
              _buildSectionHeader('DINING COST & PRICING'),
              const SizedBox(height: 10),

              _buildTextField(
                controller: _costForTwoController,
                label: 'Average Cost for Two (INR) *',
                hint: '1200',
                icon: Icons.currency_rupee_rounded,
                keyboardType: TextInputType.number,
                validator: (val) => val == null || int.tryParse(val.trim()) == null ? 'Valid number required' : null,
              ),

              // Cost Quick Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [600, 900, 1200, 1600, 2200, 3000].map((cost) {
                    final isSelected = _costForTwoController.text == cost.toString();
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _costForTwoController.text = cost.toString();
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8, bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          '₹$cost for two',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? const Color(0xFF059669) : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 18),

              // Section 3: Cuisines Multi-Select
              _buildSectionHeader('CUISINES OFFERED'),
              const SizedBox(height: 4),
              const Text(
                'Select all applicable cuisines to appear in guest search filters',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableCuisines.map((cuisine) {
                  final isSelected = _selectedCuisines.contains(cuisine);
                  return FilterChip(
                    label: Text(cuisine),
                    selected: isSelected,
                    selectedColor: const Color(0xFFECFDF5),
                    backgroundColor: Colors.white,
                    checkmarkColor: const Color(0xFF059669),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? const Color(0xFF059669) : const Color(0xFF475569),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    onSelected: (selected) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (selected) {
                          _selectedCuisines.add(cuisine);
                        } else {
                          _selectedCuisines.remove(cuisine);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Section 4: Operational Shifts & Timings
              _buildSectionHeader('OPERATIONAL SERVICE SHIFTS'),
              const SizedBox(height: 10),

              // Breakfast Shift Card
              _buildTimingCard(
                title: 'Breakfast Service Shift',
                icon: Icons.breakfast_dining_rounded,
                accentColor: const Color(0xFFEA580C),
                openTime: _breakfastOpen,
                closeTime: _breakfastClose,
                onOpenTap: () => _pickTime(context, _breakfastOpen, (t) => _breakfastOpen = t),
                onCloseTap: () => _pickTime(context, _breakfastClose, (t) => _breakfastClose = t),
              ),

              const SizedBox(height: 12),

              // Lunch Shift Card
              _buildTimingCard(
                title: 'Lunch Service Shift',
                icon: Icons.wb_sunny_rounded,
                accentColor: const Color(0xFFD97706),
                openTime: _lunchOpen,
                closeTime: _lunchClose,
                onOpenTap: () => _pickTime(context, _lunchOpen, (t) => _lunchOpen = t),
                onCloseTap: () => _pickTime(context, _lunchClose, (t) => _lunchClose = t),
              ),

              const SizedBox(height: 12),

              // Dinner Shift Card
              _buildTimingCard(
                title: 'Dinner Service Shift',
                icon: Icons.nights_stay_rounded,
                accentColor: const Color(0xFF4F46E5),
                openTime: _dinnerOpen,
                closeTime: _dinnerClose,
                onOpenTap: () => _pickTime(context, _dinnerOpen, (t) => _dinnerOpen = t),
                onCloseTap: () => _pickTime(context, _dinnerClose, (t) => _dinnerClose = t),
              ),

              const SizedBox(height: 24),

              // Section 5: Dining Floor Facilities
              _buildSectionHeader('DINING FLOOR ATTRIBUTES'),
              const SizedBox(height: 10),

              _buildFacilitySwitch(
                icon: Icons.eco_rounded,
                title: 'Pure Vegetarian Outlet',
                subtitle: 'No non-veg or meat preparations cooked on premises',
                value: _isVegOnly,
                onChanged: (val) => setState(() => _isVegOnly = val),
              ),

              _buildFacilitySwitch(
                icon: Icons.local_bar_rounded,
                title: 'Full Bar / Liquor License',
                subtitle: 'Cocktails, draught beers, and alcoholic beverages served',
                value: _hasBar,
                onChanged: (val) => setState(() => _hasBar = val),
              ),

              _buildFacilitySwitch(
                icon: Icons.ac_unit_rounded,
                title: 'Air Conditioned Dining Area',
                subtitle: 'Climate controlled indoor dining tables',
                value: _isAc,
                onChanged: (val) => setState(() => _isAc = val),
              ),

              _buildFacilitySwitch(
                icon: Icons.local_parking_rounded,
                title: 'Valet / Dedicated Parking',
                subtitle: 'Free valet or designated customer parking available',
                value: _parkingAvailable,
                onChanged: (val) => setState(() => _parkingAvailable = val),
              ),

              const SizedBox(height: 24),

              // Section 6: Hotel Photos & Menu Cards
              _buildMediaSection(context, auth),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _saveProfile,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Save & Publish Restaurant Profile',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sign Out Option Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFEE2E2), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _confirmSignOut(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sign Out of Restaurant Account',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Disconnect session for ${auth.currentRestaurantName}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFFF87171), size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: Color(0xFF64748B),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? helperText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 12),
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          helperText: helperText,
          helperStyle: const TextStyle(color: Color(0xFF059669), fontSize: 10, fontWeight: FontWeight.w600),
          prefixIcon: Icon(icon, color: const Color(0xFF059669), size: 18),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF059669), width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _buildTimingCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required String openTime,
    required String closeTime,
    required VoidCallback onOpenTap,
    required VoidCallback onCloseTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onOpenTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Opens At', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text(
                          openTime,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: onCloseTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Closes At', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text(
                          closeTime,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                      ],
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

  Widget _buildFacilitySwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? const Color(0xFF059669).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (value ? const Color(0xFF059669) : const Color(0xFF64748B)).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: value ? const Color(0xFF059669) : const Color(0xFF64748B), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch.adaptive(
              value: value,
              activeColor: const Color(0xFF059669),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MEDIA MANAGEMENT: MAIN PHOTO, SUBORDINATE (MAX 2) & MENU (UNLIMITED)
  // ==========================================
  Widget _buildMediaSection(BuildContext context, AuthProvider auth) {
    final mainPhoto = auth.profile.mainPhoto;
    final subordinatePhotos = auth.profile.subordinatePhotos;
    final menuImages = auth.profile.menuImages;
    final totalHotelPhotos = auth.profile.totalPhotosCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('HOTEL PHOTOS & MENU CARDS (SUPABASE BLOB STORAGE)'),
        const SizedBox(height: 4),
        const Text(
          'Manage primary profile picture, subordinate dining photos (limit 3 total), and menu card pages',
          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),

        if (_isUploadingMedia)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Color(0xFF2563EB), strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _uploadStatusMessage,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)),
                  ),
                ),
              ],
            ),
          ),

        // CARD 1: MAIN PHOTO (PROFILE PICTURE - 1 PHOTO)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: mainPhoto.isNotEmpty ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
              width: mainPhoto.isNotEmpty ? 1.5 : 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Main Photo (Profile Picture)',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: mainPhoto.isNotEmpty ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: mainPhoto.isNotEmpty ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                      ),
                    ),
                    child: Text(
                      mainPhoto.isNotEmpty ? 'Active Profile Pic' : 'Required',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: mainPhoto.isNotEmpty ? const Color(0xFF059669) : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'This photo represents your restaurant as the profile avatar and primary banner across customer search & the admin portal.',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
              ),
              const SizedBox(height: 14),

              if (mainPhoto.isNotEmpty)
                Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _viewFullImage(context, mainPhoto, 'Main Photo (Profile Picture)'),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: CachedNetworkImage(
                                imageUrl: mainPhoto,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: const Color(0xFFF1F5F9),
                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: const Color(0xFFF1F5F9),
                                  child: const Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, color: Color(0xFF00E599), size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'PRIMARY PROFILE PHOTO',
                                  style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isUploadingMedia ? null : () => _pickAndUploadMainPhoto(auth),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.camera_alt_outlined, size: 16, color: Color(0xFF0F172A)),
                            label: const Text('Change Main Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: _isUploadingMedia ? null : () => _confirmDeletePhoto(context, auth, mainPhoto, isMain: true),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            backgroundColor: const Color(0xFFFEF2F2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                          ),
                          child: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: _isUploadingMedia ? null : () => _pickAndUploadMainPhoto(auth),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFECFDF5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_a_photo_rounded, size: 24, color: Color(0xFF059669)),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Upload Main Photo (Profile Picture)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Tap to capture via camera or pick from gallery',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // CARD 2: SUBORDINATE HOTEL PHOTOS (MAX 2 PHOTOS)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.collections_rounded, color: Color(0xFF0F172A), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Subordinate Photos (Ambience)',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: subordinatePhotos.length >= 2 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: subordinatePhotos.length >= 2 ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0),
                      ),
                    ),
                    child: Text(
                      '${subordinatePhotos.length}/2 subordinate ($totalHotelPhotos/3 total)',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: subordinatePhotos.length >= 2 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Showcase dining ambience and tables (max 2 subordinate photos). Tap the star icon on any photo to set it as Main.',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),

              SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...subordinatePhotos.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final url = entry.value;
                      return Container(
                        width: 130,
                        margin: const EdgeInsets.only(right: 12),
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: () => _viewFullImage(context, url, 'Subordinate Photo #${idx + 1}'),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 130,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8)),
                                  ),
                                ),
                              ),
                            ),
                            // Make Main Photo Button
                            Positioned(
                              top: 4,
                              left: 4,
                              child: GestureDetector(
                                onTap: () => _confirmSetAsMainPhoto(context, auth, url),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 12),
                                      SizedBox(width: 3),
                                      Text(
                                        'Set Main',
                                        style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Delete Button
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _confirmDeletePhoto(context, auth, url, isSubordinate: true),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626).withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.delete_rounded, color: Colors.white, size: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    if (subordinatePhotos.length < 2 && totalHotelPhotos < 3)
                      GestureDetector(
                        onTap: _isUploadingMedia ? null : () => _pickAndUploadSubordinatePhoto(auth),
                        child: Container(
                          width: 120,
                          height: 110,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE2E8F0),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_photo_alternate_rounded, size: 18, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Add Photo',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                '${2 - subordinatePhotos.length} left',
                                style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // CARD 3: MENU CARDS (UNLIMITED PAGES)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.menu_book_rounded, color: Color(0xFF0F172A), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Menu Card Pages',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      '${menuImages.length} page(s) · Unlimited',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Upload your food menu, beverages, chef specials, and desserts (unlimited pages).',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),

              SizedBox(
                height: 130,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...menuImages.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final url = entry.value;
                      return Container(
                        width: 95,
                        margin: const EdgeInsets.only(right: 12),
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: () => _viewFullImage(context, url, 'Menu Page ${idx + 1}'),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 95,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const Center(
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8)),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _confirmDeletePhoto(context, auth, url, isMenu: true),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626).withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.delete_rounded, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Page ${idx + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    GestureDetector(
                      onTap: _isUploadingMedia ? null : () => _pickAndUploadMenuImages(auth),
                      child: Container(
                        width: 95,
                        height: 130,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded, size: 24, color: Color(0xFF0F172A)),
                            SizedBox(height: 6),
                            Text(
                              'Add Pages',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Multi-pick',
                              style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<ImageSource?> _showSourceSelector(BuildContext context, {required String title, String? subtitle}) async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
            ],
            const SizedBox(height: 18),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB), size: 22),
              ),
              title: const Text('Take Live Photo (Camera)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF0F172A))),
              subtitle: const Text('Capture a live picture using your camera', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFF059669), size: 22),
              ),
              title: const Text('Choose from Gallery / Photos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF0F172A))),
              subtitle: const Text('Pick existing photos from your album', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadMainPhoto(AuthProvider auth) async {
    final source = await _showSourceSelector(
      context,
      title: 'Upload Main Photo (Profile Picture)',
      subtitle: 'This will be the primary profile picture shown to customers and admin portal',
    );
    if (source == null) return;

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (file == null) return;

      setState(() {
        _isUploadingMedia = true;
        _uploadStatusMessage = 'Uploading main profile photo...';
      });

      final bytes = await file.readAsBytes();
      final success = await auth.uploadMainPhoto(bytes, file.name);

      if (!mounted) return;
      setState(() {
        _isUploadingMedia = false;
        _uploadStatusMessage = '';
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Main profile photo updated successfully!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Upload failed.'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingMedia = false;
        _uploadStatusMessage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload error: $e'), backgroundColor: const Color(0xFFDC2626)),
      );
    }
  }

  Future<void> _pickAndUploadSubordinatePhoto(AuthProvider auth) async {
    if (auth.profile.subordinatePhotos.length >= 2 || auth.profile.totalPhotosCount >= 3) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 2 subordinate photos allowed (3 photos total with Main Photo).'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final source = await _showSourceSelector(
      context,
      title: 'Upload Subordinate Ambience Photo',
      subtitle: 'Strict maximum: 2 subordinate photos (${auth.profile.subordinatePhotos.length}/2 uploaded)',
    );
    if (source == null) return;

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (file == null) return;

      setState(() {
        _isUploadingMedia = true;
        _uploadStatusMessage = 'Uploading subordinate photo...';
      });

      final bytes = await file.readAsBytes();
      final success = await auth.uploadSubordinatePhoto(bytes, file.name);

      if (!mounted) return;
      setState(() {
        _isUploadingMedia = false;
        _uploadStatusMessage = '';
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subordinate photo uploaded successfully!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Upload failed.'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingMedia = false;
        _uploadStatusMessage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload error: $e'), backgroundColor: const Color(0xFFDC2626)),
      );
    }
  }

  Future<void> _confirmSetAsMainPhoto(BuildContext context, AuthProvider auth, String url) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 22),
            SizedBox(width: 8),
            Text('Set as Main Photo?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A))),
          ],
        ),
        content: const Text(
          'Make this photo your primary profile picture? It will immediately appear on the customer app and admin portal.',
          style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Set as Main', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await auth.setAsMainPhoto(url);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo promoted to Main Photo (Profile Picture)!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadMenuImages(AuthProvider auth) async {
    final source = await _showSourceSelector(
      context,
      title: 'Upload Menu Pages',
      subtitle: 'Add pages to your digital menu card (unlimited)',
    );
    if (source == null) return;

    try {
      final List<XFile> files = [];
      if (source == ImageSource.camera) {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1920,
        );
        if (photo != null) files.add(photo);
      } else {
        final List<XFile> picked = await _picker.pickMultiImage(
          imageQuality: 85,
          maxWidth: 1920,
        );
        files.addAll(picked);
      }

      if (files.isEmpty) return;

      setState(() {
        _isUploadingMedia = true;
        _uploadStatusMessage = 'Uploading ${files.length} menu page(s)...';
      });

      int successCount = 0;
      for (final f in files) {
        final bytes = await f.readAsBytes();
        final ok = await auth.uploadMenuImage(bytes, f.name);
        if (ok) successCount++;
      }

      if (!mounted) return;
      setState(() {
        _isUploadingMedia = false;
        _uploadStatusMessage = '';
      });

      if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Uploaded $successCount menu page(s) successfully!'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Upload failed.'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingMedia = false;
        _uploadStatusMessage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload error: $e'), backgroundColor: const Color(0xFFDC2626)),
      );
    }
  }

  Future<void> _confirmDeletePhoto(
    BuildContext context,
    AuthProvider auth,
    String url, {
    bool isMain = false,
    bool isSubordinate = false,
    bool isMenu = false,
  }) async {
    final String title;
    final String desc;
    if (isMain) {
      title = 'Delete Main Profile Photo?';
      desc = 'Are you sure you want to remove your main profile photo? The next available photo will become your profile picture.';
    } else if (isSubordinate) {
      title = 'Delete Subordinate Photo?';
      desc = 'Are you sure you want to remove this subordinate photo from Supabase storage?';
    } else {
      title = 'Delete Menu Page?';
      desc = 'Are you sure you want to remove this menu page?';
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A))),
        content: Text(desc, style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (isMain) {
        await auth.deleteMainPhoto();
      } else if (isSubordinate) {
        await auth.deleteSubordinatePhoto(url);
      } else {
        await auth.deleteMenuImage(url);
      }
    }
  }

  void _viewFullImage(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Container(
                color: Colors.black,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
                child: InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: Color(0xFF00E599)),
                      ),
                    ),
                    errorWidget: (_, __, ___) => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 40),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
