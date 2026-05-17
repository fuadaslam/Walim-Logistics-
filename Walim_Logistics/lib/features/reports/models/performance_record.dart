enum ReportType {
  keetaDaily,
  keetaMonthly,
  keetaShift,
  ninjaShift,
  amazonMonthly,
  amazonPayment,
  noonReport,
  hungerStation,
  unknown;

  String get displayName {
    switch (this) {
      case ReportType.keetaDaily: return 'Keeta Daily';
      case ReportType.keetaMonthly: return 'Keeta Monthly';
      case ReportType.keetaShift: return 'Keeta Shift';
      case ReportType.ninjaShift: return 'Ninja Shift';
      case ReportType.amazonMonthly: return 'Amazon Monthly';
      case ReportType.amazonPayment: return 'Amazon Payment';
      case ReportType.noonReport: return 'Noon Report';
      case ReportType.hungerStation: return 'Hunger Station';
      case ReportType.unknown: return 'Other';
    }
  }

  String get platformHint {
    switch (this) {
      case ReportType.keetaDaily:
      case ReportType.keetaMonthly:
      case ReportType.keetaShift:
        return 'keeta';
      case ReportType.ninjaShift:
        return 'ninja';
      case ReportType.amazonMonthly:
      case ReportType.amazonPayment:
        return 'amazon';
      case ReportType.noonReport:
        return 'noon';
      case ReportType.hungerStation:
        return 'hunger';
      default:
        return '';
    }
  }
}

class PerformanceRecord {
  final String id;
  final String uploadId;
  final String platformId;
  final String platformName;
  final DateTime recordDate;
  final String externalRiderId;
  final String riderName;
  final String? riderId;

  final int? totalOrders;
  final int? deliveredOrders;
  final double? deliveryOntimePct;
  final double? shiftCompliancePct;
  final double? attendanceOntimePct;
  final double? workingHours;
  final double? pickupOntimePct;
  final double? returnOntimePct;
  final double? avgDelayMin;
  final double? avgRoamingMin;
  final double? avgOfflineMin;

  final Map<String, dynamic> rawMetrics;
  final ReportType reportType;
  final DateTime createdAt;

  const PerformanceRecord({
    this.id = '',
    required this.uploadId,
    required this.platformId,
    this.platformName = '',
    required this.recordDate,
    required this.externalRiderId,
    required this.riderName,
    this.riderId,
    this.totalOrders,
    this.deliveredOrders,
    this.deliveryOntimePct,
    this.shiftCompliancePct,
    this.attendanceOntimePct,
    this.workingHours,
    this.pickupOntimePct,
    this.returnOntimePct,
    this.avgDelayMin,
    this.avgRoamingMin,
    this.avgOfflineMin,
    this.rawMetrics = const {},
    this.reportType = ReportType.unknown,
    required this.createdAt,
  });

