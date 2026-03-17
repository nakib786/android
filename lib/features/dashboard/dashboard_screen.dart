import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_colours.dart';
import '../../main.dart';
import '../../shared/models/trip.dart';
import '../tracking/tracking_screen.dart';
import '../trips/trip_history_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../trips/edit_trip_screen.dart';
import '../trips/manual_trip_entry_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final List<Widget> screens = [
      DashboardHome(
        onViewAllTrips: () => _onDestinationSelected(1),
        onStartTrip: () => _onDestinationSelected(2),
      ),
      const TripHistoryScreen(),
      const TrackingScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
          backgroundColor: Theme.of(context).colorScheme.surface,
          indicatorColor: AppColours.canadianRed.withValues(alpha: 0.1),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 70,
          destinations: [
            _buildNavDestination(context, Icons.grid_view_rounded, Icons.grid_view_outlined, "Home"),
            _buildNavDestination(context, Icons.history_rounded, Icons.history_outlined, "Trips"),
            _buildNavDestination(context, Icons.play_circle_fill_rounded, Icons.play_circle_outline_rounded, "Track"),
            _buildNavDestination(context, Icons.analytics_rounded, Icons.analytics_outlined, "Reports"),
            _buildNavDestination(context, Icons.settings_rounded, Icons.settings_outlined, "Settings"),
          ],
        ),
      ),
    );
  }

  NavigationDestination _buildNavDestination(BuildContext context, IconData selectedIcon, IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return NavigationDestination(
      selectedIcon: Icon(selectedIcon, color: AppColours.canadianRed),
      icon: Icon(icon, color: isDark ? Colors.white70 : AppColours.charcoal.withValues(alpha: 0.6)),
      label: label,
    );
  }
}

class DashboardHome extends StatefulWidget {
  final VoidCallback onViewAllTrips;
  final VoidCallback onStartTrip;
  const DashboardHome({super.key, required this.onViewAllTrips, required this.onStartTrip});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> with SingleTickerProviderStateMixin {
  double _totalKmMonth = 0.0;
  double _businessKmYear = 0.0;
  double _totalDeduction = 0.0;
  double _businessUsePercent = 0.0;
  List<Trip> _recentTrips = [];
  bool _isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final firstDayOfYear = DateTime(now.year, 1, 1);

    final allTrips = await isar.trips.where().sortByDateDesc().findAll();

    double totalKmMonth = 0;
    double businessKmYear = 0;
    double totalDeduction = 0;
    double totalKmYear = 0;

    for (final trip in allTrips) {
      if (trip.date.isAfter(firstDayOfMonth)) {
        totalKmMonth += trip.distanceKm;
      }
      if (trip.date.isAfter(firstDayOfYear)) {
        totalKmYear += trip.distanceKm;
        if (trip.category == 'Business') {
          businessKmYear += trip.distanceKm;
          totalDeduction += trip.deductionCad;
        }
      }
    }

    if (totalKmYear > 0) {
      _businessUsePercent = (businessKmYear / totalKmYear) * 100;
    }

    if (mounted) {
      setState(() {
        _totalKmMonth = totalKmMonth;
        _businessKmYear = businessKmYear;
        _totalDeduction = totalDeduction;
        _recentTrips = allTrips.take(5).toList();
        _isLoading = false;
      });
      _animationController.forward(from: 0);
    }
  }

