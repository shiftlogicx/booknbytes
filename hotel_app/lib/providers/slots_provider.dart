import 'package:flutter/material.dart';
import '../models/slot_model.dart';
import '../services/supabase_service.dart';

class SlotsProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<DailySlotModel> _slots = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedDateIndex = 0;
  String _shiftFilter = 'ALL';
  String _currentRestaurantId = '';

  String get currentRestaurantId => _currentRestaurantId;
  List<DailySlotModel> get slots => _slots;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get selectedDateIndex => _selectedDateIndex;
  String get shiftFilter => _shiftFilter;

  final List<DateTime> dates = List.generate(
    7,
    (index) => DateTime.now().add(Duration(days: index)),
  );

  DateTime get selectedDate => dates[_selectedDateIndex];

  List<DailySlotModel> get filteredSlots {
    final selDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    return _slots.where((s) {
      if (s.startDatetime != null) {
        final slotDay = DateTime(s.startDatetime!.year, s.startDatetime!.month, s.startDatetime!.day);
        if (!slotDay.isAtSameMomentAs(selDay)) return false;
      }
      if (_shiftFilter == 'LUNCH') return s.shift == 'LUNCH';
      if (_shiftFilter == 'DINNER') return s.shift == 'DINNER';
      return true;
    }).toList();
  }

  void setSelectedDateIndex(int idx) {
    _selectedDateIndex = idx;
    notifyListeners();
  }

  void setShiftFilter(String filter) {
    _shiftFilter = filter;
    notifyListeners();
  }

  Future<void> loadSlots(String restaurantId) async {
    _currentRestaurantId = restaurantId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _supabaseService.fetchDailySlots(restaurantId);
      _slots = fetched;

      // If restaurant has no slots yet, seed standard daily operational slots
      if (_slots.isEmpty) {
        await _seedDefaultSlots(restaurantId);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading slots from Supabase: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> _seedDefaultSlots(String restaurantId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final standardTimes = [
      {'startH': 12, 'startM': 0, 'endH': 14, 'endM': 0, 'disc': 20.0, 'cap': 25},
      {'startH': 12, 'startM': 30, 'endH': 14, 'endM': 30, 'disc': 15.0, 'cap': 30},
      {'startH': 13, 'startM': 0, 'endH': 15, 'endM': 0, 'disc': 10.0, 'cap': 35},
      {'startH': 19, 'startM': 0, 'endH': 21, 'endM': 0, 'disc': 25.0, 'cap': 40},
      {'startH': 19, 'startM': 30, 'endH': 21, 'endM': 30, 'disc': 20.0, 'cap': 40},
      {'startH': 20, 'startM': 0, 'endH': 22, 'endM': 0, 'disc': 15.0, 'cap': 45},
      {'startH': 21, 'startM': 0, 'endH': 23, 'endM': 0, 'disc': 30.0, 'cap': 30},
    ];

    for (int dayOffset = 0; dayOffset < 3; dayOffset++) {
      final day = today.add(Duration(days: dayOffset));
      for (final t in standardTimes) {
        try {
          final start = DateTime(day.year, day.month, day.day, t['startH'] as int, t['startM'] as int);
          final end = DateTime(day.year, day.month, day.day, t['endH'] as int, t['endM'] as int);
          final slot = DailySlotModel(
            slotId: '',
            restaurantId: restaurantId,
            startDatetime: start,
            endDatetime: end,
            discountPercentage: t['disc'] as double,
            capacity: t['cap'] as int,
          );
          final created = await _supabaseService.insertDailySlot(slot);
          _slots.add(created);
        } catch (e) {
          debugPrint('Slot seeding item note: $e');
        }
      }
    }
  }

  // ==========================================
  // PUBLISH NEW SLOT TO SUPABASE DB
  // ==========================================
  Future<bool> publishSlot({
    required String restaurantId,
    required DateTime startDatetime,
    required DateTime endDatetime,
    required double discountPercentage,
    required int capacity,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final slot = DailySlotModel(
        slotId: '',
        restaurantId: restaurantId,
        startDatetime: startDatetime,
        endDatetime: endDatetime,
        discountPercentage: discountPercentage,
        capacity: capacity,
      );
      final created = await _supabaseService.insertDailySlot(slot);
      _slots.add(created);
      _slots.sort((a, b) => (a.startDatetime ?? DateTime(0)).compareTo(b.startDatetime ?? DateTime(0)));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // UPDATE SLOT (DISCOUNT / CAPACITY)
  // ==========================================
  Future<bool> updateSlot(String slotId, {double? discountPercentage, int? capacity}) async {
    final index = _slots.indexWhere((s) => s.slotId == slotId);
    if (index == -1) return false;

    final updated = _slots[index].copyWith(
      discountPercentage: discountPercentage,
      capacity: capacity,
    );
    _slots[index] = updated;
    notifyListeners();

    try {
      final data = <String, dynamic>{};
      if (discountPercentage != null) data['discount_percentage'] = discountPercentage;
      if (capacity != null) data['capacity'] = capacity;

      await _supabaseService.updateDailySlot(slotId, data);
      return true;
    } catch (e) {
      debugPrint('Error updating slot in Supabase: $e');
      return false;
    }
  }

  // ==========================================
  // DELETE SLOT
  // ==========================================
  Future<bool> deleteSlot(String slotId) async {
    _slots.removeWhere((s) => s.slotId == slotId);
    notifyListeners();

    try {
      await _supabaseService.deleteDailySlot(slotId);
      return true;
    } catch (e) {
      debugPrint('Error deleting slot from Supabase: $e');
      return false;
    }
  }
}
