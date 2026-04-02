/// Provider search UI + API shared strings.
class ProviderSearchConstants {
  ProviderSearchConstants._();

  /// Shown in the health plan list; [normalizeHealthPlanName] in Cloud Functions maps this to CareSource for the Ohio directory.
  static const String healthPlanNotListed = 'Not listed / not sure';

  /// Quick / broad directory search — backend maps to a general Medicaid plan.
  static const String healthPlanAll = 'All plans';
}
