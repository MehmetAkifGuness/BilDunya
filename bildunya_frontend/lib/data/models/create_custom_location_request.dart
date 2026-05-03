class CreateCustomLocationRequest {
  const CreateCustomLocationRequest({
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    this.tags,
  });

  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final List<String>? tags;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'tags': tags,
      };
}

