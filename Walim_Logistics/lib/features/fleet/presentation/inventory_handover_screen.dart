import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';

import '../../dashboard/presentation/widgets/dashboard_scaffold.dart';

class InventoryHandoverScreen extends ConsumerStatefulWidget {
  final bool showScaffold;
  const InventoryHandoverScreen({super.key, this.showScaffold = true});

  @override
  ConsumerState<InventoryHandoverScreen> createState() => _InventoryHandoverScreenState();
}

class _InventoryHandoverScreenState extends ConsumerState<InventoryHandoverScreen> {
  String? _scannedId;
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && !_isProcessing) {
      setState(() {
        _scannedId = barcodes.first.rawValue;
        _isProcessing = true;
      });
      _showAssignmentDialog();
    }
  }

  void _showAssignmentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 32,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.primaryLight),
            const SizedBox(height: 16),
            const Text(
              'Assign Asset',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Asset ID: $_scannedId',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            
            // Rider Search (Placeholder)
            TextField(
              decoration: InputDecoration(
                hintText: 'Search Rider Name or ID',
                prefixIcon: const Icon(Icons.search),
                fillColor: AppColors.surface,
              ),
            ),
            
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: Call fleetRepository.assignAsset
                Navigator.pop(context);
                setState(() => _isProcessing = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Asset successfully assigned!')),
                );
              },
              child: const Text('Confirm Assignment'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ).then((_) => setState(() => _isProcessing = false));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showScaffold) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildContent(),
              ]),
            ),
          ),
        ],
      );
    }

    return DashboardScaffold(
      title: 'INVENTORY HANDOVER',
      subtitle: 'Scan QR codes to assign assets to riders',
      activeItem: 'Assets',
      children: [
        _buildContent(),
      ],
    );
  }

  Widget _buildContent() {
    return SizedBox(
      height: 500,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: MobileScanner(
              onDetect: _onDetect,
              controller: MobileScannerController(
                facing: CameraFacing.back,
                torchEnabled: false,
              ),
            ),
          ),
          // Scanner Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Text(
              'Align QR code within the frame',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
