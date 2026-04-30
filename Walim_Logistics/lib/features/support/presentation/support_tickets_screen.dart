import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/support/presentation/widgets/issue_report_bottom_sheet.dart';
import 'package:walim_logistics/features/support/presentation/ticket_detail_screen.dart';

class SupportTicketsScreen extends StatefulWidget {
  final bool showScaffold;
  const SupportTicketsScreen({super.key, this.showScaffold = true});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Open', 'In Progress', 'Resolved'];

  final List<Map<String, dynamic>> _tickets = [
    {'id': 'TKT-1001', 'subject': 'Accident Reporting', 'status': 'Open', 'date': '27 Apr, 10:30 AM', 'priority': 'High', 'description': 'Minor collision during delivery route. No injuries reported.'},
    {'id': 'TKT-1002', 'subject': 'Fuel Card Not Working', 'status': 'In Progress', 'date': '26 Apr, 02:15 PM', 'priority': 'Medium', 'description': 'The assigned fuel card is being declined at all ENOC stations.'},
    {'id': 'TKT-1003', 'subject': 'App Glitch - GPS Issue', 'status': 'Resolved', 'date': '25 Apr, 09:00 AM', 'priority': 'Low', 'description': 'The map stops tracking after 10 minutes of usage.'},
  ];

  List<Map<String, dynamic>> get _filteredTickets {
    if (_selectedFilter == 'All') return _tickets;
    return _tickets.where((t) => t['status'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final children = [
      _buildHeader(context),
      const SizedBox(height: 32),
      _buildStatsRow(context),
      const SizedBox(height: 32),
      _buildFilterTabs(context),
      const SizedBox(height: 24),
      if (_filteredTickets.isEmpty)
        _buildEmptyState(context)
      else
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredTickets.length,
          itemBuilder: (context, index) {
            return _buildTicketCard(context, _filteredTickets[index]);
          },
        ),
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
      title: 'SUPPORT CENTER',
      subtitle: 'Manage your support requests and issues',
      showBackButton: true,
      children: children,
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: () => IssueReportBottomSheet.show(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('New Ticket', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 46),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: () => IssueReportBottomSheet.show(context),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text('New Ticket', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(150, 48),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: AppColors.primary.withValues(alpha: 0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    if (isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: [
            _buildStatCard(context, 'Total', _tickets.length.toString(), Icons.confirmation_number_rounded, AppColors.accent, width: 150),
            const SizedBox(width: 12),
            _buildStatCard(context, 'Active', _tickets.where((t) => t['status'] != 'Resolved').length.toString(), Icons.pending_actions_rounded, Colors.orange, width: 150),
            const SizedBox(width: 12),
            _buildStatCard(context, 'Resolved', _tickets.where((t) => t['status'] == 'Resolved').length.toString(), Icons.check_circle_rounded, Colors.green, width: 160),
          ],
        ),
      );
    }

    return Row(
      children: [
        _buildStatCard(context, 'Total Tickets', _tickets.length.toString(), Icons.confirmation_number_rounded, AppColors.accent),
        const SizedBox(width: 16),
        _buildStatCard(context, 'Active', _tickets.where((t) => t['status'] != 'Resolved').length.toString(), Icons.pending_actions_rounded, Colors.orange),
        const SizedBox(width: 16),
        _buildStatCard(context, 'Resolved', _tickets.where((t) => t['status'] == 'Resolved').length.toString(), Icons.check_circle_rounded, Colors.green),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color, {double? width}) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      width: width,
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: isMobile ? 18 : 22),
          ),
          SizedBox(width: isMobile ? 10 : 14),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: GoogleFonts.outfit(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w600)),
                Text(label, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: isMobile ? 10 : 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          bool isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedFilter = filter),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.outfit(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, Map<String, dynamic> t) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final priorityColor = _getPriorityColor(t['priority']);
    final statusColor = _getStatusColor(t['status']);
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TicketDetailScreen(ticket: t)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                color: priorityColor,
              ),
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(isMobile ? 14 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildPriorityTag(t['priority'], priorityColor),
                              const SizedBox(width: 10),
                              Text(
                                'ID: ${t['id']}', 
                                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              Text(
                                t['date'], 
                                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 10),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMobile) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 24),
                                ),
                                const SizedBox(width: 16),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            t['subject'], 
                                            style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: isMobile ? 16 : 18),
                                          ),
                                        ),
                                        if (isMobile) ...[
                                          const SizedBox(width: 8),
                                          _buildStatusChip(t['status'], statusColor),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      t['description'] ?? 'No description provided.',
                                      style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (!isMobile) ...[
                                const SizedBox(width: 12),
                                _buildStatusChip(t['status'], statusColor),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 8),
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white.withValues(alpha: 0.01) 
                          : Colors.grey.withValues(alpha: 0.02),
                      child: Row(
                        children: [
                          _buildActionChip(
                            context, 
                            isMobile ? 'Conversation' : 'View Conversation', 
                            Icons.chat_bubble_outline_rounded,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => TicketDetailScreen(ticket: t)),
                              );
                            },
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 18),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionChip(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label, 
              style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.assignment_turned_in_rounded, size: 80, color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            const SizedBox(height: 24),
            Text(
              'No tickets found',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Everything looks good! You don\'t have any\n${_selectedFilter.toLowerCase()} support tickets.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High': return AppColors.error;
      case 'Medium': return Colors.orange;
      default: return Colors.blue;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open': return AppColors.primary;
      case 'In Progress': return Colors.orange;
      case 'Resolved': return Colors.green;
      default: return AppColors.textSecondary;
    }
  }

  Widget _buildPriorityTag(String priority, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            priority.toUpperCase(), 
            style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Text(
        status, 
        style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

