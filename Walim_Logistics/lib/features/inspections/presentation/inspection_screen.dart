import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_fleet/l10n/app_localizations.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:last_mile_fleet/features/support/presentation/widgets/issue_report_bottom_sheet.dart';

class InspectionScreen extends ConsumerStatefulWidget {
  final bool showScaffold;
  const InspectionScreen({super.key, this.showScaffold = true});

  @override
  ConsumerState<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends ConsumerState<InspectionScreen> {
  int _currentStep = 0;
  final ImagePicker _picker = ImagePicker();
  
  File? _vehiclePhoto;
  File? _safetyPhoto;
  
  final Map<String, bool> _vehicleChecklist = {
    'Tires': false,
    'Lights': false,
    'Brakes': false,
    'Fuel/Battery': false,
  };

  final Map<String, bool> _safetyChecklist = {
    'Helmet': false,
    'Safety Jacket': false,
    'Safety Pads': false,
    'Protectors': false,
    'Safety Shoes': false,
  };

  Future<void> _takePhoto(bool isVehicle) async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        if (isVehicle) {
          _vehiclePhoto = File(photo.path);
        } else {
          _safetyPhoto = File(photo.path);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final body = Container(
      color: isDark ? AppColors.backgroundDark : AppColors.background,
      child: Column(
        children: [
          _buildProgressHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStepContent(l10n),
              ),
            ),
          ),
          _buildBottomNavigation(l10n),
        ],
      ),
    );

    if (!widget.showScaffold) return body;

    return DashboardScaffold(
      title: l10n.vehicleInspection.toUpperCase(),
      subtitle: 'Daily compliance and safety verification',
      showBackButton: true,
      actions: [
        IconButton(
          tooltip: 'Report an issue',
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.report_problem_rounded, color: AppColors.error, size: 20),
          ),
          onPressed: () => IssueReportBottomSheet.show(context),
        ),
      ],
      body: body,
    );
  }

  Widget _buildProgressHeader() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: isMobile ? 24 : 40),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Vehicle'),
          _buildStepLine(0),
          _buildStepIndicator(1, 'Safety'),
          _buildStepLine(1),
          _buildStepIndicator(2, 'Status'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    bool isCompleted = _currentStep > step;
    bool isActive = _currentStep == step;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          width: isActive ? 40 : 36,
          height: isActive ? 40 : 36,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : (isCompleted ? Colors.green : Colors.transparent),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.primary : (isCompleted ? Colors.green : Theme.of(context).dividerColor),
              width: 2,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ] : [],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
                : Text(
                    '${step + 1}',
                    style: GoogleFonts.outfit(
                      color: isActive ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive ? AppColors.primary : (isCompleted ? Colors.green : AppColors.textSecondary),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    bool isCompleted = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24, left: 8, right: 8),
        color: isCompleted ? AppColors.primary : Theme.of(context).dividerColor,
      ),
    );
  }

  Widget _buildCurrentStepContent(AppLocalizations l10n) {
    switch (_currentStep) {
      case 0:
        return _buildVehicleStep();
      case 1:
        return _buildSafetyStep();
      case 2:
        return _buildConfirmStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildVehicleStep() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Vehicle Verification', 'Upload a clear photo of your assigned vehicle'),
        const SizedBox(height: 16),
        _buildPhotoPlaceholder(_vehiclePhoto, () => _takePhoto(true)),
        const SizedBox(height: 32),
        _buildSectionTitle('Checklist', 'Ensure all components are in good working condition'),
        const SizedBox(height: 16),
        _buildChecklistCard(_vehicleChecklist),
        const SizedBox(height: 16),
        _buildReportLink('Found a vehicle issue? Report it here'),
      ],
    );
  }

  Widget _buildSafetyStep() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Personal Protection', 'A photo of you wearing the required safety gear'),
        const SizedBox(height: 16),
        _buildPhotoPlaceholder(_safetyPhoto, () => _takePhoto(false)),
        const SizedBox(height: 32),
        _buildSectionTitle('Safety Equipment', 'Verify you have all mandatory gear'),
        const SizedBox(height: 16),
        _buildChecklistCard(_safetyChecklist),
        const SizedBox(height: 16),
        _buildReportLink('Missing safety gear? Report it here'),
      ],
    );
  }

  Widget _buildConfirmStep() {
    return Center(
      key: const ValueKey(2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_rounded, size: 80, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          Text(
            'Inspection Complete!',
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'You have successfully verified all safety and vehicle protocols. You are now ready to start your mission.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 40),
          _buildSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle, style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildChecklistCard(Map<String, bool> checklist) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: checklist.keys.map((key) {
          bool isLast = checklist.keys.last == key;
          bool isChecked = checklist[key] ?? false;
          return Column(
            children: [
              CheckboxListTile(
                title: Text(
                  key, 
                  style: GoogleFonts.outfit(
                    fontWeight: isChecked ? FontWeight.bold : FontWeight.w500,
                    color: isChecked ? AppColors.primary : null,
                  )
                ),
                value: isChecked,
                activeColor: AppColors.primary,
                checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                onChanged: (val) => setState(() => checklist[key] = val!),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                secondary: Icon(
                  isChecked ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: isChecked ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
              if (!isLast) Divider(height: 1, indent: 60, endIndent: 20, color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _buildSummaryRow(Icons.motorcycle, 'Vehicle Status', 'Verified'),
          const Divider(height: 32),
          _buildSummaryRow(Icons.security, 'Safety Gear', 'Ready'),
          const Divider(height: 32),
          _buildSummaryRow(Icons.timer, 'Completion Time', 'Just now'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 16),
        Text(label, style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.green)),
      ],
    );
  }

  Widget _buildPhotoPlaceholder(File? file, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: file != null ? AppColors.primary : theme.dividerColor.withValues(alpha: 0.5),
            width: file != null ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          image: file != null ? DecorationImage(image: FileImage(file), fit: BoxFit.cover) : null,
        ),
        child: file == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_a_photo_rounded, size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Capture Photo', 
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to open camera', 
                    style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              )
            : Stack(
                children: [
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'RETAKE', 
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }


  Widget _buildReportLink(String label) {
    return Center(
      child: TextButton.icon(
        onPressed: () => IssueReportBottomSheet.show(context),
        icon: const Icon(Icons.report_problem_outlined, color: AppColors.error, size: 18),
        label: Text(
          label,
          style: GoogleFonts.outfit(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(AppLocalizations l10n) {
    bool isFirst = _currentStep == 0;
    bool isLast = _currentStep == 2;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          if (!isFirst)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep -= 1),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Icon(Icons.arrow_back),
              ),
            ),
          if (!isFirst) const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: () {
                if (_currentStep < 2) {
                  setState(() => _currentStep += 1);
                } else {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLast ? 'START SHIFT' : 'CONTINUE',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                  ),
                  const SizedBox(width: 8),
                  Icon(isLast ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
