import 'package:intl/intl.dart';
import '../models/birth_plan.dart';

class BirthPlanFormatter {
  String format(BirthPlan plan) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('BIRTH PLAN\n');
    buffer.writeln('Name: ${plan.fullName}');
    if (plan.dueDate != null) {
      buffer.writeln('Due Date: ${DateFormat('MMMM d, yyyy').format(plan.dueDate!)}');
    }
    if (plan.supportPersonName != null) {
      final relationship = plan.supportPersonRelationship != null 
          ? ' (${plan.supportPersonRelationship})'
          : '';
      buffer.writeln('Support Person(s): ${plan.supportPersonName}$relationship');
    }
    if (plan.providerName != null) {
      buffer.writeln('Provider: ${plan.providerName}');
    }
    if (plan.allergies.isNotEmpty) {
      buffer.writeln('Allergies: ${plan.allergies.join(', ')}');
    }
    buffer.writeln();
    
    // Section 1: Labor Preferences
    buffer.writeln('1. My Labor Preferences');
    if (plan.environmentPreferences.isNotEmpty) {
      buffer.writeln('I prefer ${plan.environmentPreferences.join(', ').toLowerCase()}');
    }
    if (plan.movementFreedom) {
      buffer.writeln('I want to move freely during labor');
    }
    if (plan.monitoringPreference != null) {
      buffer.writeln('Preferred monitoring: ${plan.monitoringPreference!.toLowerCase()} if medically appropriate');
    }
    if (plan.painManagementPreference != null) {
      buffer.writeln('Pain management preference:');
      final painOptions = ['Unmedicated', 'Epidural', 'Nitrous oxide', 'IV pain meds', 'Comfort measures only'];
      for (final option in painOptions) {
        final isSelected = plan.painManagementPreference == option;
        buffer.writeln('${isSelected ? '☑' : '☐'} $option${isSelected ? ' (my preference)' : ''}');
      }
    }
    if (plan.membraneSweepingPreference != null) {
      buffer.writeln('I prefer ${plan.membraneSweepingPreference!.toLowerCase()} unless medically indicated');
    }
    if (plan.traumaInformedCare || plan.communicationStyle != null) {
      buffer.writeln('I want everything explained before exams or procedures');
    }
    buffer.writeln();
    
    // Section 2: Pushing & Delivery
    buffer.writeln('2. Pushing & Delivery');
    if (plan.pushingStyle != null) {
      buffer.writeln('Pushing preference: ${plan.pushingStyle!.toLowerCase()} pushing unless guidance needed');
    }
    if (plan.preferredPushingPositions.isNotEmpty) {
      buffer.writeln('Preferred positions: ${plan.preferredPushingPositions.join(', ').toLowerCase()}');
    }
    if (plan.episiotomyPreference != null) {
      buffer.writeln('Please avoid episiotomy unless absolutely necessary');
    }
    if (plan.tearingPreference != null) {
      buffer.writeln('${plan.tearingPreference} preferred');
    }
    if (plan.whoCatchesBaby != null) {
      buffer.writeln('Cord cutting: ${plan.whoCatchesBaby!.toLowerCase()} would like to cut');
    }
    if (plan.delayedCordClampingPreference != null) {
      buffer.writeln('Cord clamping: delay ${plan.delayedCordClampingPreference!.toLowerCase()}');
    }
    buffer.writeln();
    
    // Section 3: Immediate Newborn Care
    buffer.writeln('3. Immediate Newborn Care');
    if (plan.immediateSkinToSkin) {
      buffer.writeln('Immediate skin-to-skin unless baby requires medical care');
    }
    buffer.writeln('Newborn procedures:');
    buffer.writeln('Vitamin K: ${plan.vitaminK == true ? 'Yes' : plan.vitaminK == false ? 'No' : 'Not specified'}');
    buffer.writeln('Eye ointment: ${plan.eyeOintment == true ? 'Yes' : plan.eyeOintment == false ? 'No (if legal in state)' : 'Not specified'}');
    buffer.writeln('Hep B vaccine: ${plan.hepBVaccine == true ? 'Yes' : plan.hepBVaccine == false ? 'No' : 'Not specified'}');
    if (plan.babyStaysWithParent) {
      buffer.writeln('Please do newborn assessments on my chest when possible');
    }
    buffer.writeln();
    buffer.writeln('Feeding preference:');
    if (plan.feedingPreference != null) {
      buffer.writeln(plan.feedingPreference!);
    }
    if (plan.noPacifierUntilBreastfeeding == true) {
      buffer.writeln('No pacifier unless discussed');
    }
    if (plan.lactationConsultantRequested) {
      buffer.writeln('Lactation consultant requested');
    }
    buffer.writeln();
    
    // Section 4: Postpartum Care
    buffer.writeln('4. Postpartum Care');
    if (plan.roomingIn != null) {
      buffer.writeln('Baby rooming-in: ${plan.roomingIn == true ? 'Yes' : 'No'}');
    }
    if (plan.visitorPreference != null) {
      buffer.writeln('Visitor preference: ${plan.visitorPreference}');
    }
    if (plan.postpartumPainManagement != null) {
      buffer.writeln('Pain management preference: ${plan.postpartumPainManagement}');
    }
    if (plan.mentalHealthSupport == true) {
      buffer.writeln('Please check in for mental health support if I seem overwhelmed');
    }
    buffer.writeln();
    
    // Section 5: Cesarean Birth Preferences
    buffer.writeln('5. Cesarean Birth Preferences (Planned or Emergency)');
    buffer.writeln('(This section should still be included even if planning a vaginal birth.)');
    if (plan.partnerInOR == true) {
      buffer.writeln('Partner present in OR');
    }
    if (plan.drapePreference == 'Clear drape') {
      buffer.writeln('Clear drape if available (to watch baby born)');
    }
    if (plan.babyOnChestImmediately == true) {
      buffer.writeln('Baby placed on chest immediately if safe');
    }
    if (plan.delayedCordClampingPreference != null) {
      buffer.writeln('Delayed cord clamping, even in C-section, if possible');
    }
    if (plan.surgicalClosurePreference != null) {
      buffer.writeln('I prefer ${plan.surgicalClosurePreference!.toLowerCase()} instead of staples');
    }
    if (plan.photosAllowedInOR == true) {
      buffer.writeln('Photos allowed unless restricted by staff');
    }
    buffer.writeln();
    
    // Section 6: Special Considerations
    buffer.writeln('6. Special Considerations');
    if (plan.traumaInformedCare) {
      buffer.writeln('Please announce before touching me');
    }
    if (plan.communicationStyle != null) {
      buffer.writeln('Please use ${plan.communicationStyle}');
    }
    if (plan.anxietyTriggers.isNotEmpty) {
      buffer.writeln('Anxiety trigger: ${plan.anxietyTriggers.join(', ')}');
    }
    if (plan.consentBasedCare) {
      buffer.writeln('I prefer shared decision-making with plain-language explanations');
    }
    buffer.writeln();
    
    // Section 7: In My Own Words
    if (plan.inMyOwnWords != null && plan.inMyOwnWords!.isNotEmpty) {
      buffer.writeln('7. In My Own Words');
      buffer.writeln('"${plan.inMyOwnWords}"');
      buffer.writeln();
    }
    
    return buffer.toString();
  }
}

