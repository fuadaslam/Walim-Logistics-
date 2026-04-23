import 'package:flutter/material.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  DateTimeRange? _selectedDateRange;
  final _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Leave')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Select Dates', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.primary,
                        surface: AppColors.surface,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _selectedDateRange = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 20),
                    const SizedBox(width: 16),
                    Text(
                      _selectedDateRange == null 
                        ? 'Choose start and end date' 
                        : '${_selectedDateRange!.start.toString().split(' ')[0]} to ${_selectedDateRange!.end.toString().split(' ')[0]}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Reason', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter reason for leave...',
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Leave request submitted!')),
                );
              },
              child: const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }
}
