import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../main.dart';
import '../../shared/models/vehicle.dart';
import '../onboarding/vehicle_setup_screen.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_colours.dart';
import 'package:isar/isar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  List<Vehicle> _vehicles = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _loadVehicles();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    final vehicles = await isar.vehicles.where().findAll();
    if (mounted) {
      setState(() {
        _vehicles = vehicles;
      });
      _animationController.forward(from: 0);
    }
  }

  Future<void> _deleteVehicle(int id) async {
    if (_vehicles.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("You must have at least one vehicle."),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Remove Vehicle", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to remove this vehicle?", style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("CANCEL", style: GoogleFonts.inter(color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text("REMOVE", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await isar.writeTxn(() async {
        await isar.vehicles.delete(id);
      });
      _loadVehicles();
    }
  }

  Future<void> _setDefaultVehicle(Vehicle vehicle) async {
    await isar.writeTxn(() async {
      final vehicles = await isar.vehicles.where().findAll();
      for (var v in vehicles) {
        v.isDefault = (v.id == vehicle.id);
        await isar.vehicles.put(v);
      }
    });
    _loadVehicles();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: AppColours.lightGrey,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Settings",
          style: GoogleFonts.poppins(color: AppColours.charcoal, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            _buildSectionHeader("Vehicles", showAdd: true),
            const Gap(12),
            ..._vehicles.map((vehicle) => _buildVehicleCard(vehicle)),
            const Gap(32),
            _buildSectionHeader("App Preferences"),
            const Gap(12),
            _buildSettingsContainer([
              _buildSettingsTile(
                icon: Icons.brightness_6_rounded,
                title: "Theme Mode",
                subtitle: themeMode.toString().split('.').last.toUpperCase(),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<ThemeMode>(
                    value: themeMode,
                    style: GoogleFonts.inter(color: AppColours.charcoal, fontWeight: FontWeight.w600),
                    onChanged: (ThemeMode? newMode) {
                      if (newMode != null) {
                        ref.read(themeProvider.notifier).setThemeMode(newMode);
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: ThemeMode.system, child: Text("System")),
                      DropdownMenuItem(value: ThemeMode.light, child: Text("Light")),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text("Dark")),
                    ],
                  ),
                ),
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.notifications_active_rounded,
                title: "Notifications",
                subtitle: "Alerts & Reminders",
                onTap: () {},
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.straighten_rounded,
                title: "Units",
                subtitle: "Kilometres (km)",
                onTap: () {},
              ),
            ]),
            const Gap(32),
            _buildSectionHeader("About"),
            const Gap(12),
            _buildSettingsContainer([
              _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                title: "About KiloDrive",
                subtitle: "Version 1.0.0",
                onTap: () {},
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.security_rounded,
                title: "Privacy Policy",
                onTap: () {},
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.help_outline_rounded,
                title: "Help & Support",
                onTap: () {},
              ),
            ]),
            const Gap(40),
            Center(
              child: Text(
                "MADE WITH ❤️ IN CANADA",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.grey[400],
                ),
              ),
            ),
            const Gap(40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showAdd = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.grey[600],
          ),
        ),
        if (showAdd)
          TextButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VehicleSetupScreen()),
              );
              _loadVehicles();
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text("Add Vehicle", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(foregroundColor: AppColours.canadianRed),
          ),
      ],
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        border: vehicle.isDefault ? Border.all(color: AppColours.canadianRed.withOpacity(0.3), width: 1.5) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (vehicle.isDefault ? AppColours.canadianRed : Colors.grey).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.directions_car_rounded, 
            color: vehicle.isDefault ? AppColours.canadianRed : Colors.grey,
            size: 24,
          ),
        ),
        title: Text(vehicle.nickname, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        subtitle: Text("${vehicle.year} ${vehicle.make} ${vehicle.model}", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!vehicle.isDefault)
              IconButton(
                icon: const Icon(Icons.star_border_rounded, color: Colors.amber),
                onPressed: () => _setDefaultVehicle(vehicle),
                tooltip: "Set as Default",
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.star_rounded, color: Colors.amber),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: () => _deleteVehicle(vehicle.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColours.lightGrey, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: AppColours.charcoal),
      ),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.grey),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 60, endIndent: 20, color: Colors.grey.shade100);
  }
}
