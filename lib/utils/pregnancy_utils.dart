class PregnancyUtils {
  /// Calculate current trimester based on due date
  static String calculateTrimester(DateTime? dueDate) {
    if (dueDate == null) return 'First';
    
    final now = DateTime.now();
    final daysUntilDue = dueDate.difference(now).inDays;
    final weeksPregnant = 40 - (daysUntilDue / 7).floor();
    
    if (weeksPregnant <= 0) return 'First';
    if (weeksPregnant <= 13) return 'First';
    if (weeksPregnant <= 27) return 'Second';
    return 'Third';
  }

  /// Calculate weeks pregnant based on due date
  static int calculateWeeksPregnant(DateTime? dueDate) {
    if (dueDate == null) return 0;
    
    final now = DateTime.now();
    final daysUntilDue = dueDate.difference(now).inDays;
    final weeksPregnant = 40 - (daysUntilDue / 7).floor();
    
    return weeksPregnant > 0 ? weeksPregnant : 0;
  }

  /// Get trimester-specific information
  static String getTrimesterInfo(String trimester) {
    switch (trimester) {
      case 'First':
        return 'Weeks 1-13';
      case 'Second':
        return 'Weeks 14-27';
      case 'Third':
        return 'Weeks 28-40';
      default:
        return '';
    }
  }

  /// Display title for journey card (matches NewUI trimester headings)
  static String trimesterDisplayTitle(String trimester) {
    switch (trimester) {
      case 'First':
        return 'First trimester';
      case 'Second':
        return 'Second trimester';
      case 'Third':
        return 'Third trimester';
      default:
        return 'Your pregnancy journey';
    }
  }

  /// Supportive trimester message for home journey card (NewUI-style copy)
  static String trimesterSupportMessage(String trimester) {
    switch (trimester) {
      case 'First':
        return 'You’re taking this one step at a time. Rest when you can and reach out when you need support.';
      case 'Second':
        return 'You’re doing beautifully. This is a time of steady growth and settling in.';
      case 'Third':
        return 'You’re so strong. These weeks are about preparing to meet your baby—with support all around you.';
      default:
        return 'You’re supported every step of the way.';
    }
  }

  /// Check if pregnancy is high-risk based on conditions
  /// Body changes copy for the pregnancy journey screen (trimester-level).
  static List<String> trimesterBodyFeelings(String trimester) {
    switch (trimester) {
      case 'First':
        return [
          '**Nausea or food aversions** are common early on. Small meals and hydration can help.',
          '**Fatigue** is normal—your body is doing a lot of growing work.',
          '**Breast tenderness** often shows up as hormones shift.',
          '**Mood shifts** happen; reaching out for support is a strength, not a weakness.',
        ];
      case 'Second':
        return [
          '**Your belly is growing.** Your bump may be more visible and you might feel movement more regularly.',
          '**You might have more energy** than in the first trimester.',
          '**Back or hip discomfort** is common as your body adjusts.',
          '**Skin changes** like dryness or stretch marks can appear—that’s typical for many people.',
        ];
      case 'Third':
        return [
          '**Baby is gaining weight**—you may feel heavier and more tired.',
          '**Braxton-Hicks contractions** can feel like practice tightening; your care team can help you tell them apart from labor.',
          '**Shortness of breath** or heartburn can show up as baby presses upward.',
          '**Swelling in feet or hands** can happen—mention sudden or severe swelling to your provider.',
        ];
      default:
        return [
          'Every week is different. Notice what you feel and share questions with your care team.',
        ];
    }
  }

  static List<String> trimesterBodyHelp(String trimester) {
    switch (trimester) {
      case 'First':
        return [
          'Rest when you can and ask for help with meals or chores.',
          'Keep prenatal visits—even quick check-ins matter.',
          'Gentle walks or stretching may help if your provider says they’re okay for you.',
        ];
      case 'Second':
        return [
          'Rest when you can and ask for help when you need it.',
          'Gentle stretches or prenatal yoga can ease back discomfort.',
          'Stay hydrated and moisturize your skin if it feels dry.',
        ];
      case 'Third':
        return [
          'Side-lying rest and pillows between knees can ease pressure.',
          'Light movement, if cleared by your provider, can help circulation.',
          'Pack your bag and line up support for early labor when you’re ready.',
        ];
      default:
        return ['Your care team is there for questions—no concern is too small.'];
    }
  }

  static List<String> trimesterBabyDevelopment(String trimester) {
    switch (trimester) {
      case 'First':
        return [
          '**Major organs and structures** are forming—this is a time of rapid, foundational growth.',
          '**The neural tube** (future brain and spine) develops early—folic acid and prenatal care support this process.',
          '**Heartbeat** may be detectable on ultrasound in later first-trimester visits.',
        ];
      case 'Second':
        return [
          '**Lungs are developing**—baby practices breathing movements with amniotic fluid.',
          '**Hearing improves**—your baby may respond to your voice or familiar sounds.',
          '**Taste buds form**—flavors from your meals reach the amniotic fluid.',
          '**The brain grows quickly** as connections form for movement and sensing.',
        ];
      case 'Third':
        return [
          '**Lungs mature** toward readiness for breathing air after birth.',
          '**Baby stores fat** for warmth and energy after delivery.',
          '**Movement patterns** may feel more like rolls or stretches as space gets cozy.',
          '**Brain growth continues**—early bonding and voice help support development.',
        ];
      default:
        return ['Your provider can share what they’re watching for at your stage.'];
    }
  }

  /// Friendly size hint — not medical measurement; for encouragement only.
  static String trimesterBabySizeHint(String trimester, int week) {
    if (week <= 0) {
      return 'Your baby is growing on their own timeline. Your care team tracks what matters clinically.';
    }
    switch (trimester) {
      case 'First':
        if (week <= 8) return 'About the size of a raspberry—tiny and mighty.';
        if (week <= 12) return 'About the size of a lime—lots of growth happening fast.';
        return 'Moving into the second trimester—steady growth ahead.';
      case 'Second':
        if (week <= 20) return 'About the size of a banana—movement may start to feel real.';
        if (week <= 28) return 'About the size of an eggplant—sounds and movement are picking up.';
        return 'Growing strong—your provider tracks length and weight at visits.';
      case 'Third':
        if (week <= 34) return 'About the size of a pineapple—baby is plumping up for birth.';
        return 'Nearing full term—baby is putting finishing touches on lungs and brain.';
      default:
        return 'Every pregnancy grows at its own pace.';
    }
  }

  static bool isHighRisk(List<String> chronicConditions) {
    const highRiskConditions = [
      'Diabetes',
      'Hypertension',
      'Heart Disease',
      'Kidney Disease',
      'Autoimmune Disease',
      'Blood Clotting Disorder',
    ];

    for (var condition in chronicConditions) {
      if (highRiskConditions.any((risk) => 
        condition.toLowerCase().contains(risk.toLowerCase()))) {
        return true;
      }
    }
    return false;
  }
}

