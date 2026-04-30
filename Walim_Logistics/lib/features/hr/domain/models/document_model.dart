import 'package:flutter/material.dart';

class DigitalDocument {
  final String id;
  final String title;
  final String type;
  final DateTime? expiryDate;
  final String status; // Valid, Expired, Expiring Soon, Missing
  final IconData icon;
  final Color color;
  final String? fileUrl;
  final String? notes;

  DigitalDocument({
    required this.id,
    required this.title,
    required this.type,
    this.expiryDate,
    required this.status,
    required this.icon,
    required this.color,
    this.fileUrl,
    this.notes,
  });

  factory DigitalDocument.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'Custom Label';
    final typeObj = standardDocumentTypes.firstWhere(
      (t) => t.label == type,
      orElse: () => standardDocumentTypes.last,
    );
    DateTime? expiryDate;
    if (json['expiry_date'] != null) {
      expiryDate = DateTime.tryParse(json['expiry_date'].toString());
    }
    String status = json['status'] as String? ?? 'Valid';
    if (expiryDate != null) {
      final days = expiryDate.difference(DateTime.now()).inDays;
      if (days < 0) {
        status = 'Expired';
      } else if (days <= 30) {
        status = 'Expiring Soon';
      } else {
        status = 'Valid';
      }
    }
    return DigitalDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      type: type,
      expiryDate: expiryDate,
      status: status,
      icon: typeObj.icon,
      color: typeObj.color,
      fileUrl: json['file_url'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'type': type,
        'status': status,
        'expiry_date': expiryDate?.toIso8601String().split('T')[0],
        'file_url': fileUrl,
        'notes': notes,
      };

  DigitalDocument copyWith({
    String? id,
    String? title,
    String? type,
    DateTime? expiryDate,
    String? status,
    IconData? icon,
    Color? color,
    String? fileUrl,
    String? notes,
  }) {
    return DigitalDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      fileUrl: fileUrl ?? this.fileUrl,
      notes: notes ?? this.notes,
    );
  }
}

class DocumentType {
  final String label;
  final IconData icon;
  final Color color;
  final bool isRequired;

  DocumentType({
    required this.label,
    required this.icon,
    required this.color,
    this.isRequired = false,
  });
}

final List<DocumentType> standardDocumentTypes = [
  DocumentType(label: 'Iqama / National ID', icon: Icons.badge_outlined, color: Colors.blue, isRequired: true),
  DocumentType(label: "Driver's License", icon: Icons.drive_eta_outlined, color: Colors.green, isRequired: true),
  DocumentType(label: 'Vehicle Insurance', icon: Icons.security_outlined, color: Colors.orange, isRequired: true),
  DocumentType(label: 'Health Insurance', icon: Icons.health_and_safety_outlined, color: Colors.teal, isRequired: true),
  DocumentType(label: 'Passport', icon: Icons.language_rounded, color: Colors.indigo, isRequired: false),
  DocumentType(label: 'Training Certificate', icon: Icons.school_rounded, color: Colors.purple, isRequired: false),
  DocumentType(label: 'Custom Label', icon: Icons.description_outlined, color: Colors.grey, isRequired: false),
];
