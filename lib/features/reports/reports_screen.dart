import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:isar/isar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colours.dart';
import '../../main.dart';
import '../../shared/models/trip.dart';
import '../../core/services/report_service.dart';

enum TrendView { days, weeks, months }

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
  Map<int, double> _weeklyDistances = {};
  Map<int, double> _dailyDistances = {};
  Map<String, double> _categoryCounts = {};
  
  bool _isLoading = true;
  final int _selectedYear = DateTime.now().year;
  TrendView _selectedTrendView = TrendView.months;

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

  int _getWeekNumber(DateTime date) {
    int dayOfYear = int.parse(DateFormat("D").format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
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
    Map<int, double> weeklyDistances = {};
    Map<int, double> dailyDistances = {};
    Map<String, double> categoryCounts = {};

    for (final trip in trips) {
      // Monthly
      final month = trip.date.month;
      monthlyDistances[month] = (monthlyDistances[month] ?? 0) + trip.distanceKm;

      // Weekly (ISO week number)
      final week = _getWeekNumber(trip.date);
      weeklyDistances[week] = (weeklyDistances[week] ?? 0) + trip.distanceKm;

      // Daily (Day of week 1-7)
      final day = trip.date.weekday;
      dailyDistances[day] = (dailyDistances[day] ?? 0) + trip.distanceKm;

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
        _weeklyDistances = weeklyDistances;
        _dailyDistances = dailyDistances;
        _categoryCounts = categoryCounts;
        _isLoading = false;
      });
      _animationController.forward(from: 0);
    }
  }

  Future<List<Trip>> _getTripsForYear() async {
    return await isar.trips.where()
        .filter()
        .dateBetween(DateTime(_selectedYear, 1, 1), DateTime(_selectedYear, 12, 31, 23, 59))
        .sortByDate()
        .findAll();
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
          "CRA Reports",
          style: GoogleFonts.poppins(color: isDark ? Colors.white : AppColours.charcoal, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.share_rounded, color: isDark ? Colors.white : AppColours.charcoal), onPressed: () {}),
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
                    _buildYearSelector(context),
                    const Gap(24),
                    _buildDeductionSummaryCard(),
                    const Gap(32),
                    _buildTrendHeader(context),
                    const Gap(16),
                    _buildBarChartCard(context),
                    const Gap(32),
                    _buildSectionTitle(context, "Activity Mix", Icons.pie_chart_rounded),
                    const Gap(16),
                    _buildPieChartCard(context),
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

  Widget _buildTrendHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionTitle(context, "Distance Trend", Icons.bar_chart_rounded),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : AppColours.lightGrey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildTrendToggle(TrendView.days, "D"),
              _buildTrendToggle(TrendView.weeks, "W"),
              _buildTrendToggle(TrendView.months, "M"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendToggle(TrendView view, String label) {
    final isSelected = _selectedTrendView == view;
    return GestureDetector(
      onTap: () => setState(() => _selectedTrendView = view),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColours.canadianRed : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColours.canadianRed),
        const Gap(8),
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColours.charcoal),
        ),
      ],
    );
  }

  Widget _buildYearSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded, size: 16, color: isDark ? Colors.white60 : Colors.grey[600]),
          const Gap(10),
          Text(
            "Tax Year: $_selectedYear",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColours.charcoal),
          ),
          const Gap(4),
          Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white60 : Colors.grey[600]),
        ],
      ),
    );
  }

  Widget _buildDeductionSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColours.charcoal, Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
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

  Widget _buildBarChartCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dataMap = _selectedTrendView == TrendView.months 
        ? _monthlyDistances 
        : _selectedTrendView == TrendView.weeks 
            ? _weeklyDistances 
            : _dailyDistances;
    
    int count = _selectedTrendView == TrendView.months ? 12 : _selectedTrendView == TrendView.weeks ? 53 : 7;
    double maxVal = dataMap.values.isEmpty ? 100 : dataMap.values.reduce((a, b) => a > b ? a : b);
    if (maxVal < 100) maxVal = 100;

    return Container(
      height: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 10)],
      ),
      child: dataMap.isEmpty 
        ? Center(child: Text("No tracking data yet", style: GoogleFonts.inter(color: Colors.grey)))
        : Column(
            children: [
              Expanded(
                child: BarChart(
                  BarChartData(
                    barGroups: List.generate(count, (index) {
                      final key = index + 1;
                      return BarChartGroupData(
                        x: key,
                        barRods: [
                          BarChartRodData(
                            toY: dataMap[key] ?? 0,
                            color: AppColours.canadianRed,
                            width: _selectedTrendView == TrendView.weeks ? 4 : 14,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true, 
                              toY: maxVal, 
                              color: isDark ? Colors.white10 : AppColours.lightGrey
                            ),
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
                          interval: _selectedTrendView == TrendView.weeks ? 10 : 1,
                          getTitlesWidget: (value, meta) {
                            String text = '';
                            if (_selectedTrendView == TrendView.months) {
                              const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                              if (value.toInt() >= 1 && value.toInt() <= 12) text = months[value.toInt() - 1];
                            } else if (_selectedTrendView == TrendView.days) {
                              const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                              if (value.toInt() >= 1 && value.toInt() <= 7) text = days[value.toInt() - 1];
                            } else {
                              text = value.toInt().toString();
                            }
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                text,
                                style: GoogleFonts.inter(
                                  fontSize: 10, 
                                  color: isDark ? Colors.white60 : Colors.grey[600], 
                                  fontWeight: FontWeight.bold
                                )
                              ),
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

  Widget _buildPieChartCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 10)],
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
                        badgeWidget: _buildPieBadge(context, entry.key),
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
                children: _categoryCounts.keys.map((cat) => _buildLegendItem(context, cat)).toList(),
              ),
            ],
          ),
    );
  }

  Widget _buildPieBadge(BuildContext context, String category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColours.charcoal : Colors.white, 
        shape: BoxShape.circle, 
        border: Border.all(color: _getCategoryColor(category), width: 1.5)
      ),
      child: Icon(_getCategoryIcon(category), size: 12, color: _getCategoryColor(category)),
    );
  }

  Widget _buildLegendItem(BuildContext context, String category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: _getCategoryColor(category), shape: BoxShape.circle)),
          const Gap(8),
          Text(category, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColours.charcoal)),
        ],
      ),
    );
  }

  Widget _buildExportSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: () async {
              final trips = await _getTripsForYear();
              if (trips.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No trips found for this year")));
                }
                return;
              }
              await ReportService.generatePdf(trips, _selectedYear, {
                'totalDeduction': _totalBusinessDeduction,
                'kmUnder5k': _kmUnder5k,
                'kmOver5k': _kmOver5k,
                'medical': _medicalDeduction,
                'charity': _charityDeduction,
              });
            },
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: Text("GENERATE CRA LOGBOOK", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColours.canadianRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              shadowColor: AppColours.canadianRed.withValues(alpha: 0.4),
            ),
          ),
        ),
        const Gap(16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () async {
              final trips = await _getTripsForYear();
              if (trips.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No trips found for this year")));
                }
                return;
              }
              await ReportService.generateCsv(trips, _selectedYear);
            },
            icon: const Icon(Icons.table_chart_rounded),
            label: Text("EXPORT CSV DATA", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColours.charcoal)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300, width: 2),
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
