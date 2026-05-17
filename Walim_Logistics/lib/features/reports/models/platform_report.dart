enum ReportFrequency { daily, weekly, monthly }

class PlatformReport {
  final String id;
  final String platformId;
  final String platformName;
  final String supervisorId;
  final String supervisorName;
  // Maps from upload_date in platform_report_uploads
  final DateTime reportDate;
  // Client-side only — not persisted; used for UI filtering
  final ReportFrequency frequency;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final DateTime uploadedAt;
  final String status;
  final String? attendanceReportId;

  PlatformReport({
    required this.id,
    required this.platformId,
    required this.platformName,
    required this.supervisorId,
    required this.supervisorName,
    required this.reportDate,
    this.frequency = ReportFrequency.daily,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.uploadedAt,
    this.status = 'uploaded',
    this.attendanceReportId,
  });

  factory PlatformReport.fromJson(Map<String, dynamic> json) {
    final platforms = json['platforms'];
    final profiles = json['profiles'];
    return PlatformReport(
      id: json['id'] as String? ?? '',
      platformId: json['platform_id'] as String? ?? '',
      platformName: platforms is Map ? (platforms['name'] as String? ?? 'Unknown') : 'Unknown',
      supervisorId: json['supervisor_id'] as String? ?? '',
      supervisorName: profiles is Map ? (profiles['full_name'] as String? ?? 'Unknown') : 'Unknown',
      reportDate: json['upload_date'] != null
          ? DateTime.tryParse(json['upload_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      fileUrl: json['file_url'] as String? ?? '',
      fileName: json['file_name'] as String? ?? '',
      fileType: json['file_type'] as String? ?? 'other',
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.tryParse(json['uploaded_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] as String? ?? 'uploaded',
      attendanceReportId: json['attendance_report_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'supervisor_id': supervisorId,
        'platform_id': platformId,
        'upload_date': reportDate.toIso8601String().split('T')[0],
        'file_url': fileUrl,
        'file_name': fileName,
        'file_type': _normalizedFileType(fileType),
        'status': status,
        if (attendanceReportId != null) 'attendance_report_id': attendanceReportId,
      };

  static String _normalizedFileType(String type) {
    final t = type.toLowerCase().replaceAll('.', '');
    if (t == 'xlsx' || t == 'xls') return 'excel';
    if (t == 'csv') return 'csv';
    if (t == 'pdf') return 'pdf';
    return 'other';
  }
}
