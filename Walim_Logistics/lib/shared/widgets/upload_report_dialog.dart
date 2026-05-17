import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/reports/presentation/reports_notifier.dart';
import 'package:walim_logistics/features/reports/models/platform_report.dart';

class UploadReportDialog extends ConsumerStatefulWidget {
  const UploadReportDialog({super.key});

  @override
  ConsumerState<UploadReportDialog> createState() => _UploadReportDialogState();
}

class _UploadReportDialogState extends ConsumerState<UploadReportDialog> {
  String? _selectedPlatformId;
  ReportFrequency _selectedFrequency = ReportFrequency.daily;
  DateTime _selectedDate = DateTime.now();
  
  String? _fileName;
  Uint8List? _fileBytes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final platforms = ref.read(reportsProvider).platforms;
      if (platforms.length == 1) {
        setState(() {
          _selectedPlatformId = platforms.first['id'] as String?;
        });
      }
    });
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv', 'pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _fileName = file.name;
          _fileBytes = file.bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e'))
        );
      }
    }
  }

  Future<void> _upload() async {
    if (_selectedPlatformId == null || _fileBytes == null || _fileName == null) return;

    setState(() => _loading = true);
    try {
      final ext = _fileName!.split('.').last;
      await ref.read(reportsProvider.notifier).uploadReport(
        fileName: _fileName!,
        fileType: ext,
        fileUrl: '', 
        reportDate: _selectedDate,
        frequency: _selectedFrequency,
        platformId: _selectedPlatformId!,
        fileBytes: _fileBytes,
      );
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report uploaded successfully!'),
            backgroundColor: Colors.green,
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          )
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ReportsState>(reportsProvider, (previous, next) {
      if (_selectedPlatformId == null && next.platforms.length == 1) {
        setState(() {
          _selectedPlatformId = next.platforms.first['id'] as String?;
        });
      }
    });

    final state = ref.watch(reportsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        left: 32,
        right: 32,
        top: 12,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UPLOAD PLATFORM REPORT',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Select frequency and upload your data sheet',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.divider.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (state.error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Error loading: ${state.error}',
                        style: GoogleFonts.outfit(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            _buildLabel('Select Platform'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedPlatformId,
              isExpanded: true,
              hint: Text(
                state.loading && state.platforms.isEmpty 
                  ? 'Loading platforms...' 
                  : state.platforms.isEmpty 
                    ? 'No platforms found. Add one first.'
                    : 'Choose platform',
              ),
              items: state.platforms.map((p) => DropdownMenuItem(
                value: p['id'] as String,
                child: Text(p['name'] as String),
              )).toList(),
              onChanged: state.platforms.isEmpty ? null : (v) => setState(() => _selectedPlatformId = v),
              decoration: _inputDecoration(
                prefixIcon: Icons.hub_rounded,
                suffixIcon: state.loading && state.platforms.isEmpty 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
              ),
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Frequency'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ReportFrequency>(
                        value: _selectedFrequency,
                        items: ReportFrequency.values.map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.name.toUpperCase()),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedFrequency = v!),
                        decoration: _inputDecoration(prefixIcon: Icons.schedule_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Report Date'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 1)),
                          );
                          if (d != null) setState(() => _selectedDate = d);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.divider.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.textSecondary),
                              const SizedBox(width: 12),
                              Text(DateFormat('MMM dd, yyyy').format(_selectedDate), style: GoogleFonts.outfit()),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            
            _buildLabel('Select File'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: BoxDecoration(
                  color: _fileBytes != null ? Colors.green.withValues(alpha: 0.05) : AppColors.primary.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _fileBytes != null ? Colors.green.withValues(alpha: 0.5) : AppColors.primary.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _fileBytes != null ? Icons.check_circle_rounded : Icons.cloud_upload_rounded, 
                      size: 48, 
                      color: _fileBytes != null ? Colors.green : AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _fileName ?? 'Tap to select Excel or PDF report',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: _fileName != null ? (isDark ? Colors.white : Colors.black87) : AppColors.textSecondary,
                      ),
                    ),
                    if (_fileName == null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Supports XLSX, XLS, CSV, PDF',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(
                        'File selected successfully',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_loading || _selectedPlatformId == null || _fileBytes == null) ? null : _upload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _loading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) 
                  : Text('Submit Report', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
      ),
    );
  }

  InputDecoration _inputDecoration({required IconData prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      prefixIcon: Icon(prefixIcon, size: 20),
      suffixIcon: suffixIcon != null ? Padding(
        padding: const EdgeInsets.all(16),
        child: suffixIcon,
      ) : null,
      filled: true,
      fillColor: AppColors.divider.withValues(alpha: 0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
