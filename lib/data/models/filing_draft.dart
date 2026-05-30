/// Immutable working draft for a single claim filing across the wizard steps.
class FilingDraft {
  const FilingDraft({
    required this.lawsuitId,
    required this.fullName,
    required this.address,
    required this.actionRequiredFields,
    required this.uploadedFileName,
    required this.signatureData,
  });

  final String lawsuitId;
  final String fullName;
  final String address;

  /// Dynamic per-lawsuit fields the user must supply. A `null` or empty value
  /// means the field is not yet filled in.
  final Map<String, String?> actionRequiredFields;
  final String? uploadedFileName;
  final String? signatureData;

  /// Step 1 is complete when every action-required field has a non-empty value
  /// and a proof file has been uploaded.
  bool get isStep1Complete {
    final allFieldsFilled = actionRequiredFields.values
        .every((v) => v != null && v.isNotEmpty);
    final hasFile = uploadedFileName != null && uploadedFileName!.isNotEmpty;
    return allFieldsFilled && hasFile;
  }

  /// Step 2 is complete when a signature has been captured.
  bool get isStep2Complete =>
      signatureData != null && signatureData!.isNotEmpty;

  FilingDraft copyWith({
    String? lawsuitId,
    String? fullName,
    String? address,
    Map<String, String?>? actionRequiredFields,
    String? uploadedFileName,
    String? signatureData,
  }) {
    return FilingDraft(
      lawsuitId: lawsuitId ?? this.lawsuitId,
      fullName: fullName ?? this.fullName,
      address: address ?? this.address,
      actionRequiredFields: actionRequiredFields ?? this.actionRequiredFields,
      uploadedFileName: uploadedFileName ?? this.uploadedFileName,
      signatureData: signatureData ?? this.signatureData,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilingDraft &&
        runtimeType == other.runtimeType &&
        lawsuitId == other.lawsuitId &&
        fullName == other.fullName &&
        address == other.address &&
        uploadedFileName == other.uploadedFileName &&
        signatureData == other.signatureData &&
        _mapEquals(actionRequiredFields, other.actionRequiredFields);
  }

  @override
  int get hashCode => Object.hash(
        lawsuitId,
        fullName,
        address,
        uploadedFileName,
        signatureData,
        // Order-independent hash of the map's entries so equal maps with
        // differing insertion order still produce equal hash codes.
        Object.hashAllUnordered(
          actionRequiredFields.entries
              .map((e) => Object.hash(e.key, e.value)),
        ),
      );

  static bool _mapEquals(Map<String, String?> a, Map<String, String?> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}
