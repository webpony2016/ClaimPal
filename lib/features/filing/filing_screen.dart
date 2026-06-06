import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/claim_stepper.dart';
import '../../data/models/filing_draft.dart';
import '../../data/providers.dart';
import 'filing_controller.dart';
import 'signature_codec.dart';

/// AI 1-click smart filing wizard (route `/filing/:id`).
///
/// Three steps: (0) autofill preview + action-required fields, (1) digital
/// signature + authorization, (2) success + claim progress tracker.
class FilingScreen extends ConsumerWidget {
  const FilingScreen({super.key, required this.lawsuitId});

  final String lawsuitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(filingControllerProvider(lawsuitId));

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Filing')),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorState(
          onRetry: () =>
              ref.invalidate(filingControllerProvider(lawsuitId)),
        ),
        data: (state) {
          switch (state.step) {
            case 0:
              return _Step1Review(lawsuitId: lawsuitId, draft: state.draft);
            case 1:
              return _Step2Signature(
                lawsuitId: lawsuitId,
                draft: state.draft,
                submitting: state.submitting,
              );
            default:
              return _Step3Success(lawsuitId: lawsuitId);
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 — Autofill preview + Action Required
// ---------------------------------------------------------------------------

class _Step1Review extends ConsumerWidget {
  const _Step1Review({required this.lawsuitId, required this.draft});

  final String lawsuitId;
  final FilingDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller =
        ref.read(filingControllerProvider(lawsuitId).notifier);

    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Center(child: _AiAutofillTag()),
                const SizedBox(height: 16),
                Text('Review Information', style: AppTextStyles.headlineMd),
                const SizedBox(height: 4),
                Text(
                  'Our AI has prefilled your verified details. Complete the '
                  'remaining fields to file your claim.',
                  style:
                      AppTextStyles.bodySm.copyWith(color: AppColors.mutedText),
                ),
                const SizedBox(height: 24),
                Text(
                  'VERIFIED DETAILS',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.mutedText,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                _VerifiedRow(label: 'Legal Name', value: draft.fullName),
                const SizedBox(height: 12),
                _VerifiedRow(label: 'Home Address', value: draft.address),
                const SizedBox(height: 24),
                _ActionRequiredSection(
                  draft: draft,
                  onFieldChanged: controller.setActionField,
                  onUpload: () => controller.setUploadedFile('receipt.pdf'),
                ),
              ],
            ),
          ),
        ),
        _BottomBar(
          child: ElevatedButton(
            onPressed: draft.isStep1Complete ? controller.next : null,
            style: _primaryButtonStyle(),
            child: const _ButtonLabel(
              label: 'Next',
              icon: Icons.arrow_forward,
            ),
          ),
        ),
      ],
    );
  }
}

class _AiAutofillTag extends StatelessWidget {
  const _AiAutofillTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: <Color>[AppColors.success, AppColors.primaryContainer],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            'AI Autofill Ready',
            style: AppTextStyles.labelLg.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _VerifiedRow extends StatelessWidget {
  const _VerifiedRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style:
                      AppTextStyles.labelSm.copyWith(color: AppColors.mutedText),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.success, size: 22),
        ],
      ),
    );
  }
}

class _ActionRequiredSection extends StatelessWidget {
  const _ActionRequiredSection({
    required this.draft,
    required this.onFieldChanged,
    required this.onUpload,
  });

  final FilingDraft draft;
  final void Function(String key, String? value) onFieldChanged;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.error_outline,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text('Action Required', style: AppTextStyles.headlineSm),
            ],
          ),
          const SizedBox(height: 16),
          for (final entry in draft.actionRequiredFields.entries) ...<Widget>[
            _ActionField(
              label: entry.key,
              value: entry.value,
              onChanged: (v) => onFieldChanged(entry.key, v),
            ),
            const SizedBox(height: 16),
          ],
          _UploadBox(
            fileName: draft.uploadedFileName,
            onTap: onUpload,
          ),
        ],
      ),
    );
  }
}

