import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class FilterOption {
  final String id;
  final String label;

  const FilterOption({required this.id, required this.label});
}

class SearchableFilterList extends StatefulWidget {
  final String title;
  final List<FilterOption> options;
  final String? selectedId;
  final Function(String?) onOptionSelected;

  const SearchableFilterList({
    super.key,
    required this.title,
    required this.options,
    this.selectedId,
    required this.onOptionSelected,
  });

  @override
  State<SearchableFilterList> createState() => _SearchableFilterListState();
}

class _SearchableFilterListState extends State<SearchableFilterList> {
  final TextEditingController _searchController = TextEditingController();
  bool _isExpanded = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredOptions = widget.options
        .where((opt) => opt.label.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: widget.selectedId != null,
        onExpansionChanged: (expanded) {
          setState(() => _isExpanded = expanded);
        },
        title: Text(
          widget.title,
          style: GoogleFonts.outfit(
            color: AppColors.accentGold,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
          color: AppColors.accentGold,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search ${widget.title.toLowerCase()}...',
                hintStyle: GoogleFonts.outfit(color: AppColors.softGrey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.softGrey, size: 18),
                filled: true,
                fillColor: AppColors.cardDark,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredOptions.length,
              itemBuilder: (context, index) {
                final opt = filteredOptions[index];
                final isSelected = widget.selectedId == opt.id;
                
                return ListTile(
                  dense: true,
                  title: Text(
                    opt.label,
                    style: GoogleFonts.nunito(
                      color: isSelected ? AppColors.accentGold : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected ? const Icon(Icons.check, color: AppColors.accentGold, size: 16) : null,
                  onTap: () => widget.onOptionSelected(opt.id),
                );
              },
            ),
          ),
          if (filteredOptions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No results found',
                style: GoogleFonts.outfit(color: AppColors.softGrey, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
