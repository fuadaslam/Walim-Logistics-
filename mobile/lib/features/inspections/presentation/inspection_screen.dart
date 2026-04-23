import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_fleet/l10n/app_localizations.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';

class InspectionScreen extends ConsumerStatefulWidget {
  const InspectionScreen({super.key});

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
    'Reflective Vest': false,
    'Safety Shoes': false,
    'Mobile Holder': false,
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vehicleInspection)),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep += 1);
          } else {
            // Submit logic
            Navigator.of(context).pop();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        steps: [
          Step(
            title: const Text('Vehicle'),
            isActive: _currentStep >= 0,
            content: _buildVehicleStep(),
          ),
          Step(
            title: const Text('Safety'),
            isActive: _currentStep >= 1,
            content: _buildSafetyStep(),
          ),
          Step(
            title: const Text('Confirm'),
            isActive: _currentStep >= 2,
            content: _buildConfirmStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleStep() {
    return Column(
      children: [
        _buildPhotoPlaceholder(_vehiclePhoto, () => _takePhoto(true)),
        const SizedBox(height: 16),
        ..._vehicleChecklist.keys.map((key) => CheckboxListTile(
          title: Text(key),
          value: _vehicleChecklist[key],
          onChanged: (val) => setState(() => _vehicleChecklist[key] = val!),
        )),
      ],
    );
  }

  Widget _buildSafetyStep() {
    return Column(
      children: [
        _buildPhotoPlaceholder(_safetyPhoto, () => _takePhoto(false)),
        const SizedBox(height: 16),
        ..._safetyChecklist.keys.map((key) => CheckboxListTile(
          title: Text(key),
          value: _safetyChecklist[key],
          onChanged: (val) => setState(() => _safetyChecklist[key] = val!),
        )),
      ],
    );
  }

  Widget _buildConfirmStep() {
    return const Center(
      child: Column(
        children: [
          Icon(Icons.verified_outlined, size: 64, color: AppColors.accent),
          SizedBox(height: 16),
          Text('Ready to start your shift?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('All inspections completed successfully.', textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder(File? file, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: file != null 
          ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(file, fit: BoxFit.cover))
          : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined, size: 48, color: AppColors.textSecondary),
                Text('Take Photo'),
              ],
            ),
      ),
    );
  }
}
