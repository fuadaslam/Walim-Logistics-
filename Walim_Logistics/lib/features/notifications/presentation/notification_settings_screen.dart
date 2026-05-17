import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _shiftReminders = true;
  bool _incidentAlerts = true;
  bool _documentExpiry = true;
  bool _loading = true;

  static const _keyShift = 'notif_shift_reminders';
  static const _keyIncident = 'notif_incident_alerts';
  static const _keyDocument = 'notif_document_expiry';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shiftReminders = prefs.getBool(_keyShift) ?? true;
      _incidentAlerts = prefs.getBool(_keyIncident) ?? true;
      _documentExpiry = prefs.getBool(_keyDocument) ?? true;
      _loading = false;
    });
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'WHATSAPP ALERTS',
      subtitle: 'Configure automated staff notifications',
      showBackButton: true,
      children: [
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else ...[
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
            onChanged: (val) {
              setState(() => _shiftReminders = val);
              _savePref(_keyShift, val);
            },
          ),
          _buildNotificationSwitch(
            title: 'Incident Updates',
            subtitle: 'Notify riders when supervisor approves incident',
            value: _incidentAlerts,
            onChanged: (val) {
              setState(() => _incidentAlerts = val);
              _savePref(_keyIncident, val);
            },
          ),
          _buildNotificationSwitch(
            title: 'Document Expiry',
            subtitle: 'Reminders for Iqama/License renewal',
            value: _documentExpiry,
            onChanged: (val) {
              setState(() => _documentExpiry = val);
              _savePref(_keyDocument, val);
            },
          ),
          const SizedBox(height: 48),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 24),
          const Text('API Configuration',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            tileColor: Theme.of(context).cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.api, color: AppColors.primaryLight),
            title: const Text('WhatsApp Gateway'),
            subtitle: const Text('Twilio (Connected)'),
            trailing:
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ),
        ],
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