  factory PerformanceRecord.create({
    required String uploadId,
    required String platformId,
    required DateTime recordDate,
    required String externalRiderId,
    required String riderName,
    String? riderId,
    int? totalOrders,
    int? deliveredOrders,
    double? deliveryOntimePct,
    double? shiftCompliancePct,
    double? attendanceOntimePct,
    double? workingHours,
    double? pickupOntimePct,
    double? returnOntimePct,
    double? avgDelayMin,
    double? avgRoamingMin,
    double? avgOfflineMin,
    Map<String, dynamic> rawMetrics = const {},
    ReportType reportType = ReportType.unknown,
  }) {
    return PerformanceRecord(
      uploadId: uploadId,
      platformId: platformId,
      recordDate: recordDate,
      externalRiderId: externalRiderId,
      riderName: riderName,
      riderId: riderId,
      totalOrders: totalOrders,
      deliveredOrders: deliveredOrders,
      deliveryOntimePct: deliveryOntimePct,
      shiftCompliancePct: shiftCompliancePct,
      attendanceOntimePct: attendanceOntimePct,
      workingHours: workingHours,
      pickupOntimePct: pickupOntimePct,
      returnOntimePct: returnOntimePct,
      avgDelayMin: avgDelayMin,
      avgRoamingMin: avgRoamingMin,
      avgOfflineMin: avgOfflineMin,
      rawMetrics: rawMetrics,
      reportType: reportType,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertJson() => {
    'upload_id': uploadId,
    'platform_id': platformId,
    'record_date': recordDate.toIso8601String().split('T')[0],
    'external_rider_id': externalRiderId,
    'rider_name': riderName,
    if (riderId != null) 'rider_id': riderId,
    if (totalOrders != null) 'total_orders': totalOrders,
    if (deliveredOrders != null) 'delivered_orders': deliveredOrders,
    if (deliveryOntimePct != null) 'delivery_ontime_pct': deliveryOntimePct,
    if (shiftCompliancePct != null) 'shift_compliance_pct': shiftCompliancePct,
    if (attendanceOntimePct != null) 'attendance_ontime_pct': attendanceOntimePct,
    if (workingHours != null) 'working_hours': workingHours,
    if (pickupOntimePct != null) 'pickup_ontime_pct': pickupOntimePct,
    if (returnOntimePct != null) 'return_ontime_pct': returnOntimePct,
    if (avgDelayMin != null) 'avg_delay_min': avgDelayMin,
    if (avgRoamingMin != null) 'avg_roaming_min': avgRoamingMin,
    if (avgOfflineMin != null) 'avg_offline_min': avgOfflineMin,
    'raw_metrics': rawMetrics,
    'report_type': reportType.name,
  };

  factory PerformanceRecord.fromJson(Map<String, dynamic> json) {
    return PerformanceRecord(
      id: json['id'] as String? ?? '',
      uploadId: json['upload_id'] as String? ?? '',
      platformId: json['platform_id'] as String? ?? '',
      platformName: (json['platforms'] as Map?)?['name'] as String? ?? '',
      recordDate: json['record_date'] != null
          ? DateTime.tryParse(json['record_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      externalRiderId: json['external_rider_id'] as String? ?? '',
      riderName: json['rider_name'] as String? ?? '',
      riderId: json['rider_id'] as String?,
      totalOrders: json['total_orders'] as int?,
      deliveredOrders: json['delivered_orders'] as int?,
      deliveryOntimePct: (json['delivery_ontime_pct'] as num?)?.toDouble(),
      shiftCompliancePct: (json['shift_compliance_pct'] as num?)?.toDouble(),
      attendanceOntimePct: (json['attendance_ontime_pct'] as num?)?.toDouble(),
      workingHours: (json['working_hours'] as num?)?.toDouble(),
      pickupOntimePct: (json['pickup_ontime_pct'] as num?)?.toDouble(),
      returnOntimePct: (json['return_ontime_pct'] as num?)?.toDouble(),
      avgDelayMin: (json['avg_delay_min'] as num?)?.toDouble(),
      avgRoamingMin: (json['avg_roaming_min'] as num?)?.toDouble(),
      avgOfflineMin: (json['avg_offline_min'] as num?)?.toDouble(),
      rawMetrics: (json['raw_metrics'] as Map<String, dynamic>?) ?? {},
      reportType: ReportType.values.firstWhere(
        (e) => e.name == json['report_type'],
        orElse: () => ReportType.unknown,
      ),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ShiftRecord {
  final String id;
  final String uploadId;
  final String platformId;
  final DateTime recordDate;
  final String shiftSlot;
  final String area;
  final int targetCount;
  final int? maxCount;
  final int? actualCount;
  final String externalRiderId;
  final String riderName;
  final String? riderId;

  const ShiftRecord({
    this.id = '',
    required this.uploadId,
    required this.platformId,
    required this.recordDate,
    this.shiftSlot = '',
    this.area = '',
    this.targetCount = 0,
    this.maxCount,
    this.actualCount,
    this.externalRiderId = '',
    this.riderName = '',
    this.riderId,
  });

  Map<String, dynamic> toInsertJson() => {
    'upload_id': uploadId,
    'platform_id': platformId,
    'record_date': recordDate.toIso8601String().split('T')[0],
    'shift_slot': shiftSlot,
    'area': area,
    'target_count': targetCount,
    if (maxCount != null) 'max_count': maxCount,
    if (actualCount != null) 'actual_count': actualCount,
    'external_rider_id': externalRiderId,
    'rider_name': riderName,
    if (riderId != null) 'rider_id': riderId,
  };

  factory ShiftRecord.fromJson(Map<String, dynamic> json) {
    return ShiftRecord(
      id: json['id'] as String? ?? '',
      uploadId: json['upload_id'] as String? ?? '',
      platformId: json['platform_id'] as String? ?? '',
      recordDate: json['record_date'] != null
          ? DateTime.tryParse(json['record_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      shiftSlot: json['shift_slot'] as String? ?? '',
      area: json['area'] as String? ?? '',
      targetCount: json['target_count'] as int? ?? 0,
      maxCount: json['max_count'] as int?,
      actualCount: json['actual_count'] as int?,
      externalRiderId: json['external_rider_id'] as String? ?? '',
      riderName: json['rider_name'] as String? ?? '',
      riderId: json['rider_id'] as String?,
    );
  }
}
