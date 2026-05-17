import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class TicketDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ticket;
  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'isMe': false,
      'message': 'Hello! We have received your report regarding the accident. Can you please confirm if you have already contacted the insurance company?',
      'time': '10:35 AM',
      'sender': 'Support Agent',
    },
    {
      'isMe': true,
      'message': 'Yes, I called them immediately after the incident. They said an inspector will be assigned soon.',
      'time': '10:42 AM',
      'sender': 'You',
    },
    {
      'isMe': false,
      'message': 'Perfect. Please upload the incident photos here if you have them. We need them to process the internal report.',
      'time': '10:45 AM',
      'sender': 'Support Agent',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'TICKET DETAILS',
      subtitle: 'Track and discuss your issue',
      showBackButton: true,
      children: [
        _buildTicketSummary(context),
        const SizedBox(height: 24),
        Text(
          'Conversation',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        _buildChatSection(context),
        const SizedBox(height: 16),
        _buildMessageInput(context),
      ],
    );
  }

  Widget _buildTicketSummary(BuildContext context) {
    final t = widget.ticket;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildPriorityTag(t['priority']),
              const SizedBox(width: 12),
              Text(
                'ID: ${t['id']}',
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              _buildStatusChip(t['status']),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            t['subject'],
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            t['description'] ?? 'No description provided.',
            style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Created on ${t['date']}',
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatSection(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = msg['isMe'] == true;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.support_agent_rounded, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isMe 
                            ? AppColors.primary 
                            : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08)),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 16),
                        ),
                      ),
                      child: Text(
                        msg['message'],
                        style: GoogleFonts.outfit(
                          color: isMe ? Colors.white : null,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${msg['sender']} • ${msg['time']}',
                      style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                  child: const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.accent),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.attach_file_rounded, color: AppColors.textSecondary),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: GoogleFonts.outfit(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () {
                if (_messageController.text.trim().isNotEmpty) {
                  setState(() {
                    _messages.add({
                      'isMe': true,
                      'message': _messageController.text.trim(),
                      'time': 'Just now',
                      'sender': 'You',
                    });
                    _messageController.clear();
                  });
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityTag(String priority) {
    Color color = AppColors.primary;
    if (priority == 'High') color = AppColors.error;
    if (priority == 'Medium') color = Colors.orange;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = AppColors.primary;
    if (status == 'In Progress') color = Colors.orange;
    if (status == 'Resolved') color = Colors.green;
    
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
