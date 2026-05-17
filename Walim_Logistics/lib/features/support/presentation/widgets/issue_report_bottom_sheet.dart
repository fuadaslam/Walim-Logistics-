import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/support/presentation/support_ticket_notifier.dart';

class IssueReportBottomSheet extends ConsumerStatefulWidget {
  final String? initialItem;
  const IssueReportBottomSheet({super.key, this.initialItem});

  static Future<void> show(BuildContext context, {String? item}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IssueReportBottomSheet(initialItem: item),
    );
  }

  @override
  ConsumerState<IssueReportBottomSheet> createState() => _IssueReportBottomSheetState();
}

class _IssueReportBottomSheetState extends ConsumerState<IssueReportBottomSheet> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedPriority = 'normal';
  String _selectedType = 'other';

  final _priorities = [
    {'value': 'low', 'label': 'Low'},
    {'value': 'normal', 'label': 'Medium'},
    {'value': 'high', 'label': 'High'},
  ];

  final _types = [
    {'value': 'accident', 'label': 'Accident'},
    {'value': 'fuel_issue', 'label': 'Fuel Issue'},
    {'value': 'app_glitch', 'label': 'App Glitch'},
    {'value': 'vehicle_issue', 'label': 'Vehicle Issue'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notifier = ref.read(supportTicketProvider.notifier);
    final isSubmitting = ref.watch(supportTicketProvider).isSubmitting;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.report_problem_rounded, color: AppColors.error),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Report Issue', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
                            Text(
                              widget.initialItem != null
                                  ? 'Reporting issue for: ${widget.initialItem}'
                                  : 'Tell us what is wrong',
                              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Issue Type', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _types.map((t) {
                      final isSelected = _selectedType == t['value'];
                      return InkWell(
                        onTap: () => setState(() => _selectedType = t['value']!),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : theme.dividerColor.withValues(alpha: 0.5),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            t['label']!,
                            style: GoogleFonts.outfit(
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text('Subject', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _subjectController,
                    style: GoogleFonts.outfit(),
                    decoration: InputDecoration(
                      hintText: 'Brief title for the issue...',
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Priority Level', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 12),
                  Row(
                    children: _priorities.map((p) {
                      final isSelected = _selectedPriority == p['value'];
                      final color = p['value'] == 'high'
                          ? AppColors.error
                          : (p['value'] == 'normal' ? Colors.orange : Colors.blue);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => setState(() => _selectedPriority = p['value']!),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? color : theme.dividerColor.withValues(alpha: 0.5),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  p['label']!,
                                  style: GoogleFonts.outfit(
                                    color: isSelected ? color : AppColors.textSecondary,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text('Description', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: GoogleFonts.outfit(),
                    decoration: InputDecoration(
                      hintText: 'Describe the issue in detail...',
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final subject = _subjectController.text.trim();
                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(context);
                            if (subject.isEmpty) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Please enter a subject', style: GoogleFonts.outfit()),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                              return;
                            }
                            final success = await notifier.createTicket(
                              subject: subject,
                              type: _selectedType,
                              priority: _selectedPriority,
                              description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
                            );
                            if (!mounted) return;
                            if (success) {
                              nav.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                      const SizedBox(width: 12),
                                      Text('Support ticket created successfully', style: GoogleFonts.outfit()),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            } else {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Failed to create ticket. Please try again.', style: GoogleFonts.outfit()),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      shadowColor: AppColors.primary.withValues(alpha: 0.2),
                    ),
                    child: isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('SUBMIT REPORT',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
