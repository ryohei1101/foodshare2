import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OSMMapPage extends StatefulWidget {
  const OSMMapPage({super.key});

  @override
  State<OSMMapPage> createState() => _OSMMapPageState();
}

class _OSMMapPageState extends State<OSMMapPage> {
  final LatLng fakeCurrentPos = const LatLng(35.6480, 139.7430);
  final double fakeAccuracy = 50.0;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _mapController.move(fakeCurrentPos, 17);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: LatLng(35.6480, 139.7430),
        initialZoom: 17,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        CircleLayer(
          circles: [
            CircleMarker(
              point: fakeCurrentPos,
              color: Colors.blue.withOpacity(0.2),
              borderStrokeWidth: 1,
              borderColor: Colors.blue.withOpacity(0.5),
              useRadiusInMeter: true,
              radius: fakeAccuracy,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: fakeCurrentPos,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.my_location,
                color: Colors.blue,
                size: 32,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
