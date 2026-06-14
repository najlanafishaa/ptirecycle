import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../providers/parking_provider.dart';
import '../../models/parking_zone.dart';
import '../../models/parking_slot.dart';

class CustomMapWidget extends StatefulWidget {
  final Function(ParkingZone, ParkingSlot)? onSlotSelected;
  final bool showNavigationRoute;

  const CustomMapWidget({
    super.key,
    this.onSlotSelected,
    this.showNavigationRoute = false,
  });

  @override
  State<CustomMapWidget> createState() => _CustomMapWidgetState();
}

class _CustomMapWidgetState extends State<CustomMapWidget> {
  GoogleMapController? _mapController;
  ParkingZone? _selectedZone;

  @override
  Widget build(BuildContext context) {
    final parkingProvider = Provider.of<ParkingProvider>(context);
    final zones = parkingProvider.zones;
    final activeParking = parkingProvider.activeParking;

    // Set of markers
    final Set<Marker> markers = {};

    // User location marker (simulated)
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(parkingProvider.userLatitude, parkingProvider.userLongitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(
          title: 'Posisi Anda',
          snippet: 'Ketuk peta untuk memindahkan posisi GPS',
        ),
      ),
    );

    // Seeded zones markers
    for (var zone in zones) {
      markers.add(
        Marker(
          markerId: MarkerId(zone.id),
          position: LatLng(zone.latitude, zone.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: zone.nama,
            snippet: '${zone.totalSlots} Slot • Ketuk untuk memesan',
          ),
          onTap: () {
            setState(() {
              _selectedZone = zone;
            });
            _showZoneDetailsBottomSheet(context, zone, parkingProvider);
          },
        ),
      );
    }

    // Set of Polylines for navigation route
    final Set<Polyline> polylines = {};
    if (widget.showNavigationRoute && zones.isNotEmpty) {
      ParkingZone? destZone;
      if (activeParking != null) {
        destZone = zones.firstWhere(
          (z) => z.nama == activeParking.zoneName,
          orElse: () => zones.first,
        );
      } else {
        // Look for the closest zone or selected one
        destZone = _selectedZone ?? zones.first;
      }

      if (destZone != null) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route_to_zone'),
            points: [
              LatLng(parkingProvider.userLatitude, parkingProvider.userLongitude),
              LatLng(destZone.latitude, destZone.longitude),
            ],
            color: const Color(0xFF1976D2),
            width: 5,
            geodesic: true,
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue[100]!, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // The Real Google Map View
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(-5.3600, 105.2440),
                zoom: 15.5,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              markers: markers,
              polylines: polylines,
              zoomControlsEnabled: false, // Custom zoom buttons used instead
              myLocationEnabled: false, // False since we use custom simulated markers
              myLocationButtonEnabled: false,
              onTap: (LatLng latLng) {
                parkingProvider.updateUserLocation(latLng.latitude, latLng.longitude);
              },
            ),

            // Zoom In/Out Buttons Float
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'zoom_in',
                    onPressed: () {
                      _mapController?.animateCamera(CameraUpdate.zoomIn());
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.add, color: Color(0xFF1976D2)),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoom_out',
                    onPressed: () {
                      _mapController?.animateCamera(CameraUpdate.zoomOut());
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.remove, color: Color(0xFF1976D2)),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'my_location',
                    onPressed: () {
                      // Move camera and fetch location
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(parkingProvider.userLatitude, parkingProvider.userLongitude),
                          16.5,
                        ),
                      );
                      parkingProvider.fetchRealLocation();
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: Color(0xFF1976D2)),
                  ),
                ],
              ),
            ),

            // Top Info Bar
            Positioned(
              left: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Ketuk peta untuk berpindah posisi GPS',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Display slot grid details bottom sheet
  void _showZoneDetailsBottomSheet(BuildContext context, ParkingZone zone, ParkingProvider provider) {
    provider.subscribeToSlots(zone.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Consumer<ParkingProvider>(
          builder: (context, currentProvider, child) {
            final slots = currentProvider.currentSlots;
            int emptySlots = slots.where((s) => !s.isOccupied).length;

            return Container(
              height: MediaQuery.of(context).size.height * 0.55,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pull Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header details
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                zone.nama,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D47A1),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                zone.deskripsi,
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: emptySlots > 0 ? Colors.green[50] : Colors.red[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$emptySlots/${zone.totalSlots} Kosong',
                            style: TextStyle(
                              color: emptySlots > 0 ? Colors.green[700] : Colors.red[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const Divider(),

                  // Grid layout of slots
                  Expanded(
                    child: slots.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.1,
                            ),
                            itemCount: slots.length,
                            itemBuilder: (context, index) {
                              final slot = slots[index];
                              bool isOccupied = slot.isOccupied;

                              return InkWell(
                                onTap: isOccupied
                                    ? null
                                    : () {
                                        Navigator.pop(context);
                                        if (widget.onSlotSelected != null) {
                                          widget.onSlotSelected!(zone, slot);
                                        }
                                      },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isOccupied ? Colors.red[50] : Colors.green[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isOccupied ? Colors.red[200]! : Colors.green[300]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        slot.type == 'Mobil' ? Icons.directions_car : Icons.motorcycle,
                                        color: isOccupied ? Colors.red[700] : Colors.green[700],
                                        size: 20,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        slot.kode,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isOccupied ? Colors.red[900] : Colors.green[900],
                                        ),
                                      ),
                                      Text(
                                        isOccupied ? 'Terisi' : 'Kosong',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: isOccupied ? Colors.red[700] : Colors.green[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Bottom action description
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue[700], size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Pilih slot hijau yang kosong untuk memesan/menyimpan lokasi parkir Anda.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF0D47A1)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      setState(() {
        _selectedZone = null;
      });
    });
  }
}
