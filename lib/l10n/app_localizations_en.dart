// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'EstudiApp';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get seeAll => 'See all';

  @override
  String get add => 'Add';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get close => 'Close';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get newLabel => 'New';

  @override
  String get selected => 'Selected';

  @override
  String get redeem => 'Redeem';

  @override
  String get greetingMorning => 'Good morning,';

  @override
  String get greetingAfternoon => 'Good afternoon,';

  @override
  String get greetingEvening => 'Good evening,';

  @override
  String streakDays(int count) {
    return '$count day streak';
  }

  @override
  String get shieldAvailable => 'Shield available';

  @override
  String get shieldNone => 'No shield this week';

  @override
  String get startPomodoro => 'Start Pomodoro';

  @override
  String get studyWithAI => 'Study with AI';

  @override
  String get upcomingExamsTitle => 'UPCOMING EXAMS';

  @override
  String get habitsTodayTitle => 'TODAY\'S HABITS';

  @override
  String get moreFeaturesTitle => 'MORE FEATURES';

  @override
  String get signOut => 'Sign out';

  @override
  String get addExam => 'Add exam';

  @override
  String get addHabit => 'Add habit';

  @override
  String examToday(String course) {
    return 'Your $course exam is today!';
  }

  @override
  String examTomorrow(String course) {
    return 'Tomorrow: $course exam';
  }

  @override
  String examInDays(String course, int days) {
    return '$course exam in $days days';
  }

  @override
  String get tapToStudyAI => 'Tap to study with AI →';

  @override
  String get adminPanel => 'Admin Panel 👁️';

  @override
  String get batteryTitle => 'Enable notifications';

  @override
  String get batteryBody =>
      'To receive reminders, disable battery optimization for EstudiApp.\n\nSettings → Apps → EstudiApp → Disable \"Pause unused apps\"';

  @override
  String get batteryNotNow => 'Not now';

  @override
  String get batterySettings => 'Go to Settings';

  @override
  String get gridFlashcards => 'Flashcards SRS';

  @override
  String get gridMyGrades => 'My Grades';

  @override
  String get gridWellbeing => 'My Wellbeing';

  @override
  String get gridPremium => 'Premium';

  @override
  String get gridAcademy => 'My Academy';

  @override
  String get gridPdfSim => 'PDF Simulacro';

  @override
  String get gridGroups => 'Groups';

  @override
  String get gridFeynman => 'Feynman';

  @override
  String get gridRealCases => 'Real Cases';

  @override
  String get gridVirtual => 'Virtual Class';

  @override
  String get gridSimulacros => 'Simulacros';

  @override
  String get gridStreak => 'Streak';

  @override
  String get gridAchievements => 'Achievements';

  @override
  String get gridDashboard => 'Dashboard';

  @override
  String get gridStats => 'Statistics';

  @override
  String get gridRanking => 'Ranking';

  @override
  String get gridNotifications => 'Notifications';

  @override
  String get gridStore => 'Store';

  @override
  String get gridMissions => 'Missions';

  @override
  String get loginSubtitle =>
      'Organize your exams,\nbuild habits and don\'t fail';

  @override
  String get continueGoogle => 'Continue with Google';

  @override
  String get freeForever => 'Free forever · No credit card required';

  @override
  String get featureStreak => 'Daily streak';

  @override
  String get featureCourses => 'Your courses';

  @override
  String get featurePomodoro => 'Pomodoro';

  @override
  String get onb1Title => 'Build your streak';

  @override
  String get onb1Sub =>
      'Log in every day and keep your streak alive. Get reminders at 8AM, 2PM and 8PM so you never forget.';

  @override
  String get onb2Title => 'Study with AI';

  @override
  String get onb2Sub =>
      'Generate summaries, flashcards, quizzes and study plans with artificial intelligence. Also solve photos of your exercises.';

  @override
  String get onb3Title => 'Organize your studies';

  @override
  String get onb3Sub =>
      'Track your daily habits, monitor upcoming exams and generate academic documents ready to submit.';

  @override
  String get onb4Title => 'Never forget anything';

  @override
  String get onb4Sub =>
      'Enable notifications to get reminders for your habits, exam alerts and daily motivation.';

  @override
  String get getStarted => 'Get started!';

  @override
  String get offlineTitle => 'No connection — Offline mode';

  @override
  String get offlineBody => 'Showing data from last access';

  @override
  String get welcomeStudy => 'Let\'s study! 💪';

  @override
  String mot100(int racha) {
    return '$racha days unstoppable! Centurion level 🚀';
  }

  @override
  String mot30(int racha) {
    return '$racha day streak! You\'re a legend 👑';
  }

  @override
  String get mot14 => 'Two weeks straight! Habit formed ⚡';

  @override
  String get mot7 => 'A full week! You\'re on fire 🔥';

  @override
  String get mot3 => 'Keep it up! Don\'t break the streak now 💪';

  @override
  String get mot1 => 'Great start! Keep the pace ✨';

  @override
  String get mot0 => 'Today is a great day to study 📚';

  @override
  String get shieldReady => '🛡️ Shield ready';

  @override
  String get shieldEmpty => '🛡️ No shield';

  @override
  String get myProfile => 'My profile';

  @override
  String get currentStreak => 'Current streak';

  @override
  String get maxStreak => 'Max streak';

  @override
  String get activeDays => 'Active days';

  @override
  String get viewAchievements => 'View my achievements';

  @override
  String get streakHistory => 'Streak history';

  @override
  String get academicProfiles => 'Academic profiles';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeDark => '🌙 Dark';

  @override
  String get themeSystem => '⚙️ System';

  @override
  String get themeLight => '☀️ Light';

  @override
  String get darkNow => 'dark now';

  @override
  String get lightNow => 'light now';

  @override
  String get university => 'University';

  @override
  String get career => 'Major';

  @override
  String get tapToSelect => 'Tap to select';

  @override
  String get selectCareer => 'Select your major';

  @override
  String get premiumActive => 'EstudiApp Premium active';

  @override
  String get unlockPremium => 'Unlock Premium';

  @override
  String validUntilDate(int day, int month, int year) {
    return 'Valid until $day/$month/$year';
  }

  @override
  String get premiumFeaturesDesc => 'PDF simulacros, study groups and more';

  @override
  String get statsSection => 'STATISTICS';

  @override
  String get habitsLabel => 'Habits';

  @override
  String get todayLabel => 'Today';

  @override
  String get examsLabel => 'Exams';

  @override
  String get coursesLabel => 'Courses';

  @override
  String get passedLabel => 'Passed';

  @override
  String get achievementsLabel => 'Achievements';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get languageLabel => 'Language';

  @override
  String get langSpanish => '🇪🇸 Español';

  @override
  String get langEnglish => '🇺🇸 English';

  @override
  String get premiumTitle => 'EstudiApp Premium';

  @override
  String get premiumSlogan => 'All the power of learning, without limits';

  @override
  String get premiumIncludes => 'WHAT\'S INCLUDED IN PREMIUM';

  @override
  String get choosePlan => 'CHOOSE YOUR PLAN';

  @override
  String get recommended => 'RECOMMENDED';

  @override
  String get monthlyLabel => 'MONTHLY';

  @override
  String get perYear => 'per year';

  @override
  String get perMonth => 'per month';

  @override
  String get save45pct => 'SAVE 45%';

  @override
  String get tryFree => 'Try 7 days free';

  @override
  String get tryFreeSubtitle => 'No card · One time per account';

  @override
  String subscribeBtn(String price, String period) {
    return 'Subscribe — $price/$period';
  }

  @override
  String get notAvailable => 'Not available on this device';

  @override
  String get restorePurchase => 'Restore previous purchase';

  @override
  String get securePayment => 'Secure payment via Google Play · Cancel anytime';

  @override
  String get premiumSuccess => 'Premium activated successfully!';

  @override
  String get paymentPending => 'Payment pending bank confirmation...';

  @override
  String paymentError(String message) {
    return 'Payment error: $message';
  }

  @override
  String get trialSuccess =>
      '7 days Premium activated! Enjoy without limits 🎉';

  @override
  String get trialUsed => 'You\'ve already used the free trial period.';

  @override
  String get alreadyPremium => 'You already have Premium active!';

  @override
  String get billingAnnual => 'Annual billing via Google Play';

  @override
  String get billingMonthly => 'Monthly billing via Google Play';

  @override
  String activeUntilDate(int day, int month, int year) {
    return '✓ Active until $day/$month/$year';
  }

  @override
  String fromPrice(String price) {
    return 'From $price/mo · Cancel anytime';
  }

  @override
  String get compFree => 'Free';

  @override
  String get compPremium => 'Premium';

  @override
  String get compAI => 'AI Assistant';

  @override
  String get comp5day => '5/day';

  @override
  String get compUnlimited => 'Unlimited';

  @override
  String get compFlashcards => 'Flashcards SRS';

  @override
  String get compSimulacros => 'Simulacros';

  @override
  String get comp5questions => '5 questions';

  @override
  String get compPDF => 'PDF to Quiz';

  @override
  String get compGroups => 'Study groups';

  @override
  String get compTeacher => 'Teacher panel';

  @override
  String get compNoAds => 'No ads';

  @override
  String get b1Title => 'Teacher Panel';

  @override
  String get b1Desc => 'Create your academy, add students and manage exams';

  @override
  String get b2Title => 'PDF to Quiz';

  @override
  String get b2Desc =>
      'Upload real exam PDFs and AI converts them to interactive tests';

  @override
  String get b3Title => 'Study Groups';

  @override
  String get b3Desc => 'Study in real time with your classmates';

  @override
  String get b4Title => 'Smart Notifications';

  @override
  String get b4Desc =>
      'AI schedules your reminders based on your exams and streak';

  @override
  String get b5Title => 'Unlimited AI';

  @override
  String get b5Desc =>
      'Generate content, flashcards and documents without restrictions';

  @override
  String get b6Title => 'Admission Quizzes';

  @override
  String get b6Desc => 'Access to all countries and types of admission exam';

  @override
  String get myHabits => 'My habits';

  @override
  String get newHabit => 'New habit';

  @override
  String get editHabit => 'Edit habit';

  @override
  String get habitName => 'Habit name';

  @override
  String get selectTime => 'Select time';

  @override
  String get frequency => 'Frequency:';

  @override
  String get iconPickerLabel => 'Icon:';

  @override
  String get noHabits => 'You have no habits';

  @override
  String get tapPlusToAdd => 'Tap + to add one';

  @override
  String get addHabitBtn => 'Add habit';

  @override
  String get iconStudy => 'Study';

  @override
  String get iconWater => 'Water';

  @override
  String get iconExercise => 'Exercise';

  @override
  String get iconNotes => 'Notes';

  @override
  String get iconSleep => 'Sleep';

  @override
  String get iconEat => 'Eat';

  @override
  String get iconMusic => 'Music';

  @override
  String get iconMeditation => 'Meditation';

  @override
  String get freqDaily => 'Daily';

  @override
  String get freqMon => 'Mon';

  @override
  String get freqTue => 'Tue';

  @override
  String get freqWed => 'Wed';

  @override
  String get freqThu => 'Thu';

  @override
  String get freqFri => 'Fri';

  @override
  String get freqSat => 'Sat';

  @override
  String get freqSun => 'Sun';

  @override
  String get myExams => 'My exams';

  @override
  String get newExam => 'New exam';

  @override
  String get editExam => 'Edit exam';

  @override
  String get courseNameLabel => 'Course name';

  @override
  String get selectExamTime => 'Select exam time';

  @override
  String get examNotesLabel => 'Exam notes (topics, study notes...)';

  @override
  String get notifAlert =>
      'You\'ll get alerts 2 days before, 1 day before and the day of the exam';

  @override
  String get addExamBtn => 'Add exam';

  @override
  String get examCompleted => 'Exam completed! 🎓';

  @override
  String scoreLabel(int score) {
    return 'Score: $score / 20';
  }

  @override
  String get approved => 'Passed! 🎉';

  @override
  String get notApproved => 'Not passed 💪';

  @override
  String get approvedShort => 'Passed!';

  @override
  String get notApprovedShort => 'Not passed';

  @override
  String get notesLabel => 'Notes:';

  @override
  String get noNotes => 'No notes';

  @override
  String get exportCalendar => 'Export to Calendar';

  @override
  String exportedN(int count) {
    return '$count exam(s) exported to Google Calendar';
  }

  @override
  String get noExportsMsg =>
      'No exams exported (check permissions or if there are upcoming ones)';

  @override
  String get calendarError => 'Error connecting to Google Calendar';

  @override
  String get showCompleted => 'Completed';

  @override
  String get pomodoroTitle => 'Pomodoro';

  @override
  String get breakSession => '☕ Break time';

  @override
  String get studySession => '📚 Study time';

  @override
  String get sessionsToday => 'sessions today';

  @override
  String get pomCoinSnack => '🪙 +10 coins for completing session';

  @override
  String get missionsTitle => 'Missions';

  @override
  String get dailyMissions => 'DAILY MISSIONS';

  @override
  String get dailyRenewal => 'Renew every day';

  @override
  String get weeklyMissions => 'WEEKLY MISSIONS';

  @override
  String get weeklyRenewal => 'Renew every Monday';

  @override
  String levelTitle(int level, String name) {
    return 'Level $level — $name';
  }

  @override
  String xpProgress(int xpCurrent, int xpNext) {
    return '$xpCurrent / $xpNext XP';
  }

  @override
  String get howToEarnXP => 'How to earn XP';

  @override
  String get tipDailyMission => 'Complete daily missions';

  @override
  String get tipWeeklyMission => 'Complete weekly missions';

  @override
  String get tipDailyLogin => 'Daily login reward';

  @override
  String get claimBtn => 'Claim';

  @override
  String get storeTitle => 'Store';

  @override
  String get storeSubtitle => 'Redeem your coins for exclusive rewards';

  @override
  String get howEarnCoins => 'How to earn 🪙?';

  @override
  String get insufficientCoins => '🪙 Insufficient coins';

  @override
  String itemActivated(String name) {
    return '✅ $name activated';
  }

  @override
  String get itemShieldTitle => 'Extra Shield';

  @override
  String get itemShieldDesc =>
      'Protect your streak for one additional day without losing it';

  @override
  String get itemBoostTitle => 'Streak Boost x2';

  @override
  String get itemBoostDesc => 'Double your daily streak coins for 24 hours';

  @override
  String get itemThemeTitle => 'Premium Dark Theme';

  @override
  String get itemThemeDesc => 'Activate the special dark theme for the app';

  @override
  String get earnPomodoro => 'Complete a Pomodoro session';

  @override
  String get earnSimulacro => 'Complete a simulacro';

  @override
  String get earnPerfectSim => 'Get a perfect score on a simulacro';

  @override
  String get earnDailyStreak => 'Maintain daily streak';

  @override
  String get earnIA => 'Use the AI tool';

  @override
  String get earnDailyReward => 'Daily reward for opening the app';

  @override
  String get achievementsTitle => 'My achievements';

  @override
  String get obtainedLabel => 'Obtained';

  @override
  String get pendingLabel => 'To obtain';

  @override
  String get progressLabel => 'Progress';

  @override
  String percentComplete(int pct) {
    return '$pct% complete';
  }

  @override
  String achievementUnlock(String title) {
    return 'I unlocked \"$title\" in EstudiApp! 📚';
  }

  @override
  String get achPrimerHabitoT => 'First step';

  @override
  String get achPrimerHabitoD => 'Complete your first habit';

  @override
  String get achRacha3T => 'On fire';

  @override
  String get achRacha3D => 'Keep a 3-day streak';

  @override
  String get achRacha7T => 'Unstoppable';

  @override
  String get achRacha7D => 'Keep a 7-day streak';

  @override
  String get achRacha14T => 'Steady flow';

  @override
  String get achRacha14D => 'Keep a 14-day streak';

  @override
  String get achRacha30T => 'Legend';

  @override
  String get achRacha30D => 'Keep a 30-day streak';

  @override
  String get achRacha100T => 'Centurion';

  @override
  String get achRacha100D => 'Keep a 100-day streak';

  @override
  String get achPrimerExamenT => 'Student';

  @override
  String get achPrimerExamenD => 'Add your first exam';

  @override
  String get achExamenCompletadoT => 'Passed';

  @override
  String get achExamenCompletadoD => 'Complete your first exam';

  @override
  String get achCincoHabitosT => 'Disciplined';

  @override
  String get achCincoHabitosD => 'Add 5 habits';

  @override
  String get achPomodoro1T => 'Focused';

  @override
  String get achPomodoro1D => 'Complete your first Pomodoro session';

  @override
  String get achIa1T => 'AI Master';

  @override
  String get achIa1D => 'Use AI to study for the first time';

  @override
  String get achIa50T => 'AI Expert';

  @override
  String get achIa50D => 'Perform 50 AI searches';

  @override
  String get achSimulacros10T => 'Examiner';

  @override
  String get achSimulacros10D => 'Complete 10 simulacros';

  @override
  String get achPrimerSimulacroT => 'First simulacro';

  @override
  String get achPrimerSimulacroD => 'Complete your first simulacro';

  @override
  String get achNotaPerfectaT => 'Perfect score';

  @override
  String get achNotaPerfectaD => 'Get 20/20 on an exam';

  @override
  String get achHabitosDiaT => 'Consistent';

  @override
  String get achHabitosDiaD => 'Complete all your habits in a day';

  @override
  String get admisionTitle => 'Admission Simulacros';

  @override
  String get admisionSubtitle =>
      'Practice with questions in the style of real exams';

  @override
  String get countryLabel => 'COUNTRY';

  @override
  String get examLabel => 'EXAM';

  @override
  String get questionsLabel => 'NUMBER OF QUESTIONS';

  @override
  String get recentHistory => 'RECENT HISTORY';

  @override
  String get noSimulacros => 'You haven\'t done any simulacros yet';

  @override
  String get historyError => 'Error loading history';

  @override
  String correctOf(int correct, int total) {
    return '$correct/$total correct';
  }

  @override
  String questionCounter(int current, int total) {
    return 'Question $current / $total';
  }

  @override
  String get reviewAnswers => 'ANSWER REVIEW';

  @override
  String get yourAnswer => 'Your answer:';

  @override
  String get correctAnswer => 'Correct:';

  @override
  String get resultExcellent => 'Excellent score! 🎉';

  @override
  String get resultGood => 'Good! Keep practicing 💪';

  @override
  String get resultTryMore => 'Don\'t give up, practice more';

  @override
  String get anotherSim => 'Another simulacro';

  @override
  String startSim(String country) {
    return 'Start Simulacro — $country';
  }

  @override
  String get generatingAI => 'Generating simulacro with AI...';

  @override
  String get simError => 'Error generating the simulacro. Try again.';

  @override
  String get previousQuestion => 'Previous';

  @override
  String get seeResult => 'See result';

  @override
  String get simPremiumTitle => '🔒 Premium Feature';

  @override
  String get simPremiumBody =>
      'More than 5 simulacros per day requires Premium.';

  @override
  String get simPremiumBtn => 'See Premium';

  @override
  String get iaTitle => 'Study with AI';

  @override
  String get iaSearchesExhausted => 'Exhausted';

  @override
  String iaSearchesToday(int count) {
    return '$count today';
  }

  @override
  String get iaLimitTitle => 'No searches available';

  @override
  String get iaLimitBody =>
      'You\'ve used your 5 free searches for today.\nCome back tomorrow or earn more now.';

  @override
  String get iaWatchAdBtn => 'Watch ad  (+3 free searches)';

  @override
  String get iaPremiumBtn => 'Go Premium — unlimited searches';

  @override
  String get iaAdLoading => 'Ad loading, try again in a moment';

  @override
  String get iaAdNotAvail => 'Ad not available. Try in a moment.';

  @override
  String get iaGot3 => 'You earned 3 extra searches! 🎉';

  @override
  String get iaGot2Bonus =>
      'You earned 2 extra searches for completing the simulacro! 🎯';

  @override
  String get iaClearChat => 'Clear chat';

  @override
  String get iaModeStudy => 'Study';

  @override
  String get iaModeScanner => 'Scanner';

  @override
  String get iaModeDocs => 'Docs';

  @override
  String get iaModeSim => 'Quiz';

  @override
  String get iaModeTools => 'Tools';

  @override
  String get iaScanStep1 => 'STEP 1 — What do you need?';

  @override
  String get iaScanHint => 'E.g.: Summarize this, Solve the exercises...';

  @override
  String get iaScanStep2 => 'STEP 2 — Upload file or send text only';

  @override
  String get iaScanCamera => 'Camera';

  @override
  String get iaScanGallery => 'Gallery';

  @override
  String get iaScanSendText => 'Send text only (no image)';

  @override
  String get iaAnalyzing => 'Analyzing...';

  @override
  String get iaAIResponse => 'AI Response';

  @override
  String get iaSavePDF => 'Save PDF';

  @override
  String get iaNewQuery => 'New query';

  @override
  String get notifHabitTitle => '⏰ Time for your habit!';

  @override
  String notifHabitBody(String name) {
    return 'Time for: $name';
  }

  @override
  String get notifExamTodayTitle => '📚 Your exam is today!';

  @override
  String notifExamTodayBody(String course) {
    return 'Your $course exam starts today. Good luck!';
  }

  @override
  String get notifExam2DaysTitle => '⚠️ Exam in 2 days!';

  @override
  String notifExam2DaysBody(String course) {
    return 'Your $course exam is the day after tomorrow. Study today!';
  }

  @override
  String get notifExam1DayTitle => '🚨 Exam tomorrow!';

  @override
  String notifExam1DayBody(String course) {
    return 'Your $course exam is tomorrow. Review well today!';
  }

  @override
  String get notifMissionsTitle => '🎯 Missions of the day';

  @override
  String notifMissionsPending(int count, String word) {
    return 'You have $count $word pending. Earn coins and XP!';
  }

  @override
  String get notifMissionsGeneral =>
      'Complete your daily missions and earn coins and XP!';

  @override
  String get misionSingular => 'mission';

  @override
  String get misionPlural => 'missions';

  @override
  String notifStreakTitle(int days) {
    return '🔥 Don\'t lose your $days-day streak!';
  }

  @override
  String get notifStreakBody =>
      'Complete at least one activity today to keep the streak.';

  @override
  String get notifStudyTitle => '📚 Time to study';

  @override
  String get notifStudyBody =>
      'Keep the habit: 20 minutes a day makes the difference.';

  @override
  String get myCourses => 'My courses';

  @override
  String get todayShort => 'Today';

  @override
  String get tomorrowShort => 'Tomorrow';

  @override
  String daysShort(int n) {
    return '$n days';
  }

  @override
  String rewardCoins30days(int n) {
    return '🪙 +$n coins — 30-day streak!';
  }

  @override
  String rewardCoinsWeekly(int n) {
    return '🪙 +$n coins — Weekly streak!';
  }

  @override
  String rewardCoinsDaily(int n) {
    return '🪙 +$n daily reward coins';
  }

  @override
  String get adNotNow => 'Ad not available at this time';
}
