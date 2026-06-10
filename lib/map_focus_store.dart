import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class MapFocusRequest {
  const MapFocusRequest({
    required this.point,
    required this.label,
    required this.requestId,
  });

  final LatLng point;
  final String label;
  final int requestId;
}

class MapFocusStore {
  static final ValueNotifier<MapFocusRequest?> request =
      ValueNotifier<MapFocusRequest?>(null);
  static int _nextRequestId = 0;

  static void focus(LatLng point, {String label = ''}) {
    _nextRequestId += 1;
    request.value = MapFocusRequest(
      point: point,
      label: label,
      requestId: _nextRequestId,
    );
  }
}