class _ActionField extends StatelessWidget {
  const _ActionField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTextStyles.labelLg.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadBox extends StatelessWidget {
  const _UploadBox({required this.fileName, required this.onTap});

  final String? fileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool uploaded = fileName != null && fileName!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Upload Proof',
          style: AppTextStyles.labelLg.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: DottedBorderBox(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              child: Column(
                children: <Widget>[
                  Icon(
                    uploaded ? Icons.check_circle : Icons.cloud_upload_outlined,
                    color: uploaded ? AppColors.success : AppColors.mutedText,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    uploaded ? fileName! : 'Tap to upload receipt or screenshot',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelLg.copyWith(
                      color: uploaded ? AppColors.success : AppColors.mutedText,
                    ),
                  ),
                  if (!uploaded) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      'PDF, JPG, or PNG up to 10MB',
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.mutedText),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A rounded box with a dashed outline, painted via [_DashedBorderPainter].
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: SizedBox(width: double.infinity, child: child),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  static const double _radius = 12;
  static const double _dash = 6;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(_radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + _dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Step 2 — Signature + Authorize
// ---------------------------------------------------------------------------

class _Step2Signature extends ConsumerStatefulWidget {
  const _Step2Signature({
    required this.lawsuitId,
    required this.draft,
    required this.submitting,
  });

  final String lawsuitId;
  final FilingDraft draft;
  final bool submitting;

  @override
  ConsumerState<_Step2Signature> createState() => _Step2SignatureState();
}

class _Step2SignatureState extends ConsumerState<_Step2Signature> {
  final List<Offset?> _points = <Offset?>[];

  FilingController get _controller =>
      ref.read(filingControllerProvider(widget.lawsuitId).notifier);

  void _syncSignature() {
    // Serialize the actual stroke geometry so the captured signature — not just
    // a point count — persists with the filing draft. Encodes to '' when no
    // strokes exist, keeping FilingDraft.isStep2Complete honest.
    _controller.setSignature(SignatureCodec.encode(_points));
  }

  void _clear() {
    setState(_points.clear);
    _controller.clearSignature();
  }

  Future<void> _submit() async {
    await _controller.submit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Legal Declaration', style: AppTextStyles.headlineMd),
                const SizedBox(height: 4),
                Text(
                  'Please review the following statements carefully before '
                  'signing.',
                  style:
                      AppTextStyles.bodySm.copyWith(color: AppColors.mutedText),
                ),
                const SizedBox(height: 24),
                const _DeclarationCard(),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      'Digital Signature',
                      style: AppTextStyles.labelLg
                          .copyWith(color: AppColors.primary),
                    ),
                    TextButton(
                      onPressed: _points.isEmpty ? null : _clear,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _SignaturePad(
                  points: _points,
                  onPanStart: (offset) {
                    setState(() => _points.add(offset));
                    _syncSignature();
                  },
                  onPanUpdate: (offset) {
                    setState(() => _points.add(offset));
                    _syncSignature();
                  },
                  onPanEnd: () {
                    setState(() => _points.add(null));
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    const Icon(Icons.info_outline,
                        size: 16, color: AppColors.mutedText),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Your signature is encrypted and timestamped for legal '
                        'validity.',
                        style: AppTextStyles.labelSm
                            .copyWith(color: AppColors.mutedText),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _BottomBar(
          child: Row(
            children: <Widget>[
              OutlinedButton(
                onPressed: widget.submitting
                    ? null
                    : () => _controller.back(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(96, 56),
                  side: const BorderSide(color: AppColors.outlineVariant),
                ),
                child: const Text('Back'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      (widget.draft.isStep2Complete && !widget.submitting)
                          ? _submit
                          : null,
                  style: _primaryButtonStyle(),
                  child: widget.submitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const _ButtonLabel(
                          label: 'Authorize & Submit via AI',
                          icon: Icons.shield_outlined,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeclarationCard extends StatelessWidget {
  const _DeclarationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.gavel, color: AppColors.primaryContainer, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Attestation of Accuracy',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'I declare under penalty of perjury under the laws of the '
                  'United States of America that the foregoing information is '
                  'true and correct. I understand that any false statements '
                  'made herein are punishable by law.',
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.mutedText),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    border: Border(
                      left: BorderSide(color: AppColors.primary, width: 4),
                    ),
                  ),
                  child: Text(
                    'By signing this document, I authorize ClaimPal to act as '
                    'my designated representative for the purpose of submitting '
                    'this legal claim.',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.mutedText,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignaturePad extends StatelessWidget {
  const _SignaturePad({
    required this.points,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  final List<Offset?> points;
  final ValueChanged<Offset> onPanStart;
  final ValueChanged<Offset> onPanUpdate;
  final VoidCallback onPanEnd;

  @override
  Widget build(BuildContext context) {
    final bool empty = points.every((p) => p == null);
    return AspectRatio(
      aspectRatio: 2,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          onPanStart: (d) => onPanStart(d.localPosition),
          onPanUpdate: (d) => onPanUpdate(d.localPosition),
          onPanEnd: (_) => onPanEnd(),
          child: Stack(
            children: <Widget>[
              CustomPaint(
                size: Size.infinite,
                painter: _SignaturePainter(points),
              ),
              if (empty)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.draw_outlined,
                          color: AppColors.outlineVariant, size: 28),
                      const SizedBox(height: 4),
                      Text(
                        'Sign with your finger here',
                        style: AppTextStyles.labelLg
                            .copyWith(color: AppColors.outlineVariant),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.points);

  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (a != null && b != null) {
        canvas.drawLine(a, b, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) =>
      oldDelegate.points != points;
}

// ---------------------------------------------------------------------------
// Step 3 — Success + Progress
// ---------------------------------------------------------------------------

class _Step3Success extends ConsumerWidget {
  const _Step3Success({required this.lawsuitId});

  final String lawsuitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(claimProgressProvider(lawsuitId));

    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 16),
                const _SuccessCheck(),
                const SizedBox(height: 24),
                Text(
                  'Claim Successfully Filed!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineLg,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your legal claim has been securely submitted via our AI '
                  'engine. Track its progress below.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.mutedText),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Claim Tracker', style: AppTextStyles.headlineSm),
                      const SizedBox(height: 24),
                      progressAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (e, _) => Text(
                          "Couldn't load claim progress.",
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.error),
                        ),
                        data: (progress) => ClaimStepper(progress: progress),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _BottomBar(
          child: ElevatedButton(
            onPressed: () => context.go('/tracker'),
            style: _primaryButtonStyle(),
            child: const _ButtonLabel(label: 'Back to Tracker'),
          ),
        ),
      ],
    );
  }
}

class _SuccessCheck extends StatelessWidget {
  const _SuccessCheck();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.scale(scale: value, child: child),
        );
      },
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.success.withValues(alpha: 0.12),
          border: Border.all(color: AppColors.success, width: 3),
        ),
        child: const Icon(Icons.check, color: AppColors.success, size: 56),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

ButtonStyle _primaryButtonStyle() => ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(56),
      shape: const StadiumBorder(),
    );

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            height: 24 / 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        ),
        child: child,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              "Couldn't start your filing",
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSm,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
