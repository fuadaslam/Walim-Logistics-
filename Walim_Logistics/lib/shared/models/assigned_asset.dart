class AssignedAsset {
  final String assignmentId;
  final String profileId;
  final String assetId;
  final String assetName;
  final String? assetCategory;
  final String? assetSerialNumber;
  final String assetStatus;
  final String? conditionOnAssign;
  final String? assignedByName;
  final DateTime? assignedAt;

  AssignedAsset({
    required this.assignmentId,
    required this.profileId,
    required this.assetId,
    required this.assetName,
    this.assetCategory,
    this.assetSerialNumber,
    this.assetStatus = 'assigned',
    this.conditionOnAssign,
    this.assignedByName,
    this.assignedAt,
  });

  factory AssignedAsset.fromJson(Map<String, dynamic> json) {
    // Supports both flat (profile_active_assets view) and nested (assets!inner join) formats
    final nested = json['assets'];
    final isNested = nested is Map<String, dynamic>;

    return AssignedAsset(
      assignmentId: (json['assignment_id'] ?? json['id'] ?? '') as String,
      profileId: json['profile_id'] as String,
      assetId: isNested ? (nested['id'] as String) : (json['asset_id'] as String),
      assetName: isNested ? (nested['name'] as String) : (json['asset_name'] as String),
      assetCategory: isNested ? nested['category'] as String? : json['asset_category'] as String?,
      assetSerialNumber: isNested ? nested['serial_number'] as String? : json['asset_serial_number'] as String?,
      assetStatus: isNested
          ? (nested['status'] as String? ?? 'assigned')
          : (json['asset_status'] as String? ?? 'assigned'),
      conditionOnAssign: json['condition_on_assign'] as String?,
      assignedByName: json['assigned_by_name'] as String?,
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'] as String)
          : null,
    );
  }
}
