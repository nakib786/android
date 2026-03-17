import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:permission_handler/permission_handler.dart';
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

  Future<void> _handleNotificationSettings() async {
    final status = await Permission.notification.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Notifications Disabled", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: Text("To receive trip alerts, please enable notifications in system settings.", style: GoogleFonts.inter()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCEL", style: GoogleFonts.inter(color: Colors.grey))),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: Text("OPEN SETTINGS", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColours.canadianRed)),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Notifications are already enabled."),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Settings",
          style: GoogleFonts.poppins(color: isDark ? Colors.white : AppColours.charcoal, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            _buildSectionHeader(context, "Vehicles", showAdd: true),
            const Gap(12),
            ..._vehicles.map((vehicle) => _buildVehicleCard(context, vehicle)),
            const Gap(32),
            _buildSectionHeader(context, "App Preferences"),
            const Gap(12),
            _buildSettingsContainer(context, [
              _buildSettingsTile(
                context,
                icon: Icons.brightness_6_rounded,
                title: "Theme Mode",
                subtitle: themeMode.toString().split('.').last.toUpperCase(),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<ThemeMode>(
                    value: themeMode,
                    dropdownColor: theme.colorScheme.surface,
                    style: GoogleFonts.inter(color: isDark ? Colors.white : AppColours.charcoal, fontWeight: FontWeight.w600),
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
              _buildDivider(context),
              _buildSettingsTile(
                context,
                icon: Icons.notifications_active_rounded,
                title: "Notifications",
                subtitle: "Trip Alerts & Reminders",
                onTap: _handleNotificationSettings,
              ),
              _buildDivider(context),
              _buildSettingsTile(
                context,
                icon: Icons.straighten_rounded,
                title: "Units",
                subtitle: "Kilometres (km)",
                trailing: Text(
                  "KM ONLY", 
                  style: GoogleFonts.inter(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold, 
                    color: isDark ? Colors.white38 : Colors.grey[400]
                  )
                ),
              ),
            ]),
            const Gap(32),
            _buildSectionHeader(context, "About"),
            const Gap(12),
            _buildSettingsContainer(context, [
              _buildSettingsTile(
                context,
                icon: Icons.info_outline_rounded,
                title: "About Aurora",
                subtitle: "Version 1.0.0",
                onTap: () {},
              ),
              _buildDivider(context),
              _buildSettingsTile(
                context,
                icon: Icons.security_rounded,
                title: "Privacy Policy",
                onTap: () {},
              ),
              _buildDivider(context),
              _buildSettingsTile(
                context,
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
                  color: isDark ? Colors.white24 : Colors.grey[400],
                ),
              ),
            ),
            const Gap(40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {bool showAdd = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: isDark ? Colors.white54 : Colors.grey[600],
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

  Widget _buildVehicleCard(BuildContext context, Vehicle vehicle) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        border: vehicle.isDefault ? Border.all(color: AppColours.canadianRed.withValues(alpha: 0.3), width: 1.5) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (vehicle.isDefault ? AppColours.canadianRed : Colors.grey).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.directions_car_rounded, 
            color: vehicle.isDefault ? AppColours.canadianRed : Colors.grey,
            size: 24,
          ),
        ),
        title: Text(vehicle.nickname, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColours.charcoal)),
        subtitle: Text("${vehicle.year} ${vehicle.make} ${vehicle.model}", style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600])),
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

  Widget _buildSettingsContainer(BuildContext context, List<Widget> children) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColours.lightGrey, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: isDark ? Colors.white : AppColours.charcoal),
      ),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? Colors.white : AppColours.charcoal)),
      subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey)) : null,
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white.withValues(alpha: 0.24) : Colors.grey),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(height: 1, indent: 60, endIndent: 20, color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100);
  }
}
