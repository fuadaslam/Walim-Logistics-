import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:walim_logistics/core/services/storage_service.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/hr/domain/models/document_model.dart';
import 'package:walim_logistics/features/hr/presentation/document_notifier.dart';
import 'package:intl/intl.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  final DigitalDocument document;

  const DocumentDetailScreen({
    super.key,
    required this.document,
  });

  @override
  ConsumerState<DocumentDetailScreen> createState() =>
      _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late DateTime? _expiryDate;
  late String _selectedType;
  late String? _fileUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.document.title);
    _notesController =
        TextEditingController(text: widget.document.notes ?? '');
    _expiryDate = widget.document.expiryDate;
    _selectedType = widget.document.type;
    _fileUrl = widget.document.fileUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final updatedDoc = widget.document.copyWith(
      title: _titleController.text,
      notes: _notesController.text,
      expiryDate: _expiryDate,
      type: _selectedType,
      fileUrl: _fileUrl,
    );
    await ref.read(documentProvider.notifier).upsertDocument(updatedDoc);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _handleDelete() async {
    if (widget.document.status == 'Missing') return;
    await ref
        .read(documentProvider.notifier)
        .deleteDocument(widget.document.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _handleRequestRenewal() async {
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(documentProvider.notifier)
        .requestRenewal(widget.document.id);
    if (mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Renewal request submitted')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _handleApproveRenewal() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(documentProvider.notifier)
        .approveRenewal(widget.document.id, picked);
    if (mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Renewal approved')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _uploadFile(File file) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _uploading = true);
    try {
      final profile = ref.read(authProvider).profile;
      final url = await ref.read(storageServiceProvider).uploadDocument(
            file: file,
            profileId: profile?.id ?? 'unknown',
            docType: _selectedType,
          );
      setState(() {
        _fileUrl = url;
        _uploading = false;
      });
    } catch (e) {
      setState(() => _uploading = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Attach Document',
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'Images are automatically compressed to save storage.',
              style: GoogleFonts.outfit(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            _pickerOption(
              icon: Icons.camera_alt_rounded,
              color: Colors.blue,
              title: 'Take Photo',
              subtitle: 'Photograph the document directly',
              onTap: () async {
                Navigator.pop(ctx);
                final picker = ImagePicker();
                final xFile = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 90,
                );
                if (xFile != null) await _uploadFile(File(xFile.path));
              },
            ),
            const SizedBox(height: 12),
            _pickerOption(
              icon: Icons.photo_library_rounded,
              color: Colors.purple,
              title: 'Choose from Gallery',
              subtitle: 'Select an existing photo or image',
              onTap: () async {
                Navigator.pop(ctx);
                final picker = ImagePicker();
                final xFile = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 90,
                );
                if (xFile != null) await _uploadFile(File(xFile.path));
              },
            ),
            const SizedBox(height: 12),
            _pickerOption(
              icon: Icons.picture_as_pdf_rounded,
              color: Colors.red,
              title: 'Upload PDF',
              subtitle: 'Select a PDF file (max 10 MB)',
              onTap: () async {
                Navigator.pop(ctx);
                final result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: const ['pdf'],
                );
                if (result != null && result.files.single.path != null) {
                  await _uploadFile(File(result.files.single.path!));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(subtitle,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMissing = widget.document.status == 'Missing';
    final status = widget.document.status;
    final profile = ref.watch(authProvider).profile;
    final isHr = profile?.role == 'HR';
    final needsRenewal = status == 'Expired' || status == 'Expiring Soon';
    final pendingRenewal = status == 'Pending Renewal';
    final hasFile = _fileUrl != null && _fileUrl!.isNotEmpty;
    final isPdf = hasFile && _fileUrl!.toLowerCase().endsWith('.pdf');

    return DashboardScaffold(
      title: 'DOCUMENT DETAILS',
      subtitle: widget.document.title,
      showBackButton: true,
      actions: [
        IconButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Delete Document',
                    style:
                        GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                content: Text(
                    'Are you sure you want to remove this document?',
                    style: GoogleFonts.outfit()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('CANCEL',
                        style: GoogleFonts.outfit(
                            color: AppColors.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleDelete();
                    },
                    child: Text('DELETE',
                        style: GoogleFonts.outfit(
                            color: Colors.red,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        ),
      ],
      children: [
        const SizedBox(height: 16),

        // Document preview / picker area
        GestureDetector(
          onTap: _uploading ? null : _showPickerOptions,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: widget.document.color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: widget.document.color.withValues(alpha: 0.2)),
            ),
            clipBehavior: Clip.hardEdge,
            child: _uploading
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text('Compressing & uploading...',
                          style: GoogleFonts.outfit(
                              color: AppColors.textSecondary,
                              fontSize: 13)),
                    ],
                  )
                : hasFile && !isPdf
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            _fileUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _documentPlaceholder(),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10),
                              color: Colors.black54,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.edit_rounded,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text('Tap to replace',
                                      style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : hasFile && isPdf
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf_rounded,
                                  size: 56, color: Colors.red.shade400),
                              const SizedBox(height: 12),
                              Text('PDF Attached',
                                  style: GoogleFonts.outfit(
                                      color: Colors.red.shade400,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('Tap to replace',
                                  style: GoogleFonts.outfit(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            ],
                          )
                        : _documentPlaceholder(),
          ),
        ),

        const SizedBox(height: 32),
        Text('Document Information',
            style: GoogleFonts.outfit(
                fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _buildTextField(
            'Document Title', _titleController, Icons.title_rounded),
        const SizedBox(height: 20),
        _buildTypeDropdown(),
        const SizedBox(height: 20),
        _buildDatePicker('Expiry Date', _expiryDate, (date) {
          setState(() => _expiryDate = date);
        }),
        const SizedBox(height: 20),
        _buildTextField(
            'Additional Notes', _notesController, Icons.notes_rounded,
            maxLines: 3),
        const SizedBox(height: 40),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _uploading ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(
              isMissing ? 'UPLOAD DOCUMENT' : 'SAVE CHANGES',
              style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1),
            ),
          ),
        ),
        if (!isMissing && needsRenewal && !isHr) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: _handleRequestRenewal,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'REQUEST RENEWAL',
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1),
              ),
            ),
          ),
        ],
        if (isHr && pendingRenewal) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _handleApproveRenewal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                'APPROVE RENEWAL',
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1),
              ),
            ),
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _documentPlaceholder() {
    final isMissing = widget.document.status == 'Missing';
    final pendingRenewal = widget.document.status == 'Pending Renewal';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isMissing
              ? Icons.cloud_upload_outlined
              : pendingRenewal
                  ? Icons.hourglass_top_rounded
                  : widget.document.icon,
          size: 56,
          color: widget.document.color,
        ),
        const SizedBox(height: 12),
        Text(
          isMissing
              ? 'Tap to attach document'
              : pendingRenewal
                  ? 'RENEWAL PENDING'
                  : 'Tap to replace file',
          style: GoogleFonts.outfit(
            color: isMissing
                ? AppColors.textSecondary
                : widget.document.color,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        if (isMissing) ...[
          const SizedBox(height: 4),
          Text('Photo, gallery image, or PDF',
              style: GoogleFonts.outfit(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ],
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color:
                    Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.outfit(fontSize: 15),
            decoration: InputDecoration(
              prefixIcon:
                  Icon(icon, size: 20, color: AppColors.textSecondary),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Document Type',
            style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color:
                    Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedType,
              isExpanded: true,
              items: standardDocumentTypes.map((type) {
                return DropdownMenuItem(
                  value: type.label,
                  child: Row(
                    children: [
                      Icon(type.icon, size: 20, color: type.color),
                      const SizedBox(width: 12),
                      Text(type.label,
                          style: GoogleFonts.outfit(fontSize: 15)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedType = value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
      String label, DateTime? date, Function(DateTime) onDateSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate:
                  date ?? DateTime.now().add(const Duration(days: 30)),
              firstDate:
                  DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
            );
            if (picked != null) onDateSelected(picked);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Theme.of(context)
                      .dividerColor
                      .withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(
                  date != null
                      ? DateFormat('MMM dd, yyyy').format(date)
                      : 'No expiry date',
                  style: GoogleFonts.outfit(fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
