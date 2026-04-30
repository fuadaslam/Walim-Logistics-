import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class LeaveRequestScreen extends StatefulWidget {
  final bool showScaffold;
  const LeaveRequestScreen({super.key, this.showScaffold = true});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  String? _selectedType;
  String? _handoverReason;
  
  final List<Map<String, dynamic>> _requests = [
    {'type': 'Weekly Off', 'from': '02 May', 'to': '02 May', 'status': 'Approved', 'reason': 'Regular break'},
    {'type': 'Sick Leave', 'from': '28 Apr', 'to': '30 Apr', 'status': 'Pending', 'reason': 'High Fever'},
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    final children = [
      _buildNewRequestForm(isMobile),
      SizedBox(height: isMobile ? 32 : 48),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('My Requests', style: GoogleFonts.outfit(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.w600)),
          TextButton.icon(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            icon: const Icon(Icons.filter_list_rounded, size: 18),
            label: Text('Filter', style: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _buildRequestList(isMobile),
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

  Widget _buildNewRequestForm(bool isMobile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(isMobile ? 24 : 32),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.divider.withValues(alpha: 0.8)),
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
                  child: const Icon(Icons.add_moderator_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('New Request', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w600)),
                      Text('Submit a new absence or leave request', 
                        style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                  style: GoogleFonts.outfit(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Type of Request',
                    prefixIcon: Icon(Icons.category_outlined, size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  items: ['Leave', 'Weekly Off', 'Emergency', 'Asset Handover']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedType = val),
                ),
                if (_selectedType == 'Asset Handover') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _handoverReason,
                    style: GoogleFonts.outfit(color: theme.textTheme.bodyLarge?.color, fontSize: 15),
                    decoration: const InputDecoration(
                      labelText: 'Reason for Handover',
                      prefixIcon: Icon(Icons.info_outline, size: 20),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    items: ['Resignation', 'Annual Leave', 'Termination', 'Other']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => _handoverReason = val),
                  ),
                ],
                const SizedBox(height: 16),
                if (isMobile) ...[
                  TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'From Date',
                      prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                    ),
                    onTap: () {}, // TODO: Implement date picker
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'To Date',
                      prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                    ),
                    onTap: () {}, // TODO: Implement date picker
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'From Date',
                            prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'To Date',
                            prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  maxLines: 3,
                  style: GoogleFonts.outfit(fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Detailed Reason / Notes',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.description_outlined, size: 20),
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
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 18),
                        const SizedBox(width: 12),
                        Text(
                          'Submit Request'.toUpperCase(),
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

  Widget _buildRequestList(bool isMobile) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final r = _requests[index];
        final status = r['status'];
        final color = status == 'Approved' ? Colors.green : (status == 'Pending' ? Colors.orange : Colors.red);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
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
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                r['type'] == 'Weekly Off' ? Icons.event_repeat_rounded : Icons.sick_outlined,
                                color: color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r['type'],
                                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  _buildStatusBadge(status, color),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${r['from']} - ${r['to']}',
                                    style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Icon(Icons.notes_rounded, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      r['reason'],
                                      style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status,
        style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}

