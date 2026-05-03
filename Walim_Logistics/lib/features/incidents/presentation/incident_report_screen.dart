import 'package:flutter/material.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  String _selectedType = 'accident';
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'REPORT INCIDENT',
      subtitle: 'Document a new incident for review',
      showBackButton: true,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Type of Incident', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedType,
              dropdownColor: AppColors.surface,
              decoration: InputDecoration(fillColor: AppColors.surface),
              items: ['accident', 'fuel_issue', 'app_glitch', 'other']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase())))
                  .toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            const SizedBox(height: 24),
            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Please provide details about the incident...',
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // TODO: Call incidentRepository.reportIncident
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incident reported successfully!')),
                );
              },
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ],
    );
  }
}
