import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/dashboard_provider.dart';

class AddAssetDialog extends ConsumerStatefulWidget {
  const AddAssetDialog({super.key});

  @override
  ConsumerState<AddAssetDialog> createState() => _AddAssetDialogState();
}

class _AddAssetDialogState extends ConsumerState<AddAssetDialog> {
  final _plateCtrl = TextEditingController();
  final _mvpiCtrl = TextEditingController();
  final _insuranceCtrl = TextEditingController();
  String _selectedType = 'Bike';
  bool _loading = false;

  final List<String> _types = ['Bike', 'Van'];

  @override
  void dispose() {
    _plateCtrl.dispose();
    _mvpiCtrl.dispose();
    _insuranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      'REGISTER ASSET',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Onboard a new vehicle to the fleet',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
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
            Text(
              'Vehicle Type',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _types.map((type) {
                final isSelected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () => setState(() => _selectedType = type),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.divider.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.divider.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            type == 'Bike' ? Icons.motorcycle_rounded : Icons.local_shipping_rounded,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            _buildField(
              controller: _plateCtrl,
              label: 'Plate Number',
              hint: 'e.g. 1234 ABC',
              icon: Icons.pin_outlined,
            ),
            const SizedBox(height: 20),
            _buildField(
              controller: _mvpiCtrl,
              label: 'MVPI Expiry',
              hint: 'YYYY-MM-DD',
              icon: Icons.calendar_today_outlined,
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 20),
            _buildField(
              controller: _insuranceCtrl,
              label: 'Insurance Expiry',
              hint: 'YYYY-MM-DD',
              icon: Icons.security_outlined,
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _loading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) 
                  : Text('Register Asset', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.outfit(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: AppColors.divider.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_plateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plate number is required')));
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(dashboardRepositoryProvider).createVehicle(
        plateNumber: _plateCtrl.text.trim(),
        type: _selectedType,
        mvpiExpiry: _mvpiCtrl.text.trim().isEmpty ? null : _mvpiCtrl.text.trim(),
        insuranceExpiry: _insuranceCtrl.text.trim().isEmpty ? null : _insuranceCtrl.text.trim(),
      );
      ref.invalidate(dashboardDataProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        String message = e.toString();
        if (message.contains('row-level security policy')) {
          message = 'Access Denied: You do not have permission to register fleet assets.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
