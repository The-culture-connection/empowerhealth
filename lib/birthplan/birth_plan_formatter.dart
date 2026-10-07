import 'package:intl/intl.dart';
import '../models/birth_plan.dart';

/// Turns a [BirthPlan] into the plain-text plan shown on screen and in the
/// downloaded PDF. Every field the birth plan builder collects is written out
/// here so nothing a person recorded is lost in the shared copy.
class BirthPlanFormatter {
  String format(BirthPlan plan) {
    final buffer = StringBuffer();

    void line(String label, String? value) {
      final v = value?.trim();
      if (v != null && v.isNotEmpty) buffer.writeln('$label: $v');
    }

    void list(String label, List<String> values) {
      final cleaned =
          values.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (cleaned.isNotEmpty) buffer.writeln('$label: ${cleaned.join(', ')}');
    }

    void yesNo(String label, bool? value) {
      if (value != null) buffer.writeln('$label: ${value ? 'Yes' : 'No'}');
    }

    void ifTrue(bool? value, String text) {
      if (value == true) buffer.writeln(text);
    }

    // Header
    buffer.writeln('BIRTH PLAN\n');
    line('Name', plan.fullName);
    if (plan.dueDate != null) {
      buffer.writeln(
          'Due Date: ${DateFormat('MMMM d, yyyy').format(plan.dueDate!)}');
    }
    if (plan.supportPersonName != null &&
        plan.supportPersonName!.trim().isNotEmpty) {
      final relationship = plan.supportPersonRelationship != null &&
              plan.supportPersonRelationship!.trim().isNotEmpty
          ? ' (${plan.supportPersonRelationship!.trim()})'
          : '';
      buffer.writeln(
          'Support Person(s): ${plan.supportPersonName!.trim()}$relationship');
    }
    line('Best phone number', plan.emergencyContact);
    line('Provider', plan.providerName);
    line('Preferred hospital', plan.preferredHospital);
    if (plan.doulaName != null && plan.doulaName!.trim().isNotEmpty) {
      line('Doula', plan.doulaName);
    } else if (plan.useDoula) {
      buffer.writeln('Doula or birth coach: Yes');
    }
    line('Language I want care in', plan.preferredLanguage);
    list('Allergies', plan.allergies);
    list('Ongoing health conditions', plan.medicalConditions);
    list('Pregnancy complications', plan.pregnancyComplications);
    list('Chronic health conditions', plan.chronicHealthConditions);
    list('Medications', plan.medications);
    buffer.writeln();

    // Section 1: Labor Preferences
    buffer.writeln('1. My Labor Preferences');
    list('My birth space', plan.environmentPreferences);
    line('Lighting preference', plan.lightingPreference);
    line('Noise preference', plan.noisePreference);
    yesNo('Visitors during labor', plan.visitorsAllowed);
    yesNo('Photos during labor or birth', plan.photographyAllowed);
    yesNo('Video during labor or birth', plan.videographyAllowed);
    ifTrue(plan.traumaInformedCare,
        'Please ask before touch or exams');
    list('Positions that sound good for labor', plan.preferredLaborPositions);
    list('Comfort measures', plan.naturalComfortMeasures);
    if (plan.movementFreedom) {
      buffer.writeln('I want to move freely during labor');
    }
    if (plan.monitoringPreference != null) {
      buffer.writeln(
          'Preferred monitoring: ${plan.monitoringPreference!.toLowerCase()} if medically appropriate');
    }
    line('Pain relief preference', plan.painManagementPreference);
    line('When to offer pain medication', plan.whenToOfferPainMedication);
    line('IV fluids', plan.ivFluidsPreference);
    ifTrue(plan.waterLaborAvailable,
        'I would like to labor in water if available');
    line('Membrane sweep', plan.augmentationPreference);
    line('If labor needs help starting', plan.inductionMethodsPreference);
    line('Vaginal exams', plan.vaginalExamsPreference);
    line('Breaking my water', plan.membraneRupturePreference);
    line('How I like updates and decisions explained',
        plan.communicationStyle);
    buffer.writeln();

    // Section 2: Pushing & Delivery
    buffer.writeln('2. Pushing & Delivery');
    list('Preferred pushing positions', plan.preferredPushingPositions);
    line('Guidance while pushing', plan.coachingStyle);
    ifTrue(plan.mirrorDuringPushing, 'I would like a mirror to see baby crown');
    ifTrue(plan.seeTouchBabyHeadDuringCrowning,
        "I would like to touch baby's head during crowning");
    ifTrue(plan.delayedPushingWithEpidural,
        'With an epidural, I would like to wait to push until I feel the urge');
    line('Episiotomy', plan.episiotomyPreference);
    line('Support while stretching', plan.perinealSupportPreference);
    line('Assisted delivery (vacuum/forceps)', plan.vacuumForcepsPreference);
    line('Who receives baby', plan.whoCatchesBaby);
    buffer.writeln();

    // Section 3: Immediate Newborn Care
    buffer.writeln('3. Immediate Newborn Care');
    line('Delayed cord clamping', plan.delayedCordClampingPreference);
    line('Cord clamping timing', plan.cordCuttingPreference);
    line('Who cuts the cord', plan.whoCutsCord);
    if (plan.immediateSkinToSkin) {
      buffer.writeln('Immediate skin-to-skin unless baby requires medical care');
    }
    ifTrue(plan.delayedNewbornProcedures,
        'Keep baby with me for newborn checks when possible');
    buffer.writeln('Newborn procedures:');
    buffer.writeln('Vitamin K: ${_yesNoUnset(plan.vitaminK)}');
    buffer.writeln('Antibiotic eye ointment: ${_yesNoUnset(plan.eyeOintment)}');
    buffer.writeln('Hep B vaccine: ${_yesNoUnset(plan.hepBVaccine)}');
    if (plan.cordBloodBanking == true) {
      final company = plan.cordBloodCompany?.trim() ?? '';
      buffer.writeln(
          'Save cord blood for banking${company.isNotEmpty ? ' ($company)' : ''}');
    }
    line('Placenta', plan.placentaPreference);
    line('If baby needs the NICU', plan.nicuTransferInstructions);
    final hasFeeding = plan.feedingPreference != null ||
        plan.lactationConsultantRequested ||
        plan.noPacifierUntilBreastfeeding == true ||
        plan.consentForDonorMilk == true;
    if (hasFeeding) {
      buffer.writeln();
      buffer.writeln('Feeding preference:');
      if (plan.feedingPreference != null) {
        buffer.writeln(plan.feedingPreference!);
      }
      if (plan.lactationConsultantRequested) {
        buffer.writeln('Lactation consultant requested');
      }
      ifTrue(plan.noPacifierUntilBreastfeeding,
          'Please wait on pacifiers until feeding is going well');
      ifTrue(plan.consentForDonorMilk,
          'Okay with donor breast milk if medically needed');
    }
    buffer.writeln();

    // Section 4: Postpartum Care
    buffer.writeln('4. Postpartum Care');
    if (plan.roomingIn != null) {
      buffer.writeln('Baby rooming-in: ${plan.roomingIn == true ? 'Yes' : 'No'}');
    }
    ifTrue(plan.mentalHealthScreeningPreference,
        'Please check in for mental health support if I seem overwhelmed');
    ifTrue(plan.socialWorkConsultIfNeeded, 'Social work consult if needed');
    line('Visitors after birth', plan.visitorsAfterBirth);
    line('Food needs or restrictions', plan.dietaryPreferences);
    line('Pain control plan', plan.postpartumPainControlPlan);
    buffer.writeln();

    // Section 5: Cesarean Birth Preferences
    buffer.writeln('5. Cesarean Birth Preferences (Planned or Emergency)');
    buffer.writeln(
        '(This section should still be included even if planning a vaginal birth.)');
    line('Cesarean preference', plan.cesareanPreference);
    if (plan.cesareanDrapePreference != null) {
      if (plan.cesareanDrapePreference!.toLowerCase().contains('clear')) {
        buffer.writeln('Clear drape if available (to watch baby born)');
      } else {
        line('Surgical drape', plan.cesareanDrapePreference);
      }
    }
    if (plan.supportPersonInOR != null) {
      buffer.writeln(plan.supportPersonInOR!
          ? 'Support person present in OR'
          : 'Support person in OR: No');
    }
    yesNo('Photos in the operating room', plan.photosAllowedInOR);
    ifTrue(plan.immediateSkinToSkinInOR,
        'Baby placed on chest immediately if safe');
    ifTrue(plan.delayNewbornCareUntilHolding,
        "Delay routine newborn tasks until I'm holding baby");
    ifTrue(plan.gentleCesarean, 'Gentle / family-centered cesarean');
    ifTrue(plan.musicAllowedInOR, 'Music in the operating room');
    ifTrue(plan.delayCordClampingInCesarean,
        'Delayed cord clamping, even in C-section, if possible');
    ifTrue(plan.partnerCutsCordInCesarean, 'Partner cuts the cord in OR');
    ifTrue(plan.goldenHourHonoredIfStable,
        'Honor the golden hour if baby and I are stable');
    line('Anesthesia for surgery', plan.anesthesiaPreference);
    line('Incision closure', plan.surgicalClosurePreference);
    buffer.writeln();

    // Section 6: Special Considerations
    buffer.writeln('6. Special Considerations');
    line('Faith or spiritual practices', plan.culturalReligiousRituals);
    line('Cultural traditions', plan.culturalConsiderations);
    line('Accessibility or mobility needs', plan.accessibilityNeeds);
    line('Past trauma', plan.pastBirthTraumaOrComplications);
    line('Trauma-informed care notes', plan.traumaInformedCareNotes);
    line('Communication preference', plan.preferredCommunicationStyle);
    line('Provider gender preference', plan.genderPreferenceForProviders);
    line('Bias concerns', plan.racialBiasConcerns);
    line('Stop word or phrase', plan.stopWordOrPhrase);
    line('Advocacy preferences', plan.advocacyPreferences);
    line('High-risk pregnancy notes', plan.highRiskPregnancyNotes);
    list('Things that make anxiety worse', plan.anxietyTriggers);
    if (plan.consentBasedCare) {
      buffer.writeln('Please ask me before procedures or exams');
    }
    line('How I prefer hard news to be shared', plan.preferredBadNewsDelivery);
    list('What helps me feel calmer under stress', plan.fearReductionRequests);
    buffer.writeln();

    // Section 7: In My Own Words
    if (plan.inMyOwnWords != null && plan.inMyOwnWords!.trim().isNotEmpty) {
      buffer.writeln('7. In My Own Words');
      buffer.writeln('"${plan.inMyOwnWords!.trim()}"');
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _yesNoUnset(bool? value) =>
      value == true ? 'Yes' : value == false ? 'No' : 'Not specified';
}
