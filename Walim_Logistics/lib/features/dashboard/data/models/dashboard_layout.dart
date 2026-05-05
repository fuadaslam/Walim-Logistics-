import 'dart:convert';

enum DashboardSection {
  metrics,
  actions,
  activity,
  compliance,
  performance,
}

class DashboardLayout {
  final List<DashboardSection> sections;
  final List<DashboardSection> hiddenSections;

  DashboardLayout({
    required this.sections,
    this.hiddenSections = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'sections': sections.map((x) => x.name).toList(),
      'hiddenSections': hiddenSections.map((x) => x.name).toList(),
    };
  }

  factory DashboardLayout.fromMap(Map<String, dynamic> map) {
    return DashboardLayout(
      sections: List<DashboardSection>.from(
        (map['sections'] as List).map((x) => DashboardSection.values.byName(x)),
      ),
      hiddenSections: List<DashboardSection>.from(
        (map['hiddenSections'] as List? ?? []).map((x) => DashboardSection.values.byName(x)),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory DashboardLayout.fromJson(String source) =>
      DashboardLayout.fromMap(json.decode(source));

  DashboardLayout copyWith({
    List<DashboardSection>? sections,
    List<DashboardSection>? hiddenSections,
  }) {
    return DashboardLayout(
      sections: sections ?? this.sections,
      hiddenSections: hiddenSections ?? this.hiddenSections,
    );
  }

  static DashboardLayout defaultLayout(String role) {
    switch (role) {
      case 'Admin':
      case 'Operations Manager':
        return DashboardLayout(sections: [
          DashboardSection.metrics,
          DashboardSection.actions,
          DashboardSection.activity,
        ]);
      case 'HR':
        return DashboardLayout(sections: [
          DashboardSection.metrics,
          DashboardSection.actions,
          DashboardSection.compliance,
          DashboardSection.activity,
        ]);
      case 'Business Development':
        return DashboardLayout(sections: [
          DashboardSection.metrics,
          DashboardSection.actions,
          DashboardSection.performance,
        ]);
      case 'IT_Dev':
        return DashboardLayout(sections: [
          DashboardSection.metrics,
          DashboardSection.actions,
          DashboardSection.activity,
        ]);
      case 'Supervisor':
        return DashboardLayout(sections: [
          DashboardSection.metrics,
          DashboardSection.actions,
          DashboardSection.activity,
        ]);
      default:
        return DashboardLayout(sections: [
          DashboardSection.metrics,
          DashboardSection.actions,
        ]);
    }
  }
}
