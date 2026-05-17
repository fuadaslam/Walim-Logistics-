import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/performance/presentation/performance_notifier.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/hr/presentation/hr_notifier.dart';
import 'package:intl/intl.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:walim_logistics/shared/models/profile.dart';

class AdminPerformanceScreen extends ConsumerStatefulWidget {
  final bool showScaffold;
  const AdminPerformanceScreen({super.key, this.showScaffold = true});

  @override
  ConsumerState<AdminPerformanceScreen> createState() => _AdminPerformanceScreenState();
}

class _AdminPerformanceScreenState extends ConsumerState<AdminPerformanceScreen> {
  String _selectedRoleFilter = 'All';
  bool _isSaving = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showScaffold) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildContent(context),
              ]),
            ),
          ),
        ],
      );
    }

    return DashboardScaffold(
      title: 'PERFORMANCE MANAGEMENT',
      subtitle: 'Set targets, issue bonuses and penalties for your team',
      showBackButton: true,
      activeItem: 'Performance',
      children: [
        _buildContent(context),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final allAdjAsync = ref.watch(allAdjustmentsProvider);
    final staffAsync = ref.watch(allStaffProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuickStats(context, allAdjAsync),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Staff'),
                  const SizedBox(height: 16),
                  _buildSearchAndFilter(),
                  const SizedBox(height: 20),
                  staffAsync.when(
                    data: (staff) {
                      final currentUserRole = ref.watch(authProvider).profile?.role;
                      
                      final filtered = staff.where((s) {
                        final profile = UserProfile.fromJson(s);
                        
                        // Apply role-based visibility restrictions
                        bool isVisibleByRole = true;
                        if (currentUserRole == 'Supervisor') {
                          isVisibleByRole = profile.role == 'Rider';
                        } else if (currentUserRole == 'Operations Manager') {
                          isVisibleByRole = profile.role == 'Rider' || profile.role == 'Supervisor';
                        }

                        if (!isVisibleByRole) return false;

                        // Role filter
                        if (_selectedRoleFilter != 'All' && profile.role != _selectedRoleFilter) {
                          return false;
                        }

                        // Search filter
                        if (_searchQuery.isNotEmpty) {
                          final query = _searchQuery.toLowerCase();
                          final name = profile.fullName.toLowerCase();
                          final role = profile.role.toLowerCase();
                          final email = (profile.email ?? '').toLowerCase();
                          final phone = (profile.phoneNumber ?? '').toLowerCase();
                          return name.contains(query) || role.contains(query) || email.contains(query) || phone.contains(query);
                        }

                        return true;
                      }).toList();

                      if (filtered.isEmpty) {
                        return const EmptyStatePlaceholder(
                          icon: Icons.person_search_outlined,
                          title: 'No staff found',
                          subtitle: 'Try adjusting your filters or search query to find team members.',
                          color: Colors.blueGrey,
                        );
                      }

                      // Calculate pagination
                      final totalItems = filtered.length;
                      final totalPages = (totalItems / _itemsPerPage).ceil();
                      
                      // Handle bounds of current page
                      if (_currentPage > totalPages) {
                        _currentPage = totalPages;
                      }
                      if (_currentPage < 1) {
                        _currentPage = 1;
                      }

                      final startIndex = (_currentPage - 1) * _itemsPerPage;
                      final endIndex = startIndex + _itemsPerPage;
                      final pageItems = filtered.sublist(
                        startIndex,
                        endIndex > totalItems ? totalItems : endIndex,
                      );

                      return Column(
                        children: [
                          ...pageItems.map((s) => _buildStaffCard(context, s)),
                          _buildPagination(totalItems, totalPages),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Recent Adjustments'),
                  const SizedBox(height: 16),
                  allAdjAsync.when(
                    data: (adj) => adj.isEmpty
                        ? const EmptyStatePlaceholder(
                            icon: Icons.history_rounded,
                            title: 'No adjustments',
                            subtitle: 'No bonuses or penalties have been issued this month.',
                            color: Colors.blueGrey,
                          )
                        : Column(
                            children: adj.take(15).map((a) => _buildAdjRow(context, a)).toList(),
                          ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, AsyncValue<List<Map<String, dynamic>>> allAdjAsync) {
    return allAdjAsync.when(
      data: (adj) {
        double totalBonus = 0;
        double totalPenalty = 0;
        int bonusCount = 0;
        int penaltyCount = 0;
        for (final a in adj) {
          final amt = (a['amount'] as num?)?.toDouble() ?? 0;
          if (a['type'] == 'bonus') {
            totalBonus += amt;
            bonusCount++;
          } else {
            totalPenalty += amt;
            penaltyCount++;
          }
        }
        final fmt = NumberFormat.compactCurrency(symbol: '﷼ ', decimalDigits: 0);
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return Row(
          children: [
            _buildStatChip(context, 'Bonuses', '$bonusCount issued', fmt.format(totalBonus), Colors.green, isDark),
            const SizedBox(width: 16),
            _buildStatChip(context, 'Penalties', '$penaltyCount issued', fmt.format(totalPenalty), Colors.red, isDark),
            const SizedBox(width: 16),
            _buildStatChip(context, 'Net This Month',
                totalBonus >= totalPenalty ? 'Bonus-heavy' : 'Penalty-heavy',
                '${totalBonus >= totalPenalty ? '+' : ''}${fmt.format(totalBonus - totalPenalty)}',
                totalBonus >= totalPenalty ? Colors.green : Colors.red, isDark),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatChip(BuildContext context, String label, String sub, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(sub, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleFilter() {
    final roles = ['All', 'Rider', 'Supervisor'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: roles.map((role) {
          final isSelected = _selectedRoleFilter == role;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(role),
              selected: isSelected,
              onSelected: (_) => setState(() {
                _selectedRoleFilter = role;
                _currentPage = 1;
              }),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
              labelStyle: GoogleFonts.outfit(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.01),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _currentPage = 1;
                    });
                  },
                  style: GoogleFonts.outfit(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search staff by name or username...',
                    hintStyle: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary.withValues(alpha: 0.7), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _currentPage = 1;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildRoleFilter(),
      ],
    );
  }

  Widget _buildPagination(int totalItems, int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final int startItem = (_currentPage - 1) * _itemsPerPage + 1;
    final int endItem = _currentPage * _itemsPerPage > totalItems ? totalItems : _currentPage * _itemsPerPage;

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 24),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $startItem-$endItem of $totalItems staff',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPaginationButton(
                icon: Icons.chevron_left_rounded,
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
                enabled: _currentPage > 1,
              ),
              const SizedBox(width: 8),
              ...List.generate(totalPages, (index) {
                final pageNum = index + 1;
                if (totalPages > 5) {
                  if (pageNum != 1 && pageNum != totalPages && (pageNum - _currentPage).abs() > 1) {
                    if (pageNum == 2 && _currentPage > 3) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text('...', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
                      );
                    }
                    if (pageNum == totalPages - 1 && _currentPage < totalPages - 2) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text('...', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
                      );
                    }
                    return const SizedBox.shrink();
                  }
                }

                final isSelected = pageNum == _currentPage;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => _currentPage = pageNum),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected 
                              ? AppColors.primary 
                              : (isDark ? Colors.white10 : AppColors.divider),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          pageNum.toString(),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isSelected 
                                ? Colors.white 
                                : (isDark ? Colors.white70 : AppColors.textPrimary),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 8),
              _buildPaginationButton(
                icon: Icons.chevron_right_rounded,
                onPressed: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
                enabled: _currentPage < totalPages,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool enabled,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled 
              ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white10 : AppColors.divider,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled 
              ? (isDark ? Colors.white70 : AppColors.textPrimary) 
              : AppColors.textSecondary.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildStaffCard(BuildContext context, Map<String, dynamic> staffData) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = UserProfile.fromJson(staffData);
    final name = profile.fullName;
    final role = profile.role;
    final id = profile.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(role, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIconButton(
                Icons.flag_outlined,
                Colors.indigo,
                'Set Target',
                () => _showSetTargetDialog(context, id, name),
              ),
              const SizedBox(width: 8),
              _buildIconButton(
                Icons.add_circle_outline_rounded,
                AppColors.primary,
                'Add Bonus/Penalty',
                () => _showAddAdjustmentDialog(context, id, name),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _buildAdjRow(BuildContext context, Map<String, dynamic> adj) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final isBonus = adj['type'] == 'bonus';
    final color = isBonus ? Colors.green : Colors.red;
    final amount = (adj['amount'] as num?)?.toDouble() ?? 0;
    final fmt = NumberFormat.compactCurrency(symbol: '﷼ ', decimalDigits: 0);
    final nameData = adj['profiles'];
    final staffName = nameData is Map ? nameData['full_name'] as String? ?? 'Unknown' : 'Unknown';
    final date = adj['created_at'] != null
        ? DateFormat('MMM d').format(DateTime.parse(adj['created_at']).toLocal())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(
            isBonus ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staffName,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  '${adj['reason'] ?? ''} • $date',
                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '${isBonus ? '+' : '-'}${fmt.format(amount)}',
            style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showAddAdjustmentDialog(BuildContext context, String profileId, String staffName) {
    final formKey = GlobalKey<FormState>();
    String type = 'bonus';
    String category = 'performance';
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bonus / Penalty',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Text(
                staffName,
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type selector
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeOption(
                          ctx, setDialogState,
                          label: 'Bonus',
                          icon: Icons.trending_up_rounded,
                          value: 'bonus',
                          current: type,
                          color: Colors.green,
                          onSelect: (v) => type = v,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTypeOption(
                          ctx, setDialogState,
                          label: 'Penalty',
                          icon: Icons.trending_down_rounded,
                          value: 'penalty',
                          current: type,
                          color: Colors.red,
                          onSelect: (v) => type = v,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Category
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: _inputDec('Category'),
                    items: ['performance', 'attendance', 'behavior', 'other']
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(_capitalize(c)),
                            ))
                        .toList(),
                    onChanged: (v) => setDialogState(() => category = v ?? category),
                  ),
                  const SizedBox(height: 12),
                  // Amount
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDec('Amount (SAR)'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null || double.parse(v) <= 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // Reason
                  TextFormField(
                    controller: reasonCtrl,
                    decoration: _inputDec('Reason'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  // Notes
                  TextFormField(
                    controller: notesCtrl,
                    decoration: _inputDec('Notes (optional)'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final authProfile = ref.read(authProvider).profile;
                      if (authProfile == null) return;
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() => _isSaving = true);
                      try {
                        await ref.read(performanceRepositoryProvider).addPenaltyOrBonus(
                              profileId: profileId,
                              type: type,
                              amount: double.parse(amountCtrl.text),
                              reason: reasonCtrl.text.trim(),
                              category: category,
                              issuedById: authProfile.id,
                              issuedByName: authProfile.fullName,
                              notes: notesCtrl.text.trim(),
                            );
                        ref.invalidate(allAdjustmentsProvider);
                        ref.invalidate(riderLeaderboardProvider);
                        ref.invalidate(supervisorLeaderboardProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('${_capitalize(type)} added for $staffName'),
                              backgroundColor: type == 'bonus' ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: type == 'bonus' ? Colors.green : Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                _capitalize(type),
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetTargetDialog(BuildContext context, String profileId, String staffName) {
    final formKey = GlobalKey<FormState>();
    String metric = 'attendance_rate';
    final valueCtrl = TextEditingController();

    final metricLabels = {
      'attendance_rate': 'Attendance Rate (%)',
      'delivery_count': 'Monthly Deliveries',
      'incident_free_days': 'Incident-Free Days',
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set Target',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Text(
                staffName,
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
          content: SizedBox(
            width: 360,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: metric,
                    decoration: _inputDec('Metric'),
                    items: metricLabels.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => metric = v ?? metric),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: valueCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDec('Target Value'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null || double.parse(v) < 0) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final authProfile = ref.read(authProvider).profile;
                      if (authProfile == null) return;
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() => _isSaving = true);
                      try {
                        await ref.read(performanceRepositoryProvider).setTarget(
                              profileId: profileId,
                              metric: metric,
                              targetValue: double.parse(valueCtrl.text),
                              period: 'monthly',
                              createdById: authProfile.id,
                            );
                        ref.invalidate(staffTargetsProvider(profileId));
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Target set for $staffName'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Save Target',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(
    BuildContext ctx,
    StateSetter setDialogState, {
    required String label,
    required IconData icon,
    required String value,
    required String current,
    required Color color,
    required Function(String) onSelect,
  }) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => setDialogState(() => onSelect(value)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDec(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}
