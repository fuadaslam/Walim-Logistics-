import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';

class WalimDataTable<T> extends StatefulWidget {
  final List<WalimColumn> columns;
  final List<T> items;
  final List<DataRow> Function(List<T> pagedItems) rowBuilder;
  final String title;
  final int initialRowsPerPage;
  final Function(int)? onRowsPerPageChanged;
  final bool isLoading;
  final Widget? emptyState;
  final List<Widget>? actions;

  const WalimDataTable({
    super.key,
    required this.columns,
    required this.items,
    required this.rowBuilder,
    this.title = '',
    this.initialRowsPerPage = 10,
    this.onRowsPerPageChanged,
    this.isLoading = false,
    this.emptyState,
    this.actions,
  });

  @override
  State<WalimDataTable<T>> createState() => _WalimDataTableState<T>();
}

class _WalimDataTableState<T> extends State<WalimDataTable<T>> {
  late int _rowsPerPage;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _rowsPerPage = widget.initialRowsPerPage;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (widget.isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(40.0),
        child: CircularProgressIndicator(),
      ));
    }

    if (widget.items.isEmpty) {
      return widget.emptyState ?? _buildDefaultEmptyState();
    }

    final totalItems = widget.items.length;
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage) < totalItems ? (startIndex + _rowsPerPage) : totalItems;
    final pagedItems = widget.items.sublist(startIndex, endIndex);
    final totalPages = (totalItems / _rowsPerPage).ceil();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title.isNotEmpty || widget.actions != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.title.isNotEmpty)
                    Text(
                      widget.title,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  if (widget.actions != null)
                    Row(children: widget.actions!),
                ],
              ),
            ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: widget.title.isEmpty && widget.actions == null ? const Radius.circular(24) : Radius.zero,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowColor: WidgetStateProperty.all(
                      isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.background.withValues(alpha: 0.5),
                    ),
                    dataRowMaxHeight: 75,
                    dataRowMinHeight: 65,
                    dividerThickness: 0.5,
                    horizontalMargin: 24,
                    columnSpacing: 12,
                    columns: widget.columns.map((c) => DataColumn(
                      label: _buildHeaderLabel(c.label, c.icon),
                    )).toList(),
                    rows: widget.rowBuilder(pagedItems),
                  ),
                ),
              ),
            ),
          ),
          _buildPaginationFooter(totalItems, totalPages, isDark),
        ],
      ),
    );
  }

  Widget _buildHeaderLabel(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1.0,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationFooter(int totalItems, int totalPages, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.01) : Colors.black.withValues(alpha: 0.01),
        border: Border(top: BorderSide(color: isDark ? Colors.white10 : AppColors.divider.withValues(alpha: 0.5))),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Showing ${(_currentPage * _rowsPerPage) + 1} to ${((_currentPage + 1) * _rowsPerPage).clamp(0, totalItems)} of $totalItems items',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Rows per page selector
              Text(
                'Rows:',
                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 8),
              _buildRowsPerPageSelector(isDark),
            ],
          ),
          Row(
            children: [
              _buildPageButton(
                icon: Icons.chevron_left_rounded,
                onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              ...List.generate(totalPages, (index) {
                if (totalPages > 5) {
                  if (index != 0 && index != totalPages - 1 && (index < _currentPage - 1 || index > _currentPage + 1)) {
                    if (index == _currentPage - 2 || index == _currentPage + 2) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text('...', style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5))),
                      );
                    }
                    return const SizedBox.shrink();
                  }
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildPageNumber(index, isDark),
                );
              }),
              const SizedBox(width: 8),
              _buildPageButton(
                icon: Icons.chevron_right_rounded,
                onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRowsPerPageSelector(bool isDark) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _rowsPerPage,
          items: [10, 25, 50, 100].map((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text('$value', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _rowsPerPage = value;
                _currentPage = 0;
              });
              if (widget.onRowsPerPageChanged != null) {
                widget.onRowsPerPageChanged!(value);
              }
            }
          },
          icon: Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildPageNumber(int index, bool isDark) {
    final isSelected = _currentPage == index;
    return InkWell(
      onTap: () => setState(() => _currentPage = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Text(
          '${index + 1}',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPageButton({required IconData icon, VoidCallback? onPressed, required bool isDark}) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
        ),
      ),
    );
  }

  Widget _buildDefaultEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Icon(Icons.inbox_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No data found',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class WalimColumn {
  final String label;
  final IconData icon;

  const WalimColumn({required this.label, required this.icon});
}
