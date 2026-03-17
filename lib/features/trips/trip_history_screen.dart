import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_colours.dart';
import '../../main.dart';
import '../../shared/models/trip.dart';
import 'package:intl/intl.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  List<Trip> _trips = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);
    
    QueryBuilder<Trip, Trip, QAfterFilterCondition> query = isar.trips.where().filter().idGreaterThan(-1);

    if (_selectedCategory != 'All') {
      query = query.categoryEqualTo(_selectedCategory);
    }

    final trips = await query.sortByDateDesc().findAll();
    
    if (mounted) {
      setState(() {
        _trips = trips;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTrip(Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Trip"),
        content: const Text("Are you sure you want to delete this trip? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await isar.writeTxn(() async {
        await isar.trips.delete(trip.id);
      });
      _loadTrips();
    }
  }

  Future<void> _editTrip(Trip trip) async {
    final purposeController = TextEditingController(text: trip.purpose);
    String category = trip.category;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Edit Trip"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trip.latitudePoints != null && trip.latitudePoints!.isNotEmpty)
                  Container(
                    height: 200,
                    width: double.maxFinite,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(trip.latitudePoints!.first, trip.longitudePoints!.first),
                        zoom: 13,
                      ),
                      polylines: {
                        Polyline(
                          polylineId: const PolylineId("route"),
                          points: List.generate(trip.latitudePoints!.length, (i) => LatLng(trip.latitudePoints![i], trip.longitudePoints![i])),
                          color: AppColours.canadianRed,
                          width: 4,
                        ),
                      },
                      markers: {
                        Marker(
                          markerId: const MarkerId("start"),
                          position: LatLng(trip.latitudePoints!.first, trip.longitudePoints!.first),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        ),
                        Marker(
                          markerId: const MarkerId("end"),
                          position: LatLng(trip.latitudePoints!.last, trip.longitudePoints!.last),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                        ),
                      },
                      myLocationEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    ),
                  ),
                Text("Start: ${trip.startAddress}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text("End: ${trip.endAddress}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                TextField(
                  controller: purposeController,
                  decoration: const InputDecoration(labelText: "Purpose", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                  items: ['Business', 'Personal', 'Medical', 'Charity', 'Moving'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => category = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteTrip(trip);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("DELETE"),
            ),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () async {
                trip.purpose = purposeController.text;
                trip.category = category;
                trip.isCraCompliant = trip.purpose.isNotEmpty;
                trip.needsReview = false; // Mark as reviewed
                
                await isar.writeTxn(() async {
                  await isar.trips.put(trip);
                });
                
                if (mounted) Navigator.pop(context);
                _loadTrips();
              },
              child: const Text("SAVE"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip History"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTrips),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _trips.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _trips.length,
                    itemBuilder: (context, index) {
                      return _buildTripCard(context, _trips[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No trips found",
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("Completed trips will appear here.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Business', 'Medical', 'Moving', 'Charity', 'Personal'];
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedCategory == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() => _selectedCategory = filter);
                  _loadTrips();
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, Trip trip) {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    
    return Dismissible(
      key: Key(trip.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) => showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Delete Trip"),
          content: const Text("Are you sure you want to delete this trip?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("DELETE")),
          ],
        ),
      ),
      onDismissed: (direction) async {
        await isar.writeTxn(() async {
          await isar.trips.delete(trip.id);
        });
        _loadTrips();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Trip deleted")),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: trip.needsReview 
            ? BorderSide(color: Colors.orange.shade300, width: 2) 
            : BorderSide.none,
        ),
        child: InkWell(
          onTap: () => _editTrip(trip),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (trip.needsReview)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.rate_review, size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          "NEEDS REVIEW",
                          style: TextStyle(color: Colors.orange.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dateFormat.format(trip.date), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(trip.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        trip.category,
                        style: TextStyle(color: _getCategoryColor(trip.category), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18, color: AppColours.canadianRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.purpose.isEmpty ? "No purpose specified" : trip.purpose,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "${trip.startAddress} → ${trip.endAddress}",
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit, size: 16, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 26.0),
                  child: Text(
                    "${trip.startTime != null ? timeFormat.format(trip.startTime!) : 'Unknown'} → ${trip.endTime != null ? timeFormat.format(trip.endTime!) : 'Now'}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
    
                // Odometer Section (Visible if data exists)
                if (trip.startOdometer != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 26.0),
                    child: Row(
                      children: [
                        const Icon(Icons.speed, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "Odo: ${trip.startOdometer!.toStringAsFixed(0)} → ${trip.endOdometer?.toStringAsFixed(0) ?? '??'}",
                          style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
    
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.straighten, size: 18, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "${trip.distanceKm.toStringAsFixed(2)} km",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "\$${trip.deductionCad.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          trip.isCraCompliant && !trip.needsReview ? Icons.check_circle : Icons.warning_amber_rounded,
                          color: trip.isCraCompliant && !trip.needsReview ? Colors.green.shade700 : Colors.orange,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
}
