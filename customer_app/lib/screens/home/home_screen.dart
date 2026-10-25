import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/restaurant_card.dart';
import '../../widgets/search_bar.dart';
import '../restaurant/restaurant_detail_screen.dart';
import '../bookings/my_bookings_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RestaurantProvider>(context, listen: false).fetchRestaurants();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantProvider = Provider.of<RestaurantProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: AppTheme.primaryOrange, size: 16),
                const SizedBox(width: 4),
                const Text(
                  'Pune, Maharashtra',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey.shade600),
              ],
            ),
            const Text(
              'Zero-Fee Direct Table Reservations',
              style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4EB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryOrange, size: 20),
            ),
            tooltip: 'My Bookings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => restaurantProvider.fetchRestaurants(),
        color: AppTheme.primaryOrange,
        child: CustomScrollView(
          slivers: [
            // Search & Filters Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  children: [
                    CustomSearchBar(
                      controller: _searchController,
                      onChanged: (val) => restaurantProvider.setSearchQuery(val),
                      onClear: () {
                        _searchController.clear();
                        restaurantProvider.setSearchQuery('');
                      },
                    ),
                    const SizedBox(height: 12),

                    // Filter Chips Bar
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'Pure Veg',
                            isSelected: restaurantProvider.vegOnly,
                            onTap: () => restaurantProvider.toggleVegOnly(),
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Has Bar',
                            isSelected: restaurantProvider.hasBar,
                            onTap: () => restaurantProvider.toggleHasBar(),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'AC Only',
                            isSelected: restaurantProvider.isAc,
                            onTap: () => restaurantProvider.toggleIsAc(),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Special Offers',
                            isSelected: restaurantProvider.hasOffers,
                            onTap: () => restaurantProvider.toggleHasOffers(),
                            icon: Icons.local_offer_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content Body: Loading, Empty, or Restaurant Cards
            if (restaurantProvider.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryOrange),
                ),
              )
            else if (restaurantProvider.restaurants.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 54, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'No restaurants found',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try clearing your filters or search keywords',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final restaurant = restaurantProvider.restaurants[index];
                    return RestaurantCard(
                      restaurant: restaurant,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RestaurantDetailScreen(restaurant: restaurant),
                          ),
                        );
                      },
                    );
                  },
                  childCount: restaurantProvider.restaurants.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? (color ?? AppTheme.primaryOrange) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? (color ?? AppTheme.primaryOrange) : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: isSelected ? Colors.white : Colors.grey.shade600),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
