import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/reports/models/performance_record.dart';
import 'package:walim_logistics/features/reports/presentation/performance_notifier.dart';
import 'package:walim_logistics/features/reports/presentation/reports_notifier.dart';

class UploadReportDialog extends ConsumerStatefulWidget {
  const UploadReportDialog({super.key});

  @override
  ConsumerState<UploadReportDialog> createState() => _UploadReportDialogState();
}

class _UploadReportDialogState extends ConsumerState<UploadReportDialog> {
  String? _selectedPlatformId;
  ReportType _selectedType = ReportType.keetaDaily;
  DateTime _selectedDate = DateTime.now();
  String? _fileName;
  Uint8List? _fileBytes;
  bool _loading = false;

  static const _typeOptions = [
    (ReportType.keetaDaily, 'Keeta Daily', Icons.today_rounded),
    (ReportType.keetaMonthly, 'Keeta Monthly', Icons.calendar_month_rounded),
    (ReportType.keetaShift, 'Keeta Shift Booking', Icons.grid_view_rounded),
    (ReportType.ninjaShift, 'Ninja Shift', Icons.directions_bike_rounded),
    (ReportType.amazonMonthly, 'Amazon Monthly', Icons.local_shipping_rounded),
    (ReportType.amazonPayment, 'Amazon Payment', Icons.payments_rounded),
    (ReportType.noonReport, 'Noon Report', Icons.store_rounded),
    (ReportType.hungerStation, 'Hunger Station', Icons.restaurant_rounded),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final platforms = ref.read(reportsProvider).platforms;
      if (platforms.length == 1) {
        setState(() => _selectedPlatformId = platforms.first['id'] as String?);
      }
    });
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv', 'pdf'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _fileName = file.name;
          _fileBytes = file.bytes;
          // Auto-detect type from filename
          _autoDetectType(file.name);
        });
      }
    } catch (e) {
      _showSnack('Error picking file: $e', isError: true);
    }
  }

  void _autoDetectType(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('captain_performance') || (lower.contains('keeta') && lower.endsWith('.csv'))) {
      _selectedType = ReportType.keetaMonthly;
    } else if (lower.contains('book6') || lower.contains('shift') && lower.contains('keeta')) {
      _selectedType = ReportType.keetaShift;
    } else if (lower.contains('ninja') && lower.contains('shift')) {
      _selectedType = ReportType.ninjaShift;
    } else if (lower.contains('payment') || lower.contains('walm')) {
      _selectedType = ReportType.amazonPayment;
    } else if (lower.contains('amazon') || lower.contains('april') || lower.contains('monthly')) {
      _selectedType = ReportType.amazonMonthly;
    } else if (lower.contains('noon')) {
      _selectedType = ReportType.noonReport;
    } else if (lower.contains('hunger') || lower.contains('hungerstation')) {
      _selectedType = ReportType.hungerStation;
    } else if (lower.contains('keeta') || lower.endsWith('.xlsx')) {
      _selectedType = ReportType.keetaDaily;
    }
  }

  Future<void> _upload() async {
    if (_selectedPlatformId == null || _fileBytes == null || _fileName == null) return;

    setState(() => _loading = true);
    try {
      await ref.read(performanceProvider.notifier).uploadAndParse(
        fileBytes: _fileBytes!,
        fileName: _fileName!,
        platformId: _selectedPlatformId!,
        reportDate: _selectedDate,
        reportType: _selectedType,
      );

      if (mounted) {
        Navigator.pop(context, true);
        _showSnack('Report uploaded and parsed successfully!');
      }
    } catch (e) {
      if (mounted) _showSnack('Upload failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        left: 24,
        right: 24,
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
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UPLOAD REPORT',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Select platform, type, and attach your file',
                      style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
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
            const SizedBox(height: 24),

            // Platform
            _label('Platform'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedPlatformId,
              isExpanded: true,
              hint: Text(state.platforms.isEmpty ? 'Loading…' : 'Choose platform'),
              items: state.platforms.map((p) => DropdownMenuItem(
                value: p['id'] as String,
                child: Text(p['name'] as String),
              )).toList(),
              onChanged: state.platforms.isEmpty ? null : (v) => setState(() => _selectedPlatformId = v),
              decoration: _inputDeco(Icons.hub_rounded),
            ),

            const SizedBox(height: 16),

            // Report Type
            _label('Report Type'),
            const SizedBox(height: 8),
            _TypeSelector(
              selected: _selectedType,
              onSelected: (t) => setState(() => _selectedType = t),
              options: _typeOptions,
            ),

            const SizedBox(height: 16),

            // Report Date
            _label('Report Date'),
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
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.divider.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Text(DateFormat('MMMM dd, yyyy').format(_selectedDate),
                        style: GoogleFonts.outfit()),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // File picker
            _label('Select File'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  color: _fileBytes != null
                      ? Colors.green.withValues(alpha: 0.05)
                      : AppColors.primary.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _fileBytes != null
                        ? Colors.green.withValues(alpha: 0.5)
                        : AppColors.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _fileBytes != null ? Icons.check_circle_rounded : Icons.cloud_upload_rounded,
                      size: 44,
                      color: _fileBytes != null ? Colors.green : AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _fileName ?? 'Tap to select file',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: _fileName != null
                            ? (isDark ? Colors.white : Colors.black87)
                            : AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _fileBytes != null
                          ? 'Tap to change · XLSX, CSV, PDF'
                          : 'Supports XLSX, XLS, CSV, PDF',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: _fileBytes != null ? Colors.green : AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: (_loading || _selectedPlatformId == null || _fileBytes == null)
                    ? null
                    : _upload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  disabledBackgroundColor: AppColors.divider,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.upload_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text('Upload & Parse',
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
      ),
    );
  }

  InputDecoration _inputDeco(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: AppColors.divider.withValues(alpha: 0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final ReportType selected;
  final ValueChanged<ReportType> onSelected;
  final List<(ReportType, String, IconData)> options;

  const _TypeSelector({
    required this.selected,
    required this.onSelected,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final (type, label, icon) = opt;
        final isSelected = selected == type;
        return GestureDetector(
          onTap: () => onSelected(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.divider.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider.withValues(alpha: 0.4),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
