/// [com.bildunya.dto.UpdateProfileRequest]
class UpdateProfileRequest {
  const UpdateProfileRequest({
    this.fullName,
    this.bio,
    this.phoneNumber,
    this.isAnonymous,
    this.locationPreferences,
  });

  final String? fullName;
  final String? bio;
  final String? phoneNumber;
  final bool? isAnonymous;
  final String? locationPreferences;

  Map<String, dynamic> toJson() => {
    if (fullName != null) 'fullName': fullName,
    if (bio != null) 'bio': bio,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
    if (isAnonymous != null) 'isAnonymous': isAnonymous,
    if (locationPreferences != null) 'locationPreferences': locationPreferences,
  };
}
