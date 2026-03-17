import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colours.dart';

class ManualTripEntryScreen extends StatefulWidget {
  const ManualTripEntryScreen({super.key});

  @override
  State<ManualTripEntryScreen> createState() => _ManualTripEntryScreenState();
}

class _ManualTripEntryScreenState extends State<ManualTripEntryScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _startLocationController;
  late TextEditingController _destinationController;
  late TextEditingController _distanceController;
  late TextEditingController _purposeController;

  final FocusNode _startFocus = FocusNode();
  final FocusNode _destFocus = FocusNode();
  final FocusNode _distFocus = FocusNode();
  final FocusNode _purposeFocus = FocusNode();

  DateTime _selectedDate = DateTime.now();
  String _category = 'Business';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _startLocationController = TextEditingController();
    _destinationController = TextEditingController();
    _distanceController = TextEditingController();
    _purposeController = TextEditingController();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
  }

  @override
  void dispose() {
    _startLocationController.dispose();
    _destinationController.dispose();
    _distanceController.dispose();
    _purposeController.dispose();
    _startFocus.dispose();
    _destFocus.dispose();
    _distFocus.dispose();
    _purposeFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  InputDecoration _getInputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, color: AppColours.canadianRed, size: 20) : null,
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
          "Log Manual Trip",
          style: GoogleFonts.poppins(color: AppColours.charcoal, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: BackButton(color: AppColours.charcoal),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Time & Category"),
                    const Gap(16),
                    Row(
                      children: [
                        Expanded(child: _buildDatePicker()),
                        const Gap(16),
                        Expanded(child: _buildCategoryDropdown()),
                      ],
                    ),
                    const Gap(32),
                    _buildSectionHeader("Route Details"),
                    const Gap(16),
                    _buildTextField("Start Location", "e.g. Home Office", _startLocationController, focusNode: _startFocus, nextFocus: _destFocus, icon: Icons.circle_outlined),
                    const Gap(20),
                    _buildTextField("Destination", "e.g. Client Site", _destinationController, focusNode: _destFocus, nextFocus: _distFocus, icon: Icons.location_on_rounded),
                    const Gap(20),
                    _buildTextField(
                      "Distance (km)", 
                      "0.0", 
                      _distanceController,
                      focusNode: _distFocus,
                      nextFocus: _purposeFocus,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      icon: Icons.straighten_rounded
                    ),
                    const Gap(32),
                    _buildSectionHeader("Compliance Info"),
                    const Gap(16),
                    _buildTextField(
                      "Trip Purpose", 
                      "e.g. Project kickoff meeting", 
                      _purposeController,
                      focusNode: _purposeFocus,
                      icon: Icons.edit_note_rounded
                    ),
                    const Gap(48),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            FocusScope.of(context).unfocus();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text("Trip logged successfully!"),
                                backgroundColor: AppColours.successGreen,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColours.canadianRed,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: AppColours.canadianRed.withOpacity(0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          "SAVE TRIP LOG", 
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                        ),
                      ),
                    ),
                    const Gap(40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        FocusScope.of(context).unfocus();
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2023),
          lastDate: DateTime(2027),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: AppColours.canadianRed, onPrimary: Colors.white, onSurface: AppColours.charcoal),
              ),
              child: child!,
            );
          },
        );
        if (date != null && mounted) {
          setState(() => _selectedDate = date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Date", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.bold)),
            const Gap(4),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: AppColours.canadianRed),
                const Gap(8),
                Text(
                  DateFormat('MMM d, yyyy').format(_selectedDate),
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColours.charcoal),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {FocusNode? focusNode, FocusNode? nextFocus, TextInputType keyboardType = TextInputType.text, IconData? icon}) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
      spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
      decoration: _getInputDecoration(label, icon: icon).copyWith(hintText: hint),
      keyboardType: keyboardType,
      validator: (val) {
        if (label.contains("Purpose") && _category == "Business" && (val == null || val.trim().isEmpty)) {
          return "Purpose is required for Business";
        }
        if (label.contains("Distance") && (val == null || val.isEmpty)) {
          return "Distance is required";
        }
        return null;
      },
      textInputAction: nextFocus != null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        }
      },
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = ['Business', 'Personal', 'Medical', 'Charity', 'Moving'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Category", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.bold)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _category,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              items: categories.map((c) => DropdownMenuItem(
                value: c, 
                child: Text(c, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColours.charcoal))
              )).toList(),
              onChanged: (val) {
                if (val != null && mounted) {
                  setState(() => _category = val);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
