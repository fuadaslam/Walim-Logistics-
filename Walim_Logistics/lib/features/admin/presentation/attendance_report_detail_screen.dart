import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/supervisor/presentation/supervisor_notifier.dart';

final reportDetailsProvider = FutureProvider.family.autoDispose<Map<String, dynamic>, String>((ref, reportId) async {
  final supabase = Supabase.instance.client;
  
  // Fetch report items (marked attendance)
  final itemsRes = await supabase
      .from('attendance_report_items')
      .select('*, profiles!rider_id(id, full_name, phone_number)')
      .eq('attendance_report_id', reportId)
      .order('marked_at');
      
  // Fetch platform uploads (images, PDFs etc)
  final uploadsRes = await supabase
      .from('platform_report_uploads')
      .select('*, profiles!supervisor_id(full_name)')
      .eq('attendance_report_id', reportId);
      
  // Fetch validation flags
  final flagsRes = await supabase
      .from('validation_flags')
      .select()
      .eq('attendance_report_id', reportId);
      
  // Fetch full report detail in case we want to reload it
  final reportRes = await supabase
      .from('attendance_reports')
      .select('*, profiles!supervisor_id(full_name), groups(name), platforms(name)')
      .eq('id', reportId)
      .single();

  return {
    'items': List<Map<String, dynamic>>.from(itemsRes as List),
    'uploads': List<Map<String, dynamic>>.from(uploadsRes as List),
    'flags': List<Map<String, dynamic>>.from(flagsRes as List),
    'report': Map<String, dynamic>.from(reportRes),
  };
});

class AttendanceReportDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> report;

  const AttendanceReportDetailScreen({super.key, required this.report});

  @override
  ConsumerState<AttendanceReportDetailScreen> createState() => _AttendanceReportDetailScreenState();
}

class _AttendanceReportDetailScreenState extends ConsumerState<AttendanceReportDetailScreen> {
  bool _isValidating = false;
  late Map<String, dynamic> _currentReport;

  @override
  void initState() {
    super.initState();
    _currentReport = widget.report;
  }

