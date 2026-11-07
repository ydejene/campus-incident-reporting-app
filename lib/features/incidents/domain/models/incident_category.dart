enum IncidentCategory {
  facilities('facilities', 'Facilities'),
  waterSupply('water_supply', 'Water Supply'),
  electricity('electricity', 'Electricity'),
  sanitation('sanitation', 'Sanitation'),
  internetTechnology('internet_technology', 'Internet & Technology'),
  safetySecurity('safety_security', 'Safety & Security'),
  other('other', 'Other');

  const IncidentCategory(this.value, this.label);

  final String value;
  final String label;

  static IncidentCategory fromString(String? value) {
    return IncidentCategory.values.firstWhere(
      (cat) => cat.value == value || cat.name == value,
      orElse: () => IncidentCategory.other,
    );
  }
}

