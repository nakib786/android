import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_colours.dart';
import '../dashboard/dashboard_screen.dart';
import '../../main.dart';
import '../../shared/models/vehicle.dart';

class VehicleSetupScreen extends StatefulWidget {
  const VehicleSetupScreen({super.key});

  @override
  State<VehicleSetupScreen> createState() => _VehicleSetupScreenState();
}

class _VehicleSetupScreenState extends State<VehicleSetupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nicknameController;
  late TextEditingController _licensePlateController;
  
  final FocusNode _nicknameFocus = FocusNode();
  final FocusNode _licensePlateFocus = FocusNode();

  String? _selectedYear;
  String? _selectedMake;
  String? _selectedModel;
  String _selectedIconType = 'car';
  bool _isSaving = false;

  List<String> _years = [];
  List<String> _makes = [];
  List<String> _models = [];

  bool _isLoadingInitial = true;
  bool _isLoadingModels = false;
  String? _error;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _iconTypes = [
    {'type': 'car', 'icon': Icons.directions_car_rounded, 'label': 'Car'},
    {'type': 'truck', 'icon': Icons.local_shipping_rounded, 'label': 'Truck'},
    {'type': 'van', 'icon': Icons.airport_shuttle_rounded, 'label': 'Van'},
    {'type': 'suv', 'icon': Icons.directions_car_filled_rounded, 'label': 'SUV'},
    {'type': 'motorcycle', 'icon': Icons.motorcycle_rounded, 'label': 'Bike'},
  ];

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    _licensePlateController = TextEditingController();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    
    _initializeData();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _licensePlateController.dispose();
    _nicknameFocus.dispose();
    _licensePlateFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingInitial = true;
      _error = null;
    });

    try {
      final currentYear = DateTime.now().year;
      _years = List.generate(currentYear - 1981 + 2, (index) => (currentYear + 1 - index).toString());

      final response = await http.get(Uri.parse(
          'https://vpic.nhtsa.dot.gov/api/vehicles/GetMakesForVehicleType/car?format=json'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['Results'] ?? [];
        _makes = results
            .map((item) => item['MakeName'].toString().trim())
            .where((make) => make.isNotEmpty)
            .toSet().toList()..sort();
      } else {
        throw Exception('Failed to load makes');
      }

      if (mounted) {
        setState(() {
          _isLoadingInitial = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      debugPrint("Error initializing vehicle data: $e");
      if (mounted) {
        setState(() {
          _isLoadingInitial = false;
          _error = "Could not load vehicle data. Please check your connection.";
        });
      }
    }
  }

  Future<void> _fetchModels() async {
    if (_selectedMake == null || _selectedYear == null) return;

    if (mounted) {
      setState(() {
        _isLoadingModels = true;
        _models = [];
        _selectedModel = null;
      });
    }

    try {
      final response = await http.get(Uri.parse(
          'https://vpic.nhtsa.dot.gov/api/vehicles/GetModelsForMakeYear/make/$_selectedMake/modelyear/$_selectedYear?format=json'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['Results'] ?? [];
        final fetchedModels = results
            .map((item) => item['Model_Name'].toString().trim())
            .where((model) => model.isNotEmpty)
            .toSet().toList()..sort();

        if (mounted) {
          setState(() {
            _models = fetchedModels;
            _isLoadingModels = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching models: $e");
      if (mounted) {
        setState(() {
          _isLoadingModels = false;
        });
      }
    }
  }

  void _saveVehicle() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      _nicknameFocus.unfocus();
      _licensePlateFocus.unfocus();
      FocusScope.of(context).unfocus();

      if (mounted) setState(() => _isSaving = true);

      try {
        final prefsInstance = await SharedPreferences.getInstance();
        final selectedProvince = prefsInstance.getString('selected_province') ?? 'ON';

        String nickname = _nicknameController.text.trim();
        if (nickname.isEmpty) {
          nickname = "$_selectedYear $_selectedMake $_selectedModel";
        }

        final vehicle = Vehicle()
          ..nickname = nickname
          ..make = _selectedMake!
          ..model = _selectedModel!
          ..year = int.parse(_selectedYear!)
          ..licensePlate = _licensePlateController.text
          ..province = selectedProvince
          ..colorHex = AppColours.canadianRed.toARGB32()
          ..iconType = _selectedIconType
          ..isDefault = true;

        await isar.writeTxn(() async {
          await isar.vehicles.put(vehicle);
        });

        await prefsInstance.setBool('onboarding_complete', true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Vehicle saved successfully!"),
              backgroundColor: AppColours.successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          }
        }
      } catch (e) {
        debugPrint("CRASH in _saveVehicle: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to save vehicle: $e"),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  InputDecoration _getInputDecoration(String label, {IconData? icon, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, color: AppColours.canadianRed, size: 20) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColours.canadianRed, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColours.lightGrey,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Vehicle Details",
          style: GoogleFonts.poppins(
            color: AppColours.charcoal,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: BackButton(color: AppColours.charcoal),
      ),
      body: SafeArea(
        child: _isLoadingInitial 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColours.canadianRed),
                  const Gap(16),
                  Text("Fetching vehicle database...", style: GoogleFonts.inter(color: Colors.grey)),
                ],
              ),
            )
          : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                      const Gap(16),
                      Text(
                        _error!, 
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: AppColours.charcoal, fontWeight: FontWeight.w500),
                      ),
                      const Gap(24),
                      ElevatedButton(
                        onPressed: _initializeData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColours.canadianRed,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Retry Connection"),
                      )
                    ],
                  ),
                ),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Let's set up your vehicle",
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColours.charcoal,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            "This helps us track your mileage accurately.",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Gap(24),
                          
                          Text(
                            "Vehicle Type",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: AppColours.charcoal,
                            ),
                          ),
                          const Gap(12),
                          SizedBox(
                            height: 90,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _iconTypes.length,
                              itemBuilder: (context, index) {
                                final item = _iconTypes[index];
                                final isSelected = _selectedIconType == item['type'];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    width: 85,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColours.canadianRed : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isSelected 
                                            ? AppColours.canadianRed.withValues(alpha: 0.3) 
                                            : Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                      border: Border.all(
                                        color: isSelected ? AppColours.canadianRed : Colors.grey.shade200,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => setState(() => _selectedIconType = item['type']),
                                        borderRadius: BorderRadius.circular(20),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              item['icon'], 
                                              color: isSelected ? Colors.white : Colors.grey[600],
                                              size: 28,
                                            ),
                                            const Gap(6),
                                            Text(
                                              item['label'], 
                                              style: GoogleFonts.inter(
                                                fontSize: 12, 
                                                color: isSelected ? Colors.white : Colors.grey[600], 
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                                              )
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const Gap(32),
                          
                          _buildSectionTitle("General Information"),
                          const Gap(16),
                          
                          DropdownButtonFormField<String>(
                            initialValue: _selectedYear,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            decoration: _getInputDecoration("Model Year", icon: Icons.calendar_today_rounded),
                            items: _years.map((year) => DropdownMenuItem(value: year, child: Text(year, style: GoogleFonts.inter()))).toList(),
                            onChanged: _isSaving ? null : (val) {
                              if (mounted) {
                                setState(() {
                                  _selectedYear = val;
                                  _fetchModels();
                                });
                              }
                            },
                            validator: (val) => val == null ? "Please select a year" : null,
                          ),

                          const Gap(20),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedMake,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            decoration: _getInputDecoration("Vehicle Make", icon: Icons.branding_watermark_rounded),
                            items: _makes.map((make) => DropdownMenuItem(value: make, child: Text(make, style: GoogleFonts.inter()))).toList(),
                            onChanged: _isSaving ? null : (val) {
                              if (mounted) {
                                setState(() {
                                  _selectedMake = val;
                                  _fetchModels();
                                });
                              }
                            },
                            validator: (val) => val == null ? "Please select a make" : null,
                          ),
                          
                          const Gap(20),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: DropdownButtonFormField<String>(
                              key: ValueKey(_isLoadingModels),
                              initialValue: _selectedModel,
                              isExpanded: true,
                              icon: _isLoadingModels 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColours.canadianRed))
                                : const Icon(Icons.keyboard_arrow_down_rounded),
                              decoration: _getInputDecoration(
                                _isLoadingModels ? "Loading models..." : "Model", 
                                icon: Icons.directions_car_rounded
                              ),
                              items: _models.map((model) => DropdownMenuItem(value: model, child: Text(model, style: GoogleFonts.inter()))).toList(),
                              onChanged: (_isSaving || _isLoadingModels || _models.isEmpty) ? null : (val) {
                                if (mounted) setState(() => _selectedModel = val);
                              },
                              validator: (val) => val == null ? "Please select a model" : null,
                            ),
                          ),

                          const Gap(32),
                          _buildSectionTitle("Personalization"),
                          const Gap(16),

                          TextFormField(
                            controller: _nicknameController,
                            focusNode: _nicknameFocus,
                            spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                            style: GoogleFonts.inter(),
                            decoration: _getInputDecoration("Nickname (Optional)", icon: Icons.edit_note_rounded),
                            enabled: !_isSaving,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_licensePlateFocus),
                          ),
                          
                          const Gap(20),
                          TextFormField(
                            controller: _licensePlateController,
                            focusNode: _licensePlateFocus,
                            spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                            style: GoogleFonts.inter(),
                            decoration: _getInputDecoration("License Plate (Optional)", icon: Icons.pin_rounded),
                            enabled: !_isSaving,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _saveVehicle(),
                          ),
                          
                          const Gap(48),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isSaving || _isLoadingInitial ? null : _saveVehicle,
                              style: ElevatedButton.styleFrom(
                                elevation: 4,
                                shadowColor: AppColours.canadianRed.withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                backgroundColor: AppColours.canadianRed,
                                foregroundColor: Colors.white,
                              ),
                              child: _isSaving
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                                  : Text(
                                      "COMPLETE SETUP", 
                                      style: GoogleFonts.poppins(
                                        fontSize: 16, 
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      )
                                    ),
                            ),
                          ),
                          const Gap(32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColours.canadianRed,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Gap(10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColours.charcoal,
          ),
        ),
      ],
    );
  }
}
