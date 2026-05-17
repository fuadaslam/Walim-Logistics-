import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/support/presentation/support_ticket_notifier.dart';
import 'package:walim_logistics/features/support/presentation/widgets/issue_report_bottom_sheet.dart';
import 'package:walim_logistics/features/support/presentation/ticket_detail_screen.dart';

class SupportTicketsScreen extends ConsumerWidget {
  final bool showScaffold;
  const SupportTicketsScreen({super.key, this.showScaffold = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(supportTicketProvider);
    final tickets = state.tickets;

    final children = [
      _buildHeader(context, ref),
      const SizedBox(height: 32),
      _buildStatsRow(context, tickets),
      const SizedBox(height: 32),
      _FilterTabs(tickets: tickets),
    ];

    if (!showScaffold) {
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

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final button = ElevatedButton.icon(
      onPressed: () async {
        await IssueReportBottomSheet.show(context);
        ref.read(supportTicketProvider.notifier).refresh();
      },
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text('New Ticket',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(isMobile ? double.infinity : 150, 48),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: AppColors.primary.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (isMobile) return button;
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [button]);
  }

  Widget _buildStatsRow(BuildContext context, List<Map<String, dynamic>> tickets) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final cards = [
      _StatCard(label: isMobile ? 'Total' : 'Total Tickets', value: tickets.length.toString(), icon: Icons.confirmation_number_rounded, color: AppColors.accent, width: isMobile ? 150 : null),
      _StatCard(label: 'Active', value: tickets.where((t) => t['status'] != 'resolved' && t['status'] != 'closed').length.toString(), icon: Icons.pending_actions_rounded, color: Colors.orange, width: isMobile ? 150 : null),
      _StatCard(label: 'Resolved', value: tickets.where((t) => t['status'] == 'resolved').length.toString(), icon: Icons.check_circle_rounded, color: Colors.green, width: isMobile ? 160 : null),
    ];

    if (isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: [
            cards[0],
            const SizedBox(width: 12),
            cards[1],
            const SizedBox(width: 12),
            cards[2],
          ],
        ),
      );
    }
    return Row(children: [
      Expanded(child: cards[0]),
      const SizedBox(width: 16),
      Expanded(child: cards[1]),
      const SizedBox(width: 16),
      Expanded(child: cards[2]),
    ]);
  }
}

class _FilterTabs extends StatefulWidget {
  final List<Map<String, dynamic>> tickets;
  const _FilterTabs({required this.tickets});

  @override
  State<_FilterTabs> createState() => _FilterTabsState();
}

class _FilterTabsState extends State<_FilterTabs> {
  String _selected = 'All';
  final _filters = ['All', 'open', 'in_progress', 'resolved', 'closed'];
  final _labels = {'All': 'All', 'open': 'Open', 'in_progress': 'In Progress', 'resolved': 'Resolved', 'closed': 'Closed'};

  List<Map<String, dynamic>> get _filtered {
    if (_selected == 'All') return widget.tickets;
    return widget.tickets.where((t) => t['status'] == _selected).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filters.map((f) {
              final isSelected = _selected == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _selected = f),
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
                      _labels[f]!,
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
        ),
        const SizedBox(height: 24),
        if (_filtered.isEmpty)
          _buildEmptyState(context)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filtered.length,
            itemBuilder: (context, i) => _TicketCard(ticket: _filtered[i]),
          ),
      ],
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
              child: Icon(Icons.assignment_turned_in_rounded,
                  size: 80, color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            const SizedBox(height: 24),
            Text('No tickets found',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Everything looks good! No ${_selected == 'All' ? '' : _labels[_selected]!.toLowerCase()} tickets.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final priority = ticket['priority'] ?? 'normal';
    final status = ticket['status'] ?? 'open';
    final priorityColor = _priorityColor(priority);
    final statusColor = _statusColor(status);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: ticket)),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4, color: priorityColor),
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
                              _PriorityTag(priority: priority, color: priorityColor),
                              const SizedBox(width: 10),
                              Text(
                                'ID: ${ticket['id'].toString().substring(0, 8).toUpperCase()}',
                                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              Text(
                                _formatDate(ticket['created_at']),
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
                                            ticket['subject'] ?? '',
                                            style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: isMobile ? 16 : 18),
                                          ),
                                        ),
                                        if (isMobile) ...[
                                          const SizedBox(width: 8),
                                          _StatusChip(status: status, color: statusColor),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      ticket['description'] ?? 'No description provided.',
                                      style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (!isMobile) ...[
                                const SizedBox(width: 12),
                                _StatusChip(status: status, color: statusColor),
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
                          InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: ticket)),
                            ),
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
                                  const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    isMobile ? 'Conversation' : 'View Conversation',
                                    style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
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

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return '${dt.day} ${_month(dt.month)}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  String _month(int m) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];

  Color _priorityColor(String p) {
    switch (p) {
      case 'high':
      case 'urgent': return AppColors.error;
      case 'normal': return Colors.orange;
      default: return Colors.blue;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'open': return AppColors.primary;
      case 'in_progress': return Colors.orange;
      case 'resolved': return Colors.green;
      case 'closed': return AppColors.textSecondary;
      default: return AppColors.textSecondary;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double? width;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color, this.width});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      width: width,
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
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
}

class _PriorityTag extends StatelessWidget {
  final String priority;
  final Color color;
  const _PriorityTag({required this.priority, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(priority.toUpperCase(), style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusChip({required this.status, required this.color});

  String get _label => status.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Text(_label, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
