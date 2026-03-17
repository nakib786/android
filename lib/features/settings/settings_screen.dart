import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';
import '../../shared/models/vehicle.dart';
import '../onboarding/vehicle_setup_screen.dart';
import '../../core/providers/theme_provider.dart';
import 'package:isar/isar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  List<Vehicle> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final vehicles = await isar.vehicles.where().findAll();
    if (mounted) {
      setState(() {
        _vehicles = vehicles;
      });
    }
  }

  Future<void> _deleteVehicle(int id) async {
    if (_vehicles.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must have at least one vehicle.")),
      );
      return;
    }

    await isar.writeTxn(() async {
      await isar.vehicles.delete(id);
    });
    _loadVehicles();
  }

  Future<void> _setDefaultVehicle(Vehicle vehicle) async {
    await isar.writeTxn(() async {
      // Unset previous default
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
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Vehicles", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const VehicleSetupScreen()),
                    );
                    _loadVehicles();
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add New"),
                ),
              ],
            ),
          ),
          ..._vehicles.map((vehicle) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: vehicle.isDefault ? Colors.green : Colors.grey[200],
                  child: Icon(Icons.directions_car, color: vehicle.isDefault ? Colors.white : Colors.grey),
                ),
                title: Text(vehicle.nickname),
                subtitle: Text("${vehicle.year} ${vehicle.make} ${vehicle.model}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!vehicle.isDefault)
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        onPressed: () => _setDefaultVehicle(vehicle),
                        tooltip: "Set as Default",
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteVehicle(vehicle.id),
                    ),
                  ],
                ),
              )),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("App Preferences", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text("Theme Mode"),
            subtitle: Text(themeMode.toString().split('.').last.toUpperCase()),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              onChanged: (ThemeMode? newMode) {
                if (newMode != null) {
                  ref.read(themeProvider.notifier).setThemeMode(newMode);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text("System"),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text("Light"),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text("Dark"),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text("Notifications"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text("Units"),
            subtitle: const Text("Kilometres (km)"),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("About KiloDrive"),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
