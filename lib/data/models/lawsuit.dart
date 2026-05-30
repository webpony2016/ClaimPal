/// Whether a lawsuit is currently open for claims.
enum LawsuitStatus { active, expired }

/// High-level category used for grouping and (in the UI) icon selection.
enum LawsuitCategory { privacy, finance, health, security, other }

/// Immutable representation of a class-action lawsuit a user may claim against.
class Lawsuit {
  const Lawsuit({
    required this.id,
    required this.title,
    required this.brand,
    required this.category,
    required this.status,
    required this.payoutLabel,
    required this.payoutValue,
    required this.deadline,
    required this.expiredDaysAgo,
    required this.eligibility,
    required this.requiredProof,
  });

  final String id;
  final String title;
  final String brand;
  final LawsuitCategory category;
  final LawsuitStatus status;
  final String payoutLabel;
  final String payoutValue;
  final DateTime? deadline;
  final int? expiredDaysAgo;
  final String eligibility;
  final List<String> requiredProof;

  Lawsuit copyWith({
    String? id,
    String? title,
    String? brand,
    LawsuitCategory? category,
    LawsuitStatus? status,
    String? payoutLabel,
    String? payoutValue,
    DateTime? deadline,
    int? expiredDaysAgo,
    String? eligibility,
    List<String>? requiredProof,
  }) {
    return Lawsuit(
      id: id ?? this.id,
      title: title ?? this.title,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      status: status ?? this.status,
      payoutLabel: payoutLabel ?? this.payoutLabel,
      payoutValue: payoutValue ?? this.payoutValue,
      deadline: deadline ?? this.deadline,
      expiredDaysAgo: expiredDaysAgo ?? this.expiredDaysAgo,
      eligibility: eligibility ?? this.eligibility,
      requiredProof: requiredProof ?? this.requiredProof,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Lawsuit &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        title == other.title &&
        brand == other.brand &&
        category == other.category &&
        status == other.status &&
        payoutLabel == other.payoutLabel &&
        payoutValue == other.payoutValue &&
        deadline == other.deadline &&
        expiredDaysAgo == other.expiredDaysAgo &&
        eligibility == other.eligibility &&
        _listEquals(requiredProof, other.requiredProof);
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        brand,
        category,
        status,
        payoutLabel,
        payoutValue,
        deadline,
        expiredDaysAgo,
        eligibility,
        Object.hashAll(requiredProof),
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
