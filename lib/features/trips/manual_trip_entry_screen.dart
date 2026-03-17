import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/theme/app_colours.dart';
import '../../main.dart';
import '../../shared/models/trip.dart';
import '../../shared/models/vehicle.dart';

class ManualTripEntryScreen extends StatefulWidget {
  const ManualTripEntryScreen({super.key});

  @override
  State<ManualTripEntryScreen> createState() => _ManualTripEntryScreenState();
}

class _ManualTripEntryScreenState extends State<ManualTripEntryScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  final List<TextEditingController> _addressControllers = [
    TextEditingController(), // Start
    TextEditingController(), // End
  ];

  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _category = 'Business';
  Vehicle? _selectedVehicle;
  List<Vehicle> _availableVehicles = [];
  
  bool _isCalculating = false;
  String? _estimatedTime;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
  }

  Future<void> _loadVehicles() async {
    final vehicles = await isar.vehicles.where().findAll();
    if (mounted) {
      setState(() {
        _availableVehicles = vehicles;
        if (vehicles.isNotEmpty) {
          _selectedVehicle = vehicles.firstWhere((v) => v.isDefault, orElse: () => vehicles.first);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _addressControllers) {
      controller.dispose();
    }
    _distanceController.dispose();
    _purposeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _addStop() {
    setState(() {
      _addressControllers.insert(_addressControllers.length - 1, TextEditingController());
    });
  }

  void _removeStop(int index) {
    if (_addressControllers.length > 2) {
      setState(() {
        _addressControllers[index].dispose();
        _addressControllers.removeAt(index);
      });
      _calculateRoute();
    }
  }

  Future<void> _calculateRoute() async {
    final filledAddresses = _addressControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (filledAddresses.length < 2) return;

    setState(() => _isCalculating = true);

    try {
      // For a production app, use Google Distance Matrix API or similar.
      // Here we simulate a calculation based on address strings for the demo.
      // Real implementation would require a valid API Key.
      
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      // Mock calculation: 12.5km per stop as a placeholder
      double mockDistance = (filledAddresses.length - 1) * 12.5;
      int mockMinutes = (mockDistance * 1.5).toInt();

      if (mounted) {
        setState(() {
          _distanceController.text = mockDistance.toStringAsFixed(1);
          _estimatedTime = "${mockMinutes} mins";
          _isCalculating = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isCalculating = false);
    }
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicle == null) return;

    final trip = Trip()
      ..date = _selectedDate
      ..startTime = _selectedDate
      ..endTime = _selectedDate.add(const Duration(hours: 1)) // Estimated
      ..distanceKm = double.tryParse(_distanceController.text) ?? 0.0
      ..purpose = _purposeController.text
      ..category = _category
      ..vehicleId = _selectedVehicle!.id
      ..startAddress = _addressControllers.first.text
      ..endAddress = _addressControllers.last.text
      ..deductionCad = (double.tryParse(_distanceController.text) ?? 0.0) * 0.73
      ..isCraCompliant = _purposeController.text.isNotEmpty
      ..needsReview = false;

    await isar.writeTxn(() async {
      await isar.trips.put(trip);
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Manual trip logged successfully!"),
          backgroundColor: AppColours.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Log Manual Trip",
          style: GoogleFonts.poppins(color: isDark ? Colors.white : AppColours.charcoal, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: BackButton(color: isDark ? Colors.white : AppColours.charcoal),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, "Route & Addresses"),
                const Gap(16),
                _buildAddressList(context),
                const Gap(12),
                TextButton.icon(
                  onPressed: _addStop,
                  icon: const Icon(Icons.add_location_alt_rounded, size: 20),
                  label: Text("Add Stop / Waypoint", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(foregroundColor: AppColours.canadianRed),
                ),
                const Gap(32),
                _buildSectionHeader(context, "Calculated Details"),
                const Gap(16),
                Row(
                  children: [
                    Expanded(
                      child: _buildReadOnlyField(
                        context,
                        "Distance",
                        "${_distanceController.text} km",
                        Icons.straighten_rounded,
                        isLoading: _isCalculating,
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: _buildReadOnlyField(
                        context,
                        "Est. Time",
                        _estimatedTime ?? "--",
                        Icons.access_time_rounded,
                        isLoading: _isCalculating,
                      ),
                    ),
                  ],
                ),
                const Gap(32),
                _buildSectionHeader(context, "Trip Info"),
                const Gap(16),
                _buildVehicleAndDateRow(context),
                const Gap(20),
                _buildCategoryAndPurpose(context),
                const Gap(48),
                _buildSaveButton(context),
                const Gap(40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        color: isDark ? Colors.white54 : Colors.grey[600],
      ),
    );
  }

  Widget _buildAddressList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: List.generate(_addressControllers.length, (index) {
        String label = index == 0 ? "Start Point" : (index == _addressControllers.length - 1 ? "Destination" : "Stop ${index}");
        IconData icon = index == 0 ? Icons.circle_outlined : (index == _addressControllers.length - 1 ? Icons.location_on_rounded : Icons.more_vert_rounded);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _addressControllers[index],
                  style: GoogleFonts.inter(color: isDark ? Colors.white : AppColours.charcoal),
                  decoration: InputDecoration(
                    labelText: label,
                    prefixIcon: Icon(icon, color: AppColours.canadianRed, size: 20),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  onChanged: (_) => _calculateRoute(),
                  validator: (val) => val == null || val.isEmpty ? "Required" : null,
                ),
              ),
              if (index > 0 && index < _addressControllers.length - 1)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                  onPressed: () => _removeStop(index),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildReadOnlyField(BuildContext context, String label, String value, IconData icon, {bool isLoading = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
          const Gap(4),
          Row(
            children: [
              Icon(icon, size: 16, color: AppColours.canadianRed),
              const Gap(8),
              isLoading 
                ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppColours.charcoal)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleAndDateRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<Vehicle>(
            value: _selectedVehicle,
            dropdownColor: Theme.of(context).colorScheme.surface,
            decoration: InputDecoration(
              labelText: "Vehicle",
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            items: _availableVehicles.map((v) => DropdownMenuItem(value: v, child: Text(v.nickname))).toList(),
            onChanged: (val) => setState(() => _selectedVehicle = val),
          ),
        ),
        const Gap(16),
        Expanded(
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2023),
                lastDate: DateTime(2027),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Date", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const Gap(4),
                  Text(DateFormat('MMM d, yyyy').format(_selectedDate), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryAndPurpose(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _category,
          dropdownColor: Theme.of(context).colorScheme.surface,
          decoration: InputDecoration(
            labelText: "Category",
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          items: ['Business', 'Personal', 'Medical', 'Charity', 'Moving'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (val) => setState(() => _category = val!),
        ),
        const Gap(20),
        TextFormField(
          controller: _purposeController,
          style: GoogleFonts.inter(color: isDark ? Colors.white : AppColours.charcoal),
          decoration: InputDecoration(
            labelText: "Trip Purpose",
            hintText: "Meeting with client...",
            prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColours.canadianRed),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          validator: (val) => val == null || val.isEmpty ? "Required" : null,
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _saveTrip,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColours.canadianRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          shadowColor: AppColours.canadianRed.withOpacity(0.4),
        ),
        child: Text("SAVE MANUAL LOG", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
      ),
    );
  }
}
