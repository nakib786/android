import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import '../../core/theme/app_colours.dart';
import '../../main.dart';
import '../../shared/models/trip.dart';

class EditTripScreen extends StatefulWidget {
  final Trip trip;
  final VoidCallback onSaved;

  const EditTripScreen({super.key, required this.trip, required this.onSaved});

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  late TextEditingController _purposeController;
  late String _category;
  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _purposeController = TextEditingController(text: widget.trip.purpose);
    _category = widget.trip.category;
    _initPolylines();
  }

  void _initPolylines() {
    if (widget.trip.latitudePoints != null && widget.trip.latitudePoints!.isNotEmpty) {
      final points = List.generate(
        widget.trip.latitudePoints!.length,
        (i) => LatLng(widget.trip.latitudePoints![i], widget.trip.longitudePoints![i]),
      );
      _polylines.add(
        Polyline(
          polylineId: const PolylineId("route"),
          points: points,
          color: AppColours.canadianRed,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
    }
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _deleteTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete Trip", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to delete this trip? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("DELETE", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await isar.writeTxn(() async {
        await isar.trips.delete(widget.trip.id);
      });
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _saveChanges() async {
    widget.trip.purpose = _purposeController.text;
    widget.trip.category = _category;
    widget.trip.isCraCompliant = widget.trip.purpose.isNotEmpty;
    widget.trip.needsReview = false;

    await isar.writeTxn(() async {
      await isar.trips.put(widget.trip);
    });
    
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('EEEE, MMMM d, y');
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: isDark ? Colors.black54 : Colors.white70,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppColours.charcoal),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: isDark ? Colors.black54 : Colors.white70,
              child: IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                onPressed: _deleteTrip,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Interactive Map Background
          Positioned.fill(
            child: widget.trip.latitudePoints != null && widget.trip.latitudePoints!.isNotEmpty
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(widget.trip.latitudePoints!.first, widget.trip.longitudePoints!.first),
                      zoom: 14,
                    ),
                    polylines: _polylines,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      // Fit bounds
                      final bounds = _getBounds(_polylines.first.points);
                      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
                    },
                    myLocationEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: true,
                    compassEnabled: true,
                  )
                : Container(color: theme.scaffoldBackgroundColor, child: const Center(child: Icon(Icons.map_outlined, size: 64, color: Colors.grey))),
          ),
          
          // Bottom Details Panel
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5)),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                    const Gap(24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dateFormat.format(widget.trip.date), style: GoogleFonts.inter(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                              Text("Trip Details", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColours.charcoal)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColours.successGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            "\$${widget.trip.deductionCad.toStringAsFixed(2)}",
                            style: GoogleFonts.poppins(color: AppColours.successGreen, fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                    const Gap(24),
                    
                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickStat(context, Icons.straighten_rounded, "${widget.trip.distanceKm.toStringAsFixed(1)} km", "Distance"),
                        _buildQuickStat(context, Icons.access_time_rounded, "${widget.trip.startTime != null ? timeFormat.format(widget.trip.startTime!) : '--'}", "Start"),
                        _buildQuickStat(context, Icons.flag_rounded, "${widget.trip.endTime != null ? timeFormat.format(widget.trip.endTime!) : '--'}", "End"),
                      ],
                    ),
                    
                    const Gap(24),
                    const Divider(),
                    const Gap(24),
                    
                    Text("PURPOSE", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                    const Gap(12),
                    TextField(
                      controller: _purposeController,
                      style: GoogleFonts.inter(fontSize: 16, color: isDark ? Colors.white : AppColours.charcoal),
                      decoration: InputDecoration(
                        hintText: "Enter trip purpose (e.g. Client Meeting)",
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.05) : AppColours.lightGrey,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.edit_rounded, color: AppColours.canadianRed),
                      ),
                    ),
                    const Gap(24),
                    
                    Text("CATEGORY", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                    const Gap(12),
                    DropdownButtonFormField<String>(
                      value: _category,
                      dropdownColor: theme.colorScheme.surface,
                      style: GoogleFonts.inter(fontSize: 16, color: isDark ? Colors.white : AppColours.charcoal),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.05) : AppColours.lightGrey,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.category_rounded, color: AppColours.canadianRed),
                      ),
                      items: ['Business', 'Personal', 'Medical', 'Charity', 'Moving'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => _category = val!),
                    ),
                    const Gap(32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColours.canadianRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        child: Text("SAVE CHANGES", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(BuildContext context, IconData icon, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, color: AppColours.canadianRed, size: 20),
        const Gap(4),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppColours.charcoal)),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  LatLngBounds _getBounds(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;
    for (final p in points) {
      if (minLat == null || p.latitude < minLat) minLat = p.latitude;
      if (maxLat == null || p.latitude > maxLat) maxLat = p.latitude;
      if (minLng == null || p.longitude < minLng) minLng = p.longitude;
      if (maxLng == null || p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }
}
