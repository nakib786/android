class CraRates {
  // Official 2026 rates (effective January 1, 2026)
  
  // Provincial rates (AB, BC, MB, NB, NL, NS, ON, PE, QC, SK)
  static const double provincialTier1 = 0.73; // First 5,000 km
  static const double provincialTier2 = 0.67; // After 5,000 km
  
  // Territory rates (NT, YT, NU)
  static const double territoryTier1 = 0.77; // First 5,000 km
  static const double territoryTier2 = 0.71; // After 5,000 km
  
  // Other rates
  static const double medicalMovingRate = 0.21;
  static const double charityVolunteerRate = 0.14;
  
  // Threshold
  static const int kmThreshold = 5000;
  
  // Tax Year
  static const int taxYear = 2026;
}
