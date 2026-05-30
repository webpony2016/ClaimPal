import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Rounded search input used by the tracker and explore feeds.
class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.onChanged, this.hintText});

  final ValueChanged<String> onChanged;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: AppTextStyles.bodyMd,
      decoration: InputDecoration(
        hintText: hintText ?? 'Search class actions...',
        hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.outline),
        prefixIcon: const Icon(Icons.search, color: AppColors.outline),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.navy, width: 2),
        ),
      ),
    );
  }
}
