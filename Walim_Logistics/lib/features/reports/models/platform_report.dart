import 'package:flutter/foundation.dart';

enum ReportFrequency { daily, weekly, monthly }

class PlatformReport {
  final String id;
  final String platformId;
  final String platformName;
  final String supervisorId;
  final String supervisorName;
  final DateTime reportDate;
  final ReportFrequency frequency;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final DateTime uploadedAt;
  final String status; // 'uploaded', 'verified', 'flagged'

  PlatformReport({
    required this.id,
    required this.platformId,
    required this.platformName,
    required this.supervisorId,
    required this.supervisorName,
    required this.reportDate,
    required this.frequency,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.uploadedAt,
    this.status = 'uploaded',
  });

  factory PlatformReport.fromJson(Map<String, dynamic> json) {
    return PlatformReport(
      id: json['id'],
      platformId: json['platform_id'],
      platformName: json['platforms']?['name'] ?? 'Unknown',
      supervisorId: json['supervisor_id'],
      supervisorName: json['profiles']?['full_name'] ?? 'Unknown',
      reportDate: DateTime.parse(json['report_date']),
      frequency: ReportFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => ReportFrequency.daily,
      ),
      fileUrl: json['file_url'],
      fileName: json['file_name'],
      fileType: json['file_type'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
      status: json['status'] ?? 'uploaded',
    );
  }

  Map<String, dynamic> toJson() => {
        'platform_id': platformId,
        'supervisor_id': supervisorId,
        'report_date': reportDate.toIso8601String().split('T')[0],
        'frequency': frequency.name,
        'file_url': fileUrl,
        'file_name': fileName,
        'file_type': fileType,
        'status': status,
      };
}
