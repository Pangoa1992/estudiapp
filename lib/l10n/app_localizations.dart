import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'EstudiApp'**
  String get appTitle;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @saveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get saveChanges;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @seeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todos'**
  String get seeAll;

  /// No description provided for @add.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get add;

  /// No description provided for @back.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get back;

  /// No description provided for @next.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get skip;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @ok.
  ///
  /// In es, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @newLabel.
  ///
  /// In es, this message translates to:
  /// **'Nuevo'**
  String get newLabel;

  /// No description provided for @selected.
  ///
  /// In es, this message translates to:
  /// **'Seleccionado'**
  String get selected;

  /// No description provided for @redeem.
  ///
  /// In es, this message translates to:
  /// **'Canjear'**
  String get redeem;

  /// No description provided for @greetingMorning.
  ///
  /// In es, this message translates to:
  /// **'Buenos días,'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In es, this message translates to:
  /// **'Buenas tardes,'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In es, this message translates to:
  /// **'Buenas noches,'**
  String get greetingEvening;

  /// No description provided for @streakDays.
  ///
  /// In es, this message translates to:
  /// **'{count} días de racha'**
  String streakDays(int count);

  /// No description provided for @shieldAvailable.
  ///
  /// In es, this message translates to:
  /// **'Escudo disponible'**
  String get shieldAvailable;

  /// No description provided for @shieldNone.
  ///
  /// In es, this message translates to:
  /// **'Sin escudo esta semana'**
  String get shieldNone;

  /// No description provided for @startPomodoro.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Pomodoro'**
  String get startPomodoro;

  /// No description provided for @studyWithAI.
  ///
  /// In es, this message translates to:
  /// **'Estudiar con IA'**
  String get studyWithAI;

  /// No description provided for @upcomingExamsTitle.
  ///
  /// In es, this message translates to:
  /// **'EXÁMENES PRÓXIMOS'**
  String get upcomingExamsTitle;

  /// No description provided for @habitsTodayTitle.
  ///
  /// In es, this message translates to:
  /// **'HÁBITOS DE HOY'**
  String get habitsTodayTitle;

  /// No description provided for @moreFeaturesTitle.
  ///
  /// In es, this message translates to:
  /// **'MÁS FUNCIONES'**
  String get moreFeaturesTitle;

  /// No description provided for @signOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get signOut;

  /// No description provided for @addExam.
  ///
  /// In es, this message translates to:
  /// **'Agregar examen'**
  String get addExam;

  /// No description provided for @addHabit.
  ///
  /// In es, this message translates to:
  /// **'Agregar hábito'**
  String get addHabit;

  /// No description provided for @examToday.
  ///
  /// In es, this message translates to:
  /// **'¡Hoy es tu examen de {course}!'**
  String examToday(String course);

  /// No description provided for @examTomorrow.
  ///
  /// In es, this message translates to:
  /// **'Mañana: examen de {course}'**
  String examTomorrow(String course);

  /// No description provided for @examInDays.
  ///
  /// In es, this message translates to:
  /// **'Examen de {course} en {days} días'**
  String examInDays(String course, int days);

  /// No description provided for @tapToStudyAI.
  ///
  /// In es, this message translates to:
  /// **'Toca para estudiar con IA →'**
  String get tapToStudyAI;

  /// No description provided for @adminPanel.
  ///
  /// In es, this message translates to:
  /// **'Panel Admin 👁️'**
  String get adminPanel;

  /// No description provided for @batteryTitle.
  ///
  /// In es, this message translates to:
  /// **'Activa las notificaciones'**
  String get batteryTitle;

  /// No description provided for @batteryBody.
  ///
  /// In es, this message translates to:
  /// **'Para recibir recordatorios desactiva la optimización de batería para EstudiApp.\n\nAjustes → Apps → EstudiApp → Desactiva \"Pausar actividades no utilizadas\"'**
  String get batteryBody;

  /// No description provided for @batteryNotNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get batteryNotNow;

  /// No description provided for @batterySettings.
  ///
  /// In es, this message translates to:
  /// **'Ir a Ajustes'**
  String get batterySettings;

  /// No description provided for @gridFlashcards.
  ///
  /// In es, this message translates to:
  /// **'Flashcards SRS'**
  String get gridFlashcards;

  /// No description provided for @gridMyGrades.
  ///
  /// In es, this message translates to:
  /// **'Mis Notas'**
  String get gridMyGrades;

  /// No description provided for @gridWellbeing.
  ///
  /// In es, this message translates to:
  /// **'Mi Bienestar'**
  String get gridWellbeing;

  /// No description provided for @gridPremium.
  ///
  /// In es, this message translates to:
  /// **'Premium'**
  String get gridPremium;

  /// No description provided for @gridAcademy.
  ///
  /// In es, this message translates to:
  /// **'Mi Academia'**
  String get gridAcademy;

  /// No description provided for @gridPdfSim.
  ///
  /// In es, this message translates to:
  /// **'PDF Simulacro'**
  String get gridPdfSim;

  /// No description provided for @gridGroups.
  ///
  /// In es, this message translates to:
  /// **'Grupos'**
  String get gridGroups;

  /// No description provided for @gridFeynman.
  ///
  /// In es, this message translates to:
  /// **'Feynman'**
  String get gridFeynman;

  /// No description provided for @gridRealCases.
  ///
  /// In es, this message translates to:
  /// **'Casos Reales'**
  String get gridRealCases;

  /// No description provided for @gridVirtual.
  ///
  /// In es, this message translates to:
  /// **'Aula Virtual'**
  String get gridVirtual;

  /// No description provided for @gridSimulacros.
  ///
  /// In es, this message translates to:
  /// **'Simulacros'**
  String get gridSimulacros;

  /// No description provided for @gridStreak.
  ///
  /// In es, this message translates to:
  /// **'Racha'**
  String get gridStreak;

  /// No description provided for @gridAchievements.
  ///
  /// In es, this message translates to:
  /// **'Mis Logros'**
  String get gridAchievements;

  /// No description provided for @gridDashboard.
  ///
  /// In es, this message translates to:
  /// **'Dashboard'**
  String get gridDashboard;

  /// No description provided for @gridStats.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get gridStats;

  /// No description provided for @gridRanking.
  ///
  /// In es, this message translates to:
  /// **'Ranking'**
  String get gridRanking;

  /// No description provided for @gridNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get gridNotifications;

  /// No description provided for @gridStore.
  ///
  /// In es, this message translates to:
  /// **'Tienda'**
  String get gridStore;

  /// No description provided for @gridMissions.
  ///
  /// In es, this message translates to:
  /// **'Misiones'**
  String get gridMissions;

  /// No description provided for @loginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Organiza tus examenes,\ncumple tus habitos y no reprobes'**
  String get loginSubtitle;

  /// No description provided for @continueGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get continueGoogle;

  /// No description provided for @freeForever.
  ///
  /// In es, this message translates to:
  /// **'Gratis para siempre · Sin tarjeta requerida'**
  String get freeForever;

  /// No description provided for @featureStreak.
  ///
  /// In es, this message translates to:
  /// **'Racha diaria'**
  String get featureStreak;

  /// No description provided for @featureCourses.
  ///
  /// In es, this message translates to:
  /// **'Tus cursos'**
  String get featureCourses;

  /// No description provided for @featurePomodoro.
  ///
  /// In es, this message translates to:
  /// **'Pomodoro'**
  String get featurePomodoro;

  /// No description provided for @onb1Title.
  ///
  /// In es, this message translates to:
  /// **'Construye tu racha'**
  String get onb1Title;

  /// No description provided for @onb1Sub.
  ///
  /// In es, this message translates to:
  /// **'Ingresa cada día y mantén tu racha activa. Recibe recordatorios a las 8AM, 2PM y 8PM para no olvidarlo.'**
  String get onb1Sub;

  /// No description provided for @onb2Title.
  ///
  /// In es, this message translates to:
  /// **'Estudia con IA'**
  String get onb2Title;

  /// No description provided for @onb2Sub.
  ///
  /// In es, this message translates to:
  /// **'Genera resúmenes, flashcards, simulacros y planes de estudio con inteligencia artificial. También resuelve fotos de tus ejercicios.'**
  String get onb2Sub;

  /// No description provided for @onb3Title.
  ///
  /// In es, this message translates to:
  /// **'Organiza tus estudios'**
  String get onb3Title;

  /// No description provided for @onb3Sub.
  ///
  /// In es, this message translates to:
  /// **'Registra tus hábitos diarios, controla tus exámenes próximos y genera documentos académicos listos para entregar.'**
  String get onb3Sub;

  /// No description provided for @onb4Title.
  ///
  /// In es, this message translates to:
  /// **'Nunca olvides nada'**
  String get onb4Title;

  /// No description provided for @onb4Sub.
  ///
  /// In es, this message translates to:
  /// **'Activa las notificaciones para recibir recordatorios de tus hábitos, alertas de exámenes y motivación diaria.'**
  String get onb4Sub;

  /// No description provided for @getStarted.
  ///
  /// In es, this message translates to:
  /// **'¡Empezar ahora!'**
  String get getStarted;

  /// No description provided for @offlineTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión — Modo offline'**
  String get offlineTitle;

  /// No description provided for @offlineBody.
  ///
  /// In es, this message translates to:
  /// **'Mostrando datos del último acceso'**
  String get offlineBody;

  /// No description provided for @welcomeStudy.
  ///
  /// In es, this message translates to:
  /// **'¡A estudiar! 💪'**
  String get welcomeStudy;

  /// No description provided for @mot100.
  ///
  /// In es, this message translates to:
  /// **'¡{racha} días imparable! Nivel centurión 🚀'**
  String mot100(int racha);

  /// No description provided for @mot30.
  ///
  /// In es, this message translates to:
  /// **'¡{racha} días de racha! Eres una leyenda 👑'**
  String mot30(int racha);

  /// No description provided for @mot14.
  ///
  /// In es, this message translates to:
  /// **'¡Dos semanas seguidas! Hábito forjado ⚡'**
  String get mot14;

  /// No description provided for @mot7.
  ///
  /// In es, this message translates to:
  /// **'¡Una semana entera! Estás en fuego 🔥'**
  String get mot7;

  /// No description provided for @mot3.
  ///
  /// In es, this message translates to:
  /// **'¡Vas bien! No rompas la racha ahora 💪'**
  String get mot3;

  /// No description provided for @mot1.
  ///
  /// In es, this message translates to:
  /// **'¡Buen comienzo! Mantén el ritmo ✨'**
  String get mot1;

  /// No description provided for @mot0.
  ///
  /// In es, this message translates to:
  /// **'Hoy es un gran día para estudiar 📚'**
  String get mot0;

  /// No description provided for @shieldReady.
  ///
  /// In es, this message translates to:
  /// **'🛡️ Escudo listo'**
  String get shieldReady;

  /// No description provided for @shieldEmpty.
  ///
  /// In es, this message translates to:
  /// **'🛡️ Sin escudo'**
  String get shieldEmpty;

  /// No description provided for @myProfile.
  ///
  /// In es, this message translates to:
  /// **'Mi perfil'**
  String get myProfile;

  /// No description provided for @currentStreak.
  ///
  /// In es, this message translates to:
  /// **'Racha actual'**
  String get currentStreak;

  /// No description provided for @maxStreak.
  ///
  /// In es, this message translates to:
  /// **'Racha máxima'**
  String get maxStreak;

  /// No description provided for @activeDays.
  ///
  /// In es, this message translates to:
  /// **'Días activos'**
  String get activeDays;

  /// No description provided for @viewAchievements.
  ///
  /// In es, this message translates to:
  /// **'Ver mis logros'**
  String get viewAchievements;

  /// No description provided for @streakHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial de racha'**
  String get streakHistory;

  /// No description provided for @academicProfiles.
  ///
  /// In es, this message translates to:
  /// **'Perfiles académicos'**
  String get academicProfiles;

  /// No description provided for @appearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get appearance;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'🌙 Oscuro'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In es, this message translates to:
  /// **'⚙️ Sistema'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'☀️ Claro'**
  String get themeLight;

  /// No description provided for @darkNow.
  ///
  /// In es, this message translates to:
  /// **'oscuro ahora'**
  String get darkNow;

  /// No description provided for @lightNow.
  ///
  /// In es, this message translates to:
  /// **'claro ahora'**
  String get lightNow;

  /// No description provided for @university.
  ///
  /// In es, this message translates to:
  /// **'Universidad'**
  String get university;

  /// No description provided for @career.
  ///
  /// In es, this message translates to:
  /// **'Carrera'**
  String get career;

  /// No description provided for @tapToSelect.
  ///
  /// In es, this message translates to:
  /// **'Toca para seleccionar'**
  String get tapToSelect;

  /// No description provided for @selectCareer.
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu carrera'**
  String get selectCareer;

  /// No description provided for @premiumActive.
  ///
  /// In es, this message translates to:
  /// **'EstudiApp Premium activo'**
  String get premiumActive;

  /// No description provided for @unlockPremium.
  ///
  /// In es, this message translates to:
  /// **'Desbloquear Premium'**
  String get unlockPremium;

  /// No description provided for @validUntilDate.
  ///
  /// In es, this message translates to:
  /// **'Válido hasta {day}/{month}/{year}'**
  String validUntilDate(int day, int month, int year);

  /// No description provided for @premiumFeaturesDesc.
  ///
  /// In es, this message translates to:
  /// **'PDF simulacros, grupos de estudio y más'**
  String get premiumFeaturesDesc;

  /// No description provided for @statsSection.
  ///
  /// In es, this message translates to:
  /// **'ESTADÍSTICAS'**
  String get statsSection;

  /// No description provided for @habitsLabel.
  ///
  /// In es, this message translates to:
  /// **'Hábitos'**
  String get habitsLabel;

  /// No description provided for @todayLabel.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get todayLabel;

  /// No description provided for @examsLabel.
  ///
  /// In es, this message translates to:
  /// **'Exámenes'**
  String get examsLabel;

  /// No description provided for @coursesLabel.
  ///
  /// In es, this message translates to:
  /// **'Cursos'**
  String get coursesLabel;

  /// No description provided for @passedLabel.
  ///
  /// In es, this message translates to:
  /// **'Aprobados'**
  String get passedLabel;

  /// No description provided for @achievementsLabel.
  ///
  /// In es, this message translates to:
  /// **'Logros'**
  String get achievementsLabel;

  /// No description provided for @notSpecified.
  ///
  /// In es, this message translates to:
  /// **'No especificado'**
  String get notSpecified;

  /// No description provided for @languageLabel.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get languageLabel;

  /// No description provided for @langSpanish.
  ///
  /// In es, this message translates to:
  /// **'🇪🇸 Español'**
  String get langSpanish;

  /// No description provided for @langEnglish.
  ///
  /// In es, this message translates to:
  /// **'🇺🇸 English'**
  String get langEnglish;

  /// No description provided for @premiumTitle.
  ///
  /// In es, this message translates to:
  /// **'EstudiApp Premium'**
  String get premiumTitle;

  /// No description provided for @premiumSlogan.
  ///
  /// In es, this message translates to:
  /// **'Todo el poder del aprendizaje, sin límites'**
  String get premiumSlogan;

  /// No description provided for @premiumIncludes.
  ///
  /// In es, this message translates to:
  /// **'QUÉ INCLUYE PREMIUM'**
  String get premiumIncludes;

  /// No description provided for @choosePlan.
  ///
  /// In es, this message translates to:
  /// **'ELIGE TU PLAN'**
  String get choosePlan;

  /// No description provided for @recommended.
  ///
  /// In es, this message translates to:
  /// **'RECOMENDADO'**
  String get recommended;

  /// No description provided for @monthlyLabel.
  ///
  /// In es, this message translates to:
  /// **'MENSUAL'**
  String get monthlyLabel;

  /// No description provided for @perYear.
  ///
  /// In es, this message translates to:
  /// **'por año'**
  String get perYear;

  /// No description provided for @perMonth.
  ///
  /// In es, this message translates to:
  /// **'por mes'**
  String get perMonth;

  /// No description provided for @save45pct.
  ///
  /// In es, this message translates to:
  /// **'AHORRAS 45%'**
  String get save45pct;

  /// No description provided for @tryFree.
  ///
  /// In es, this message translates to:
  /// **'Probar 7 días gratis'**
  String get tryFree;

  /// No description provided for @tryFreeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Requiere método de pago · Renueva automáticamente'**
  String get tryFreeSubtitle;

  /// No description provided for @trialNeedsPaymentMethod.
  ///
  /// In es, this message translates to:
  /// **'Necesitas un método de pago en Google Play para activar la prueba gratuita. Google no te cobrará durante los 7 días de prueba.'**
  String get trialNeedsPaymentMethod;

  /// No description provided for @subscribeBtn.
  ///
  /// In es, this message translates to:
  /// **'Suscribirse — {price}/{period}'**
  String subscribeBtn(String price, String period);

  /// No description provided for @notAvailable.
  ///
  /// In es, this message translates to:
  /// **'No disponible en este dispositivo'**
  String get notAvailable;

  /// No description provided for @restorePurchase.
  ///
  /// In es, this message translates to:
  /// **'Restaurar compra anterior'**
  String get restorePurchase;

  /// No description provided for @securePayment.
  ///
  /// In es, this message translates to:
  /// **'Pago seguro a través de Google Play · Cancela cuando quieras'**
  String get securePayment;

  /// No description provided for @premiumSuccess.
  ///
  /// In es, this message translates to:
  /// **'¡Premium activado con éxito!'**
  String get premiumSuccess;

  /// No description provided for @paymentPending.
  ///
  /// In es, this message translates to:
  /// **'Pago pendiente de confirmación bancaria...'**
  String get paymentPending;

  /// No description provided for @premiumVerifyError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos verificar tu compra con Google Play. Si se te cobró, cierra y vuelve a abrir la app para restaurarla, o escríbenos.'**
  String get premiumVerifyError;

  /// No description provided for @paymentError.
  ///
  /// In es, this message translates to:
  /// **'Error en el pago: {message}'**
  String paymentError(String message);

  /// No description provided for @trialSuccess.
  ///
  /// In es, this message translates to:
  /// **'¡7 días Premium activados! Disfruta sin límites 🎉'**
  String get trialSuccess;

  /// No description provided for @trialUsed.
  ///
  /// In es, this message translates to:
  /// **'Ya usaste el período de prueba gratuito.'**
  String get trialUsed;

  /// No description provided for @alreadyPremium.
  ///
  /// In es, this message translates to:
  /// **'¡Ya tienes Premium activo!'**
  String get alreadyPremium;

  /// No description provided for @billingAnnual.
  ///
  /// In es, this message translates to:
  /// **'Cobro anual vía Google Play'**
  String get billingAnnual;

  /// No description provided for @billingMonthly.
  ///
  /// In es, this message translates to:
  /// **'Cobro mensual vía Google Play'**
  String get billingMonthly;

  /// No description provided for @activeUntilDate.
  ///
  /// In es, this message translates to:
  /// **'✓ Activo hasta {day}/{month}/{year}'**
  String activeUntilDate(int day, int month, int year);

  /// No description provided for @fromPrice.
  ///
  /// In es, this message translates to:
  /// **'Desde {price}/mes · Cancela cuando quieras'**
  String fromPrice(String price);

  /// No description provided for @compFree.
  ///
  /// In es, this message translates to:
  /// **'Gratis'**
  String get compFree;

  /// No description provided for @compPremium.
  ///
  /// In es, this message translates to:
  /// **'Premium'**
  String get compPremium;

  /// No description provided for @compAI.
  ///
  /// In es, this message translates to:
  /// **'Asistente IA'**
  String get compAI;

  /// No description provided for @comp5day.
  ///
  /// In es, this message translates to:
  /// **'5/día'**
  String get comp5day;

  /// No description provided for @compUnlimited.
  ///
  /// In es, this message translates to:
  /// **'Ilimitado'**
  String get compUnlimited;

  /// No description provided for @compFlashcards.
  ///
  /// In es, this message translates to:
  /// **'Flashcards SRS'**
  String get compFlashcards;

  /// No description provided for @compSimulacros.
  ///
  /// In es, this message translates to:
  /// **'Simulacros'**
  String get compSimulacros;

  /// No description provided for @comp5questions.
  ///
  /// In es, this message translates to:
  /// **'5 preguntas'**
  String get comp5questions;

  /// No description provided for @compPDF.
  ///
  /// In es, this message translates to:
  /// **'PDF a Simulacro'**
  String get compPDF;

  /// No description provided for @compGroups.
  ///
  /// In es, this message translates to:
  /// **'Grupos de estudio'**
  String get compGroups;

  /// No description provided for @compTeacher.
  ///
  /// In es, this message translates to:
  /// **'Panel Docente'**
  String get compTeacher;

  /// No description provided for @compNoAds.
  ///
  /// In es, this message translates to:
  /// **'Sin anuncios'**
  String get compNoAds;

  /// No description provided for @b1Title.
  ///
  /// In es, this message translates to:
  /// **'Panel de Docente'**
  String get b1Title;

  /// No description provided for @b1Desc.
  ///
  /// In es, this message translates to:
  /// **'Crea tu academia, agrega alumnos y gestiona exámenes'**
  String get b1Desc;

  /// No description provided for @b2Title.
  ///
  /// In es, this message translates to:
  /// **'PDF a Simulacro'**
  String get b2Title;

  /// No description provided for @b2Desc.
  ///
  /// In es, this message translates to:
  /// **'Sube exámenes reales en PDF y la IA los convierte a tests interactivos'**
  String get b2Desc;

  /// No description provided for @b3Title.
  ///
  /// In es, this message translates to:
  /// **'Grupos de Estudio'**
  String get b3Title;

  /// No description provided for @b3Desc.
  ///
  /// In es, this message translates to:
  /// **'Estudia en tiempo real con tus compañeros'**
  String get b3Desc;

  /// No description provided for @b4Title.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones Inteligentes'**
  String get b4Title;

  /// No description provided for @b4Desc.
  ///
  /// In es, this message translates to:
  /// **'La IA programa tus recordatorios según tus exámenes y racha'**
  String get b4Desc;

  /// No description provided for @b5Title.
  ///
  /// In es, this message translates to:
  /// **'IA sin límites'**
  String get b5Title;

  /// No description provided for @b5Desc.
  ///
  /// In es, this message translates to:
  /// **'Genera contenido, flashcards y documentos sin restricciones'**
  String get b5Desc;

  /// No description provided for @b6Title.
  ///
  /// In es, this message translates to:
  /// **'Simulacros de Admisión'**
  String get b6Title;

  /// No description provided for @b6Desc.
  ///
  /// In es, this message translates to:
  /// **'Acceso a todos los países y tipos de examen de admisión'**
  String get b6Desc;

  /// No description provided for @myHabits.
  ///
  /// In es, this message translates to:
  /// **'Mis habitos'**
  String get myHabits;

  /// No description provided for @newHabit.
  ///
  /// In es, this message translates to:
  /// **'Nuevo habito'**
  String get newHabit;

  /// No description provided for @editHabit.
  ///
  /// In es, this message translates to:
  /// **'Editar habito'**
  String get editHabit;

  /// No description provided for @habitName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del habito'**
  String get habitName;

  /// No description provided for @selectTime.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar hora'**
  String get selectTime;

  /// No description provided for @frequency.
  ///
  /// In es, this message translates to:
  /// **'Frecuencia:'**
  String get frequency;

  /// No description provided for @iconPickerLabel.
  ///
  /// In es, this message translates to:
  /// **'Icono:'**
  String get iconPickerLabel;

  /// No description provided for @noHabits.
  ///
  /// In es, this message translates to:
  /// **'No tienes habitos'**
  String get noHabits;

  /// No description provided for @tapPlusToAdd.
  ///
  /// In es, this message translates to:
  /// **'Toca + para agregar uno'**
  String get tapPlusToAdd;

  /// No description provided for @addHabitBtn.
  ///
  /// In es, this message translates to:
  /// **'Agregar habito'**
  String get addHabitBtn;

  /// No description provided for @iconStudy.
  ///
  /// In es, this message translates to:
  /// **'Estudio'**
  String get iconStudy;

  /// No description provided for @iconWater.
  ///
  /// In es, this message translates to:
  /// **'Agua'**
  String get iconWater;

  /// No description provided for @iconExercise.
  ///
  /// In es, this message translates to:
  /// **'Ejercicio'**
  String get iconExercise;

  /// No description provided for @iconNotes.
  ///
  /// In es, this message translates to:
  /// **'Apuntes'**
  String get iconNotes;

  /// No description provided for @iconSleep.
  ///
  /// In es, this message translates to:
  /// **'Dormir'**
  String get iconSleep;

  /// No description provided for @iconEat.
  ///
  /// In es, this message translates to:
  /// **'Comer'**
  String get iconEat;

  /// No description provided for @iconMusic.
  ///
  /// In es, this message translates to:
  /// **'Musica'**
  String get iconMusic;

  /// No description provided for @iconMeditation.
  ///
  /// In es, this message translates to:
  /// **'Meditacion'**
  String get iconMeditation;

  /// No description provided for @freqDaily.
  ///
  /// In es, this message translates to:
  /// **'Diario'**
  String get freqDaily;

  /// No description provided for @freqMon.
  ///
  /// In es, this message translates to:
  /// **'Lun'**
  String get freqMon;

  /// No description provided for @freqTue.
  ///
  /// In es, this message translates to:
  /// **'Mar'**
  String get freqTue;

  /// No description provided for @freqWed.
  ///
  /// In es, this message translates to:
  /// **'Mie'**
  String get freqWed;

  /// No description provided for @freqThu.
  ///
  /// In es, this message translates to:
  /// **'Jue'**
  String get freqThu;

  /// No description provided for @freqFri.
  ///
  /// In es, this message translates to:
  /// **'Vie'**
  String get freqFri;

  /// No description provided for @freqSat.
  ///
  /// In es, this message translates to:
  /// **'Sab'**
  String get freqSat;

  /// No description provided for @freqSun.
  ///
  /// In es, this message translates to:
  /// **'Dom'**
  String get freqSun;

  /// No description provided for @myExams.
  ///
  /// In es, this message translates to:
  /// **'Mis exámenes'**
  String get myExams;

  /// No description provided for @newExam.
  ///
  /// In es, this message translates to:
  /// **'Nuevo examen'**
  String get newExam;

  /// No description provided for @editExam.
  ///
  /// In es, this message translates to:
  /// **'Editar examen'**
  String get editExam;

  /// No description provided for @courseNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del curso'**
  String get courseNameLabel;

  /// No description provided for @selectExamTime.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar hora del examen'**
  String get selectExamTime;

  /// No description provided for @examNotesLabel.
  ///
  /// In es, this message translates to:
  /// **'Notas del examen (temas, apuntes...)'**
  String get examNotesLabel;

  /// No description provided for @notifAlert.
  ///
  /// In es, this message translates to:
  /// **'Recibirás alertas 2 días antes, 1 día antes y el mismo día del examen'**
  String get notifAlert;

  /// No description provided for @addExamBtn.
  ///
  /// In es, this message translates to:
  /// **'Agregar examen'**
  String get addExamBtn;

  /// No description provided for @examCompleted.
  ///
  /// In es, this message translates to:
  /// **'¡Examen completado! 🎓'**
  String get examCompleted;

  /// No description provided for @scoreLabel.
  ///
  /// In es, this message translates to:
  /// **'Nota: {score} / 20'**
  String scoreLabel(int score);

  /// No description provided for @approved.
  ///
  /// In es, this message translates to:
  /// **'¡Aprobado! 🎉'**
  String get approved;

  /// No description provided for @notApproved.
  ///
  /// In es, this message translates to:
  /// **'No aprobado 💪'**
  String get notApproved;

  /// No description provided for @approvedShort.
  ///
  /// In es, this message translates to:
  /// **'¡Aprobado!'**
  String get approvedShort;

  /// No description provided for @notApprovedShort.
  ///
  /// In es, this message translates to:
  /// **'No aprobado'**
  String get notApprovedShort;

  /// No description provided for @notesLabel.
  ///
  /// In es, this message translates to:
  /// **'Notas:'**
  String get notesLabel;

  /// No description provided for @noNotes.
  ///
  /// In es, this message translates to:
  /// **'Sin notas'**
  String get noNotes;

  /// No description provided for @exportCalendar.
  ///
  /// In es, this message translates to:
  /// **'Exportar a Calendar'**
  String get exportCalendar;

  /// No description provided for @exportedN.
  ///
  /// In es, this message translates to:
  /// **'{count} examen(es) exportado(s) a Google Calendar'**
  String exportedN(int count);

  /// No description provided for @noExportsMsg.
  ///
  /// In es, this message translates to:
  /// **'No se exportaron examenes (verifica permisos o si hay proximos)'**
  String get noExportsMsg;

  /// No description provided for @calendarError.
  ///
  /// In es, this message translates to:
  /// **'Error al conectar con Google Calendar'**
  String get calendarError;

  /// No description provided for @showCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completados'**
  String get showCompleted;

  /// No description provided for @pomodoroTitle.
  ///
  /// In es, this message translates to:
  /// **'Pomodoro'**
  String get pomodoroTitle;

  /// No description provided for @breakSession.
  ///
  /// In es, this message translates to:
  /// **'☕ Tiempo de descanso'**
  String get breakSession;

  /// No description provided for @studySession.
  ///
  /// In es, this message translates to:
  /// **'📚 Tiempo de estudio'**
  String get studySession;

  /// No description provided for @sessionsToday.
  ///
  /// In es, this message translates to:
  /// **'sesiones hoy'**
  String get sessionsToday;

  /// No description provided for @pomCoinSnack.
  ///
  /// In es, this message translates to:
  /// **'🪙 +10 monedas por completar sesión'**
  String get pomCoinSnack;

  /// No description provided for @missionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Misiones'**
  String get missionsTitle;

  /// No description provided for @dailyMissions.
  ///
  /// In es, this message translates to:
  /// **'MISIONES DIARIAS'**
  String get dailyMissions;

  /// No description provided for @dailyRenewal.
  ///
  /// In es, this message translates to:
  /// **'Se renuevan cada día'**
  String get dailyRenewal;

  /// No description provided for @weeklyMissions.
  ///
  /// In es, this message translates to:
  /// **'MISIONES SEMANALES'**
  String get weeklyMissions;

  /// No description provided for @weeklyRenewal.
  ///
  /// In es, this message translates to:
  /// **'Se renuevan cada lunes'**
  String get weeklyRenewal;

  /// No description provided for @levelTitle.
  ///
  /// In es, this message translates to:
  /// **'Nivel {level} — {name}'**
  String levelTitle(int level, String name);

  /// No description provided for @xpProgress.
  ///
  /// In es, this message translates to:
  /// **'{xpCurrent} / {xpNext} XP'**
  String xpProgress(int xpCurrent, int xpNext);

  /// No description provided for @howToEarnXP.
  ///
  /// In es, this message translates to:
  /// **'Cómo ganar XP'**
  String get howToEarnXP;

  /// No description provided for @tipDailyMission.
  ///
  /// In es, this message translates to:
  /// **'Completar misiones diarias'**
  String get tipDailyMission;

  /// No description provided for @tipWeeklyMission.
  ///
  /// In es, this message translates to:
  /// **'Completar misiones semanales'**
  String get tipWeeklyMission;

  /// No description provided for @tipDailyLogin.
  ///
  /// In es, this message translates to:
  /// **'Recompensa de inicio diario'**
  String get tipDailyLogin;

  /// No description provided for @claimBtn.
  ///
  /// In es, this message translates to:
  /// **'Reclamar'**
  String get claimBtn;

  /// No description provided for @storeTitle.
  ///
  /// In es, this message translates to:
  /// **'Tienda'**
  String get storeTitle;

  /// No description provided for @storeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Canjea tus monedas por recompensas exclusivas'**
  String get storeSubtitle;

  /// No description provided for @howEarnCoins.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo ganar 🪙?'**
  String get howEarnCoins;

  /// No description provided for @insufficientCoins.
  ///
  /// In es, this message translates to:
  /// **'🪙 Monedas insuficientes'**
  String get insufficientCoins;

  /// No description provided for @itemActivated.
  ///
  /// In es, this message translates to:
  /// **'✅ {name} activado'**
  String itemActivated(String name);

  /// No description provided for @itemShieldTitle.
  ///
  /// In es, this message translates to:
  /// **'Escudo Extra'**
  String get itemShieldTitle;

  /// No description provided for @itemShieldDesc.
  ///
  /// In es, this message translates to:
  /// **'Protege tu racha un día adicional sin perderla'**
  String get itemShieldDesc;

  /// No description provided for @itemBoostTitle.
  ///
  /// In es, this message translates to:
  /// **'Boost de Racha x2'**
  String get itemBoostTitle;

  /// No description provided for @itemBoostDesc.
  ///
  /// In es, this message translates to:
  /// **'Duplica las monedas de racha diaria durante 24 horas'**
  String get itemBoostDesc;

  /// No description provided for @itemThemeTitle.
  ///
  /// In es, this message translates to:
  /// **'Tema Oscuro Premium'**
  String get itemThemeTitle;

  /// No description provided for @itemThemeDesc.
  ///
  /// In es, this message translates to:
  /// **'Activa el tema oscuro especial de la app'**
  String get itemThemeDesc;

  /// No description provided for @earnPomodoro.
  ///
  /// In es, this message translates to:
  /// **'Completar sesión Pomodoro'**
  String get earnPomodoro;

  /// No description provided for @earnSimulacro.
  ///
  /// In es, this message translates to:
  /// **'Completar un simulacro'**
  String get earnSimulacro;

  /// No description provided for @earnPerfectSim.
  ///
  /// In es, this message translates to:
  /// **'Sacar puntaje perfecto en simulacro'**
  String get earnPerfectSim;

  /// No description provided for @earnDailyStreak.
  ///
  /// In es, this message translates to:
  /// **'Mantener racha diaria'**
  String get earnDailyStreak;

  /// No description provided for @earnIA.
  ///
  /// In es, this message translates to:
  /// **'Usar herramienta de IA'**
  String get earnIA;

  /// No description provided for @earnDailyReward.
  ///
  /// In es, this message translates to:
  /// **'Recompensa diaria al abrir la app'**
  String get earnDailyReward;

  /// No description provided for @achievementsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis logros'**
  String get achievementsTitle;

  /// No description provided for @obtainedLabel.
  ///
  /// In es, this message translates to:
  /// **'Obtenidos'**
  String get obtainedLabel;

  /// No description provided for @pendingLabel.
  ///
  /// In es, this message translates to:
  /// **'Por obtener'**
  String get pendingLabel;

  /// No description provided for @progressLabel.
  ///
  /// In es, this message translates to:
  /// **'Progreso'**
  String get progressLabel;

  /// No description provided for @percentComplete.
  ///
  /// In es, this message translates to:
  /// **'{pct}% completado'**
  String percentComplete(int pct);

  /// No description provided for @achievementUnlock.
  ///
  /// In es, this message translates to:
  /// **'¡Desbloqueé \"{title}\" en EstudiApp! 📚'**
  String achievementUnlock(String title);

  /// No description provided for @achPrimerHabitoT.
  ///
  /// In es, this message translates to:
  /// **'Primer paso'**
  String get achPrimerHabitoT;

  /// No description provided for @achPrimerHabitoD.
  ///
  /// In es, this message translates to:
  /// **'Completa tu primer hábito'**
  String get achPrimerHabitoD;

  /// No description provided for @achRacha3T.
  ///
  /// In es, this message translates to:
  /// **'En llamas'**
  String get achRacha3T;

  /// No description provided for @achRacha3D.
  ///
  /// In es, this message translates to:
  /// **'Mantén una racha de 3 días'**
  String get achRacha3D;

  /// No description provided for @achRacha7T.
  ///
  /// In es, this message translates to:
  /// **'Imparable'**
  String get achRacha7T;

  /// No description provided for @achRacha7D.
  ///
  /// In es, this message translates to:
  /// **'Mantén una racha de 7 días'**
  String get achRacha7D;

  /// No description provided for @achRacha14T.
  ///
  /// In es, this message translates to:
  /// **'Flujo constante'**
  String get achRacha14T;

  /// No description provided for @achRacha14D.
  ///
  /// In es, this message translates to:
  /// **'Mantén una racha de 14 días'**
  String get achRacha14D;

  /// No description provided for @achRacha30T.
  ///
  /// In es, this message translates to:
  /// **'Leyenda'**
  String get achRacha30T;

  /// No description provided for @achRacha30D.
  ///
  /// In es, this message translates to:
  /// **'Mantén una racha de 30 días'**
  String get achRacha30D;

  /// No description provided for @achRacha100T.
  ///
  /// In es, this message translates to:
  /// **'Centurión'**
  String get achRacha100T;

  /// No description provided for @achRacha100D.
  ///
  /// In es, this message translates to:
  /// **'Mantén una racha de 100 días'**
  String get achRacha100D;

  /// No description provided for @achPrimerExamenT.
  ///
  /// In es, this message translates to:
  /// **'Estudiante'**
  String get achPrimerExamenT;

  /// No description provided for @achPrimerExamenD.
  ///
  /// In es, this message translates to:
  /// **'Agrega tu primer examen'**
  String get achPrimerExamenD;

  /// No description provided for @achExamenCompletadoT.
  ///
  /// In es, this message translates to:
  /// **'Aprobado'**
  String get achExamenCompletadoT;

  /// No description provided for @achExamenCompletadoD.
  ///
  /// In es, this message translates to:
  /// **'Completa tu primer examen'**
  String get achExamenCompletadoD;

  /// No description provided for @achCincoHabitosT.
  ///
  /// In es, this message translates to:
  /// **'Disciplinado'**
  String get achCincoHabitosT;

  /// No description provided for @achCincoHabitosD.
  ///
  /// In es, this message translates to:
  /// **'Agrega 5 hábitos'**
  String get achCincoHabitosD;

  /// No description provided for @achPomodoro1T.
  ///
  /// In es, this message translates to:
  /// **'Enfocado'**
  String get achPomodoro1T;

  /// No description provided for @achPomodoro1D.
  ///
  /// In es, this message translates to:
  /// **'Completa tu primera sesión Pomodoro'**
  String get achPomodoro1D;

  /// No description provided for @achIa1T.
  ///
  /// In es, this message translates to:
  /// **'IA Master'**
  String get achIa1T;

  /// No description provided for @achIa1D.
  ///
  /// In es, this message translates to:
  /// **'Usa la IA para estudiar por primera vez'**
  String get achIa1D;

  /// No description provided for @achIa50T.
  ///
  /// In es, this message translates to:
  /// **'Experto IA'**
  String get achIa50T;

  /// No description provided for @achIa50D.
  ///
  /// In es, this message translates to:
  /// **'Realiza 50 búsquedas con la IA'**
  String get achIa50D;

  /// No description provided for @achSimulacros10T.
  ///
  /// In es, this message translates to:
  /// **'Examinador'**
  String get achSimulacros10T;

  /// No description provided for @achSimulacros10D.
  ///
  /// In es, this message translates to:
  /// **'Completa 10 simulacros'**
  String get achSimulacros10D;

  /// No description provided for @achPrimerSimulacroT.
  ///
  /// In es, this message translates to:
  /// **'Primer simulacro'**
  String get achPrimerSimulacroT;

  /// No description provided for @achPrimerSimulacroD.
  ///
  /// In es, this message translates to:
  /// **'Completa tu primer simulacro'**
  String get achPrimerSimulacroD;

  /// No description provided for @achNotaPerfectaT.
  ///
  /// In es, this message translates to:
  /// **'Nota perfecta'**
  String get achNotaPerfectaT;

  /// No description provided for @achNotaPerfectaD.
  ///
  /// In es, this message translates to:
  /// **'Obtén 20/20 en un examen'**
  String get achNotaPerfectaD;

  /// No description provided for @achHabitosDiaT.
  ///
  /// In es, this message translates to:
  /// **'Constante'**
  String get achHabitosDiaT;

  /// No description provided for @achHabitosDiaD.
  ///
  /// In es, this message translates to:
  /// **'Completa todos tus hábitos en un día'**
  String get achHabitosDiaD;

  /// No description provided for @admisionTitle.
  ///
  /// In es, this message translates to:
  /// **'Simulacros de Admisión'**
  String get admisionTitle;

  /// No description provided for @admisionSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Practica con preguntas al estilo de los exámenes reales'**
  String get admisionSubtitle;

  /// No description provided for @countryLabel.
  ///
  /// In es, this message translates to:
  /// **'PAÍS'**
  String get countryLabel;

  /// No description provided for @examLabel.
  ///
  /// In es, this message translates to:
  /// **'EXAMEN'**
  String get examLabel;

  /// No description provided for @questionsLabel.
  ///
  /// In es, this message translates to:
  /// **'CANTIDAD DE PREGUNTAS'**
  String get questionsLabel;

  /// No description provided for @recentHistory.
  ///
  /// In es, this message translates to:
  /// **'HISTORIAL RECIENTE'**
  String get recentHistory;

  /// No description provided for @noSimulacros.
  ///
  /// In es, this message translates to:
  /// **'Aún no has hecho simulacros'**
  String get noSimulacros;

  /// No description provided for @historyError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar historial'**
  String get historyError;

  /// No description provided for @correctOf.
  ///
  /// In es, this message translates to:
  /// **'{correct}/{total} correctas'**
  String correctOf(int correct, int total);

  /// No description provided for @questionCounter.
  ///
  /// In es, this message translates to:
  /// **'Pregunta {current} / {total}'**
  String questionCounter(int current, int total);

  /// No description provided for @reviewAnswers.
  ///
  /// In es, this message translates to:
  /// **'REVISIÓN DE RESPUESTAS'**
  String get reviewAnswers;

  /// No description provided for @yourAnswer.
  ///
  /// In es, this message translates to:
  /// **'Tu respuesta:'**
  String get yourAnswer;

  /// No description provided for @correctAnswer.
  ///
  /// In es, this message translates to:
  /// **'Correcta:'**
  String get correctAnswer;

  /// No description provided for @resultExcellent.
  ///
  /// In es, this message translates to:
  /// **'¡Excelente puntaje! 🎉'**
  String get resultExcellent;

  /// No description provided for @resultGood.
  ///
  /// In es, this message translates to:
  /// **'¡Bien! Sigue practicando 💪'**
  String get resultGood;

  /// No description provided for @resultTryMore.
  ///
  /// In es, this message translates to:
  /// **'No te rindas, practica más'**
  String get resultTryMore;

  /// No description provided for @anotherSim.
  ///
  /// In es, this message translates to:
  /// **'Otro simulacro'**
  String get anotherSim;

  /// No description provided for @startSim.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Simulacro — {country}'**
  String startSim(String country);

  /// No description provided for @generatingAI.
  ///
  /// In es, this message translates to:
  /// **'Generando simulacro con IA...'**
  String get generatingAI;

  /// No description provided for @simError.
  ///
  /// In es, this message translates to:
  /// **'Error al generar el simulacro. Intenta de nuevo.'**
  String get simError;

  /// No description provided for @previousQuestion.
  ///
  /// In es, this message translates to:
  /// **'Anterior'**
  String get previousQuestion;

  /// No description provided for @seeResult.
  ///
  /// In es, this message translates to:
  /// **'Ver resultado'**
  String get seeResult;

  /// No description provided for @simPremiumTitle.
  ///
  /// In es, this message translates to:
  /// **'🔒 Función Premium'**
  String get simPremiumTitle;

  /// No description provided for @simPremiumBody.
  ///
  /// In es, this message translates to:
  /// **'Más de 5 simulacros al día requiere Premium.'**
  String get simPremiumBody;

  /// No description provided for @simPremiumBtn.
  ///
  /// In es, this message translates to:
  /// **'Ver Premium'**
  String get simPremiumBtn;

  /// No description provided for @iaTitle.
  ///
  /// In es, this message translates to:
  /// **'Estudiar con IA'**
  String get iaTitle;

  /// No description provided for @iaSearchesExhausted.
  ///
  /// In es, this message translates to:
  /// **'Agotadas'**
  String get iaSearchesExhausted;

  /// No description provided for @iaSearchesToday.
  ///
  /// In es, this message translates to:
  /// **'{count} hoy'**
  String iaSearchesToday(int count);

  /// No description provided for @iaLimitTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin búsquedas disponibles'**
  String get iaLimitTitle;

  /// No description provided for @iaLimitBody.
  ///
  /// In es, this message translates to:
  /// **'Usaste tus 5 búsquedas gratuitas de hoy.\nVuelve mañana o gana más ahora mismo.'**
  String get iaLimitBody;

  /// No description provided for @iaWatchAdBtn.
  ///
  /// In es, this message translates to:
  /// **'Ver anuncio  (+3 búsquedas gratis)'**
  String get iaWatchAdBtn;

  /// No description provided for @iaPremiumBtn.
  ///
  /// In es, this message translates to:
  /// **'Hacerse Premium — búsquedas ilimitadas'**
  String get iaPremiumBtn;

  /// No description provided for @iaAdLoading.
  ///
  /// In es, this message translates to:
  /// **'Anuncio cargando, intenta de nuevo en un momento'**
  String get iaAdLoading;

  /// No description provided for @iaAdNotAvail.
  ///
  /// In es, this message translates to:
  /// **'Anuncio no disponible. Intenta en un momento.'**
  String get iaAdNotAvail;

  /// No description provided for @iaGot3.
  ///
  /// In es, this message translates to:
  /// **'¡Ganaste 3 búsquedas extra! 🎉'**
  String get iaGot3;

  /// No description provided for @iaGot2Bonus.
  ///
  /// In es, this message translates to:
  /// **'¡Ganaste 2 búsquedas extra por completar el simulacro! 🎯'**
  String get iaGot2Bonus;

  /// No description provided for @iaClearChat.
  ///
  /// In es, this message translates to:
  /// **'Limpiar chat'**
  String get iaClearChat;

  /// No description provided for @iaModeStudy.
  ///
  /// In es, this message translates to:
  /// **'Estudiar'**
  String get iaModeStudy;

  /// No description provided for @iaModeScanner.
  ///
  /// In es, this message translates to:
  /// **'Scanner'**
  String get iaModeScanner;

  /// No description provided for @iaModeDocs.
  ///
  /// In es, this message translates to:
  /// **'Docs'**
  String get iaModeDocs;

  /// No description provided for @iaModeSim.
  ///
  /// In es, this message translates to:
  /// **'Simulacro'**
  String get iaModeSim;

  /// No description provided for @iaModeTools.
  ///
  /// In es, this message translates to:
  /// **'Herramientas'**
  String get iaModeTools;

  /// No description provided for @iaScanStep1.
  ///
  /// In es, this message translates to:
  /// **'PASO 1 — ¿Qué necesitas?'**
  String get iaScanStep1;

  /// No description provided for @iaScanHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Resúmeme esto, Resuelve los ejercicios...'**
  String get iaScanHint;

  /// No description provided for @iaScanStep2.
  ///
  /// In es, this message translates to:
  /// **'PASO 2 — Carga archivo o envía solo texto'**
  String get iaScanStep2;

  /// No description provided for @iaScanCamera.
  ///
  /// In es, this message translates to:
  /// **'Cámara'**
  String get iaScanCamera;

  /// No description provided for @iaScanGallery.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get iaScanGallery;

  /// No description provided for @iaScanSendText.
  ///
  /// In es, this message translates to:
  /// **'Enviar solo texto (sin imagen)'**
  String get iaScanSendText;

  /// No description provided for @iaAnalyzing.
  ///
  /// In es, this message translates to:
  /// **'Analizando...'**
  String get iaAnalyzing;

  /// No description provided for @iaAIResponse.
  ///
  /// In es, this message translates to:
  /// **'Respuesta de la IA'**
  String get iaAIResponse;

  /// No description provided for @iaSavePDF.
  ///
  /// In es, this message translates to:
  /// **'Guardar PDF'**
  String get iaSavePDF;

  /// No description provided for @iaNewQuery.
  ///
  /// In es, this message translates to:
  /// **'Nueva consulta'**
  String get iaNewQuery;

  /// No description provided for @notifHabitTitle.
  ///
  /// In es, this message translates to:
  /// **'⏰ Hora de tu habito!'**
  String get notifHabitTitle;

  /// No description provided for @notifHabitBody.
  ///
  /// In es, this message translates to:
  /// **'Es momento de: {name}'**
  String notifHabitBody(String name);

  /// No description provided for @notifExamTodayTitle.
  ///
  /// In es, this message translates to:
  /// **'📚 Hoy es tu examen!'**
  String get notifExamTodayTitle;

  /// No description provided for @notifExamTodayBody.
  ///
  /// In es, this message translates to:
  /// **'Tu examen de {course} empieza hoy. Mucho exito!'**
  String notifExamTodayBody(String course);

  /// No description provided for @notifExam2DaysTitle.
  ///
  /// In es, this message translates to:
  /// **'⚠️ Examen en 2 dias!'**
  String get notifExam2DaysTitle;

  /// No description provided for @notifExam2DaysBody.
  ///
  /// In es, this message translates to:
  /// **'Tu examen de {course} es pasado manana. Estudia hoy!'**
  String notifExam2DaysBody(String course);

  /// No description provided for @notifExam1DayTitle.
  ///
  /// In es, this message translates to:
  /// **'🚨 Examen manana!'**
  String get notifExam1DayTitle;

  /// No description provided for @notifExam1DayBody.
  ///
  /// In es, this message translates to:
  /// **'Tu examen de {course} es manana. Repasa bien hoy!'**
  String notifExam1DayBody(String course);

  /// No description provided for @notifMissionsTitle.
  ///
  /// In es, this message translates to:
  /// **'🎯 Misiones del día'**
  String get notifMissionsTitle;

  /// No description provided for @notifMissionsPending.
  ///
  /// In es, this message translates to:
  /// **'Tienes {count} {word} pendientes. ¡Gana monedas y XP!'**
  String notifMissionsPending(int count, String word);

  /// No description provided for @notifMissionsGeneral.
  ///
  /// In es, this message translates to:
  /// **'¡Completa tus misiones diarias y gana monedas y XP!'**
  String get notifMissionsGeneral;

  /// No description provided for @misionSingular.
  ///
  /// In es, this message translates to:
  /// **'misión'**
  String get misionSingular;

  /// No description provided for @misionPlural.
  ///
  /// In es, this message translates to:
  /// **'misiones'**
  String get misionPlural;

  /// No description provided for @notifStreakTitle.
  ///
  /// In es, this message translates to:
  /// **'🔥 ¡No pierdas tu racha de {days} días!'**
  String notifStreakTitle(int days);

  /// No description provided for @notifStreakBody.
  ///
  /// In es, this message translates to:
  /// **'Completa aunque sea una actividad hoy para mantener la racha.'**
  String get notifStreakBody;

  /// No description provided for @notifStudyTitle.
  ///
  /// In es, this message translates to:
  /// **'📚 Hora de estudiar'**
  String get notifStudyTitle;

  /// No description provided for @notifStudyBody.
  ///
  /// In es, this message translates to:
  /// **'Mantén el hábito: 20 minutos al día hacen la diferencia.'**
  String get notifStudyBody;

  /// No description provided for @myCourses.
  ///
  /// In es, this message translates to:
  /// **'Mis cursos'**
  String get myCourses;

  /// No description provided for @todayShort.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get todayShort;

  /// No description provided for @tomorrowShort.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get tomorrowShort;

  /// No description provided for @daysShort.
  ///
  /// In es, this message translates to:
  /// **'{n} días'**
  String daysShort(int n);

  /// No description provided for @rewardCoins30days.
  ///
  /// In es, this message translates to:
  /// **'🪙 +{n} monedas — ¡Racha de 30 días!'**
  String rewardCoins30days(int n);

  /// No description provided for @rewardCoinsWeekly.
  ///
  /// In es, this message translates to:
  /// **'🪙 +{n} monedas — ¡Racha semanal!'**
  String rewardCoinsWeekly(int n);

  /// No description provided for @rewardCoinsDaily.
  ///
  /// In es, this message translates to:
  /// **'🪙 +{n} monedas de recompensa diaria'**
  String rewardCoinsDaily(int n);

  /// No description provided for @adNotNow.
  ///
  /// In es, this message translates to:
  /// **'Anuncio no disponible en este momento'**
  String get adNotNow;

  /// No description provided for @refTitle.
  ///
  /// In es, this message translates to:
  /// **'Programa de Referidos'**
  String get refTitle;

  /// No description provided for @refMyCode.
  ///
  /// In es, this message translates to:
  /// **'Tu código de referido'**
  String get refMyCode;

  /// No description provided for @refCopyCode.
  ///
  /// In es, this message translates to:
  /// **'Copiar'**
  String get refCopyCode;

  /// No description provided for @refShareCode.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get refShareCode;

  /// No description provided for @refCodeCopied.
  ///
  /// In es, this message translates to:
  /// **'¡Código copiado al portapapeles!'**
  String get refCodeCopied;

  /// No description provided for @refShareText.
  ///
  /// In es, this message translates to:
  /// **'¡Únete a EstudiApp con mi código {codigo} y recibe 50 monedas de bienvenida! 🎓\n\nEstudia con IA, gamifica tus hábitos y mejora tus notas. ¡Descárgala gratis!'**
  String refShareText(String codigo);

  /// No description provided for @refTotalCoins.
  ///
  /// In es, this message translates to:
  /// **'Total ganado: {n} 🪙'**
  String refTotalCoins(int n);

  /// No description provided for @refHowItWorks.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo funciona?'**
  String get refHowItWorks;

  /// No description provided for @refStep1.
  ///
  /// In es, this message translates to:
  /// **'Comparte tu código con un amigo'**
  String get refStep1;

  /// No description provided for @refStep2.
  ///
  /// In es, this message translates to:
  /// **'Tu amigo se registra y lo ingresa'**
  String get refStep2;

  /// No description provided for @refStep3.
  ///
  /// In es, this message translates to:
  /// **'¡Ambos reciben monedas al instante!'**
  String get refStep3;

  /// No description provided for @refApplyCode.
  ///
  /// In es, this message translates to:
  /// **'Tengo un código de amigo'**
  String get refApplyCode;

  /// No description provided for @refApplyTitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresar código de amigo'**
  String get refApplyTitle;

  /// No description provided for @refApplyHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: WILLY2026'**
  String get refApplyHint;

  /// No description provided for @refApplyBtn.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get refApplyBtn;

  /// No description provided for @refApplyOk.
  ///
  /// In es, this message translates to:
  /// **'¡Código aplicado! Recibiste 50 monedas 🎉'**
  String get refApplyOk;

  /// No description provided for @refApplyAlreadyUsed.
  ///
  /// In es, this message translates to:
  /// **'Ya usaste un código de referido anteriormente'**
  String get refApplyAlreadyUsed;

  /// No description provided for @refApplyInvalid.
  ///
  /// In es, this message translates to:
  /// **'Código inválido. Revisa y vuelve a intentarlo'**
  String get refApplyInvalid;

  /// No description provided for @refApplyOwn.
  ///
  /// In es, this message translates to:
  /// **'No puedes usar tu propio código 😄'**
  String get refApplyOwn;

  /// No description provided for @refApplyError.
  ///
  /// In es, this message translates to:
  /// **'Error al aplicar el código. Intenta de nuevo'**
  String get refApplyError;

  /// No description provided for @refCodeError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu código. Revisa tu conexión e inténtalo de nuevo.'**
  String get refCodeError;

  /// No description provided for @refHistory.
  ///
  /// In es, this message translates to:
  /// **'Mis referidos'**
  String get refHistory;

  /// No description provided for @refNoHistory.
  ///
  /// In es, this message translates to:
  /// **'Aún no has referido a nadie'**
  String get refNoHistory;

  /// No description provided for @refNoHistoryDesc.
  ///
  /// In es, this message translates to:
  /// **'Comparte tu código y gana 100 monedas por cada amigo que se una'**
  String get refNoHistoryDesc;

  /// No description provided for @refFriendJoined.
  ///
  /// In es, this message translates to:
  /// **'Se unió el {fecha}'**
  String refFriendJoined(String fecha);

  /// No description provided for @refPromptTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Tienes un código de amigo?'**
  String get refPromptTitle;

  /// No description provided for @refPromptBody.
  ///
  /// In es, this message translates to:
  /// **'Si alguien te invitó a EstudiApp, ingresa su código y recibe 50 monedas de bienvenida 🎁'**
  String get refPromptBody;

  /// No description provided for @refPromptSkip.
  ///
  /// In es, this message translates to:
  /// **'No tengo código'**
  String get refPromptSkip;

  /// No description provided for @gridReferidos.
  ///
  /// In es, this message translates to:
  /// **'Referidos'**
  String get gridReferidos;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
