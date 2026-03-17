import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_colours.dart';
import '../../main.dart';
import '../../shared/models/trip.dart';
import 'package:intl/intl.dart';
import 'edit_trip_screen.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> with SingleTickerProviderStateMixin {
  List<Trip> _trips = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadTrips();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);
    
    QueryBuilder<Trip, Trip, QAfterFilterCondition> query = isar.trips.where().filter().idGreaterThan(-1);

    if (_selectedCategory != 'All') {
      query = query.categoryEqualTo(_selectedCategory);
    }

    final trips = await query.sortByDateDesc().findAll();
    
    if (mounted) {
      setState(() {
        _trips = trips;
        _isLoading = false;
      });
      _animationController.forward(from: 0);
    }
  }

  Future<void> _navigateToEditTrip(Trip trip) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTripScreen(
          trip: trip,
          onSaved: _loadTrips,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Trip History",
          style: GoogleFonts.poppins(color: isDark ? Colors.white : AppColours.charcoal, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white : AppColours.charcoal),
            onPressed: _loadTrips,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColours.canadianRed))
              : _trips.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _trips.length,
                    itemBuilder: (context, index) {
                      return FadeTransition(
                        opacity: _animationController,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Interval((index / _trips.length).clamp(0, 1), 1, curve: Curves.easeOut),
                            ),
                          ),
                          child: _buildTripCard(context, _trips[index]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_outlined, size: 80, color: Colors.grey[300]),
          const Gap(16),
          Text(
            "No trips found",
            style: GoogleFonts.poppins(fontSize: 18, color: AppColours.charcoal, fontWeight: FontWeight.bold),
          ),
          const Gap(8),
          Text("Completed trips will appear here.", style: GoogleFonts.inter(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Business', 'Medical', 'Moving', 'Charity', 'Personal'];
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedCategory == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: ChoiceChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (val) {
                  if (val) {
                    setState(() => _selectedCategory = filter);
                    _loadTrips();
                  }
                },
                selectedColor: AppColours.canadianRed.withOpacity(0.1),
                labelStyle: GoogleFonts.inter(
                  color: isSelected ? AppColours.canadianRed : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isSelected ? AppColours.canadianRed : Colors.transparent),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, Trip trip) {
    final dateFormat = DateFormat('EEE, MMM d');
    final timeFormat = DateFormat('h:mm a');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: trip.needsReview ? Border.all(color: Colors.orange.shade200, width: 1.5) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToEditTrip(trip),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(trip.category).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            trip.category.toUpperCase(),
                            style: GoogleFonts.inter(color: _getCategoryColor(trip.category), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ),
                        if (trip.needsReview) ...[
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 12, color: Colors.orange),
                                const Gap(4),
                                Text("REVIEW", style: GoogleFonts.inter(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(dateFormat.format(trip.date), style: GoogleFonts.inter(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
                const Gap(16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.circle, size: 12, color: AppColours.successGreen),
                        Container(width: 1.5, height: 24, color: isDark ? Colors.white10 : Colors.grey[200]),
                        const Icon(Icons.location_on_rounded, size: 14, color: AppColours.canadianRed),
                      ],
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.purpose.isEmpty ? "Unspecified Purpose" : trip.purpose,
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColours.charcoal),
                          ),
                          const Gap(4),
                          Text(
                            "${trip.startAddress} → ${trip.endAddress}",
                            style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                        const Gap(4),
                        Text(
                          "${trip.startTime != null ? timeFormat.format(trip.startTime!) : '...'} - ${trip.endTime != null ? timeFormat.format(trip.endTime!) : 'Now'}",
                          style: GoogleFonts.inter(color: isDark ? Colors.white54 : Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.straighten_rounded, size: 16, color: Colors.grey),
                        const Gap(4),
                        Text("${trip.distanceKm.toStringAsFixed(1)} km", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColours.charcoal)),
                      ],
                    ),
                  ],
                ),
                const Gap(16),
                Container(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100),
                const Gap(16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text("Deduction", style: GoogleFonts.inter(color: isDark ? Colors.white54 : Colors.grey, fontSize: 13)),
                        const Gap(8),
                        Text(
                          "\$${trip.deductionCad.toStringAsFixed(2)}",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColours.successGreen, fontSize: 18),
                        ),
                      ],
                    ),
                    Icon(
                      trip.isCraCompliant && !trip.needsReview ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                      color: trip.isCraCompliant && !trip.needsReview ? AppColours.successGreen : Colors.orange,
                      size: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Business': return AppColours.canadianRed;
      case 'Medical': return Colors.blue;
      case 'Charity': return Colors.green;
      case 'Moving': return Colors.orange;
      default: return Colors.grey;
    }
  }
}
