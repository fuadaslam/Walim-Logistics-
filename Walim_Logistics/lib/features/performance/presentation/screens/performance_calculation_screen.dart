import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PerformanceCalculationScreen extends ConsumerStatefulWidget {
  const PerformanceCalculationScreen({super.key});

  @override
  ConsumerState<PerformanceCalculationScreen> createState() => _PerformanceCalculationScreenState();
}

class _PerformanceCalculationScreenState extends ConsumerState<PerformanceCalculationScreen> {
  final _attendanceController = TextEditingController(text: '40');
  final _incidentController = TextEditingController(text: '20');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('system_settings').select('key, value').inFilter('key', [
        'perf_weight_attendance',
        'perf_weight_incident',
      ]);

      for (var setting in response) {
        if (setting['key'] == 'perf_weight_attendance') {
          _attendanceController.text = setting['value'];
        } else if (setting['key'] == 'perf_weight_incident') {
          _incidentController.text = setting['value'];
        }
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final att = double.tryParse(_attendanceController.text) ?? 40;
    final inc = double.tryParse(_incidentController.text) ?? 20;

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      await Future.wait([
        supabase.from('system_settings').upsert({'key': 'perf_weight_attendance', 'value': att.toString()}, onConflict: 'key'),
        supabase.from('system_settings').upsert({'key': 'perf_weight_incident', 'value': inc.toString()}, onConflict: 'key'),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Performance scoring configuration saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'SCORING CONFIGURATION',
      subtitle: 'Design the weights and calculation logic for performance scores',
      showBackButton: true,
      activeItem: 'Performance',
      children: [
        _buildContent(context),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 32),
          _buildWeightSection(),
          const SizedBox(height: 48),
          Row(
            children: [
              ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Save Configuration',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 28),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scoring Strategy',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                ),
                Text(
                  'Set the maximum points for each category. The sum of these weights determines the total possible base score (excluding bonuses).',
                  style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeightInput(
          'Attendance Weight',
          'Maximum points for 100% attendance compliance.',
          Icons.fact_check_outlined,
          Colors.blue,
          _attendanceController,
        ),

        const SizedBox(height: 24),
        _buildWeightInput(
          'Incident Free Weight',
          'Maximum points for having zero incidents this week.',
          Icons.shield_outlined,
          Colors.orange,
          _incidentController,
        ),
      ],
    );
  }

  Widget _buildWeightInput(String label, String subtitle, IconData icon, Color color, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 40),
          SizedBox(
            width: 100,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
              decoration: InputDecoration(
                suffixText: 'pts',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
