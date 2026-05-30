import 'package:flutter_test/flutter_test.dart';
import 'package:claimpal/data/models/filing_draft.dart';

void main() {
  test('isStep1Complete true when all fields filled and file uploaded', () {
    const draft = FilingDraft(
      lawsuitId: 'l1',
      fullName: 'Jane Doe',
      address: '1 Main St',
      actionRequiredFields: {'orderId': 'A123', 'date': '2024-01-01'},
      uploadedFileName: 'receipt.pdf',
      signatureData: null,
    );
    expect(draft.isStep1Complete, isTrue);
  });

  test('isStep1Complete false when a field value is null', () {
    const draft = FilingDraft(
      lawsuitId: 'l1',
      fullName: 'Jane Doe',
      address: '1 Main St',
      actionRequiredFields: {'orderId': 'A123', 'date': null},
      uploadedFileName: 'receipt.pdf',
      signatureData: null,
    );
    expect(draft.isStep1Complete, isFalse);
  });

  test('isStep1Complete false when a field value is empty', () {
    const draft = FilingDraft(
      lawsuitId: 'l1',
      fullName: 'Jane Doe',
      address: '1 Main St',
      actionRequiredFields: {'orderId': ''},
      uploadedFileName: 'receipt.pdf',
      signatureData: null,
    );
    expect(draft.isStep1Complete, isFalse);
  });

  test('isStep1Complete false when file missing or empty', () {
    const noFile = FilingDraft(
      lawsuitId: 'l1',
      fullName: 'Jane Doe',
      address: '1 Main St',
      actionRequiredFields: {'orderId': 'A123'},
      uploadedFileName: null,
      signatureData: null,
    );
    expect(noFile.isStep1Complete, isFalse);
    const emptyFile = FilingDraft(
      lawsuitId: 'l1',
      fullName: 'Jane Doe',
      address: '1 Main St',
      actionRequiredFields: {'orderId': 'A123'},
      uploadedFileName: '',
      signatureData: null,
    );
    expect(emptyFile.isStep1Complete, isFalse);
  });

  test('isStep2Complete reflects signature presence', () {
    const noSig = FilingDraft(
      lawsuitId: 'l1',
      fullName: 'Jane Doe',
      address: '1 Main St',
      actionRequiredFields: {'orderId': 'A123'},
      uploadedFileName: 'receipt.pdf',
      signatureData: null,
    );
    expect(noSig.isStep2Complete, isFalse);
    const emptySig = FilingDraft(
      lawsuitId: 'l1',
      fullName: 'Jane Doe',
      address: '1 Main St',
      actionRequiredFields: {'orderId': 'A123'},
      uploadedFileName: 'receipt.pdf',
      signatureData: '',
    );
    expect(emptySig.isStep2Complete, isFalse);
    final signed = noSig.copyWith(signatureData: 'sig-base64');
    expect(signed.isStep2Complete, isTrue);
  });

  test('copyWith changes fields', () {
    const draft = FilingDraft(
      lawsuitId: 'l1',
      fullName: 'Jane Doe',
      address: '1 Main St',
      actionRequiredFields: {'orderId': 'A123'},
      uploadedFileName: null,
      signatureData: null,
    );
    final updated = draft.copyWith(
      fullName: 'John Roe',
      uploadedFileName: 'doc.pdf',
    );
    expect(updated.fullName, 'John Roe');
    expect(updated.uploadedFileName, 'doc.pdf');
    expect(updated.lawsuitId, 'l1');
  });

  test('equality and hashCode including map contents', () {
    const a = FilingDraft(
      lawsuitId: 'l1',
      fullName: 'Jane Doe',
      address: '1 Main St',
      actionRequiredFields: {'orderId': 'A123', 'date': '2024'},
      uploadedFileName: 'receipt.pdf',
      signatureData: 'sig',
    );
    const b = FilingDraft(
      lawsuitId: 'l1',
      fullName: 'Jane Doe',
      address: '1 Main St',
      actionRequiredFields: {'orderId': 'A123', 'date': '2024'},
      uploadedFileName: 'receipt.pdf',
      signatureData: 'sig',
    );
    const c = FilingDraft(
      lawsuitId: 'l1',
      fullName: 'Jane Doe',
      address: '1 Main St',
      actionRequiredFields: {'orderId': 'A999', 'date': '2024'},
      uploadedFileName: 'receipt.pdf',
      signatureData: 'sig',
    );
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    expect(a, isNot(equals(c)));
  });
}
