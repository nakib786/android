import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:isar/isar.dart';
import '../../core/theme/app_colours.dart';
import '../../main.dart';
import '../../shared/models/trip.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  double _totalBusinessDeduction = 0.0;
  double _kmUnder5k = 0.0;
  double _kmOver5k = 0.0;
  double _medicalDeduction = 0.0;
  double _charityDeduction = 0.0;
  
  Map<int, double> _monthlyDistances = {};
  Map<String, double> _categoryCounts = {};
  
  bool _isLoading = true;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadReportData();
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
      // Monthly distance
      final month = trip.date.month;
      monthlyDistances[month] = (monthlyDistances[month] ?? 0) + trip.distanceKm;

      // Category counts for pie chart
      categoryCounts[trip.category] = (categoryCounts[trip.category] ?? 0) + 1;

      // Deductions
      if (trip.category == 'Business') {
        totalBusinessKm += trip.distanceKm;
      } else if (trip.category == 'Medical') {
        medicalDeduction += trip.deductionCad;
      } else if (trip.category == 'Charity') {
        charityDeduction += trip.deductionCad;
      }
    }

    // CRA Logic: first 5000km at higher rate
    double kmUnder5k = totalBusinessKm > 5000 ? 5000 : totalBusinessKm;
    double kmOver5k = totalBusinessKm > 5000 ? totalBusinessKm - 5000 : 0;
    
    // Note: In a real app, these rates should come from a central config
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CRA Reports"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReportData),
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildYearSelector(),
                const SizedBox(height: 20),
                _buildDeductionSummary(),
                const SizedBox(height: 20),
                _buildChartHeader("Monthly Distance (km)"),
                _buildBarChart(),
                const SizedBox(height: 20),
                _buildChartHeader("Trips by Category"),
                _buildPieChart(),
                const SizedBox(height: 30),
                _buildExportSection(context),
              ],
            ),
          ),
    );
  }

  Widget _buildYearSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Tax Year: $_selectedYear", style: const TextStyle(fontWeight: FontWeight.bold)),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  Widget _buildDeductionSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryRow("Total Business Deduction", "\$${_totalBusinessDeduction.toStringAsFixed(2)}", isTotal: true),
            const Divider(),
            _buildSummaryRow("km at \$0.73 (first 5,000)", _kmUnder5k.toStringAsFixed(1)),
            _buildSummaryRow("km at \$0.67 (after 5,000)", _kmOver5k.toStringAsFixed(1)),
            _buildSummaryRow("Medical/Moving", "\$${_medicalDeduction.toStringAsFixed(2)}"),
            _buildSummaryRow("Charity/Volunteer", "\$${_charityDeduction.toStringAsFixed(2)}"),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: FontWeight.bold, color: isTotal ? AppColours.canadianRed : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildChartHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBarChart() {
    if (_monthlyDistances.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: Text("No data for chart", style: TextStyle(color: Colors.grey))));
    }

    return SizedBox(
      height: 200,
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
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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
                  if (value.toInt() < 1 || value.toInt() > 12) return const Text('');
                  return Text(months[value.toInt() - 1], style: const TextStyle(fontSize: 10));
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    if (_categoryCounts.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: Text("No data for chart", style: TextStyle(color: Colors.grey))));
    }

    final colors = [AppColours.canadianRed, Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.grey];
    int colorIndex = 0;

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: _categoryCounts.entries.map((entry) {
            final color = colors[colorIndex % colors.length];
            colorIndex++;
            return PieChartSectionData(
              value: entry.value,
              color: color,
              title: entry.key,
              radius: 50,
              titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildExportSection(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text("EXPORT CRA PDF LOGBOOK", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColours.canadianRed),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.table_chart),
            label: const Text("EXPORT CSV (EXCEL)"),
          ),
        ),
      ],
    );
  }
}
