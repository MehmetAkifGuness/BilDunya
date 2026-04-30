/// [LocationPickerView] sonucu.
class PickedLocation {
  const PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });

  final double latitude;
  final double longitude;
  final String locationName;
}
