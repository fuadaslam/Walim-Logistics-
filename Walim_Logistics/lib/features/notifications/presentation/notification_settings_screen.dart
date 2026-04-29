import 'package:flutter/material.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _shiftReminders = true;
  bool _codWarnings = true;
  bool _incidentAlerts = true;
  bool _documentExpiry = true;

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'WHATSAPP ALERTS',
      subtitle: 'Configure automated staff notifications',
      showBackButton: true,
      children: [
        const Text(
          'Automated Notifications',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Configure which alerts are sent to staff via WhatsApp.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 32),
        
        _buildNotificationSwitch(
          title: 'Shift Reminders',
          subtitle: 'Sent 1 hour before shift starts',
          value: _shiftReminders,
          onChanged: (val) => setState(() => _shiftReminders = val),
        ),
        _buildNotificationSwitch(
          title: 'COD Discrepancy Warnings',
          subtitle: 'Alerts riders when cash doesn\'t match',
          value: _codWarnings,
          onChanged: (val) => setState(() => _codWarnings = val),
        ),
        _buildNotificationSwitch(
          title: 'Incident Updates',
          subtitle: 'Notify riders when supervisor approves incident',
          value: _incidentAlerts,
          onChanged: (val) => setState(() => _incidentAlerts = val),
        ),
        _buildNotificationSwitch(
          title: 'Document Expiry',
          subtitle: 'Reminders for Iqama/License renewal',
          value: _documentExpiry,
          onChanged: (val) => setState(() => _documentExpiry = val),
        ),
        
        const SizedBox(height: 48),
        const Divider(color: AppColors.divider),
        const SizedBox(height: 24),
        const Text('API Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ListTile(
          tileColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: const Icon(Icons.api, color: AppColors.primaryLight),
          title: const Text('WhatsApp Gateway'),
          subtitle: const Text('Twilio (Connected)'),
          trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ),
      ],
    );
  }

  Widget _buildNotificationSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.accent,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
    );
  }
}
