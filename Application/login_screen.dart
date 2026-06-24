class UserProfile {
  final String? id;
  final String name;
  final int? age;
  final String? gender;
  final double? height;
  final double? weight;
  final List<String> chronicIllnesses;
  final bool? familyCvdHistory;
  final int? familyCvdAge;
  final bool? smoking;
  final String? caffeine;
  final String? activityLevel;
  final bool? exerciseFrequency;
  final String? stressLevel;
  final String? sleepQuality;
  final List<String> baselineSymptoms;
  final String? dailyActivity;
  final String? patchPlacement;
  final bool? consentGiven;
  final bool onboardingComplete;
  final bool? patchActivated;

  const UserProfile({
    this.id,
    required this.name,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.chronicIllnesses = const [],
    this.familyCvdHistory,
    this.familyCvdAge,
    this.smoking,
    this.caffeine,
    this.activityLevel,
    this.exerciseFrequency,
    this.stressLevel,
    this.sleepQuality,
    this.baselineSymptoms = const [],
    this.dailyActivity,
    this.patchPlacement,
    this.consentGiven,
    this.onboardingComplete = false,
    this.patchActivated,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'],
    name: json['name'] ?? '',
    age: json['age'],
    gender: json['gender'],
    height: (json['height'] as num?)?.toDouble(),
    weight: (json['weight'] as num?)?.toDouble(),
    chronicIllnesses: List<String>.from(json['chronic_illnesses'] ?? []),
    familyCvdHistory: json['family_cvd_history'],
    familyCvdAge: json['family_cvd_age'],
    smoking: json['smoking'],
    caffeine: json['caffeine'],
    activityLevel: json['activity_level'],
    exerciseFrequency: json['exercise_frequency'],
    stressLevel: json['stress_level'],
    sleepQuality: json['sleep_quality'],
    baselineSymptoms: List<String>.from(json['baseline_symptoms'] ?? []),
    dailyActivity: json['daily_activity'],
    patchPlacement: json['patch_placement'],
    consentGiven: json['consent_given'],
    onboardingComplete: json['onboarding_complete'] ?? false,
    patchActivated: json['patch_activated'],
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'gender': gender,
    'height': height,
    'weight': weight,
    'chronic_illnesses': chronicIllnesses,
    'family_cvd_history': familyCvdHistory,
    'family_cvd_age': familyCvdAge,
    'smoking': smoking,
    'caffeine': caffeine,
    'activity_level': activityLevel,
    'exercise_frequency': exerciseFrequency,
    'stress_level': stressLevel,
    'sleep_quality': sleepQuality,
    'baseline_symptoms': baselineSymptoms,
    'daily_activity': dailyActivity,
    'patch_placement': patchPlacement,
    'consent_given': consentGiven,
    'onboarding_complete': onboardingComplete,
    'patch_activated': patchActivated,
  };
}
