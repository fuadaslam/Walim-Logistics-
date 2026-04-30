import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/hr/domain/models/document_model.dart';
import 'package:intl/intl.dart';

class DocumentDetailScreen extends StatefulWidget {
  final DigitalDocument document;
  final Function(DigitalDocument) onUpdate;
  final VoidCallback onDelete;

  const DocumentDetailScreen({
    super.key,
    required this.document,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late DateTime? _expiryDate;
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.document.title);
    _notesController = TextEditingController(text: widget.document.notes ?? '');
    _expiryDate = widget.document.expiryDate;
    _selectedType = widget.document.type;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final updatedDoc = widget.document.copyWith(
      title: _titleController.text,
      notes: _notesController.text,
      expiryDate: _expiryDate,
      type: _selectedType,
    );
    widget.onUpdate(updatedDoc);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isMissing = widget.document.status == 'Missing';

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
                title: Text('Delete Document', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                content: Text('Are you sure you want to remove this document?', style: GoogleFonts.outfit()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('CANCEL', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onDelete();
                      Navigator.pop(context);
                    },
                    child: Text('DELETE', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
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
        // Document Preview Card (Mockup)
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.document.color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.document.color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.document.icon, size: 64, color: widget.document.color),
              const SizedBox(height: 16),
              if (isMissing)
                Text(
                  'DOCUMENT MISSING',
                  style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
                )
              else
                Text(
                  'DIGITAL COPY ATTACHED',
                  style: GoogleFonts.outfit(color: widget.document.color, fontWeight: FontWeight.bold, fontSize: 16),
                ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text('Document Information', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        
        // Form Fields
        _buildTextField('Document Title', _titleController, Icons.title_rounded),
        const SizedBox(height: 20),
        
        _buildTypeDropdown(),
        const SizedBox(height: 20),
        
        _buildDatePicker('Expiry Date', _expiryDate, (date) {
          setState(() => _expiryDate = date);
        }),
        const SizedBox(height: 20),
        
        _buildTextField('Additional Notes', _notesController, Icons.notes_rounded, maxLines: 3),
        
        const SizedBox(height: 40),
        
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(
              isMissing ? 'UPLOAD DOCUMENT' : 'SAVE CHANGES',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.outfit(fontSize: 15),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        Text('Document Type', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
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
                      Text(type.label, style: GoogleFonts.outfit(fontSize: 15)),
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

  Widget _buildDatePicker(String label, DateTime? date, Function(DateTime) onDateSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
            );
            if (picked != null) onDateSelected(picked);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(
                  date != null ? DateFormat('MMM dd, yyyy').format(date) : 'No expiry date',
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
