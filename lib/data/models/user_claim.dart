import 'claim_progress.dart';

enum UserClaimStatus {
  draft,
  submitted,
  underReview,
  approved,
  payoutSent,
  rejected,
  selfIneligible,
}

class UserClaim {
  const UserClaim({
    required this.id,
    required this.lawsuitId,
    required this.status,
    required this.currentStage,
    required this.filingData,
    required this.attemptCount,
    required this.submittedAt,
    required this.reviewedAt,
    required this.rejectedAt,
    required this.payoutConfirmedAt,
    required this.payoutAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String lawsuitId;
  final UserClaimStatus status;
  final ClaimStage? currentStage;
  final Map<String, dynamic> filingData;
  final int attemptCount;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime? rejectedAt;
  final DateTime? payoutConfirmedAt;
  final double? payoutAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isSelfIneligible => status == UserClaimStatus.selfIneligible;

  bool get isRejected => status == UserClaimStatus.rejected;

  bool get isPaid => payoutConfirmedAt != null;

  bool get isSubmittedClaim {
    switch (status) {
      case UserClaimStatus.submitted:
      case UserClaimStatus.underReview:
      case UserClaimStatus.approved:
      case UserClaimStatus.payoutSent:
        return true;
      case UserClaimStatus.draft:
      case UserClaimStatus.rejected:
      case UserClaimStatus.selfIneligible:
        return false;
    }
  }

  bool get showsInClaimList => isSubmittedClaim || isPaid;

  double get confirmedPayoutAmount => isPaid ? (payoutAmount ?? 0) : 0;

  Map<String, String?> get actionRequiredFields {
    final raw = filingData['action_required_fields'];
    if (raw is! Map) {
      return const <String, String?>{};
    }

    return raw.map(
      (key, value) => MapEntry(key.toString(), value?.toString()),
    );
  }

  String? get uploadedFileName => filingData['uploaded_file_name']?.toString();

  String? get signatureData => filingData['signature_data']?.toString();

  String? get fullName => filingData['full_name']?.toString();

  String? get address => filingData['address']?.toString();

  UserClaim copyWith({
    String? id,
    String? lawsuitId,
    UserClaimStatus? status,
    ClaimStage? currentStage,
    Map<String, dynamic>? filingData,
    int? attemptCount,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    DateTime? rejectedAt,
    DateTime? payoutConfirmedAt,
    double? payoutAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserClaim(
      id: id ?? this.id,
      lawsuitId: lawsuitId ?? this.lawsuitId,
      status: status ?? this.status,
      currentStage: currentStage ?? this.currentStage,
      filingData: filingData ?? this.filingData,
      attemptCount: attemptCount ?? this.attemptCount,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      payoutConfirmedAt: payoutConfirmedAt ?? this.payoutConfirmedAt,
      payoutAmount: payoutAmount ?? this.payoutAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
