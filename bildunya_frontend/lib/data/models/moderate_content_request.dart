/// `PATCH /contents/{id}/moderation` gövdesi.
class ModerateContentRequest {
  const ModerateContentRequest({
    required this.verificationStatus,
    this.rejectionReason,
  });

  final String verificationStatus; // APPROVED, REJECTED
  final String? rejectionReason;

  Map<String, dynamic> toJson() => {
    'verificationStatus': verificationStatus,
    if (rejectionReason != null) 'rejectionReason': rejectionReason,
  };
}
