import 'package:flutter/material.dart';
import '../../core/theme/app_colours.dart';

class VehicleManagementScreen extends StatelessWidget {
  const VehicleManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Vehicles"),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 0, // Removed mock data
        itemBuilder: (context, index) {
          return _buildVehicleCard(
            context,
            "",
            "",
            "",
            false,
          );
        },
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, String name, String make, String color, bool isDefault) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColours.canadianRed.withAlpha(25),
          child: const Icon(Icons.directions_car, color: AppColours.canadianRed),
        ),
        title: Text(name),
        subtitle: Text("$make · $color ${isDefault ? '· Default' : ''}"),
        trailing: const Icon(Icons.edit),
        onTap: () {},
      ),
    );
  }
}
