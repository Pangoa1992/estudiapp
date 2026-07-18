// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'EstudiApp';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get save => 'Guardar';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Eliminar';

  @override
  String get seeAll => 'Ver todos';

  @override
  String get add => 'Agregar';

  @override
  String get back => 'Volver';

  @override
  String get next => 'Siguiente';

  @override
  String get skip => 'Saltar';

  @override
  String get retry => 'Reintentar';

  @override
  String get loading => 'Cargando...';

  @override
  String get error => 'Error';

  @override
  String get close => 'Cerrar';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get newLabel => 'Nuevo';

  @override
  String get selected => 'Seleccionado';

  @override
  String get redeem => 'Canjear';

  @override
  String get greetingMorning => 'Buenos días,';

  @override
  String get greetingAfternoon => 'Buenas tardes,';

  @override
  String get greetingEvening => 'Buenas noches,';

  @override
  String streakDays(int count) {
    return '$count días de racha';
  }

  @override
  String get shieldAvailable => 'Escudo disponible';

  @override
  String get shieldNone => 'Sin escudo esta semana';

  @override
  String get startPomodoro => 'Iniciar Pomodoro';

  @override
  String get studyWithAI => 'Estudiar con IA';

  @override
  String get upcomingExamsTitle => 'EXÁMENES PRÓXIMOS';

  @override
  String get habitsTodayTitle => 'HÁBITOS DE HOY';

  @override
  String get moreFeaturesTitle => 'MÁS FUNCIONES';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get addExam => 'Agregar examen';

  @override
  String get addHabit => 'Agregar hábito';

  @override
  String examToday(String course) {
    return '¡Hoy es tu examen de $course!';
  }

  @override
  String examTomorrow(String course) {
    return 'Mañana: examen de $course';
  }

  @override
  String examInDays(String course, int days) {
    return 'Examen de $course en $days días';
  }

  @override
  String get tapToStudyAI => 'Toca para estudiar con IA →';

  @override
  String get adminPanel => 'Panel Admin 👁️';

  @override
  String get batteryTitle => 'Activa las notificaciones';

  @override
  String get batteryBody =>
      'Para recibir recordatorios desactiva la optimización de batería para EstudiApp.\n\nAjustes → Apps → EstudiApp → Desactiva \"Pausar actividades no utilizadas\"';

  @override
  String get batteryNotNow => 'Ahora no';

  @override
  String get batterySettings => 'Ir a Ajustes';

  @override
  String get gridFlashcards => 'Flashcards SRS';

  @override
  String get gridMyGrades => 'Mis Notas';

  @override
  String get gridWellbeing => 'Mi Bienestar';

  @override
  String get gridPremium => 'Premium';

  @override
  String get gridAcademy => 'Mi Academia';

  @override
  String get gridPdfSim => 'PDF Simulacro';

  @override
  String get gridGroups => 'Grupos';

  @override
  String get gridFeynman => 'Feynman';

  @override
  String get gridRealCases => 'Casos Reales';

  @override
  String get gridVirtual => 'Aula Virtual';

  @override
  String get gridSimulacros => 'Simulacros';

  @override
  String get gridStreak => 'Racha';

  @override
  String get gridAchievements => 'Mis Logros';

  @override
  String get gridDashboard => 'Dashboard';

  @override
  String get gridStats => 'Estadísticas';

  @override
  String get gridRanking => 'Ranking';

  @override
  String get gridNotifications => 'Notificaciones';

  @override
  String get gridStore => 'Tienda';

  @override
  String get gridMissions => 'Misiones';

  @override
  String get loginSubtitle =>
      'Organiza tus examenes,\ncumple tus habitos y no reprobes';

  @override
  String get continueGoogle => 'Continuar con Google';

  @override
  String get freeForever => 'Gratis para siempre · Sin tarjeta requerida';

  @override
  String get featureStreak => 'Racha diaria';

  @override
  String get featureCourses => 'Tus cursos';

  @override
  String get featurePomodoro => 'Pomodoro';

  @override
  String get onb1Title => 'Construye tu racha';

  @override
  String get onb1Sub =>
      'Ingresa cada día y mantén tu racha activa. Recibe recordatorios a las 8AM, 2PM y 8PM para no olvidarlo.';

  @override
  String get onb2Title => 'Estudia con IA';

  @override
  String get onb2Sub =>
      'Genera resúmenes, flashcards, simulacros y planes de estudio con inteligencia artificial. También resuelve fotos de tus ejercicios.';

  @override
  String get onb3Title => 'Organiza tus estudios';

  @override
  String get onb3Sub =>
      'Registra tus hábitos diarios, controla tus exámenes próximos y genera documentos académicos listos para entregar.';

  @override
  String get onb4Title => 'Nunca olvides nada';

  @override
  String get onb4Sub =>
      'Activa las notificaciones para recibir recordatorios de tus hábitos, alertas de exámenes y motivación diaria.';

  @override
  String get getStarted => '¡Empezar ahora!';

  @override
  String get offlineTitle => 'Sin conexión — Modo offline';

  @override
  String get offlineBody => 'Mostrando datos del último acceso';

  @override
  String get welcomeStudy => '¡A estudiar! 💪';

  @override
  String mot100(int racha) {
    return '¡$racha días imparable! Nivel centurión 🚀';
  }

  @override
  String mot30(int racha) {
    return '¡$racha días de racha! Eres una leyenda 👑';
  }

  @override
  String get mot14 => '¡Dos semanas seguidas! Hábito forjado ⚡';

  @override
  String get mot7 => '¡Una semana entera! Estás en fuego 🔥';

  @override
  String get mot3 => '¡Vas bien! No rompas la racha ahora 💪';

  @override
  String get mot1 => '¡Buen comienzo! Mantén el ritmo ✨';

  @override
  String get mot0 => 'Hoy es un gran día para estudiar 📚';

  @override
  String get shieldReady => '🛡️ Escudo listo';

  @override
  String get shieldEmpty => '🛡️ Sin escudo';

  @override
  String get myProfile => 'Mi perfil';

  @override
  String get currentStreak => 'Racha actual';

  @override
  String get maxStreak => 'Racha máxima';

  @override
  String get activeDays => 'Días activos';

  @override
  String get viewAchievements => 'Ver mis logros';

  @override
  String get streakHistory => 'Historial de racha';

  @override
  String get academicProfiles => 'Perfiles académicos';

  @override
  String get appearance => 'Apariencia';

  @override
  String get themeDark => '🌙 Oscuro';

  @override
  String get themeSystem => '⚙️ Sistema';

  @override
  String get themeLight => '☀️ Claro';

  @override
  String get darkNow => 'oscuro ahora';

  @override
  String get lightNow => 'claro ahora';

  @override
  String get university => 'Universidad';

  @override
  String get career => 'Carrera';

  @override
  String get tapToSelect => 'Toca para seleccionar';

  @override
  String get selectCareer => 'Selecciona tu carrera';

  @override
  String get premiumActive => 'EstudiApp Premium activo';

  @override
  String get unlockPremium => 'Desbloquear Premium';

  @override
  String validUntilDate(int day, int month, int year) {
    return 'Válido hasta $day/$month/$year';
  }

  @override
  String get premiumFeaturesDesc => 'PDF simulacros, grupos de estudio y más';

  @override
  String get statsSection => 'ESTADÍSTICAS';

  @override
  String get habitsLabel => 'Hábitos';

  @override
  String get todayLabel => 'Hoy';

  @override
  String get examsLabel => 'Exámenes';

  @override
  String get coursesLabel => 'Cursos';

  @override
  String get passedLabel => 'Aprobados';

  @override
  String get achievementsLabel => 'Logros';

  @override
  String get notSpecified => 'No especificado';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get langSpanish => '🇪🇸 Español';

  @override
  String get langEnglish => '🇺🇸 English';

  @override
  String get premiumTitle => 'EstudiApp Premium';

  @override
  String get premiumSlogan => 'Todo el poder del aprendizaje, sin límites';

  @override
  String get premiumIncludes => 'QUÉ INCLUYE PREMIUM';

  @override
  String get choosePlan => 'ELIGE TU PLAN';

  @override
  String get recommended => 'RECOMENDADO';

  @override
  String get monthlyLabel => 'MENSUAL';

  @override
  String get perYear => 'por año';

  @override
  String get perMonth => 'por mes';

  @override
  String get save45pct => 'AHORRAS 45%';

  @override
  String get tryFree => 'Probar 7 días gratis';

  @override
  String get tryFreeSubtitle =>
      'Requiere método de pago · Renueva automáticamente';

  @override
  String get trialNeedsPaymentMethod =>
      'Necesitas un método de pago en Google Play para activar la prueba gratuita. Google no te cobrará durante los 7 días de prueba.';

  @override
  String subscribeBtn(String price, String period) {
    return 'Suscribirse — $price/$period';
  }

  @override
  String get notAvailable => 'No disponible en este dispositivo';

  @override
  String get restorePurchase => 'Restaurar compra anterior';

  @override
  String get securePayment =>
      'Pago seguro a través de Google Play · Cancela cuando quieras';

  @override
  String get premiumSuccess => '¡Premium activado con éxito!';

  @override
  String get paymentPending => 'Pago pendiente de confirmación bancaria...';

  @override
  String paymentError(String message) {
    return 'Error en el pago: $message';
  }

  @override
  String get trialSuccess =>
      '¡7 días Premium activados! Disfruta sin límites 🎉';

  @override
  String get trialUsed => 'Ya usaste el período de prueba gratuito.';

  @override
  String get alreadyPremium => '¡Ya tienes Premium activo!';

  @override
  String get billingAnnual => 'Cobro anual vía Google Play';

  @override
  String get billingMonthly => 'Cobro mensual vía Google Play';

  @override
  String activeUntilDate(int day, int month, int year) {
    return '✓ Activo hasta $day/$month/$year';
  }

  @override
  String fromPrice(String price) {
    return 'Desde $price/mes · Cancela cuando quieras';
  }

  @override
  String get compFree => 'Gratis';

  @override
  String get compPremium => 'Premium';

  @override
  String get compAI => 'Asistente IA';

  @override
  String get comp5day => '5/día';

  @override
  String get compUnlimited => 'Ilimitado';

  @override
  String get compFlashcards => 'Flashcards SRS';

  @override
  String get compSimulacros => 'Simulacros';

  @override
  String get comp5questions => '5 preguntas';

  @override
  String get compPDF => 'PDF a Simulacro';

  @override
  String get compGroups => 'Grupos de estudio';

  @override
  String get compTeacher => 'Panel Docente';

  @override
  String get compNoAds => 'Sin anuncios';

  @override
  String get b1Title => 'Panel de Docente';

  @override
  String get b1Desc => 'Crea tu academia, agrega alumnos y gestiona exámenes';

  @override
  String get b2Title => 'PDF a Simulacro';

  @override
  String get b2Desc =>
      'Sube exámenes reales en PDF y la IA los convierte a tests interactivos';

  @override
  String get b3Title => 'Grupos de Estudio';

  @override
  String get b3Desc => 'Estudia en tiempo real con tus compañeros';

  @override
  String get b4Title => 'Notificaciones Inteligentes';

  @override
  String get b4Desc =>
      'La IA programa tus recordatorios según tus exámenes y racha';

  @override
  String get b5Title => 'IA sin límites';

  @override
  String get b5Desc =>
      'Genera contenido, flashcards y documentos sin restricciones';

  @override
  String get b6Title => 'Simulacros de Admisión';

  @override
  String get b6Desc =>
      'Acceso a todos los países y tipos de examen de admisión';

  @override
  String get myHabits => 'Mis habitos';

  @override
  String get newHabit => 'Nuevo habito';

  @override
  String get editHabit => 'Editar habito';

  @override
  String get habitName => 'Nombre del habito';

  @override
  String get selectTime => 'Seleccionar hora';

  @override
  String get frequency => 'Frecuencia:';

  @override
  String get iconPickerLabel => 'Icono:';

  @override
  String get noHabits => 'No tienes habitos';

  @override
  String get tapPlusToAdd => 'Toca + para agregar uno';

  @override
  String get addHabitBtn => 'Agregar habito';

  @override
  String get iconStudy => 'Estudio';

  @override
  String get iconWater => 'Agua';

  @override
  String get iconExercise => 'Ejercicio';

  @override
  String get iconNotes => 'Apuntes';

  @override
  String get iconSleep => 'Dormir';

  @override
  String get iconEat => 'Comer';

  @override
  String get iconMusic => 'Musica';

  @override
  String get iconMeditation => 'Meditacion';

  @override
  String get freqDaily => 'Diario';

  @override
  String get freqMon => 'Lun';

  @override
  String get freqTue => 'Mar';

  @override
  String get freqWed => 'Mie';

  @override
  String get freqThu => 'Jue';

  @override
  String get freqFri => 'Vie';

  @override
  String get freqSat => 'Sab';

  @override
  String get freqSun => 'Dom';

  @override
  String get myExams => 'Mis exámenes';

  @override
  String get newExam => 'Nuevo examen';

  @override
  String get editExam => 'Editar examen';

  @override
  String get courseNameLabel => 'Nombre del curso';

  @override
  String get selectExamTime => 'Seleccionar hora del examen';

  @override
  String get examNotesLabel => 'Notas del examen (temas, apuntes...)';

  @override
  String get notifAlert =>
      'Recibirás alertas 2 días antes, 1 día antes y el mismo día del examen';

  @override
  String get addExamBtn => 'Agregar examen';

  @override
  String get examCompleted => '¡Examen completado! 🎓';

  @override
  String scoreLabel(int score) {
    return 'Nota: $score / 20';
  }

  @override
  String get approved => '¡Aprobado! 🎉';

  @override
  String get notApproved => 'No aprobado 💪';

  @override
  String get approvedShort => '¡Aprobado!';

  @override
  String get notApprovedShort => 'No aprobado';

  @override
  String get notesLabel => 'Notas:';

  @override
  String get noNotes => 'Sin notas';

  @override
  String get exportCalendar => 'Exportar a Calendar';

  @override
  String exportedN(int count) {
    return '$count examen(es) exportado(s) a Google Calendar';
  }

  @override
  String get noExportsMsg =>
      'No se exportaron examenes (verifica permisos o si hay proximos)';

  @override
  String get calendarError => 'Error al conectar con Google Calendar';

  @override
  String get showCompleted => 'Completados';

  @override
  String get pomodoroTitle => 'Pomodoro';

  @override
  String get breakSession => '☕ Tiempo de descanso';

  @override
  String get studySession => '📚 Tiempo de estudio';

  @override
  String get sessionsToday => 'sesiones hoy';

  @override
  String get pomCoinSnack => '🪙 +10 monedas por completar sesión';

  @override
  String get missionsTitle => 'Misiones';

  @override
  String get dailyMissions => 'MISIONES DIARIAS';

  @override
  String get dailyRenewal => 'Se renuevan cada día';

  @override
  String get weeklyMissions => 'MISIONES SEMANALES';

  @override
  String get weeklyRenewal => 'Se renuevan cada lunes';

  @override
  String levelTitle(int level, String name) {
    return 'Nivel $level — $name';
  }

  @override
  String xpProgress(int xpCurrent, int xpNext) {
    return '$xpCurrent / $xpNext XP';
  }

  @override
  String get howToEarnXP => 'Cómo ganar XP';

  @override
  String get tipDailyMission => 'Completar misiones diarias';

  @override
  String get tipWeeklyMission => 'Completar misiones semanales';

  @override
  String get tipDailyLogin => 'Recompensa de inicio diario';

  @override
  String get claimBtn => 'Reclamar';

  @override
  String get storeTitle => 'Tienda';

  @override
  String get storeSubtitle => 'Canjea tus monedas por recompensas exclusivas';

  @override
  String get howEarnCoins => '¿Cómo ganar 🪙?';

  @override
  String get insufficientCoins => '🪙 Monedas insuficientes';

  @override
  String itemActivated(String name) {
    return '✅ $name activado';
  }

  @override
  String get itemShieldTitle => 'Escudo Extra';

  @override
  String get itemShieldDesc => 'Protege tu racha un día adicional sin perderla';

  @override
  String get itemBoostTitle => 'Boost de Racha x2';

  @override
  String get itemBoostDesc =>
      'Duplica las monedas de racha diaria durante 24 horas';

  @override
  String get itemThemeTitle => 'Tema Oscuro Premium';

  @override
  String get itemThemeDesc => 'Activa el tema oscuro especial de la app';

  @override
  String get earnPomodoro => 'Completar sesión Pomodoro';

  @override
  String get earnSimulacro => 'Completar un simulacro';

  @override
  String get earnPerfectSim => 'Sacar puntaje perfecto en simulacro';

  @override
  String get earnDailyStreak => 'Mantener racha diaria';

  @override
  String get earnIA => 'Usar herramienta de IA';

  @override
  String get earnDailyReward => 'Recompensa diaria al abrir la app';

  @override
  String get achievementsTitle => 'Mis logros';

  @override
  String get obtainedLabel => 'Obtenidos';

  @override
  String get pendingLabel => 'Por obtener';

  @override
  String get progressLabel => 'Progreso';

  @override
  String percentComplete(int pct) {
    return '$pct% completado';
  }

  @override
  String achievementUnlock(String title) {
    return '¡Desbloqueé \"$title\" en EstudiApp! 📚';
  }

  @override
  String get achPrimerHabitoT => 'Primer paso';

  @override
  String get achPrimerHabitoD => 'Completa tu primer hábito';

  @override
  String get achRacha3T => 'En llamas';

  @override
  String get achRacha3D => 'Mantén una racha de 3 días';

  @override
  String get achRacha7T => 'Imparable';

  @override
  String get achRacha7D => 'Mantén una racha de 7 días';

  @override
  String get achRacha14T => 'Flujo constante';

  @override
  String get achRacha14D => 'Mantén una racha de 14 días';

  @override
  String get achRacha30T => 'Leyenda';

  @override
  String get achRacha30D => 'Mantén una racha de 30 días';

  @override
  String get achRacha100T => 'Centurión';

  @override
  String get achRacha100D => 'Mantén una racha de 100 días';

  @override
  String get achPrimerExamenT => 'Estudiante';

  @override
  String get achPrimerExamenD => 'Agrega tu primer examen';

  @override
  String get achExamenCompletadoT => 'Aprobado';

  @override
  String get achExamenCompletadoD => 'Completa tu primer examen';

  @override
  String get achCincoHabitosT => 'Disciplinado';

  @override
  String get achCincoHabitosD => 'Agrega 5 hábitos';

  @override
  String get achPomodoro1T => 'Enfocado';

  @override
  String get achPomodoro1D => 'Completa tu primera sesión Pomodoro';

  @override
  String get achIa1T => 'IA Master';

  @override
  String get achIa1D => 'Usa la IA para estudiar por primera vez';

  @override
  String get achIa50T => 'Experto IA';

  @override
  String get achIa50D => 'Realiza 50 búsquedas con la IA';

  @override
  String get achSimulacros10T => 'Examinador';

  @override
  String get achSimulacros10D => 'Completa 10 simulacros';

  @override
  String get achPrimerSimulacroT => 'Primer simulacro';

  @override
  String get achPrimerSimulacroD => 'Completa tu primer simulacro';

  @override
  String get achNotaPerfectaT => 'Nota perfecta';

  @override
  String get achNotaPerfectaD => 'Obtén 20/20 en un examen';

  @override
  String get achHabitosDiaT => 'Constante';

  @override
  String get achHabitosDiaD => 'Completa todos tus hábitos en un día';

  @override
  String get admisionTitle => 'Simulacros de Admisión';

  @override
  String get admisionSubtitle =>
      'Practica con preguntas al estilo de los exámenes reales';

  @override
  String get countryLabel => 'PAÍS';

  @override
  String get examLabel => 'EXAMEN';

  @override
  String get questionsLabel => 'CANTIDAD DE PREGUNTAS';

  @override
  String get recentHistory => 'HISTORIAL RECIENTE';

  @override
  String get noSimulacros => 'Aún no has hecho simulacros';

  @override
  String get historyError => 'Error al cargar historial';

  @override
  String correctOf(int correct, int total) {
    return '$correct/$total correctas';
  }

  @override
  String questionCounter(int current, int total) {
    return 'Pregunta $current / $total';
  }

  @override
  String get reviewAnswers => 'REVISIÓN DE RESPUESTAS';

  @override
  String get yourAnswer => 'Tu respuesta:';

  @override
  String get correctAnswer => 'Correcta:';

  @override
  String get resultExcellent => '¡Excelente puntaje! 🎉';

  @override
  String get resultGood => '¡Bien! Sigue practicando 💪';

  @override
  String get resultTryMore => 'No te rindas, practica más';

  @override
  String get anotherSim => 'Otro simulacro';

  @override
  String startSim(String country) {
    return 'Iniciar Simulacro — $country';
  }

  @override
  String get generatingAI => 'Generando simulacro con IA...';

  @override
  String get simError => 'Error al generar el simulacro. Intenta de nuevo.';

  @override
  String get previousQuestion => 'Anterior';

  @override
  String get seeResult => 'Ver resultado';

  @override
  String get simPremiumTitle => '🔒 Función Premium';

  @override
  String get simPremiumBody => 'Más de 5 simulacros al día requiere Premium.';

  @override
  String get simPremiumBtn => 'Ver Premium';

  @override
  String get iaTitle => 'Estudiar con IA';

  @override
  String get iaSearchesExhausted => 'Agotadas';

  @override
  String iaSearchesToday(int count) {
    return '$count hoy';
  }

  @override
  String get iaLimitTitle => 'Sin búsquedas disponibles';

  @override
  String get iaLimitBody =>
      'Usaste tus 5 búsquedas gratuitas de hoy.\nVuelve mañana o gana más ahora mismo.';

  @override
  String get iaWatchAdBtn => 'Ver anuncio  (+3 búsquedas gratis)';

  @override
  String get iaPremiumBtn => 'Hacerse Premium — búsquedas ilimitadas';

  @override
  String get iaAdLoading => 'Anuncio cargando, intenta de nuevo en un momento';

  @override
  String get iaAdNotAvail => 'Anuncio no disponible. Intenta en un momento.';

  @override
  String get iaGot3 => '¡Ganaste 3 búsquedas extra! 🎉';

  @override
  String get iaGot2Bonus =>
      '¡Ganaste 2 búsquedas extra por completar el simulacro! 🎯';

  @override
  String get iaClearChat => 'Limpiar chat';

  @override
  String get iaModeStudy => 'Estudiar';

  @override
  String get iaModeScanner => 'Scanner';

  @override
  String get iaModeDocs => 'Docs';

  @override
  String get iaModeSim => 'Simulacro';

  @override
  String get iaModeTools => 'Herramientas';

  @override
  String get iaScanStep1 => 'PASO 1 — ¿Qué necesitas?';

  @override
  String get iaScanHint => 'Ej: Resúmeme esto, Resuelve los ejercicios...';

  @override
  String get iaScanStep2 => 'PASO 2 — Carga archivo o envía solo texto';

  @override
  String get iaScanCamera => 'Cámara';

  @override
  String get iaScanGallery => 'Galería';

  @override
  String get iaScanSendText => 'Enviar solo texto (sin imagen)';

  @override
  String get iaAnalyzing => 'Analizando...';

  @override
  String get iaAIResponse => 'Respuesta de la IA';

  @override
  String get iaSavePDF => 'Guardar PDF';

  @override
  String get iaNewQuery => 'Nueva consulta';

  @override
  String get notifHabitTitle => '⏰ Hora de tu habito!';

  @override
  String notifHabitBody(String name) {
    return 'Es momento de: $name';
  }

  @override
  String get notifExamTodayTitle => '📚 Hoy es tu examen!';

  @override
  String notifExamTodayBody(String course) {
    return 'Tu examen de $course empieza hoy. Mucho exito!';
  }

  @override
  String get notifExam2DaysTitle => '⚠️ Examen en 2 dias!';

  @override
  String notifExam2DaysBody(String course) {
    return 'Tu examen de $course es pasado manana. Estudia hoy!';
  }

  @override
  String get notifExam1DayTitle => '🚨 Examen manana!';

  @override
  String notifExam1DayBody(String course) {
    return 'Tu examen de $course es manana. Repasa bien hoy!';
  }

  @override
  String get notifMissionsTitle => '🎯 Misiones del día';

  @override
  String notifMissionsPending(int count, String word) {
    return 'Tienes $count $word pendientes. ¡Gana monedas y XP!';
  }

  @override
  String get notifMissionsGeneral =>
      '¡Completa tus misiones diarias y gana monedas y XP!';

  @override
  String get misionSingular => 'misión';

  @override
  String get misionPlural => 'misiones';

  @override
  String notifStreakTitle(int days) {
    return '🔥 ¡No pierdas tu racha de $days días!';
  }

  @override
  String get notifStreakBody =>
      'Completa aunque sea una actividad hoy para mantener la racha.';

  @override
  String get notifStudyTitle => '📚 Hora de estudiar';

  @override
  String get notifStudyBody =>
      'Mantén el hábito: 20 minutos al día hacen la diferencia.';

  @override
  String get myCourses => 'Mis cursos';

  @override
  String get todayShort => 'Hoy';

  @override
  String get tomorrowShort => 'Mañana';

  @override
  String daysShort(int n) {
    return '$n días';
  }

  @override
  String rewardCoins30days(int n) {
    return '🪙 +$n monedas — ¡Racha de 30 días!';
  }

  @override
  String rewardCoinsWeekly(int n) {
    return '🪙 +$n monedas — ¡Racha semanal!';
  }

  @override
  String rewardCoinsDaily(int n) {
    return '🪙 +$n monedas de recompensa diaria';
  }

  @override
  String get adNotNow => 'Anuncio no disponible en este momento';

  @override
  String get refTitle => 'Programa de Referidos';

  @override
  String get refMyCode => 'Tu código de referido';

  @override
  String get refCopyCode => 'Copiar';

  @override
  String get refShareCode => 'Compartir';

  @override
  String get refCodeCopied => '¡Código copiado al portapapeles!';

  @override
  String refShareText(String codigo) {
    return '¡Únete a EstudiApp con mi código $codigo y recibe 50 monedas de bienvenida! 🎓\n\nEstudia con IA, gamifica tus hábitos y mejora tus notas. ¡Descárgala gratis!';
  }

  @override
  String refTotalCoins(int n) {
    return 'Total ganado: $n 🪙';
  }

  @override
  String get refHowItWorks => '¿Cómo funciona?';

  @override
  String get refStep1 => 'Comparte tu código con un amigo';

  @override
  String get refStep2 => 'Tu amigo se registra y lo ingresa';

  @override
  String get refStep3 => '¡Ambos reciben monedas al instante!';

  @override
  String get refApplyCode => 'Tengo un código de amigo';

  @override
  String get refApplyTitle => 'Ingresar código de amigo';

  @override
  String get refApplyHint => 'Ej: WILLY2026';

  @override
  String get refApplyBtn => 'Aplicar';

  @override
  String get refApplyOk => '¡Código aplicado! Recibiste 50 monedas 🎉';

  @override
  String get refApplyAlreadyUsed =>
      'Ya usaste un código de referido anteriormente';

  @override
  String get refApplyInvalid => 'Código inválido. Revisa y vuelve a intentarlo';

  @override
  String get refApplyOwn => 'No puedes usar tu propio código 😄';

  @override
  String get refApplyError => 'Error al aplicar el código. Intenta de nuevo';

  @override
  String get refCodeError =>
      'No pudimos cargar tu código. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get refHistory => 'Mis referidos';

  @override
  String get refNoHistory => 'Aún no has referido a nadie';

  @override
  String get refNoHistoryDesc =>
      'Comparte tu código y gana 100 monedas por cada amigo que se una';

  @override
  String refFriendJoined(String fecha) {
    return 'Se unió el $fecha';
  }

  @override
  String get refPromptTitle => '¿Tienes un código de amigo?';

  @override
  String get refPromptBody =>
      'Si alguien te invitó a EstudiApp, ingresa su código y recibe 50 monedas de bienvenida 🎁';

  @override
  String get refPromptSkip => 'No tengo código';

  @override
  String get gridReferidos => 'Referidos';
}
