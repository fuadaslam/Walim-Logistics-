import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:walim_logistics/features/hr/domain/models/document_model.dart';
import 'package:walim_logistics/features/hr/presentation/document_detail_screen.dart';
import 'package:walim_logistics/features/hr/presentation/document_notifier.dart';

class DocumentVaultScreen extends ConsumerStatefulWidget {
  final bool showScaffold;
  const DocumentVaultScreen({super.key, this.showScaffold = true});

  @override
  ConsumerState<DocumentVaultScreen> createState() => _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends ConsumerState<DocumentVaultScreen> {
  String _searchQuery = '';

  List<DigitalDocument> _filtered(List<DigitalDocument> docs) => docs
      .where((d) => d.title.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  List<DocumentType> _missingRequired(List<DigitalDocument> docs) {
    final existing = docs.map((d) => d.type).toSet();
    return standardDocumentTypes
        .where((t) => t.isRequired && !existing.contains(t.label))
        .toList();
  }

  void _addDocument() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddDocumentSheet(),
    );
  }

  Widget _buildAddDocumentSheet() {
    String customLabel = '';
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            top: 32,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add New Document',
                      style: GoogleFonts.outfit(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 24),
              Text('Enter custom label (optional)',
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.5)),
                ),
                child: TextField(
                  onChanged: (v) => setSheetState(() => customLabel = v),
                  style: GoogleFonts.outfit(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'e.g. Health Certificate...',
                    hintStyle: GoogleFonts.outfit(
                        color: AppColors.textSecondary
                            .withValues(alpha: 0.4)),
                    prefixIcon:
                        const Icon(Icons.label_outline_rounded, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Or select from standard types',
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight:
                        MediaQuery.of(context).size.height * 0.4),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: standardDocumentTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final type = standardDocumentTypes[index];
                    return ListTile(
                      onTap: () {
                        Navigator.pop(context);
                        final finalTitle = customLabel.isNotEmpty
                            ? customLabel
                            : type.label;
                        final newDoc = DigitalDocument(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          title: finalTitle,
                          type: type.label,
                          status: 'Missing',
                          icon: type.icon,
                          color: type.color,
                        );
                        _navigateToDetail(newDoc);
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: type.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(type.icon, color: type.color),
                      ),
                      title: Text(type.label,
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                            color: Theme.of(context)
                                .dividerColor
                                .withValues(alpha: 0.5)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToDetail(DigitalDocument doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentDetailScreen(document: doc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docState = ref.watch(documentProvider);
    final allDocs = docState.documents;
    final filtered = _filtered(allDocs);
    final missing = _missingRequired(allDocs);

    final children = [
      const SizedBox(height: 8),
      // Search Bar
      Container(
        height: 54,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color:
                  Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.search_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.7)),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search documents...',
                  hintStyle: GoogleFonts.outfit(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      fontSize: 15),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),

      // Loading state
      if (docState.isLoading)
        const Center(child: CircularProgressIndicator()),

      // Missing Documents
      if (!docState.isLoading && missing.isNotEmpty) ...[
        Row(
          children: [
            Text('Missing Required',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent)),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12)),
              child: Text(missing.length.toString(),
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...missing.map((type) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMissingDocCard(type),
            )),
        const SizedBox(height: 24),
      ],

      if (!docState.isLoading) ...[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Digital Documents',
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            Text('${filtered.length} Total',
                style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 16),

        if (filtered.isEmpty && _searchQuery.isNotEmpty)
          const EmptyStatePlaceholder(
            icon: Icons.search_off_rounded,
            title: 'No Documents Found',
            subtitle: 'Try adjusting your search to find the document you\'re looking for.',
            color: Colors.blueGrey,
          ),

        ...filtered.map((doc) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildDocumentCard(context, doc),
            )),

        if (_searchQuery.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildAddDocumentCard(),
          ),
        const SizedBox(height: 100),
      ],
    ];

    if (!widget.showScaffold) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );
    }

    return DashboardScaffold(
      title: 'DOCUMENTS VAULT',
      subtitle: 'Your digital copies of official documents',
      showBackButton: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDocument,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.cloud_upload_outlined),
        label: Text('UPLOAD',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, letterSpacing: 1)),
        elevation: 8,
      ),
      children: children,
    );
  }

  Widget _buildMissingDocCard(DocumentType type) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: () {
          final newDoc = DigitalDocument(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: type.label,
            type: type.label,
            status: 'Missing',
            icon: type.icon,
            color: type.color,
          );
          _navigateToDetail(newDoc);
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(type.icon, color: Colors.redAccent, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type.label,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Required document missing',
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.redAccent.withValues(alpha: 0.7))),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10)),
                child: Text('UPLOAD',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, DigitalDocument doc) {
    final expiryText = doc.expiryDate != null
        ? 'Expires in ${doc.expiryDate!.difference(DateTime.now()).inDays} days'
        : 'No expiry date';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(doc),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: doc.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(doc.icon, color: doc.color, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.title,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 4),
                    Text(expiryText,
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              _buildStatusBadge(doc.status),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.textSecondary, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddDocumentCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            style: BorderStyle.solid),
      ),
      child: InkWell(
        onTap: _addDocument,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline_rounded,
                  color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'ADD NEW DOCUMENT',
                style: GoogleFonts.outfit(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'Valid'
        ? Colors.green
        : status == 'Missing'
            ? Colors.red
            : status == 'Expiring Soon'
                ? Colors.orange
                : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.outfit(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}
