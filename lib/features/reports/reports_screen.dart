import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:isar/isar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_colours.dart';
import '../../main.dart';
import '../../shared/models/trip.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  double _totalBusinessDeduction = 0.0;
  double _kmUnder5k = 0.0;
  double _kmOver5k = 0.0;
  double _medicalDeduction = 0.0;
  double _charityDeduction = 0.0;
  
  Map<int, double> _monthlyDistances = {};
  Map<String, double> _categoryCounts = {};
  
  bool _isLoading = true;
  int _selectedYear = DateTime.now().year;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _loadReportData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    final trips = await isar.trips.where()
        .filter()
        .dateBetween(DateTime(_selectedYear, 1, 1), DateTime(_selectedYear, 12, 31, 23, 59))
        .findAll();

    double totalBusinessKm = 0;
    double medicalDeduction = 0;
    double charityDeduction = 0;
    Map<int, double> monthlyDistances = {};
    Map<String, double> categoryCounts = {};

    for (final trip in trips) {
      final month = trip.date.month;
      monthlyDistances[month] = (monthlyDistances[month] ?? 0) + trip.distanceKm;
      categoryCounts[trip.category] = (categoryCounts[trip.category] ?? 0) + 1;

      if (trip.category == 'Business') {
        totalBusinessKm += trip.distanceKm;
      } else if (trip.category == 'Medical') {
        medicalDeduction += trip.deductionCad;
      } else if (trip.category == 'Charity') {
        charityDeduction += trip.deductionCad;
      }
    }

    double kmUnder5k = totalBusinessKm > 5000 ? 5000 : totalBusinessKm;
    double kmOver5k = totalBusinessKm > 5000 ? totalBusinessKm - 5000 : 0;
    double totalBusinessDeduction = (kmUnder5k * 0.73) + (kmOver5k * 0.67);

    if (mounted) {
      setState(() {
        _kmUnder5k = kmUnder5k;
        _kmOver5k = kmOver5k;
        _totalBusinessDeduction = totalBusinessDeduction;
        _medicalDeduction = medicalDeduction;
        _charityDeduction = charityDeduction;
        _monthlyDistances = monthlyDistances;
        _categoryCounts = categoryCounts;
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
          "CRA Reports",
          style: GoogleFonts.poppins(color: AppColours.charcoal, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.share_rounded, color: AppColours.charcoal), onPressed: () {}),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColours.canadianRed))
        : RefreshIndicator(
            onRefresh: _loadReportData,
            color: AppColours.canadianRed,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildYearSelector(),
                    const Gap(24),
                    _buildDeductionSummaryCard(),
                    const Gap(32),
                    _buildSectionTitle("Distance Trend", Icons.bar_chart_rounded),
                    const Gap(16),
                    _buildBarChartCard(),
                    const Gap(32),
                    _buildSectionTitle("Activity Mix", Icons.pie_chart_rounded),
                    const Gap(16),
                    _buildPieChartCard(),
                    const Gap(40),
                    _buildExportSection(context),
                    const Gap(40),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColours.canadianRed),
        const Gap(8),
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColours.charcoal),
        ),
      ],
    );
  }

  Widget _buildYearSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey[600]),
          const Gap(10),
          Text(
            "Tax Year: $_selectedYear",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColours.charcoal),
          ),
          const Gap(4),
          Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[600]),
        ],
      ),
    );
  }

  Widget _buildDeductionSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColours.charcoal, AppColours.charcoal.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: AppColours.charcoal.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Text("Total Business Deduction", style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
          const Gap(8),
          Text(
            "\$${_totalBusinessDeduction.toStringAsFixed(2)}",
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const Gap(24),
          _buildSummaryItem("First 5,000 km (\$0.73)", _kmUnder5k.toStringAsFixed(1)),
          const Gap(12),
          _buildSummaryItem("After 5,000 km (\$0.67)", _kmOver5k.toStringAsFixed(1)),
          const Divider(color: Colors.white12, height: 32),
          _buildSummaryItem("Medical / Moving", "\$${_medicalDeduction.toStringAsFixed(2)}"),
          const Gap(12),
          _buildSummaryItem("Charity / Volunteer", "\$${_charityDeduction.toStringAsFixed(2)}"),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
        Text(value, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildBarChartCard() {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: _monthlyDistances.isEmpty 
        ? Center(child: Text("No tracking data yet", style: GoogleFonts.inter(color: Colors.grey)))
        : Column(
            children: [
              Expanded(
                child: BarChart(
                  BarChartData(
                    barGroups: List.generate(12, (index) {
                      final month = index + 1;
                      return BarChartGroupData(
                        x: month,
                        barRods: [
                          BarChartRodData(
                            toY: _monthlyDistances[month] ?? 0,
                            color: AppColours.canadianRed,
                            width: 14,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            backDrawRodData: BackgroundBarChartRodData(show: true, toY: 500, color: AppColours.lightGrey),
                          )
                        ],
                      );
                    }),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                            if (value.toInt() < 1 || value.toInt() > 12) return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(months[value.toInt() - 1], style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildPieChartCard() {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: _categoryCounts.isEmpty
        ? Center(child: Text("No category data", style: GoogleFonts.inter(color: Colors.grey)))
        : Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: _categoryCounts.entries.map((entry) {
                      return PieChartSectionData(
                        value: entry.value,
                        color: _getCategoryColor(entry.key),
                        title: '',
                        radius: 50,
                        badgeWidget: _buildPieBadge(entry.key),
                        badgePositionPercentageOffset: 1.3,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Gap(20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _categoryCounts.keys.map((cat) => _buildLegendItem(cat)).toList(),
              ),
            ],
          ),
    );
  }

  Widget _buildPieBadge(String category) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _getCategoryColor(category), width: 1.5)),
      child: Icon(_getCategoryIcon(category), size: 12, color: _getCategoryColor(category)),
    );
  }

  Widget _buildLegendItem(String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: _getCategoryColor(category), shape: BoxShape.circle)),
          const Gap(8),
          Text(category, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColours.charcoal)),
        ],
      ),
    );
  }

  Widget _buildExportSection(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: Text("GENERATE CRA LOGBOOK", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColours.canadianRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              shadowColor: AppColours.canadianRed.withOpacity(0.4),
            ),
          ),
        ),
        const Gap(16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.table_chart_rounded),
            label: Text("EXPORT CSV DATA", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColours.charcoal)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ),
      ],
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Business': return Icons.business_center_rounded;
      case 'Medical': return Icons.medical_services_rounded;
      case 'Charity': return Icons.favorite_rounded;
      case 'Moving': return Icons.local_shipping_rounded;
      default: return Icons.person_rounded;
    }
  }
}
