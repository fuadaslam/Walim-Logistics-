import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'leave_request_notifier.dart';

class LeaveRequestScreen extends ConsumerStatefulWidget {
  final bool showScaffold;
  const LeaveRequestScreen({super.key, this.showScaffold = true});

  @override
  ConsumerState<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends ConsumerState<LeaveRequestScreen> {
  String? _selectedType;
  String? _handoverReason;
  DateTime? _fromDate;
  DateTime? _toDate;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_toDate != null && _toDate!.isBefore(picked)) {
            _toDate = picked;
          }
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedType == null || _fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await ref.read(leaveRequestProvider.notifier).submit(
          type: _selectedType!,
          startDate: _fromDate!,
          endDate: _toDate!,
          reason: _reasonController.text,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request submitted successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _selectedType = null;
        _fromDate = null;
        _toDate = null;
        _reasonController.clear();
      });
    } else {
      final error = ref.read(leaveRequestProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to submit request'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaveRequestProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    final children = [
      _buildNewRequestForm(isMobile, state.isSubmitting),
      SizedBox(height: isMobile ? 32 : 48),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('My Requests',
              style: GoogleFonts.outfit(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w600)),
          TextButton.icon(
            onPressed: () => ref.read(leaveRequestProvider.notifier).refresh(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('Refresh',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _buildRequestList(isMobile, state),
    ];

    if (!widget.showScaffold) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );
    }

    return DashboardScaffold(
      title: 'MY REQUESTS',
      subtitle: 'Plan your time off and track approval status',
      showBackButton: true,
      children: children,
    );
  }

  Widget _buildNewRequestForm(bool isMobile, bool isSubmitting) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(isMobile ? 24 : 32),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.divider.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 18 : 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_moderator_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('New Request',
                          style: GoogleFonts.outfit(
                              fontSize: 17, fontWeight: FontWeight.w600)),
                      Text('Submit a new absence or leave request',
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(isMobile ? 18 : 24),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  style: GoogleFonts.outfit(
                      color: theme.textTheme.bodyLarge?.color, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Type of Request',
                    prefixIcon:
                        Icon(Icons.category_outlined, size: 20),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  items: [
                    'Leave',
                    'Weekly Off',
                    'Emergency',
                    'Asset Handover',
                    'Sick Leave',
                    'Annual Leave',
                  ]
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedType = val),
                ),
                if (_selectedType == 'Asset Handover') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _handoverReason,
                    style: GoogleFonts.outfit(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 15),
                    decoration: const InputDecoration(
                      labelText: 'Reason for Handover',
                      prefixIcon: Icon(Icons.info_outline, size: 20),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    items: [
                      'Resignation',
                      'Annual Leave',
                      'Termination',
                      'Other'
                    ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _handoverReason = val),
                  ),
                ],
                const SizedBox(height: 16),
                if (isMobile) ...[
                  _buildDateField('From Date', _fromDate, () => _pickDate(isFrom: true)),
                  const SizedBox(height: 16),
                  _buildDateField('To Date', _toDate, () => _pickDate(isFrom: false)),
                ] else
                  Row(
                    children: [
                      Expanded(
                          child: _buildDateField('From Date', _fromDate,
                              () => _pickDate(isFrom: true))),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildDateField('To Date', _toDate,
                              () => _pickDate(isFrom: false))),
                    ],
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 3,
                  style: GoogleFonts.outfit(fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Detailed Reason / Notes',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child:
                          Icon(Icons.description_outlined, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_rounded, size: 18),
                              const SizedBox(width: 12),
                              Text(
                                'SUBMIT REQUEST',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
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

  Widget _buildDateField(
      String label, DateTime? date, VoidCallback onTap) {
    final formatted =
        date != null ? DateFormat('dd MMM yyyy').format(date) : '';
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: formatted),
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            const Icon(Icons.calendar_today_rounded, size: 18),
        suffixIcon: date != null
            ? IconButton(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: () => setState(() {
                  if (label.contains('From')) {
                    _fromDate = null;
                  } else {
                    _toDate = null;
                  }
                }),
              )
            : null,
      ),
    );
  }

  Widget _buildRequestList(bool isMobile, LeaveRequestState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.event_available_rounded,
                  size: 48,
                  color: AppColors.textSecondary.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text('No requests yet',
                  style:
                      GoogleFonts.outfit(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.requests.length,
      itemBuilder: (context, index) {
        final r = state.requests[index];
        final status = r['status'] as String? ?? 'Pending';
        final color = status == 'Approved'
            ? Colors.green
            : status == 'Rejected'
                ? Colors.red
                : Colors.orange;
        final fromStr = r['start_date'] != null
            ? DateFormat('dd MMM').format(DateTime.parse(r['start_date']))
            : '—';
        final toStr = r['end_date'] != null
            ? DateFormat('dd MMM').format(DateTime.parse(r['end_date']))
            : '—';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Theme.of(context)
                    .dividerColor
                    .withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.all(isMobile ? 16 : 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.event_note_outlined,
                                color: color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r['type'] as String? ?? 'Request',
                                    style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  _buildStatusBadge(status, color),
                                ],
                              ),
                            ),
                            const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: AppColors.textSecondary),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(
                                      Icons.calendar_month_outlined,
                                      size: 14,
                                      color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$fromStr - $toStr',
                                    style: GoogleFonts.outfit(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            if (r['reason'] != null)
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.end,
                                  children: [
                                    const Icon(Icons.notes_rounded,
                                        size: 14,
                                        color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        r['reason'] as String,
                                        style: GoogleFonts.outfit(
                                            color:
                                                AppColors.textSecondary,
                                            fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(status,
          style: GoogleFonts.outfit(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11)),
    );
  }
}
