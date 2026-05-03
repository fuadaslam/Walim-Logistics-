class Inspection {
  final String id;
  final String profileId;
  final String? vehicleId;
  final String inspectionType;
  final bool isSafeToDrive;
  final Map<String, dynamic>? checklistData;
  final List<String>? photoUrls;
  final DateTime createdAt;
  final String? riderName;

  Inspection({
    required this.id,
    required this.profileId,
    this.vehicleId,
    required this.inspectionType,
    required this.isSafeToDrive,
    this.checklistData,
    this.photoUrls,
    required this.createdAt,
    this.riderName,
  });

  factory Inspection.fromJson(Map<String, dynamic> json) {
    return Inspection(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      vehicleId: json['vehicle_id'] as String?,
      inspectionType: json['inspection_type'] as String,
      isSafeToDrive: json['is_safe_to_drive'] as bool,
      checklistData: json['checklist_data'] as Map<String, dynamic>?,
      photoUrls: (json['photo_urls'] as List?)?.map((e) => e as String).toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      riderName: json['profiles']?['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'vehicle_id': vehicleId,
      'inspection_type': inspectionType,
      'is_safe_to_drive': isSafeToDrive,
      'checklist_data': checklistData,
      'photo_urls': photoUrls,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