  Future<void> _runValidation() async {
    setState(() => _isValidating = true);
    try {
      final repo = ref.read(supervisorRepositoryProvider);
      await repo.runValidation(_currentReport['id'] as String);
      
      // Refresh details
      ref.invalidate(reportDetailsProvider(_currentReport['id'] as String));
      final details = await ref.read(reportDetailsProvider(_currentReport['id'] as String).future);
      
      setState(() {
        _currentReport = details['report'] as Map<String, dynamic>;
        _isValidating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Validation completed successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      setState(() => _isValidating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validation failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(String newStatus, {String? notes}) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('attendance_reports').update({
        'status': newStatus,
        if (notes != null) 'correction_notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _currentReport['id']);

      ref.invalidate(reportDetailsProvider(_currentReport['id'] as String));
      final details = await ref.read(reportDetailsProvider(_currentReport['id'] as String).future);
      
      setState(() {
        _currentReport = details['report'] as Map<String, dynamic>;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report status updated to $newStatus'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showCorrectionDialog() {
    final controller = TextEditingController(text: _currentReport['correction_notes'] as String? ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Request Correction',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Specify what needs to be corrected by the supervisor:',
              style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              style: GoogleFonts.outfit(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Describe issues with attendance, manual rider, or missing files...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus('NEEDS_CORRECTION', notes: controller.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: Text('Submit Request', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(reportDetailsProvider(_currentReport['id'] as String));
    final isDesktop = MediaQuery.of(context).size.width > 1000;
    
    return DashboardScaffold(
      title: 'SHIFT REPORT DETAILS',
      subtitle: 'Review SOS, EOS details, marked riders, validation flags, and platform files',
      showBackButton: true,
      children: [
        detailsAsync.when(
          data: (data) {
            final items = data['items'] as List<Map<String, dynamic>>;
            final uploads = data['uploads'] as List<Map<String, dynamic>>;
            final flags = data['flags'] as List<Map<String, dynamic>>;
            
            final presentCount = items.where((i) => i['attendance_status'] == 'present').length;
            final absentCount = items.where((i) => i['attendance_status'] == 'absent').length;
            final manualCount = items.where((i) => i['is_manual_addition'] == true).length;
            final leaveCount = items.where((i) => ['leave', 'suspended'].contains(i['attendance_status'])).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderPanel(presentCount, absentCount, leaveCount, manualCount),
                const SizedBox(height: 24),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildRiderAttendanceList(items),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildValidationFlagsSection(flags),
                            const SizedBox(height: 24),
                            _buildHandoverEOSSection(uploads),
                            const SizedBox(height: 24),
                            _buildAdminActionsPanel(),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildRiderAttendanceList(items),
                      const SizedBox(height: 24),
                      _buildValidationFlagsSection(flags),
                      const SizedBox(height: 24),
                      _buildHandoverEOSSection(uploads),
                      const SizedBox(height: 24),
                      _buildAdminActionsPanel(),
                    ],
                  ),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(80.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Text(
                'Failed to load details: $err',
                style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderPanel(int present, int absent, int leave, int manual) {
    final sosTime = _currentReport['sos_submitted_at'] != null
        ? DateFormat('HH:mm').format(DateTime.parse(_currentReport['sos_submitted_at']).toLocal())
        : '---';
    final eosTime = _currentReport['eos_submitted_at'] != null
        ? DateFormat('HH:mm').format(DateTime.parse(_currentReport['eos_submitted_at']).toLocal())
        : '---';
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _currentReport['groups']?['name'] ?? 'N/A',
                          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                        _buildStatusBadge(_currentReport['status']),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildHeaderMeta(Icons.storefront_rounded, _currentReport['platforms']?['name'] ?? 'N/A'),
                        const SizedBox(width: 24),
                        _buildHeaderMeta(Icons.person_outline_rounded, _currentReport['profiles']?['full_name'] ?? 'N/A'),
                        const SizedBox(width: 24),
                        _buildHeaderMeta(Icons.calendar_today_rounded, DateFormat('MMMM dd, yyyy').format(DateTime.parse(_currentReport['report_date']))),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      _buildTimeBadge('SOS Time', sosTime, const Color(0xFF3B82F6)),
                      const SizedBox(width: 12),
                      _buildTimeBadge('EOS Time', eosTime, const Color(0xFF6366F1)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatBox('Total Marked', present + absent + leave, const Color(0xFF4B5563)),
              _buildStatBox('Present Riders', present, const Color(0xFF10B981)),
              _buildStatBox('Absent Riders', absent, const Color(0xFFEF4444)),
              _buildStatBox('On Leave / Susp.', leave, const Color(0xFFF59E0B)),
              _buildStatBox('Manual Additions', manual, const Color(0xFF8B5CF6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMeta(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTimeBadge(String title, String time, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.access_time_filled_rounded, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                time,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildRiderAttendanceList(List<Map<String, dynamic>> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Rider Attendance details',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Text(
                  'No riders marked for this shift report.',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final item = items[index];
                final status = item['attendance_status'] as String? ?? 'present';
                final isManual = item['is_manual_addition'] == true;
                final isCarryOver = item['is_carry_over'] == true;

                Color badgeColor;
                IconData badgeIcon;
                switch (status) {
                  case 'present':
                    badgeColor = const Color(0xFF10B981);
                    badgeIcon = Icons.check_circle_outline_rounded;
                    break;
                  case 'absent':
                    badgeColor = const Color(0xFFEF4444);
                    badgeIcon = Icons.cancel_outlined;
                    break;
                  case 'leave':
                    badgeColor = const Color(0xFFF59E0B);
                    badgeIcon = Icons.hotel_rounded;
                    break;
                  case 'suspended':
                    badgeColor = const Color(0xFF6B7280);
                    badgeIcon = Icons.gavel_rounded;
                    break;
                  default:
                    badgeColor = const Color(0xFF6B7280);
                    badgeIcon = Icons.help_outline_rounded;
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: badgeColor.withValues(alpha: 0.1),
                      foregroundColor: badgeColor,
                      child: Icon(badgeIcon, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item['rider_name'] ?? 'Unknown Rider',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              if (isManual) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Manual Addition',
                                    style: GoogleFonts.outfit(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                              if (isCarryOver) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Carry Over',
                                    style: GoogleFonts.outfit(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Iqama / ID: ${item['rider_iqama'] ?? 'N/A'}',
                            style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          if (status == 'absent' && item['absence_reason'] != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.1)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Absence Reason: ${item['absence_reason']}',
                                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFFEF4444), fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (isManual && item['manual_addition_reason'] != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, size: 14, color: Colors.orange),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Addition Reason: ${item['manual_addition_reason']}',
                                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildValidationFlagsSection(List<Map<String, dynamic>> flags) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.report_problem_rounded, color: const Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              Text(
                'Validation Flags',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _isValidating ? null : _runValidation,
                icon: _isValidating
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.playlist_add_check_rounded, size: 16),
                label: Text('Run Diagnostics', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (flags.isEmpty)
            Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No validation issues or flags found. Perfect compliance!',
                    style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: flags.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final flag = flags[index];
                final type = flag['flag_type'] as String? ?? 'GENERAL';
                
                Color iconColor = const Color(0xFFEF4444);
                if (type == 'MANUAL_ADDED_RIDER') {
                  iconColor = Colors.orange;
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 20, color: iconColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.replaceAll('_', ' '),
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: iconColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            flag['description'] ?? 'Validation Warning',
                            style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHandoverEOSSection(List<Map<String, dynamic>> uploads) {
    final notes = _currentReport['handover_notes'] as String? ?? '';
    final correction = _currentReport['correction_notes'] as String? ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_turned_in_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'EOS & Handover Details',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (notes.isNotEmpty) ...[
            Text(
              'Handover Notes:',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
              ),
              child: Text(
                notes,
                style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textPrimary, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (correction.isNotEmpty) ...[
            Text(
              'Correction Feedback / Notes:',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFFEF4444)),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.1)),
              ),
              child: Text(
                correction,
                style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFFEF4444), fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Uploaded Platform Reports:',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          if (uploads.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'No report uploads available.',
                style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
              ),
            )
          else
            Column(
              children: uploads.map((upload) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        upload['file_type'] == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
                        color: upload['file_type'] == 'pdf' ? const Color(0xFFEF4444) : Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              upload['file_name'] ?? 'File Upload',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Uploaded by ${upload['profiles']?['full_name'] ?? 'Supervisor'}',
                              style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.download_rounded, color: AppColors.primary),
                        onPressed: () {
                          // In a real app, open or download fileUrl
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Downloading ${upload['file_name']}...')),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminActionsPanel() {
    final status = _currentReport['status'] as String? ?? 'DRAFT';
    final isApproved = status == 'APPROVED';
    final isCorrection = status == 'NEEDS_CORRECTION';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Review and Compliance Actions',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isApproved
                      ? null
                      : () => _updateStatus('APPROVED'),
                  icon: const Icon(Icons.verified_user_rounded),
                  label: Text('Approve Report', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isCorrection
                      ? null
                      : _showCorrectionDialog,
                  icon: const Icon(Icons.error_outline_rounded),
                  label: Text('Request Correction', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: BorderSide(color: isCorrection ? const Color(0xFFEF4444).withValues(alpha: 0.2) : const Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'APPROVED':
        icon = Icons.verified_rounded;
        color = const Color(0xFF10B981); // Emerald Green
        break;
      case 'SOS_SUBMITTED':
        icon = Icons.login_rounded;
        color = const Color(0xFF3B82F6); // Blue
        break;
      case 'EOS_SUBMITTED':
        icon = Icons.logout_rounded;
        color = const Color(0xFF6366F1); // Indigo
        break;
      case 'NEEDS_CORRECTION':
        icon = Icons.error_outline_rounded;
        color = const Color(0xFFEF4444); // Red
        break;
      default:
        icon = Icons.help_outline_rounded;
        color = const Color(0xFF64748B); // Slate Grey
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            status.replaceAll('_', ' '),
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
