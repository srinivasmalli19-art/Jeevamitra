import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../generated/l10n/app_localizations.dart';

/// Floating search bar styled as a card, matching the Dashboard's
/// elevated-surface language. UI only: it manages its own text so typing
/// and clearing feel real, but does not filter anything — [onChanged] and
/// [onSubmitted] are exposed so real search logic can be wired in later
/// without touching this widget again.
class SearchCard extends StatefulWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilterTap;

  const SearchCard({
    super.key,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
  });

  @override
  State<SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<SearchCard> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    setState(() => _hasText = false);
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.cardRadius,
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (v) {
                setState(() => _hasText = v.isNotEmpty);
                widget.onChanged?.call(v);
              },
              onSubmitted: widget.onSubmitted,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: widget.hint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (_hasText)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
              onPressed: _clear,
              tooltip: loc.clearBtn,
            ),
          if (widget.onFilterTap != null)
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
              onPressed: widget.onFilterTap,
              tooltip: loc.filtersLabel,
            ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
    );
  }
}
