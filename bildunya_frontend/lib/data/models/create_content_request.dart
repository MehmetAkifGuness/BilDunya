/// [com.bildunya.dto.CreateContentRequest] — Jackson camelCase.
class CreateContentRequest {
  const CreateContentRequest({
    required this.description,
    required this.contentType,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.shareType,
    this.tags,
  });

  final String description;
  final String contentType;
  final double latitude;
  final double longitude;
  final String? locationName;
  final String? shareType;
  final String? tags;

  Map<String, dynamic> toJson() => {
        'description': description,
        'contentType': contentType,
        'latitude': latitude,
        'longitude': longitude,
        if (locationName != null) 'locationName': locationName,
        if (shareType != null) 'shareType': shareType,
        if (tags != null) 'tags': tags,
      };
}
