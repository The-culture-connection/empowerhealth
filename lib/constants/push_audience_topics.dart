/// FCM topic names for admin “Compose a Message” audiences.
/// Must match [SEGMENT_TO_FCM_TOPIC] in admindash Cloud Functions (`notificationDashboard.ts`).
class PushAudienceTopics {
  PushAudienceTopics._();

  static const general = 'empower_general';

  static const trimesterFirst = 'empower_trimester_first';
  static const trimesterSecond = 'empower_trimester_second';
  static const trimesterThird = 'empower_trimester_third';
  static const postpartum = 'empower_postpartum';

  static const cohortNavigator = 'empower_cohort_navigator';
  static const cohortSelfDirected = 'empower_cohort_self_directed';

  /// All audience topics the app manages (not `community_new_posts`).
  static List<String> allManagedAudienceTopics() => [
        general,
        trimesterFirst,
        trimesterSecond,
        trimesterThird,
        postpartum,
        cohortNavigator,
        cohortSelfDirected,
      ];
}
