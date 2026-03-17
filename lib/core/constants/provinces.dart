enum CanadaProvince {
  ab('Alberta', 'AB', false),
  bc('British Columbia', 'BC', false),
  mb('Manitoba', 'MB', false),
  nb('New Brunswick', 'NB', false),
  nl('Newfoundland and Labrador', 'NL', false),
  ns('Nova Scotia', 'NS', false),
  nt('Northwest Territories', 'NT', true),
  nu('Nunavut', 'NU', true),
  on('Ontario', 'ON', false),
  pe('Prince Edward Island', 'PE', false),
  qc('Quebec', 'QC', false),
  sk('Saskatchewan', 'SK', false),
  yt('Yukon', 'YT', true);

  final String name;
  final String code;
  final bool isTerritory;

  const CanadaProvince(this.name, this.code, this.isTerritory);

  static CanadaProvince fromCode(String code) {
    return CanadaProvince.values.firstWhere(
      (p) => p.code == code,
      orElse: () => CanadaProvince.on,
    );
  }
}
