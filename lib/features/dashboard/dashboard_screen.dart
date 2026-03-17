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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardHome(),
    const TripHistoryScreen(),
    const TrackingScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          backgroundColor: Colors.white,
          indicatorColor: AppColours.canadianRed.withOpacity(0.1),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 70,
          destinations: [
            _buildNavDestination(Icons.grid_view_rounded, Icons.grid_view_outlined, "Home"),
            _buildNavDestination(Icons.history_rounded, Icons.history_outlined, "Trips"),
            _buildNavDestination(Icons.play_circle_fill_rounded, Icons.play_circle_outline_rounded, "Track"),
            _buildNavDestination(Icons.analytics_rounded, Icons.analytics_outlined, "Reports"),
            _buildNavDestination(Icons.settings_rounded, Icons.settings_outlined, "Settings"),
          ],
        ),
      ),
    );
  }

  NavigationDestination _buildNavDestination(IconData selectedIcon, IconData icon, String label) {
    return NavigationDestination(
      selectedIcon: Icon(selectedIcon, color: AppColours.canadianRed),
      icon: Icon(icon, color: AppColours.charcoal.withOpacity(0.6)),
      label: label,
    );
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColours.lightGrey,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Dashboard",
          style: GoogleFonts.poppins(
            color: AppColours.charcoal,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColours.charcoal),
            onPressed: () {},
          ),
          const Gap(8),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {},
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: AppColours.canadianRed,
                child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
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
                      _buildTopBanner(context),
                      const Gap(24),
                      _buildSectionTitle("Summary"),
                      const Gap(16),
                      _buildSummaryGrid(),
                      const Gap(24),
                      _buildProgressSection(),
                      const Gap(24),
                      _buildQuickActions(context),
                      const Gap(32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle("Recent Trips"),
                          TextButton(
                            onPressed: () {},
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
                      _buildRecentTripsList(),
                      const Gap(40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColours.charcoal,
      ),
    );
  }

  Widget _buildTopBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColours.canadianRed, AppColours.canadianRed.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColours.canadianRed.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.stars_rounded,
              size: 100,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                  const Gap(8),
                  Text(
                    "2026 CRA Rate",
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Gap(12),
              Text(
                "\$0.73/km",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "For the first 5,000 km",
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              const Gap(8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Next: \$0.67/km",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      childAspectRatio: 1.1,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildSummaryCard("Total km", _totalKmMonth.toStringAsFixed(1), "This month", Icons.directions_car_rounded, Colors.blue),
        _buildSummaryCard("Business km", _businessKmYear.toStringAsFixed(1), "This year", Icons.business_center_rounded, Colors.orange),
        _buildSummaryCard("CRA Deduction", "\$${_totalDeduction.toStringAsFixed(2)}", "Estimated", Icons.account_balance_wallet_rounded, Colors.green),
        _buildSummaryCard("Business Use", "${_businessUsePercent.toStringAsFixed(0)}%", "Compliance", Icons.pie_chart_rounded, Colors.purple),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColours.charcoal,
            ),
          ),
          const Gap(2),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColours.charcoal.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    double progress = _businessKmYear / 5000;
    if (progress > 1.0) progress = 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Deduction Tier Progress",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColours.charcoal,
                ),
              ),
              Text(
                "${(progress * 100).toStringAsFixed(0)}%",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: AppColours.successGreen,
                ),
              ),
            ],
          ),
          const Gap(12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColours.lightGrey,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColours.successGreen),
              minHeight: 10,
            ),
          ),
          const Gap(12),
          Text(
            "${_businessKmYear.toStringAsFixed(0)} km logged of 5,000 km tier",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildActionButton(context, "Start Trip", Icons.play_arrow_rounded, AppColours.successGreen)),
        const Gap(12),
        Expanded(child: _buildActionButton(context, "Manual", Icons.add_rounded, Colors.blue)),
        const Gap(12),
        Expanded(child: _buildActionButton(context, "Export", Icons.ios_share_rounded, Colors.orange)),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color) {
    return ElevatedButton(
      onPressed: () {},
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
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTripsList() {
    if (_recentTrips.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(Icons.directions_car_outlined, size: 48, color: Colors.grey[300]),
            const Gap(16),
            Text(
              "No recent trips found.",
              style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.w500),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isBusiness ? AppColours.canadianRed : Colors.grey).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isBusiness ? Icons.business_center_rounded : Icons.person_rounded,
                color: isBusiness ? AppColours.canadianRed : Colors.grey,
                size: 22,
              ),
            ),
            title: Text(
              trip.purpose.isEmpty ? "Untitled Trip" : trip.purpose,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(4),
                Row(
                  children: [
                    Text(
                      "${dateFormat.format(trip.date)} • ${trip.distanceKm.toStringAsFixed(1)} km",
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColours.lightGrey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        trip.category,
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "\$${trip.deductionCad.toStringAsFixed(2)}",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, 
                    color: AppColours.successGreen,
                    fontSize: 16,
                  ),
                ),
                Icon(
                  trip.isCraCompliant ? Icons.verified_rounded : Icons.error_outline_rounded,
                  color: trip.isCraCompliant ? AppColours.successGreen : AppColours.amberWarning, 
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