  void _showCraRateDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.info_rounded, color: AppColours.canadianRed),
            const Gap(10),
            Text("CRA Mileage Rates", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRateInfoRow("First 5,000 km", "\$0.73 per km", true),
            const Gap(12),
            _buildRateInfoRow("Over 5,000 km", "\$0.67 per km", false),
            const Gap(16),
            const Divider(),
            const Gap(12),
            Text(
              "These rates are set by the Canada Revenue Agency for 2026 tax year reimbursement.",
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("GOT IT", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColours.canadianRed)),
          ),
        ],
      ),
    );
  }

  Widget _buildRateInfoRow(String label, String rate, bool isHighlighted) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal)),
        Text(rate, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isHighlighted ? AppColours.successGreen : null)),
      ],
    );
  }

  Future<void> _navigateToEditTrip(Trip trip) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTripScreen(
          trip: trip,
          onSaved: _loadDashboardData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    double kmProgress = _businessKmYear / 5000;
    if (kmProgress > 1.0) kmProgress = 1.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false, // Prevents centering title when space is tight
        title: Text(
          "Dashboard",
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white : AppColours.charcoal,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          // KM Progress in Header
          Flexible(
            child: GestureDetector(
              onTap: () => _showCraRateDetails(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColours.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColours.successGreen.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                            value: kmProgress,
                            strokeWidth: 2.5,
                            backgroundColor: AppColours.successGreen.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColours.successGreen),
                          ),
                        ),
                        const Icon(Icons.bolt_rounded, size: 10, color: AppColours.successGreen),
                      ],
                    ),
                    const Gap(6),
                    Text(
                      "${_businessKmYear.toStringAsFixed(0)} km",
                      style: GoogleFonts.poppins(
                        color: AppColours.successGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: isDark ? Colors.white : AppColours.charcoal),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const Gap(8),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {},
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: AppColours.canadianRed,
                child: Icon(Icons.person_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColours.canadianRed))
          : RefreshIndicator(
              color: AppColours.canadianRed,
              onRefresh: _loadDashboardData,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryGrid(context),
                      const Gap(24),
                      _buildQuickActions(context),
                      const Gap(32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle(context, "Recent Trips"),
                          TextButton(
                            onPressed: widget.onViewAllTrips,
                            child: Text(
                              "View All",
                              style: GoogleFonts.inter(
                                color: AppColours.canadianRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(8),
                      _buildRecentTripsList(context),
                      const Gap(40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppColours.charcoal,
      ),
    );
  }

  Widget _buildSummaryGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      childAspectRatio: 1.1,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildSummaryCard(context, "Total km", _totalKmMonth.toStringAsFixed(1), "This month", Icons.directions_car_rounded, Colors.blue),
        _buildSummaryCard(context, "Business km", _businessKmYear.toStringAsFixed(1), "This year", Icons.business_center_rounded, Colors.orange),
        _buildSummaryCard(context, "CRA Deduction", "\$${_totalDeduction.toStringAsFixed(2)}", "Estimated", Icons.account_balance_wallet_rounded, AppColours.successGreen),
        _buildSummaryCard(context, "Business Use", "${_businessUsePercent.toStringAsFixed(0)}%", "Compliance", Icons.pie_chart_rounded, Colors.purple),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, String subtitle, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColours.charcoal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Gap(2),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white70 : AppColours.charcoal.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: isDark ? Colors.white38 : Colors.grey,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildActionButton(context, "Start Trip", Icons.play_arrow_rounded, AppColours.successGreen, onTap: widget.onStartTrip)),
        const Gap(12),
        Expanded(
          child: _buildActionButton(
            context, 
            "Manual", 
            Icons.add_rounded, 
            Colors.blue, 
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const ManualTripEntryScreen()));
              _loadDashboardData();
            }
          )
        ),
        const Gap(12),
        Expanded(child: _buildActionButton(context, "Export", Icons.ios_share_rounded, Colors.orange, onTap: () {})),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, {VoidCallback? onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const Gap(4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTripsList(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (_recentTrips.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(Icons.directions_car_outlined, size: 48, color: isDark ? Colors.white12 : Colors.grey[300]),
            const Gap(16),
            Text(
              "No recent trips found.",
              style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('MMM d');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentTrips.length,
      itemBuilder: (context, index) {
        final trip = _recentTrips[index];
        final isBusiness = trip.category == 'Business';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToEditTrip(trip),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isBusiness ? AppColours.canadianRed : Colors.grey).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isBusiness ? Icons.business_center_rounded : Icons.person_rounded,
                        color: isBusiness ? AppColours.canadianRed : Colors.grey,
                        size: 20,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.purpose.isEmpty ? "Untitled Trip" : trip.purpose,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold, 
                              fontSize: 14,
                              color: isDark ? Colors.white : AppColours.charcoal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Gap(4),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  "${dateFormat.format(trip.date)} • ${trip.distanceKm.toStringAsFixed(1)} km",
                                  style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Gap(6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white12 : AppColours.lightGrey,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  trip.category,
                                  style: GoogleFonts.inter(
                                    fontSize: 9, 
                                    fontWeight: FontWeight.bold, 
                                    color: isDark ? Colors.white70 : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Gap(8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "\$${trip.deductionCad.toStringAsFixed(2)}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, 
                            color: AppColours.successGreen,
                            fontSize: 15,
                          ),
                        ),
                        Icon(
                          trip.isCraCompliant ? Icons.verified_rounded : Icons.error_outline_rounded,
                          color: trip.isCraCompliant ? AppColours.successGreen : AppColours.amberWarning, 
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
