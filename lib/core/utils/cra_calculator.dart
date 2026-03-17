import '../constants/cra_rates.dart';
import '../constants/provinces.dart';

class CraCalculator {
  static double calculateDeduction({
    required double distanceKm,
    required double cumulativeYearlyKm,
    required CanadaProvince province,
    required String category,
  }) {
    if (category == 'Personal') return 0.0;

    if (category == 'Medical' || category == 'Moving') {
      return distanceKm * CraRates.medicalMovingRate;
    }

    if (category == 'Charity' || category == 'Volunteer') {
      return distanceKm * CraRates.charityVolunteerRate;
    }

    // Business category
    final isTerritory = province.isTerritory;
    final tier1Rate = isTerritory ? CraRates.territoryTier1 : CraRates.provincialTier1;
    final tier2Rate = isTerritory ? CraRates.territoryTier2 : CraRates.provincialTier2;
    const threshold = CraRates.kmThreshold;

    if (cumulativeYearlyKm >= threshold) {
      return distanceKm * tier2Rate;
    } else if (cumulativeYearlyKm + distanceKm <= threshold) {
      return distanceKm * tier1Rate;
    } else {
      // Split trip
      final tier1Km = threshold - cumulativeYearlyKm;
      final tier2Km = distanceKm - tier1Km;
      return (tier1Km * tier1Rate) + (tier2Km * tier2Rate);
    }
  }

  static double calculateBusinessUsePercentage(double businessKm, double totalKm) {
    if (totalKm == 0) return 0.0;
    return (businessKm / totalKm) * 100;
  }
}
