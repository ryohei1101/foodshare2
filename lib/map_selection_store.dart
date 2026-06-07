import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class MapShopSelection {
  const MapShopSelection({
    required this.key,
    required this.shopName,
    required this.location,
    required this.point,
  });

  final String key;
  final String shopName;
  final String location;
  final LatLng point;
}

class MapSelectionStore {
  MapSelectionStore._();

  static final ValueNotifier<List<MapShopSelection>> pollSelections =
      ValueNotifier<List<MapShopSelection>>([]);

  static void togglePollSelection(MapShopSelection selection) {
    final selections = [...pollSelections.value];
    final index = selections.indexWhere((item) => item.key == selection.key);

    if (index >= 0) {
      selections.removeAt(index);
    } else {
      selections.add(selection);
    }

    pollSelections.value = selections;
  }

  static bool containsPollSelection(String key) {
    return pollSelections.value.any((item) => item.key == key);
  }
}
