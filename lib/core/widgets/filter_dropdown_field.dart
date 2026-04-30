import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

class DropdownOption {
  final String id;
  final String label;

  const DropdownOption({required this.id, required this.label});
}

class FilterDropdownField extends StatefulWidget {
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final List<DropdownOption> options;
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final bool isLoading;

  const FilterDropdownField({
    super.key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    required this.options,
    required this.onSelected,
    this.selectedId,
    this.isLoading = false,
  });

  @override
  State<FilterDropdownField> createState() => _FilterDropdownFieldState();
}

class _FilterDropdownFieldState extends State<FilterDropdownField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _lastValidLabel = '';

  @override
  void initState() {
    super.initState();
    _syncSelectedLabel();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant FilterDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId ||
        oldWidget.options.length != widget.options.length) {
      _syncSelectedLabel();
    }
  }

  void _syncSelectedLabel() {
    if (widget.selectedId == null) {
      _controller.text = '';
      _lastValidLabel = '';
      return;
    }
    final match = widget.options.firstWhere(
      (o) => o.id == widget.selectedId,
      orElse: () => const DropdownOption(id: '', label: ''),
    );
    final newText = match.id.isEmpty ? '' : match.label;
    if (_controller.text != newText) {
      _controller.text = newText;
    }
    _lastValidLabel = newText;
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      if (_controller.text != _lastValidLabel) {
        _controller.text = _lastValidLabel;
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.outfit(
            color: AppColors.accentGold,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        TypeAheadField<DropdownOption>(
          controller: _controller,
          focusNode: _focusNode,
          builder: (context, ctrl, focusNode) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.borderSoft.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: ctrl,
                focusNode: focusNode,
                cursorColor: AppColors.accentGold,
                style: GoogleFonts.outfit(
                  color: AppColors.textWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                onTap: () {
                  if (ctrl.text.isNotEmpty) {
                    ctrl.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: ctrl.text.length,
                    );
                  }
                },
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: GoogleFonts.outfit(
                    color: AppColors.softGrey.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      widget.prefixIcon,
                      color: AppColors.accentGold,
                      size: 20,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  suffixIcon: ctrl.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            ctrl.clear();
                            _lastValidLabel = '';
                            widget.onSelected(null);
                            FocusScope.of(context).unfocus();
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppColors.softGrey,
                            size: 18,
                          ),
                        )
                      : const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.accentGold,
                          size: 22,
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            );
          },
          suggestionsCallback: (pattern) {
            final lower = pattern.toLowerCase();
            if (lower.isEmpty) return widget.options;
            if (lower == _lastValidLabel.toLowerCase()) return widget.options;
            return widget.options
                .where((o) => o.label.toLowerCase().contains(lower))
                .toList();
          },
          itemBuilder: (context, option) {
            final isSelected = option.id == widget.selectedId;
            return Container(
              color: AppColors.cardDark,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option.label,
                      style: GoogleFonts.outfit(
                        color: isSelected
                            ? AppColors.accentGold
                            : AppColors.textWhite,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_rounded,
                      color: AppColors.accentGold,
                      size: 18,
                    ),
                ],
              ),
            );
          },
          decorationBuilder: (context, child) {
            return Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: AppColors.cardDark,
              shadowColor: Colors.black.withValues(alpha: 0.4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.borderSoft.withValues(alpha: 0.8),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: child,
                ),
              ),
            );
          },
          loadingBuilder: (context) => SizedBox(
            height: 100,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) => _buildShimmerItem(),
            ),
          ),
          emptyBuilder: (context) => Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'No matches found',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppColors.softGrey,
                fontSize: 13,
              ),
            ),
          ),
          onSelected: (option) {
            _controller.text = option.label;
            _lastValidLabel = option.label;
            widget.onSelected(option.id);
            FocusScope.of(context).unfocus();
          },
          offset: const Offset(0, 6),
          debounceDuration: const Duration(milliseconds: 200),
          hideOnEmpty: false,
          hideOnLoading: false,
          hideWithKeyboard: false,
          constraints: const BoxConstraints(maxHeight: 280),
          retainOnLoading: true,
        ),
      ],
    );
  }

  Widget _buildShimmerItem() {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: AppColors.borderSoft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        height: 16,
        decoration: BoxDecoration(
          color: AppColors.borderSoft,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
