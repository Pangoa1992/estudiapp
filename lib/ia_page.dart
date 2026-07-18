import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'services/unity_ads_config.dart';
import 'models/flashcard_srs_model.dart';
import 'services/srs_service.dart';
import 'services/carrera_service.dart';
import 'services/ia_limite_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:share_plus/share_plus.dart';
import 'premium_page.dart';
import 'services/monedas_service.dart';
import 'l10n_helper.dart';

class IAPage extends StatefulWidget {
  const IAPage({super.key});
  @override
  State<IAPage> createState() => _IAPageState();
}

class _IAPageState extends State<IAPage> {
  final TextEditingController _temaController = TextEditingController();
  final TextEditingController _diasController = TextEditingController();
  final TextEditingController _documentoController = TextEditingController();
  final TextEditingController _preguntaScannerController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  List<Map<String, String>> _chatMensajes = [];
  bool _cargandoChat = false;
  String _temaActual = '';

  // ── ADS (Unity Ads) + LÍMITE DIARIO ─────────
  // Unity usa un modelo estático load/show por placement: se precarga con
  // UnityAds.load() y se muestra con UnityAds.showVideoAd(); tras cada show se
  // vuelve a cargar para tener el siguiente listo.
  bool _interstitialLoaded = false;
  int _contadorUsos = 0;
  bool _rewardedLoaded = false;
  int _busquedasRestantes = IaLimiteService.limiteGratuito;

  void _cargarIntersticial() {
    UnityAds.load(
      placementId: UnityAdsConfig.interstitial,
      onComplete: (_) => _interstitialLoaded = true,
      onFailed: (_, error, message) => _interstitialLoaded = false,
    );
  }

  void _mostrarIntersticial() {
    _contadorUsos++;
    if (_contadorUsos % 3 == 0 && _interstitialLoaded) {
      _interstitialLoaded = false;
      UnityAds.showVideoAd(
        placementId: UnityAdsConfig.interstitial,
        onComplete: (_) => _cargarIntersticial(), // precarga el siguiente
        onSkipped: (_) => _cargarIntersticial(),
        onFailed: (_, error, message) => _cargarIntersticial(),
      );
    }
  }

  // ── REWARDED AD (video recompensado de Unity) ──────────
  // Un único placement sirve para el +3 de búsquedas y el +2 de simulacro; el
  // monto de la recompensa lo controla la app, no el anuncio.
  void _cargarRewardedAd() {
    UnityAds.load(
      placementId: UnityAdsConfig.rewarded,
      onComplete: (_) => _rewardedLoaded = true,
      onFailed: (_, error, message) => _rewardedLoaded = false,
    );
  }

  /// Muestra el video recompensado y, si el usuario lo ve completo, otorga
  /// [cantidad] búsquedas extra y muestra [mensaje]. Si lo salta o falla, no
  /// se otorga recompensa. En cualquier caso se precarga el siguiente.
  Future<void> _mostrarRewardedConRecompensa(int cantidad, String mensaje) async {
    if (!_rewardedLoaded) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.iaAdNotAvail)),
        );
      }
      return;
    }
    _rewardedLoaded = false;
    UnityAds.showVideoAd(
      placementId: UnityAdsConfig.rewarded,
      onComplete: (_) async {
        await IaLimiteService.agregarBonus(cantidad: cantidad);
        await _actualizarRestantes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensaje),
              backgroundColor: const Color(0xFF5DE0C5),
            ),
          );
        }
        _cargarRewardedAd(); // precarga el siguiente
      },
      onSkipped: (_) => _cargarRewardedAd(), // salteado → sin recompensa
      onFailed: (_, error, message) => _cargarRewardedAd(),
    );
  }

  // Video recompensado del simulacro (+2 búsquedas). Se muestra sin bloquear si
  // no está cargado (a diferencia de la pasarela, aquí es un extra opcional).
  Future<void> _mostrarRewardedInterstitial() async {
    if (!_rewardedLoaded) return;
    await _mostrarRewardedConRecompensa(2, context.l10n.iaGot2Bonus);
  }

  Future<void> _actualizarRestantes() async {
    final r = await IaLimiteService.restantes();
    if (mounted) setState(() => _busquedasRestantes = r);
  }

  // Video recompensado de la pasarela de límite (+3 búsquedas).
  Future<void> _mostrarRewardedAd() =>
      _mostrarRewardedConRecompensa(
          IaLimiteService.bonusPorAnuncio, context.l10n.iaGot3);

  Future<void> _mostrarPasarela() async {
    if (!mounted) return;
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E2A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF7C6AF7).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Color(0xFF7C6AF7), size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.iaLimitTitle,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.iaLimitBody,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _rewardedLoaded
                    ? () { Navigator.pop(ctx); _mostrarRewardedAd(); }
                    : null,
                icon: const Icon(Icons.play_circle_outline, color: Colors.white),
                label: Text(
                  l10n.iaWatchAdBtn,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5DE0C5),
                  disabledBackgroundColor: const Color(0xFF2A2A3A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (!_rewardedLoaded)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.iaAdLoading,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPage()));
                },
                icon: const Icon(Icons.star_rounded, color: Colors.white),
                label: Text(
                  l10n.iaPremiumBtn,
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C6AF7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel, style: const TextStyle(color: Colors.white38)),
            ),
          ],
        ),
      ),
    );
  }

  /// Verifica el límite diario y descuenta 1 búsqueda.
  /// Devuelve `false` (y muestra la pasarela) si ya se agotó el cupo.
  Future<bool> _verificarYConsumir() async {
    final ok = await IaLimiteService.consumir();
    if (!ok) {
      await _mostrarPasarela();
      return false;
    }
    await _actualizarRestantes();
    // Acumular total histórico de búsquedas IA (para logro ia_50)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('perfiles')
          .doc(user.uid)
          .set({'iaUsosTotal': FieldValue.increment(1)}, SetOptions(merge: true));
    }
    MonedasService.agregar(MonedasService.porIA, 'ia');
    return true;
  }
  // ── FIN ADS + LÍMITE ──────────────────────────────────

  @override
  void initState() {
    super.initState();
    _cargarHistorialChat();
    _cargarIntersticial();
    _cargarRewardedAd();
    _cargarCarrera();
    _actualizarRestantes();
  }

  Future<void> _cargarCarrera() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('perfiles')
          .doc(user.uid)
          .get();
      final carrera = doc.data()?['carrera'] as String? ?? '';
      if (mounted) setState(() => _carrera = carrera);
    } catch (_) {}
  }

  @override
  void dispose() {
    // Unity Ads usa un modelo estático por placement; no hay instancias que
    // liberar (los widgets de banner sí se liberan solos al desmontarse).
    _concepto1Controller.dispose();
    _concepto2Controller.dispose();
    _nemotecniaController.dispose();
    _correctorController.dispose();
    _chatHerramientasController.dispose();
    _chatHerramientasScroll.dispose();
    _temaHerramientasController.dispose();
    _evalController.dispose();
    _evalScroll.dispose();
    _materiasRutaController.dispose();
    _horasRutaController.dispose();
    _typewriterTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarHistorialChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('historial_ia')
          .doc(user.uid)
          .collection('mensajes')
          .orderBy('timestamp', descending: true)
          .limit(40)
          .get();
      final mensajes = snap.docs.reversed
          .map((d) => {'role': d['role'] as String, 'text': d['texto'] as String})
          .toList();
      if (mounted) setState(() => _chatMensajes = mensajes);
    } catch (_) {}
  }

  void _guardarMensajeChat(String role, String texto) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || texto.isEmpty) return;
    FirebaseFirestore.instance
        .collection('historial_ia')
        .doc(user.uid)
        .collection('mensajes')
        .add({
      'role': role,
      'texto': texto,
      'tema': _temaActual,
      'timestamp': Timestamp.now(),
    });
  }

  Future<void> _limpiarChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _chatMensajes = []);
    try {
      final docs = await FirebaseFirestore.instance
          .collection('historial_ia')
          .doc(user.uid)
          .collection('mensajes')
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final d in docs.docs) batch.delete(d.reference);
      await batch.commit();
    } catch (_) {}
  }

  bool _cargando = false;
  String _progreso = '';
  String _resumen = '';
  String _error = '';
  List<Map<String, String>> _preguntas = [];
  List<Map<String, String>> _flashcards = [];
  List<String> _tips = [];
  List<String> _planEstudio = [];
  List<Map<String, String>> _ejercicios = [];
  List<String> _mapaConceptual = [];
  int _tabSeleccionada = 0;
  List<bool> _preguntasAbiertas = [];
  List<bool> _ejerciciosAbiertos = [];
  File? _imagenSeleccionada;
  String _respuestaImagen = '';
  bool _cargandoImagen = false;
  String _documentoGenerado = '';
  bool _cargandoDocumento = false;
  String _tipoDocumento = 'Monografia';
  int _modoActual = 0;
  final ImagePicker _picker = ImagePicker();
  final List<String> _tiposDocumento = ['Monografia', 'Resumen', 'Ensayo', 'Informe', 'Tesis'];
  String _carrera = '';

  final TextEditingController _simulacroTemaController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  String _nivelSeleccionado = 'Universidad';
  String _dificultadSeleccionada = 'Intermedio';
  List<Map<String, dynamic>> _preguntasSimulacro = [];
  List<String?> _respuestasUsuario = [];
  bool _cargandoSimulacro = false;
  bool _simulacroTerminado = false;
  int _preguntaActual = 0;
  final List<String> _niveles = ['Primaria', 'Secundaria', 'Universidad'];
  final List<String> _dificultades = ['Básico', 'Intermedio', 'Avanzado'];

  // ── TYPEWRITER ───────────────────────────────────────────────────────────────
  Timer? _typewriterTimer;

  // ── SIMULACRO HISTORIAL + DEBILIDADES ─────────────────────────────────────────
  bool _analizandoDebilidades = false;
  String _analisisDebilidades = '';

  // ── RUTA DE APRENDIZAJE ───────────────────────────────────────────────────────
  final TextEditingController _materiasRutaController = TextEditingController();
  final TextEditingController _horasRutaController = TextEditingController();
  String _resultadoRuta = '';
  bool _cargandoRuta = false;

  // ── HERRAMIENTAS ─────────────────────────────────────────────────────────────
  int _subModoHerramientas = -1;
  // Comparador
  final TextEditingController _concepto1Controller = TextEditingController();
  final TextEditingController _concepto2Controller = TextEditingController();
  String _resultadoComparador = '';
  bool _cargandoComparador = false;
  // Nemotecnias
  final TextEditingController _nemotecniaController = TextEditingController();
  String _resultadoNemotecnia = '';
  bool _cargandoNemotecnia = false;
  // Corrector
  final TextEditingController _correctorController = TextEditingController();
  String _resultadoCorrector = '';
  bool _cargandoCorrector = false;
  // Feynman / Socrático (chat compartido con contexto diferente)
  List<Map<String, String>> _chatHerramientas = [];
  bool _cargandoChatHerramientas = false;
  final TextEditingController _chatHerramientasController = TextEditingController();
  final ScrollController _chatHerramientasScroll = ScrollController();
  final TextEditingController _temaHerramientasController = TextEditingController();
  bool _chatHerramientasIniciado = false;

  // ── EVALÚAME ──────────────────────────────────────────────────────────────────
  List<Map<String, String>> _evalMensajes = [];
  bool _cargandoEval = false;
  bool _evalIniciado = false;
  final TextEditingController _evalController = TextEditingController();
  final ScrollController _evalScroll = ScrollController();

  static const _cloudRunUrl = 'https://llamaria-2o5lsg4hxa-uc.a.run.app';

  Future<(Map<String, dynamic>?, String?)> _llamarCloudFunction({
    required List<Map<String, dynamic>> messages,
    int maxTokens = 3000,
  }) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      try {
        final cred = await FirebaseAuth.instance.signInAnonymously();
        user = cred.user;
      } catch (e) {
        return (null, 'No se pudo iniciar sesión. Verifica tu conexión.');
      }
    }
    if (user == null) return (null, 'No hay sesión activa. Cierra y vuelve a abrir la app.');
    final String idToken;
    try {
      idToken = await user.getIdToken() ?? '';
    } catch (e) {
      return (null, 'Error de autenticación. Vuelve a abrir la app.');
    }
    try {
      final response = await http.post(
        Uri.parse(_cloudRunUrl),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $idToken'},
        body: jsonEncode({'data': {'messages': messages, 'maxTokens': maxTokens}}),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return (Map<String, dynamic>.from(body['result'] as Map), null);
      }
      if (response.statusCode == 401) return (null, 'Sesión expirada. Vuelve a abrir la app.');
      if (response.statusCode == 429) return (null, 'Demasiadas solicitudes. Espera un momento e intenta de nuevo.');
      if (response.statusCode == 400) return (null, 'La solicitud contiene contenido no válido.');
      return (null, 'Error del servicio IA (${response.statusCode}).');
    } catch (e) {
      return (null, 'Error de conexión. Verifica tu internet.');
    }
  }

  Future<(Map<String, dynamic>?, String?)> _llamarIA(String prompt) async {
    final (data, cfError) = await _llamarCloudFunction(
      messages: [{'role': 'user', 'content': prompt}],
    );
    if (data == null) return (null, cfError);
    try {
      final texto = (data['content'] as List).first['text'] as String;
      String jsonLimpio = texto.trim();
      final inicio = jsonLimpio.indexOf('{');
      final fin = jsonLimpio.lastIndexOf('}');
      if (inicio != -1 && fin != -1) jsonLimpio = jsonLimpio.substring(inicio, fin + 1);
      return (jsonDecode(jsonLimpio) as Map<String, dynamic>, null);
    } catch (e) {
      return (null, 'Error al procesar la respuesta de la IA.');
    }
  }

  Future<String?> _llamarIATexto(String prompt) async {
    final (data, _) = await _llamarCloudFunction(
      messages: [{'role': 'user', 'content': prompt}],
    );
    try {
      return (data?['content'] as List?)?.first['text'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _llamarIAConImagen(String base64Image, String preguntaExtra) async {
    final textoPregunta = preguntaExtra.isNotEmpty
        ? 'Eres un tutor universitario experto con capacidad OCR avanzada. '
          'Analiza esta imagen aunque sea borrosa, oscura o tomada en ángulo. '
          'Primero extrae TODO el texto visible (si algo es ilegible, infiere por contexto y marca con [?]). '
          'Luego responde: "$preguntaExtra". Resuelve paso a paso en español. Sé claro y didáctico.'
        : 'Eres un tutor universitario experto con capacidad OCR avanzada. '
          'Esta imagen puede ser un apunte, libro, ejercicio o examen universitario. '
          'AUNQUE la imagen sea borrosa, tenga mala iluminación o esté en ángulo: '
          '1) Extrae e interpreta TODO el texto visible con máxima precisión. '
          '2) Si algo no está del todo claro, usa el contexto académico para inferirlo y marca con [?] lo que sea definitivamente ilegible. '
          '3) Resuelve y explica todo paso a paso en español. Sé claro y didáctico.';
    final (data, _) = await _llamarCloudFunction(
      messages: [{'role': 'user', 'content': [
        {'type': 'image', 'source': {'type': 'base64', 'media_type': 'image/jpeg', 'data': base64Image}},
        {'type': 'text', 'text': textoPregunta},
      ]}],
      maxTokens: 2000,
    );
    try {
      return (data?['content'] as List?)?.first['text'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _tomarFoto(ImageSource source) async {
    try {
      final XFile? imagen = await _picker.pickImage(source: source, imageQuality: 88, maxWidth: 1600);
      if (imagen == null) return;
      if (!await _verificarYConsumir()) return; // ── LÍMITE DIARIO
      setState(() { _imagenSeleccionada = File(imagen.path); _respuestaImagen = ''; _cargandoImagen = true; });
      final bytes = await _imagenSeleccionada!.readAsBytes();
      final base64Image = base64Encode(bytes);
      final respuesta = await _llamarIAConImagen(base64Image, _preguntaScannerController.text.trim());
      setState(() { _respuestaImagen = respuesta ?? 'No se pudo analizar. Intenta de nuevo.'; _cargandoImagen = false; });
    } catch (e) {
      setState(() { _respuestaImagen = 'Error al procesar la imagen.'; _cargandoImagen = false; });
    }
  }

  Future<void> _preguntarSoloTexto() async {
    final pregunta = _preguntaScannerController.text.trim();
    if (pregunta.isEmpty) return;
    if (!await _verificarYConsumir()) return; // ── LÍMITE DIARIO
    setState(() { _respuestaImagen = ''; _cargandoImagen = true; _imagenSeleccionada = null; });
    final respuesta = await _llamarIATexto(
      'Eres un tutor universitario experto. Responde lo siguiente de forma clara y detallada en español: "$pregunta"',
    );
    setState(() { _respuestaImagen = respuesta ?? 'No se pudo responder. Intenta de nuevo.'; _cargandoImagen = false; });
  }

  Future<void> _subirPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (result == null) return;
      // Verificar tamaño ANTES de consumir la búsqueda para no perderla en vano
      final file = File(result.files.single.path!);
      const maxBytes = 5 * 1024 * 1024;
      if (await file.length() > maxBytes) {
        setState(() { _respuestaImagen = 'El PDF es demasiado grande (máx. 5 MB).'; _cargandoImagen = false; });
        return;
      }
      if (!await _verificarYConsumir()) return; // ── LÍMITE DIARIO
      setState(() { _respuestaImagen = ''; _cargandoImagen = true; });
      final bytes = await file.readAsBytes();
      final base64PDF = base64Encode(bytes);
      final preguntaExtra = _preguntaScannerController.text.trim();
      final textoPregunta = preguntaExtra.isNotEmpty
          ? 'Eres un tutor universitario experto. Analiza este PDF y además responde: "$preguntaExtra". Resuelve TODO paso a paso en español.'
          : 'Eres un tutor universitario experto. Analiza este PDF y resuelve TODO lo que encuentres paso a paso en español.';
      final (data, _) = await _llamarCloudFunction(
        messages: [{'role': 'user', 'content': [
          {'type': 'document', 'source': {'type': 'base64', 'media_type': 'application/pdf', 'data': base64PDF}},
          {'type': 'text', 'text': textoPregunta},
        ]}],
      );
      String respuesta = 'No se pudo analizar el PDF.';
      try { if (data != null) respuesta = (data['content'] as List).first['text'] as String; } catch (_) {}
      setState(() { _respuestaImagen = respuesta; _cargandoImagen = false; });
    } catch (e) {
      setState(() { _respuestaImagen = 'Error al procesar el PDF.'; _cargandoImagen = false; });
    }
  }

  Future<void> _generarDocumento() async {
    if (_documentoController.text.isEmpty) return;
    if (!await _verificarYConsumir()) return; // ── LÍMITE DIARIO
    setState(() { _cargandoDocumento = true; _documentoGenerado = ''; });
    final respuesta = await _llamarIATexto(
      'Eres un escritor academico universitario experto. '
      'Genera una $_tipoDocumento completa sobre: "${_documentoController.text}". '
      'Incluye: introduccion, desarrollo con puntos clave, conclusion y referencias. '
      'Usa lenguaje academico formal en español. Minimo 500 palabras.',
    );
    setState(() { _cargandoDocumento = false; });
    _typewrite(respuesta ?? 'Error al generar. Intenta de nuevo.', (t) => setState(() => _documentoGenerado = t));
    _mostrarIntersticial(); // ── NUEVO: muestra anuncio al generar documento
  }

  Future<void> _descargarPDF() async {
    if (_documentoGenerado.isEmpty) return;
    try {
      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          final parrafos = _documentoGenerado.split('\n');
          return [
            pw.Text('$_tipoDocumento: ${_documentoController.text}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            ...parrafos.map((p) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 6), child: pw.Text(p.replaceAll('#', '').replaceAll('*', '').trim(), style: const pw.TextStyle(fontSize: 11)))),
          ];
        },
      ));
      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final fileName = 'EstudiApp_${_tipoDocumento}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: '$_tipoDocumento generado con EstudiApp');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al compartir: $e')));
    }
  }

  Future<void> _compartirRespuestaScanner() async {
    if (_respuestaImagen.isEmpty) return;
    try {
      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          final parrafos = _respuestaImagen.split('\n');
          return [
            pw.Text('Análisis - EstudiApp', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            ...parrafos.map((p) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text(p.replaceAll('#', '').replaceAll('*', '').trim(), style: const pw.TextStyle(fontSize: 11)),
            )),
          ];
        },
      ));
      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/EstudiApp_Scanner_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Análisis generado con EstudiApp');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _generarSimulacro() async {
    if (_simulacroTemaController.text.isEmpty) return;
    if (!await _verificarYConsumir()) return; // ── LÍMITE DIARIO
    final tema = _simulacroTemaController.text;
    final cantidad = int.tryParse(_cantidadController.text) ?? 5;
    setState(() { _cargandoSimulacro = true; _preguntasSimulacro = []; _respuestasUsuario = []; _simulacroTerminado = false; _preguntaActual = 0; });
    final contextoCarrera = CarreraService.contextoIA(_carrera);
    final prefijoCarrera = contextoCarrera.isNotEmpty ? '$contextoCarrera\n' : '';
    final (respuesta, _) = await _llamarIA(
      '${prefijoCarrera}Genera un simulacro de examen de "$tema" para nivel $_nivelSeleccionado con dificultad $_dificultadSeleccionada. '
      'Crea exactamente $cantidad preguntas de opcion multiple. '
      'Responde SOLO con JSON valido sin texto extra. '
      'Formato: {"preguntas": [{"pregunta": "texto", "opciones": ["A. op1", "B. op2", "C. op3", "D. op4"], "correcta": "A", "explicacion": "por que"}]}. '
      'La clave "correcta" debe ser solo la letra A, B, C o D. Todo en español.',
    );
    if (respuesta == null || respuesta['preguntas'] == null) { setState(() => _cargandoSimulacro = false); return; }
    final preguntas = List<Map<String, dynamic>>.from((respuesta['preguntas'] as List).map((e) => Map<String, dynamic>.from(e)));
    setState(() { _preguntasSimulacro = preguntas; _respuestasUsuario = List.filled(preguntas.length, null); _cargandoSimulacro = false; });
    _mostrarIntersticial(); // ── NUEVO: muestra anuncio al generar simulacro
  }

  void _responderPregunta(String respuesta) => setState(() => _respuestasUsuario[_preguntaActual] = respuesta);

  void _siguientePregunta() {
    if (_preguntaActual < _preguntasSimulacro.length - 1) {
      setState(() => _preguntaActual++);
    } else {
      setState(() { _simulacroTerminado = true; _analisisDebilidades = ''; });
      _guardarSimulacroHistorial();
      _mostrarRewardedInterstitial();
      // Notificación si logra 20/20
      final total = _preguntasSimulacro.length;
      if (total > 0 && _puntaje == total) {
        _notificarLogro(
          'simulacro_perfecto',
          '🏆 ¡Puntuación perfecta!',
          '¡${_puntaje}/$total en ${_simulacroTemaController.text}! Eres una máquina. 🎯',
        );
      }
    }
  }

  int get _puntaje {
    int correctas = 0;
    for (int i = 0; i < _preguntasSimulacro.length; i++) {
      final correcta = _preguntasSimulacro[i]['correcta']?.toString().trim().toUpperCase();
      final respuesta = _respuestasUsuario[i]?.trim().toUpperCase();
      if (correcta != null && respuesta != null && respuesta.startsWith(correcta)) correctas++;
    }
    return correctas;
  }

  Future<void> _enviarMensajeChat() async {
    final pregunta = _chatController.text.trim();
    if (pregunta.isEmpty || _cargandoChat) return;
    if (!await _verificarYConsumir()) return; // ── LÍMITE DIARIO
    _chatController.clear();
    setState(() { _chatMensajes.add({'role': 'user', 'text': pregunta}); _cargandoChat = true; });
    _guardarMensajeChat('user', pregunta);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) _chatScrollController.animateTo(_chatScrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
    final respuesta = await _llamarIATexto(
      'Eres un tutor universitario experto en "$_temaActual". El estudiante pregunta: "$pregunta". Responde de forma clara, didactica y en español. Maximo 200 palabras.',
    );
    final textoRespuesta = respuesta ?? 'No pude responder. Intenta de nuevo.';
    setState(() { _chatMensajes.add({'role': 'ia', 'text': textoRespuesta}); _cargandoChat = false; });
    _guardarMensajeChat('ia', textoRespuesta);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) _chatScrollController.animateTo(_chatScrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  Future<void> _generarContenido() async {
    if (_temaController.text.isEmpty) return;
    if (!await _verificarYConsumir()) return; // ── LÍMITE DIARIO
    final tema = _temaController.text;
    final dias = _diasController.text.isEmpty ? '7' : _diasController.text;
    setState(() {
      _cargando = true; _error = ''; _resumen = '';
      _preguntas = []; _flashcards = []; _tips = [];
      _planEstudio = []; _ejercicios = []; _mapaConceptual = [];
      _preguntasAbiertas = []; _ejerciciosAbiertos = [];
      _chatMensajes = [];
      _evalMensajes = []; _evalIniciado = false;
      _temaActual = tema;
      _progreso = 'Generando contenido con IA...';
    });
    final contexto = CarreraService.contextoIA(_carrera);
    final prefijo = contexto.isNotEmpty ? '$contexto\n' : '';

    // ── OPTIMIZACIÓN: 1 sola llamada API en lugar de 2 (ahorra ~50 % de crédito) ──
    final (data, cfError) = await _llamarCloudFunction(
      messages: [{'role': 'user', 'content':
        '${prefijo}Tengo examen de "$tema" en $dias dias. '
        'Responde SOLO con JSON válido sin texto extra. '
        'Formato exacto: {'
        '"resumen":"3 párrafos del tema",'
        '"preguntas":[{"pregunta":"p1","respuesta":"r1"},{"pregunta":"p2","respuesta":"r2"},{"pregunta":"p3","respuesta":"r3"},{"pregunta":"p4","respuesta":"r4"},{"pregunta":"p5","respuesta":"r5"}],'
        '"flashcards":[{"pregunta":"c1","respuesta":"d1"},{"pregunta":"c2","respuesta":"d2"},{"pregunta":"c3","respuesta":"d3"},{"pregunta":"c4","respuesta":"d4"}],'
        '"tips":["t1","t2","t3","t4","t5"],'
        '"plan":["Dia 1: a","Dia 2: a","Dia 3: a","Dia 4: a"],'
        '"ejercicios":[{"problema":"e1","solucion":"s1"},{"problema":"e2","solucion":"s2"}],'
        '"mapa":["concepto","sub1","sub2","sub3","sub4"]}. Todo en español.'}],
      maxTokens: 5000,
    );
    if (data == null) {
      setState(() { _error = cfError ?? 'Error al generar.'; _cargando = false; _progreso = ''; });
      return;
    }
    Map<String, dynamic> respuesta;
    try {
      final texto = (data['content'] as List).first['text'] as String;
      String jsonLimpio = texto.trim();
      final inicio = jsonLimpio.indexOf('{');
      final fin = jsonLimpio.lastIndexOf('}');
      if (inicio != -1 && fin != -1) jsonLimpio = jsonLimpio.substring(inicio, fin + 1);
      respuesta = jsonDecode(jsonLimpio) as Map<String, dynamic>;
    } catch (_) {
      setState(() { _error = 'Error al procesar la respuesta de la IA.'; _cargando = false; _progreso = ''; });
      return;
    }
    final preguntas = List<Map<String, String>>.from((respuesta['preguntas'] ?? []).map((e) => Map<String, String>.from((e as Map).map((k, v) => MapEntry(k.toString(), v.toString())))));
    final ejercicios = List<Map<String, String>>.from((respuesta['ejercicios'] ?? []).map((e) => Map<String, String>.from((e as Map).map((k, v) => MapEntry(k.toString(), v.toString())))));
    final flashcards = List<Map<String, String>>.from((respuesta['flashcards'] ?? []).map((e) => Map<String, String>.from((e as Map).map((k, v) => MapEntry(k.toString(), v.toString())))));
    setState(() {
      _resumen = respuesta['resumen']?.toString() ?? '';
      _preguntas = preguntas; _flashcards = flashcards;
      _tips = List<String>.from((respuesta['tips'] ?? []).map((e) => e.toString()));
      _planEstudio = List<String>.from((respuesta['plan'] ?? []).map((e) => e.toString()));
      _ejercicios = ejercicios;
      _mapaConceptual = List<String>.from((respuesta['mapa'] ?? []).map((e) => e.toString()));
      _preguntasAbiertas = List.filled(preguntas.length, false);
      _ejerciciosAbiertos = List.filled(ejercicios.length, false);
      _cargando = false; _progreso = '';
    });
    _mostrarIntersticial();
    final iaUser = FirebaseAuth.instance.currentUser;
    if (iaUser != null) {
      FirebaseFirestore.instance.collection('logros').doc(iaUser.uid).set(
        {'obtenidos': FieldValue.arrayUnion(['ia_1'])}, SetOptions(merge: true),
      );
    }
  }

  Future<void> _guardarEnSRS() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _flashcards.isEmpty) return;

    final cursosSnap = await FirebaseFirestore.instance
        .collection('cursos')
        .where('userId', isEqualTo: user.uid)
        .get();

    if (!mounted) return;

    String cursoId = _temaActual;
    String cursoNombre = _temaActual;

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('¿En qué mazo guardar?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF7C6AF7),
                radius: 16,
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 14),
              ),
              title: Text('Mazo: $_temaActual',
                  style: const TextStyle(color: Colors.white)),
              subtitle: const Text('Nuevo mazo con el tema actual',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () {
                cursoId = _temaActual;
                cursoNombre = _temaActual;
                Navigator.pop(ctx);
              },
            ),
            if (cursosSnap.docs.isNotEmpty) ...[
              const Divider(color: Colors.white12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('O vincular a un curso existente:',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
              ...cursosSnap.docs.map((c) {
                final data = c.data();
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Color(data['color'] as int? ?? 0xFF7C6AF7),
                    radius: 14,
                    child: Text(
                      (data['nombre'] as String? ?? '?')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(data['nombre'] ?? '',
                      style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    cursoId = c.id;
                    cursoNombre = data['nombre'] ?? _temaActual;
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    int guardadas = 0;
    for (final fc in _flashcards) {
      final pregunta = fc['pregunta'] ?? '';
      final respuesta = fc['respuesta'] ?? '';
      if (pregunta.isEmpty || respuesta.isEmpty) continue;
      await SRSService.guardar(FlashcardSRS(
        id: '',
        pregunta: pregunta,
        respuesta: respuesta,
        cursoId: cursoId,
        cursoNombre: cursoNombre,
        userId: user.uid,
        proximaRevision: DateTime.now(),
        creadoEn: DateTime.now(),
      ));
      guardadas++;
    }

    if (mounted && guardadas > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$guardadas flashcards guardadas en SRS 🧠'),
          backgroundColor: const Color(0xFF1E1E2A),
        ),
      );
    }
  }

  // ── NOTIFICACIONES DE LOGRO ──────────────────────────────────────────────────

  Future<void> _notificarLogro(String tipo, String titulo, String cuerpo) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('notificarLogro')
          .call({'tipo': tipo, 'titulo': titulo, 'cuerpo': cuerpo});
    } catch (_) {}
  }

  // ── TYPEWRITER ───────────────────────────────────────────────────────────────

  void _typewrite(String text, void Function(String) setter) {
    _typewriterTimer?.cancel();
    int i = 0;
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (!mounted) { timer.cancel(); return; }
      i = (i + 4).clamp(0, text.length);
      setter(text.substring(0, i));
      if (i >= text.length) timer.cancel();
    });
  }

  // ── SIMULACRO HISTORIAL ────────────────────────────────────────────────────

  Future<void> _guardarSimulacroHistorial() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _preguntasSimulacro.isEmpty) return;
    final errores = <Map<String, String>>[];
    for (int i = 0; i < _preguntasSimulacro.length; i++) {
      final p = _preguntasSimulacro[i];
      final correcta = p['correcta']?.toString().trim().toUpperCase() ?? '';
      final respuesta = _respuestasUsuario[i]?.trim().toUpperCase() ?? '';
      if (!respuesta.startsWith(correcta)) {
        final opciones = List<String>.from(p['opciones'] ?? []);
        final opcionCorrecta = opciones.firstWhere((o) => o.toUpperCase().startsWith(correcta), orElse: () => correcta);
        errores.add({
          'pregunta': p['pregunta']?.toString() ?? '',
          'correcta': opcionCorrecta,
          'usuarioRespondio': _respuestasUsuario[i] ?? 'Sin respuesta',
        });
        if (errores.length >= 10) break;
      }
    }
    try {
      await FirebaseFirestore.instance
          .collection('simulacros_historial')
          .doc(user.uid)
          .collection('resultados')
          .add({
        'tema': _simulacroTemaController.text,
        'nivel': _nivelSeleccionado,
        'dificultad': _dificultadSeleccionada,
        'puntaje': _puntaje,
        'total': _preguntasSimulacro.length,
        'porcentaje': (_puntaje / _preguntasSimulacro.length * 100).round(),
        'fecha': Timestamp.now(),
        'errores': errores,
      });
    } catch (_) {}
  }

  Future<void> _analizarDebilidades() async {
    if (!await _verificarYConsumir()) return;
    setState(() { _analizandoDebilidades = true; _analisisDebilidades = ''; });
    final user = FirebaseAuth.instance.currentUser;
    final tema = _simulacroTemaController.text;
    List<Map<String, dynamic>> historial = [];
    if (user != null) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('simulacros_historial')
            .doc(user.uid)
            .collection('resultados')
            .orderBy('fecha', descending: true)
            .limit(5)
            .get();
        historial = snap.docs.map((d) => d.data()).toList();
      } catch (_) {}
    }
    String contextoHistorial = '';
    if (historial.isNotEmpty) {
      contextoHistorial = historial.map((h) {
        final errores = (h['errores'] as List<dynamic>? ?? []).map((e) => '  • ${e['pregunta']}').join('\n');
        return 'Simulacro del ${(h['fecha'] as Timestamp?)?.toDate().toString().substring(0, 10) ?? '?'}: ${h['puntaje']}/${h['total']} (${h['porcentaje']}%)\nPreguntas falladas:\n$errores';
      }).join('\n\n');
    } else {
      final erroresActuales = <String>[];
      for (int i = 0; i < _preguntasSimulacro.length; i++) {
        final correcta = _preguntasSimulacro[i]['correcta']?.toString().trim().toUpperCase() ?? '';
        if (!(_respuestasUsuario[i]?.trim().toUpperCase() ?? '').startsWith(correcta)) {
          erroresActuales.add('  • ${_preguntasSimulacro[i]['pregunta']}');
        }
      }
      contextoHistorial = 'Simulacro actual: $_puntaje/${_preguntasSimulacro.length}\nPreguntas falladas:\n${erroresActuales.join('\n')}';
    }
    final res = await _llamarIATexto(
      'Eres un tutor universitario analizando el desempeño de un estudiante en "$tema".\n\n'
      'HISTORIAL DE SIMULACROS:\n$contextoHistorial\n\n'
      'Basándote en los errores, responde en español:\n'
      '1) SUBTEMAS DÉBILES: lista los 3-5 conceptos específicos donde más falla\n'
      '2) PATRÓN DE ERRORES: qué tipo de preguntas le cuestan más (conceptuales, aplicación, cálculo, etc)\n'
      '3) PLAN DE ACCIÓN: qué estudiar primero esta semana, con técnicas específicas para cada subtema débil\n'
      '4) PRONÓSTICO: si sigue el plan, ¿qué nota podría sacar en el examen?\n'
      'Sé directo y específico, no genérico.',
    );
    setState(() { _analizandoDebilidades = false; });
    _typewrite(res ?? 'No se pudo analizar. Intenta de nuevo.', (t) => setState(() => _analisisDebilidades = t));
  }

  // ── RUTA DE APRENDIZAJE ────────────────────────────────────────────────────

  Future<void> _generarRutaAprendizaje() async {
    final materias = _materiasRutaController.text.trim();
    if (materias.isEmpty) return;
    if (!await _verificarYConsumir()) return;
    setState(() { _cargandoRuta = true; _resultadoRuta = ''; });
    final horas = _horasRutaController.text.trim().isEmpty ? '10' : _horasRutaController.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    String contextoSimulacros = '';
    if (user != null) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('simulacros_historial')
            .doc(user.uid)
            .collection('resultados')
            .orderBy('fecha', descending: true)
            .limit(8)
            .get();
        if (snap.docs.isNotEmpty) {
          final resumen = snap.docs.map((d) {
            final data = d.data();
            return '${data['tema']} — ${data['porcentaje']}% (${data['puntaje']}/${data['total']})';
          }).join('\n');
          contextoSimulacros = '\nHISTORIAL DE SIMULACROS DEL ESTUDIANTE:\n$resumen';
        }
      } catch (_) {}
    }
    final res = await _llamarIATexto(
      'Eres un coach educativo universitario experto en planificación de estudio.\n'
      'Carrera del estudiante: ${_carrera.isNotEmpty ? _carrera : 'Universitaria'}\n'
      'Materias y temas de esta semana: $materias\n'
      'Horas disponibles para estudiar: $horas horas en la semana$contextoSimulacros\n\n'
      'Genera un PLAN DE ESTUDIO SEMANAL PERSONALIZADO en español que incluya:\n'
      '1) DISTRIBUCIÓN DIARIA: qué estudiar cada día (lunes a domingo) con bloques de tiempo específicos\n'
      '2) TÉCNICA RECOMENDADA para cada materia según el tipo de contenido\n'
      '3) PRIORIDADES: qué estudiar primero y por qué (basado en el historial si existe)\n'
      '4) MOMENTOS DE REPASO: cuándo repasar lo aprendido antes del examen\n'
      '5) CONSEJO DEL DÍA: una motivación o tip clave para esta semana.\n'
      'Sé concreto con horarios (ej: "Lunes 7-8pm: Cálculo — repaso de derivadas con ejercicios").',
    );
    setState(() { _cargandoRuta = false; });
    _typewrite(res ?? 'Error al generar. Intenta de nuevo.', (t) => setState(() => _resultadoRuta = t));
    _mostrarIntersticial();
    if (res != null) {
      _notificarLogro(
        'ruta_completada',
        '🗺️ ¡Tu ruta de estudio está lista!',
        'Tu plan personalizado para esta semana ya está generado. ¡A estudiar! 📚',
      );
    }
  }

  // ── HERRAMIENTAS: métodos ─────────────────────────────────────────────────

  Future<void> _compararConceptos() async {
    final a = _concepto1Controller.text.trim();
    final b = _concepto2Controller.text.trim();
    if (a.isEmpty || b.isEmpty) return;
    if (!await _verificarYConsumir()) return;
    setState(() { _cargandoComparador = true; _resultadoComparador = ''; });
    final res = await _llamarIATexto(
      'Eres un tutor universitario. Compara "$a" y "$b" de forma clara y estructurada en español. '
      'Incluye: 1) Definición breve de cada uno, 2) Tabla de diferencias clave (al menos 5 aspectos), '
      '3) Similitudes importantes, 4) Cuándo usar/aplicar cada uno. Sé concreto y didáctico.',
    );
    setState(() { _cargandoComparador = false; });
    _typewrite(res ?? 'Error al comparar. Intenta de nuevo.', (t) => setState(() => _resultadoComparador = t));
    _mostrarIntersticial();
  }

  Future<void> _generarNemotecnia() async {
    final concepto = _nemotecniaController.text.trim();
    if (concepto.isEmpty) return;
    if (!await _verificarYConsumir()) return;
    setState(() { _cargandoNemotecnia = true; _resultadoNemotecnia = ''; });
    final res = await _llamarIATexto(
      'Eres un experto en técnicas de memorización. Para el concepto o lista: "$concepto", genera en español:\n'
      '1) Una nemotecnia o acrónimo fácil de recordar\n'
      '2) Una analogía con algo cotidiano\n'
      '3) Una historia corta o imagen mental que lo fije en la memoria\n'
      '4) Un truco extra si aplica. Sé creativo y memorable.',
    );
    setState(() { _cargandoNemotecnia = false; });
    _typewrite(res ?? 'Error al generar. Intenta de nuevo.', (t) => setState(() => _resultadoNemotecnia = t));
    _mostrarIntersticial();
  }

  Future<void> _corregirRedaccion() async {
    final texto = _correctorController.text.trim();
    if (texto.isEmpty) return;
    if (!await _verificarYConsumir()) return;
    setState(() { _cargandoCorrector = true; _resultadoCorrector = ''; });
    final res = await _llamarIATexto(
      'Eres un corrector académico universitario experto. Analiza este texto en español:\n\n"$texto"\n\n'
      'Proporciona:\n1) TEXTO CORREGIDO: versión mejorada con errores corregidos\n'
      '2) ERRORES ENCONTRADOS: lista de los errores de gramática/ortografía/puntuación corregidos\n'
      '3) MEJORAS DE ESTILO: sugerencias para elevar el nivel académico\n'
      '4) PUNTUACIÓN ACADÉMICA: del 1 al 10 con justificación breve.',
    );
    setState(() { _cargandoCorrector = false; });
    _typewrite(res ?? 'Error al corregir. Intenta de nuevo.', (t) => setState(() => _resultadoCorrector = t));
  }

  Future<void> _iniciarChatHerramientas() async {
    final tema = _temaHerramientasController.text.trim();
    if (tema.isEmpty) return;
    if (!await _verificarYConsumir()) return;
    final esFeynman = _subModoHerramientas == 3;
    final mensajeInicio = esFeynman
        ? 'Perfecto. Ahora explícame "$tema" con tus propias palabras, como si yo no supiera nada del tema. No te preocupes por ser perfecto, simplemente explícalo como lo entiendes.'
        : 'Bien. Cuéntame, ¿qué sabes sobre "$tema"? Empieza por lo más básico.';
    setState(() {
      _chatHerramientas = [{'role': 'ia', 'text': mensajeInicio}];
      _chatHerramientasIniciado = true;
      _cargandoChatHerramientas = false;
    });
  }

  Future<void> _enviarMensajeChatHerramientas() async {
    final texto = _chatHerramientasController.text.trim();
    if (texto.isEmpty || _cargandoChatHerramientas) return;
    if (!await _verificarYConsumir()) return;
    final tema = _temaHerramientasController.text.trim();
    _chatHerramientasController.clear();
    setState(() { _chatHerramientas.add({'role': 'user', 'text': texto}); _cargandoChatHerramientas = true; });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatHerramientasScroll.hasClients) _chatHerramientasScroll.animateTo(_chatHerramientasScroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
    final historial = _chatHerramientas.map((m) => {'role': m['role'] == 'ia' ? 'assistant' : 'user', 'content': m['text']!}).toList();
    final esFeynman = _subModoHerramientas == 3;
    final systemMsg = esFeynman
        ? {'role': 'user', 'content': 'Eres un tutor que aplica la Técnica Feynman para el tema "$tema". '
            'El estudiante te explicará el tema. Tu rol es: 1) Identificar qué partes explicó bien, '
            '2) Señalar dónde hay vacíos o confusión con preguntas guía amables, '
            '3) NO dar la respuesta directamente, sino hacer preguntas que lo lleven a descubrirla. '
            'Máximo 150 palabras por respuesta. Responde en español.'}
        : {'role': 'user', 'content': 'Eres un Tutor Socrático para el tema "$tema". '
            'Nunca des la respuesta directa. En cambio, haz preguntas que guíen al estudiante a razonar y llegar solo a la conclusión. '
            'Usa analogías con situaciones cotidianas cuando sea útil. '
            'Máximo 120 palabras por respuesta. Responde en español.'};
    final (data, _) = await _llamarCloudFunction(
      messages: [systemMsg, ...historial.skip(1)],
      maxTokens: 500,
    );
    String respuesta = 'No pude responder. Intenta de nuevo.';
    try { if (data != null) respuesta = (data['content'] as List).first['text'] as String; } catch (_) {}
    setState(() { _chatHerramientas.add({'role': 'ia', 'text': respuesta}); _cargandoChatHerramientas = false; });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatHerramientasScroll.hasClients) _chatHerramientasScroll.animateTo(_chatHerramientasScroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  // ── EVALÚAME: métodos ─────────────────────────────────────────────────────

  Future<void> _iniciarEvaluame() async {
    if (_temaActual.isEmpty) return;
    if (!await _verificarYConsumir()) return;
    setState(() { _cargandoEval = true; });
    final res = await _llamarIATexto(
      'Eres un profesor universitario evaluando oralmente al estudiante sobre "$_temaActual". '
      'Haz la PRIMERA pregunta de evaluación. Debe ser abierta (no de sí/no), sobre un concepto clave del tema. '
      'Solo escribe la pregunta, sin explicaciones adicionales. Máximo 2 oraciones. En español.',
    );
    setState(() {
      _evalMensajes = [{'role': 'ia', 'text': res ?? '¿Puedes explicarme el concepto principal de $_temaActual con tus propias palabras?'}];
      _evalIniciado = true;
      _cargandoEval = false;
    });
  }

  Future<void> _enviarRespuestaEvaluame() async {
    final respuesta = _evalController.text.trim();
    if (respuesta.isEmpty || _cargandoEval) return;
    if (!await _verificarYConsumir()) return;
    _evalController.clear();
    setState(() { _evalMensajes.add({'role': 'user', 'text': respuesta}); _cargandoEval = true; });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_evalScroll.hasClients) _evalScroll.animateTo(_evalScroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
    final historial = _evalMensajes.map((m) => {'role': m['role'] == 'ia' ? 'assistant' : 'user', 'content': m['text']!}).toList();
    final systemMsg = {'role': 'user', 'content':
      'Eres un profesor universitario evaluando oralmente sobre "$_temaActual". Tu flujo es:\n'
      '1) Evalúa la respuesta del estudiante: di si es correcta, parcial o incorrecta\n'
      '2) Da retroalimentación breve y constructiva (máx 2 oraciones)\n'
      '3) Haz la SIGUIENTE pregunta sobre otro aspecto del tema\n'
      'Si el estudiante lleva 5 o más intercambios, en vez de nueva pregunta da un resumen de su desempeño con calificación del 1 al 20.\n'
      'Máximo 180 palabras. En español.'
    };
    final (data, _) = await _llamarCloudFunction(
      messages: [systemMsg, ...historial.skip(1)],
      maxTokens: 600,
    );
    String textoIA = 'No pude responder. Intenta de nuevo.';
    try { if (data != null) textoIA = (data['content'] as List).first['text'] as String; } catch (_) {}
    setState(() { _evalMensajes.add({'role': 'ia', 'text': textoIA}); _cargandoEval = false; });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_evalScroll.hasClients) _evalScroll.animateTo(_evalScroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        title: Row(children: [
          Text(l10n.iaTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          if (_busquedasRestantes < 999)
            GestureDetector(
              onTap: _busquedasRestantes == 0 ? _mostrarPasarela : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: _busquedasRestantes == 0
                      ? const Color(0xFFF7584A).withOpacity(0.18)
                      : const Color(0xFF5DE0C5).withOpacity(0.13),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _busquedasRestantes == 0
                        ? const Color(0xFFF7584A).withOpacity(0.5)
                        : const Color(0xFF5DE0C5).withOpacity(0.35),
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    _busquedasRestantes == 0 ? Icons.lock_outline : Icons.bolt,
                    color: _busquedasRestantes == 0
                        ? const Color(0xFFF7584A)
                        : const Color(0xFF5DE0C5),
                    size: 11,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    _busquedasRestantes == 0
                        ? l10n.iaSearchesExhausted
                        : l10n.iaSearchesToday(_busquedasRestantes),
                    style: TextStyle(
                      color: _busquedasRestantes == 0
                          ? const Color(0xFFF7584A)
                          : const Color(0xFF5DE0C5),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]),
              ),
            ),
        ]),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_chatMensajes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
              tooltip: l10n.iaClearChat,
              onPressed: _limpiarChat,
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _modoBtn(l10n.iaModeStudy, Icons.book, 0),
                _modoBtn(l10n.iaModeScanner, Icons.camera_alt, 1),
                _modoBtn(l10n.iaModeDocs, Icons.description, 2),
                _modoBtn(l10n.iaModeSim, Icons.quiz, 3),
                _modoBtn(l10n.iaModeTools, Icons.build_circle_outlined, 4),
              ]),
            ),
          ),
          Expanded(child: _modoActual == 0 ? _buildEstudio() : _modoActual == 1 ? _buildScanner() : _modoActual == 2 ? _buildDocumento() : _modoActual == 3 ? _buildSimulacro() : _buildHerramientas()),
        ],
      ),
    );
  }

  Widget _modoBtn(String label, IconData icono, int index) {
    final selected = _modoActual == index;
    return _TapScale(
      onTap: () => setState(() => _modoActual = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF7C6AF7) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icono, color: selected ? Colors.white : Colors.white38, size: 16),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white38,
              fontSize: 10,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }

  Widget _buildScanner() {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2030),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF5DE0C5).withOpacity(0.25)),
          ),
          child: const Row(children: [
            Icon(Icons.tips_and_updates, color: Color(0xFF5DE0C5), size: 15),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Mejor resultado: buena luz, encuadre recto, texto enfocado. La IA puede leer imágenes borrosas, pero la calidad mejora la precisión.',
              style: TextStyle(color: Color(0xFF5DE0C5), fontSize: 11, height: 1.4),
            )),
          ]),
        ),
        const SizedBox(height: 14),
        Text(l10n.iaScanStep1, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF7C6AF7).withOpacity(0.4))),
          child: TextField(
            controller: _preguntaScannerController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3, minLines: 1,
            decoration: InputDecoration(hintText: l10n.iaScanHint, hintStyle: const TextStyle(color: Colors.white38, fontSize: 13), contentPadding: const EdgeInsets.all(14), border: InputBorder.none),
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.iaScanStep2, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: GestureDetector(onTap: () => _tomarFoto(ImageSource.camera), child: _scanBtn(l10n.iaScanCamera, Icons.camera_alt, const Color(0xFF7C6AF7), true))),
          const SizedBox(width: 8),
          Expanded(child: GestureDetector(onTap: () => _tomarFoto(ImageSource.gallery), child: _scanBtn(l10n.iaScanGallery, Icons.photo_library, const Color(0xFF7C6AF7), false))),
          const SizedBox(width: 8),
          Expanded(child: GestureDetector(onTap: _subirPDF, child: _scanBtn('PDF', Icons.picture_as_pdf, const Color(0xFFF7584A), false))),
        ]),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _preguntarSoloTexto,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF5DE0C5).withOpacity(0.4))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.send, color: Color(0xFF5DE0C5), size: 18),
              const SizedBox(width: 8),
              Text(l10n.iaScanSendText, style: const TextStyle(color: Color(0xFF5DE0C5), fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        if (_imagenSeleccionada != null) ...[
          const SizedBox(height: 16),
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imagenSeleccionada!, width: double.infinity, height: 200, fit: BoxFit.cover)),
        ],
        if (_cargandoImagen) ...[
          const SizedBox(height: 20),
          const Center(child: CircularProgressIndicator(color: Color(0xFF7C6AF7))),
          const SizedBox(height: 8),
          Center(child: Text(l10n.iaAnalyzing, style: const TextStyle(color: Colors.white54))),
        ],
        if (_respuestaImagen.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF5DE0C5).withOpacity(0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Icon(Icons.auto_awesome, color: Color(0xFF5DE0C5), size: 16), const SizedBox(width: 8), Text(l10n.iaAIResponse, style: const TextStyle(color: Color(0xFF5DE0C5), fontWeight: FontWeight.bold))]),
              const SizedBox(height: 12),
              Text(_respuestaImagen.replaceAll('###', '').replaceAll('##', '').replaceAll('#', '').replaceAll('**', '').replaceAll('*', ''), style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _compartirRespuestaScanner,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xFFF7584A).withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFF7584A).withOpacity(0.3))),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.download, color: Color(0xFFF7584A), size: 14), const SizedBox(width: 4), Text(l10n.iaSavePDF, style: const TextStyle(color: Color(0xFFF7584A), fontSize: 12, fontWeight: FontWeight.w600))]),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() { _respuestaImagen = ''; _imagenSeleccionada = null; _preguntaScannerController.clear(); }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xFF7C6AF7).withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF7C6AF7).withOpacity(0.3))),
                      child: Center(child: Text(l10n.iaNewQuery, style: const TextStyle(color: Color(0xFF7C6AF7), fontSize: 13, fontWeight: FontWeight.w600))),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _scanBtn(String label, IconData icono, Color color, bool filled) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: filled ? color : const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12), border: filled ? null : Border.all(color: color.withOpacity(0.5))),
      child: Column(children: [
        Icon(icono, color: filled ? Colors.white : color, size: 24),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: filled ? Colors.white : color, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildDocumento() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Tipo de documento', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: _tiposDocumento.map((tipo) {
            final selected = _tipoDocumento == tipo;
            return GestureDetector(
              onTap: () => setState(() => _tipoDocumento = tipo),
              child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: selected ? const Color(0xFF7C6AF7) : const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(20)), child: Text(tipo, style: TextStyle(color: selected ? Colors.white : Colors.white54, fontSize: 13, fontWeight: selected ? FontWeight.bold : FontWeight.normal))),
            );
          }).toList()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _documentoController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(hintText: 'Ej: La revolucion industrial y su impacto', hintStyle: const TextStyle(color: Colors.white38), labelText: 'Tema del documento', labelStyle: const TextStyle(color: Color(0xFF7C6AF7)), filled: true, fillColor: const Color(0xFF1E1E2A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), alignLabelWithHint: true),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _cargandoDocumento ? null : _generarDocumento,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C6AF7), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _cargandoDocumento ? const CircularProgressIndicator(color: Colors.white) : Text('Generar $_tipoDocumento', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        if (_documentoGenerado.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF5DE0C5).withOpacity(0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Documento generado', style: TextStyle(color: Color(0xFF5DE0C5), fontWeight: FontWeight.bold)),
                GestureDetector(onTap: _descargarPDF, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFF7584A), borderRadius: BorderRadius.circular(8)), child: const Row(children: [Icon(Icons.download, color: Colors.white, size: 14), SizedBox(width: 4), Text('PDF', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))]))),
              ]),
              const SizedBox(height: 12),
              Text(_documentoGenerado, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6)),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildEstudio() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(children: [
            TextField(controller: _temaController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Ej: Calculo II, Python, Historia', hintStyle: const TextStyle(color: Colors.white38), labelText: 'Tema a estudiar', labelStyle: const TextStyle(color: Color(0xFF7C6AF7)), filled: true, fillColor: const Color(0xFF1E1E2A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 12),
            TextField(controller: _diasController, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Ej: 7', hintStyle: const TextStyle(color: Colors.white38), labelText: 'Dias para el examen', labelStyle: const TextStyle(color: Color(0xFF7C6AF7)), filled: true, fillColor: const Color(0xFF1E1E2A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando ? null : _generarContenido,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C6AF7), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _cargando
                    ? Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(color: Colors.white), const SizedBox(height: 8), Text(_progreso, style: const TextStyle(color: Colors.white70, fontSize: 12))])
                    : const Text('Generar contenido con IA', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF2A1A1A), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
                  GestureDetector(onTap: _generarContenido, child: const Text('Reintentar', style: TextStyle(color: Color(0xFF7C6AF7), fontSize: 12, fontWeight: FontWeight.bold))),
                ]),
              ),
            ],
            if (_resumen.isNotEmpty) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [_tabBtn('Resumen', 0), _tabBtn('Preguntas', 1), _tabBtn('Flashcards', 2), _tabBtn('Tips', 3), _tabBtn('Plan', 4), _tabBtn('Ejercicios', 5), _tabBtn('Mapa', 6), _tabBtn('Evalúame', 7)])),
            ],
          ]),
        ),
        if (_resumen.isNotEmpty) Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 0), child: _buildContenido())),
        if (_resumen.isEmpty && !_cargando) Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: _buildTemasPopulares(),
        ),
        if (_resumen.isEmpty) const Spacer(),
        if (_resumen.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(color: const Color(0xFF1E1E2A), border: Border(top: BorderSide(color: const Color(0xFF7C6AF7).withOpacity(0.2)))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (_chatMensajes.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: ListView.builder(
                    controller: _chatScrollController,
                    shrinkWrap: true,
                    itemCount: _chatMensajes.length,
                    itemBuilder: (context, i) {
                      final msg = _chatMensajes[i];
                      final esUsuario = msg['role'] == 'user';
                      return Align(
                        alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(color: esUsuario ? const Color(0xFF7C6AF7) : const Color(0xFF2A2A3A), borderRadius: BorderRadius.circular(12)),
                          child: Text(msg['text'] ?? '', style: TextStyle(color: esUsuario ? Colors.white : Colors.white70, fontSize: 13, height: 1.4)),
                        ),
                      );
                    },
                  ),
                ),
              if (_cargandoChat)
                const Padding(padding: EdgeInsets.only(bottom: 6), child: Row(children: [SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C6AF7))), SizedBox(width: 8), Text('Respondiendo...', style: TextStyle(color: Colors.white38, fontSize: 12))])),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(hintText: 'Pregunta sobre $_temaActual...', hintStyle: const TextStyle(color: Colors.white38, fontSize: 13), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), filled: true, fillColor: const Color(0xFF0F0F14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                    onSubmitted: (_) => _enviarMensajeChat(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(onTap: _enviarMensajeChat, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF7C6AF7), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.send, color: Colors.white, size: 18))),
              ]),
            ]),
          ),
      ],
    );
  }

  Widget _tabBtn(String label, int index) {
    final selected = _tabSeleccionada == index;
    return GestureDetector(
      onTap: () => setState(() => _tabSeleccionada = index),
      child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: selected ? const Color(0xFF7C6AF7) : const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(20)), child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white54, fontSize: 12))),
    );
  }

  Widget _buildContenido() {
    switch (_tabSeleccionada) {
      case 0: return SingleChildScrollView(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12)), child: Text(_resumen, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6))));
      case 1: return ListView.builder(itemCount: _preguntas.length, itemBuilder: (context, i) => GestureDetector(onTap: () => setState(() => _preguntasAbiertas[i] = !_preguntasAbiertas[i]), child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text('${i + 1}. ${_preguntas[i]['pregunta'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))), Icon(_preguntasAbiertas[i] ? Icons.expand_less : Icons.expand_more, color: const Color(0xFF7C6AF7))]), if (_preguntasAbiertas[i]) ...[const SizedBox(height: 8), const Divider(color: Colors.white12), const SizedBox(height: 8), Text('${_preguntas[i]['respuesta'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5))]]))));
      case 2: return Column(
        children: [
          GestureDetector(
            onTap: _guardarEnSRS,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF7C6AF7), Color(0xFF5A4ED4)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_alt, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Guardar ${_flashcards.length} flashcards en SRS 🧠',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _flashcards.length,
              itemBuilder: (context, i) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2A),
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_flashcards[i]['pregunta'] ?? ''}',
                        style: const TextStyle(
                            color: Color(0xFF7C6AF7),
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 8),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),
                    Text('${_flashcards[i]['respuesta'] ?? ''}',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
      case 3: return ListView.builder(itemCount: _tips.length, itemBuilder: (context, i) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12)), child: Text('💡 ${_tips[i]}', style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5))));
      case 4: return ListView.builder(itemCount: _planEstudio.length, itemBuilder: (context, i) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF7C6AF7).withOpacity(0.3))), child: Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFF7C6AF7), borderRadius: BorderRadius.circular(8)), child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))), const SizedBox(width: 12), Expanded(child: Text(_planEstudio[i], style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5)))])));
      case 5: return ListView.builder(itemCount: _ejercicios.length, itemBuilder: (context, i) => GestureDetector(onTap: () => setState(() => _ejerciciosAbiertos[i] = !_ejerciciosAbiertos[i]), child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text('📝 ${_ejercicios[i]['problema'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))), Icon(_ejerciciosAbiertos[i] ? Icons.expand_less : Icons.expand_more, color: const Color(0xFF5DE0C5))]), if (_ejerciciosAbiertos[i]) ...[const SizedBox(height: 8), const Divider(color: Colors.white12), const SizedBox(height: 8), Text('${_ejercicios[i]['solucion'] ?? ''}', style: const TextStyle(color: Color(0xFF5DE0C5), fontSize: 13, height: 1.5))]]))));
      case 6: return _buildMapaVisual();
      case 7: return _buildEvaluame();
      default: return const SizedBox();
    }
  }

  int? get _notaEvaluame {
    final iaMsgs = _evalMensajes.where((m) => m['role'] == 'ia').toList();
    if (iaMsgs.isEmpty) return null;
    final texto = iaMsgs.last['text'] ?? '';
    final regex = RegExp(r'(\d{1,2})\s*/\s*20', caseSensitive: false);
    final match = regex.firstMatch(texto);
    if (match == null) return null;
    final n = int.tryParse(match.group(1) ?? '');
    return (n != null && n >= 1 && n <= 20) ? n : null;
  }

  Widget _buildNotaCard(int nota) {
    final color = nota >= 14 ? const Color(0xFF5DE0C5) : nota >= 11 ? const Color(0xFFF7A26A) : const Color(0xFFF7584A);
    final msg = nota >= 14 ? '¡Excelente resultado!' : nota >= 11 ? 'Bien, sigue mejorando' : 'Sigue practicando';
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.2), const Color(0xFF0F0F14)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.55)),
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
          child: Center(child: Text('$nota', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Calificación: $nota / 20', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 2),
          Text(msg, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
      ]),
    );
  }

  Widget _buildEvaluame() {
    if (_temaActual.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFF7A26A).withOpacity(0.12), shape: BoxShape.circle), child: const Icon(Icons.info_outline, color: Color(0xFFF7A26A), size: 44)),
            const SizedBox(height: 16),
            const Text('Primero estudia un tema', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Ve a la pestaña Estudiar, ingresa un tema y genera el contenido. Luego regresa aquí para ser evaluado.', style: TextStyle(color: Colors.white54, fontSize: 13), textAlign: TextAlign.center),
          ]),
        ),
      );
    }
    if (!_evalIniciado) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFF7A26A).withOpacity(0.12), shape: BoxShape.circle), child: const Icon(Icons.record_voice_over, color: Color(0xFFF7A26A), size: 44)),
            const SizedBox(height: 16),
            const Text('Evalúame', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('La IA te hará preguntas sobre "$_temaActual" y evaluará tus respuestas.\nAl final recibirás una nota del 1 al 20.', style: const TextStyle(color: Colors.white54, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            _cargandoEval
                ? const CircularProgressIndicator(color: Color(0xFFF7A26A))
                : SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _iniciarEvaluame, icon: const Icon(Icons.play_arrow, color: Colors.white), label: const Text('Iniciar evaluación oral', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF7A26A), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
          ]),
        ),
      );
    }
    final nota = _notaEvaluame;
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        color: const Color(0xFF1E1E2A),
        child: Row(children: [
          const Icon(Icons.record_voice_over, color: Color(0xFFF7A26A), size: 14),
          const SizedBox(width: 6),
          Expanded(child: Text('Evaluación oral — $_temaActual', style: const TextStyle(color: Color(0xFFF7A26A), fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          GestureDetector(onTap: () => setState(() { _evalMensajes = []; _evalIniciado = false; }), child: const Icon(Icons.refresh, color: Colors.white38, size: 18)),
        ]),
      ),
      if (nota != null) _buildNotaCard(nota),
      Expanded(
        child: ListView.builder(
          controller: _evalScroll,
          padding: const EdgeInsets.all(12),
          itemCount: _evalMensajes.length + (_cargandoEval ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == _evalMensajes.length) {
              return const Padding(padding: EdgeInsets.only(left: 8, bottom: 6), child: Row(children: [SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF7A26A))), SizedBox(width: 8), Text('Evaluando...', style: TextStyle(color: Colors.white38, fontSize: 12))]));
            }
            final msg = _evalMensajes[i];
            final esUsuario = msg['role'] == 'user';
            return Align(
              alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                decoration: BoxDecoration(
                  color: esUsuario ? const Color(0xFFF7A26A).withOpacity(0.85) : const Color(0xFF1E1E2A),
                  borderRadius: BorderRadius.circular(14),
                  border: esUsuario ? null : Border.all(color: const Color(0xFFF7A26A).withOpacity(0.25)),
                ),
                child: Text(msg['text'] ?? '', style: TextStyle(color: esUsuario ? Colors.white : Colors.white70, fontSize: 13, height: 1.5)),
              ),
            );
          },
        ),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(color: const Color(0xFF1E1E2A), border: Border(top: BorderSide(color: const Color(0xFFF7A26A).withOpacity(0.2)))),
        child: Row(children: [
          Expanded(child: TextField(controller: _evalController, style: const TextStyle(color: Colors.white, fontSize: 13), decoration: const InputDecoration(hintText: 'Escribe tu respuesta...', hintStyle: TextStyle(color: Colors.white38, fontSize: 13), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), filled: true, fillColor: Color(0xFF0F0F14), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide.none)), onSubmitted: (_) => _enviarRespuestaEvaluame())),
          const SizedBox(width: 8),
          _TapScale(onTap: _enviarRespuestaEvaluame, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF7A26A), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.send, color: Colors.white, size: 18))),
        ]),
      ),
    ]);
  }

  Widget _buildHerramientas() {
    if (_subModoHerramientas == -1) return _buildHerramientasGrid();
    const nombres = ['Comparador', 'Nemotecnia', 'Corrector', 'Feynman', 'Socrático', 'Mi Ruta'];
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Row(children: [
          _TapScale(
            onTap: () => setState(() {
              _subModoHerramientas = -1;
              _chatHerramientas = [];
              _chatHerramientasIniciado = false;
              _temaHerramientasController.clear();
            }),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF7C6AF7).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF7C6AF7), size: 14),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            nombres[_subModoHerramientas],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ]),
      ),
      Expanded(child: _subModoHerramientas == 0 ? _buildComparador() : _subModoHerramientas == 1 ? _buildNemotecnia() : _subModoHerramientas == 2 ? _buildCorrector() : _subModoHerramientas == 5 ? _buildRutaAprendizaje() : _buildChatHerramientas()),
    ]);
  }

  Widget _buildHerramientasGrid() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('HERRAMIENTAS DE ESTUDIO', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.88,
          children: [
            _herramientaCard('Comparador', 'Compara dos conceptos lado a lado', Icons.compare_arrows, const Color(0xFF7C6AF7), const Color(0xFF5A4ED4), 0),
            _herramientaCard('Nemotecnia', 'Técnicas de memorización y asociación', Icons.lightbulb_outline, const Color(0xFFF7A26A), const Color(0xFFD06020), 1),
            _herramientaCard('Corrector', 'Mejora y corrige textos académicos', Icons.spellcheck, const Color(0xFF5DE0C5), const Color(0xFF2A9080), 2),
            _herramientaCard('Feynman', 'Aprende explicándole al tutor IA', Icons.psychology, const Color(0xFF4A90E2), const Color(0xFF2D60C0), 3),
            _herramientaCard('Socrático', 'Razona con preguntas guiadas', Icons.question_answer, const Color(0xFFF7584A), const Color(0xFFB03020), 4),
            _herramientaCard('Mi Ruta', 'Plan semanal personalizado con IA', Icons.route, const Color(0xFF56D98B), const Color(0xFF2A9A55), 5),
          ],
        ),
      ]),
    );
  }

  Widget _herramientaCard(String nombre, String desc, IconData icono, Color c1, Color c2, int idx) {
    return _TapScale(
      onTap: () => setState(() {
        _subModoHerramientas = idx;
        _chatHerramientas = [];
        _chatHerramientasIniciado = false;
        _temaHerramientasController.clear();
      }),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c1.withOpacity(0.18), const Color(0xFF1E1E2A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c1.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [c1, c2]),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 10),
            Text(nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.3), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildComparador() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12)), child: const Row(children: [Icon(Icons.compare_arrows, color: Color(0xFF7C6AF7), size: 20), SizedBox(width: 8), Expanded(child: Text('Escribe dos conceptos y la IA los comparará con tabla de diferencias, similitudes y cuándo usar cada uno.', style: TextStyle(color: Colors.white54, fontSize: 12)))])),
        const SizedBox(height: 14),
        TextField(controller: _concepto1Controller, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Ej: Mitosis', hintStyle: const TextStyle(color: Colors.white38), labelText: 'Concepto A', labelStyle: const TextStyle(color: Color(0xFF7C6AF7)), filled: true, fillColor: const Color(0xFF1E1E2A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        const SizedBox(height: 10),
        TextField(controller: _concepto2Controller, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Ej: Meiosis', hintStyle: const TextStyle(color: Colors.white38), labelText: 'Concepto B', labelStyle: const TextStyle(color: Color(0xFF7C6AF7)), filled: true, fillColor: const Color(0xFF1E1E2A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _cargandoComparador ? null : _compararConceptos, icon: const Icon(Icons.compare_arrows, color: Colors.white, size: 18), label: _cargandoComparador ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Comparar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C6AF7), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        if (_resultadoComparador.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF5DE0C5).withOpacity(0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.auto_awesome, color: Color(0xFF5DE0C5), size: 14), SizedBox(width: 6), Text('Comparación', style: TextStyle(color: Color(0xFF5DE0C5), fontWeight: FontWeight.bold, fontSize: 13))]),
            const SizedBox(height: 10),
            Text(_resultadoComparador.replaceAll('**', '').replaceAll('###', '').replaceAll('##', '').replaceAll('#', ''), style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6)),
          ])),
        ],
      ]),
    );
  }

  Widget _buildNemotecnia() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12)), child: const Row(children: [Icon(Icons.lightbulb_outline, color: Color(0xFFF7A26A), size: 20), SizedBox(width: 8), Expanded(child: Text('Escribe lo que necesitas memorizar y la IA generará nemotecnias, analogías e imágenes mentales.', style: TextStyle(color: Colors.white54, fontSize: 12)))])),
        const SizedBox(height: 14),
        TextField(controller: _nemotecniaController, style: const TextStyle(color: Colors.white), maxLines: 3, minLines: 1, decoration: InputDecoration(hintText: 'Ej: Los planetas del sistema solar en orden, Las fases de la mitosis...', hintStyle: const TextStyle(color: Colors.white38), labelText: 'Concepto o lista a memorizar', labelStyle: const TextStyle(color: Color(0xFFF7A26A)), filled: true, fillColor: const Color(0xFF1E1E2A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), alignLabelWithHint: true)),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _cargandoNemotecnia ? null : _generarNemotecnia, icon: const Icon(Icons.lightbulb, color: Colors.white, size: 18), label: _cargandoNemotecnia ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Generar nemotecnia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF7A26A), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        if (_resultadoNemotecnia.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF7A26A).withOpacity(0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.lightbulb, color: Color(0xFFF7A26A), size: 14), SizedBox(width: 6), Text('Tus nemotecnias', style: TextStyle(color: Color(0xFFF7A26A), fontWeight: FontWeight.bold, fontSize: 13))]),
            const SizedBox(height: 10),
            Text(_resultadoNemotecnia.replaceAll('**', '').replaceAll('###', '').replaceAll('##', '').replaceAll('#', ''), style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6)),
          ])),
        ],
      ]),
    );
  }

  Widget _buildCorrector() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12)), child: const Row(children: [Icon(Icons.spellcheck, color: Color(0xFF5DE0C5), size: 20), SizedBox(width: 8), Expanded(child: Text('Pega tu texto académico y la IA lo corregirá, mejorará el estilo y te dará una puntuación.', style: TextStyle(color: Colors.white54, fontSize: 12)))])),
        const SizedBox(height: 14),
        TextField(controller: _correctorController, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 8, minLines: 4, decoration: InputDecoration(hintText: 'Pega aquí tu párrafo, introducción o texto académico...', hintStyle: const TextStyle(color: Colors.white38, fontSize: 13), labelText: 'Texto a corregir', labelStyle: const TextStyle(color: Color(0xFF5DE0C5)), filled: true, fillColor: const Color(0xFF1E1E2A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), alignLabelWithHint: true)),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _cargandoCorrector ? null : _corregirRedaccion, icon: const Icon(Icons.auto_fix_high, color: Colors.white, size: 18), label: _cargandoCorrector ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Corregir y mejorar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5DE0C5), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        if (_resultadoCorrector.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF5DE0C5).withOpacity(0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Row(children: [Icon(Icons.auto_fix_high, color: Color(0xFF5DE0C5), size: 14), SizedBox(width: 6), Text('Corrección', style: TextStyle(color: Color(0xFF5DE0C5), fontWeight: FontWeight.bold, fontSize: 13))]),
              GestureDetector(onTap: () async { await Share.share(_resultadoCorrector); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF5DE0C5).withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: const Row(children: [Icon(Icons.share, size: 12, color: Color(0xFF5DE0C5)), SizedBox(width: 4), Text('Compartir', style: TextStyle(color: Color(0xFF5DE0C5), fontSize: 11))]))),
            ]),
            const SizedBox(height: 10),
            Text(_resultadoCorrector.replaceAll('**', '').replaceAll('###', '').replaceAll('##', '').replaceAll('#', ''), style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6)),
          ])),
        ],
      ]),
    );
  }

  Widget _buildRutaAprendizaje() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [const Color(0xFF5DE0C5).withOpacity(0.15), const Color(0xFF0F0F14)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF5DE0C5).withOpacity(0.3)),
          ),
          child: const Row(children: [
            Icon(Icons.route, color: Color(0xFF5DE0C5), size: 22),
            SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ruta de aprendizaje personalizada', style: TextStyle(color: Color(0xFF5DE0C5), fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(height: 4),
              Text('La IA analiza tu historial de simulacros y genera un plan semanal a tu medida.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ])),
          ]),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _materiasRutaController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3, minLines: 2,
          decoration: InputDecoration(
            hintText: 'Ej: Cálculo II, Física, Programación en Python...',
            hintStyle: const TextStyle(color: Colors.white38),
            labelText: 'Materias / temas de esta semana',
            labelStyle: const TextStyle(color: Color(0xFF5DE0C5)),
            filled: true, fillColor: const Color(0xFF1E1E2A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _horasRutaController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Ej: 12',
            hintStyle: const TextStyle(color: Colors.white38),
            labelText: 'Horas disponibles esta semana',
            labelStyle: const TextStyle(color: Color(0xFF5DE0C5)),
            filled: true, fillColor: const Color(0xFF1E1E2A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _cargandoRuta ? null : _generarRutaAprendizaje,
            icon: _cargandoRuta
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            label: Text(_cargandoRuta ? 'Generando tu plan...' : 'Generar mi ruta de estudio', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5DE0C5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (_resultadoRuta.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF5DE0C5).withOpacity(0.35)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Row(children: [Icon(Icons.calendar_today, color: Color(0xFF5DE0C5), size: 14), SizedBox(width: 6), Text('Tu plan semanal', style: TextStyle(color: Color(0xFF5DE0C5), fontWeight: FontWeight.bold, fontSize: 13))]),
                GestureDetector(
                  onTap: () async => Share.share(_resultadoRuta),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF5DE0C5).withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: const Row(children: [Icon(Icons.share, size: 12, color: Color(0xFF5DE0C5)), SizedBox(width: 4), Text('Compartir', style: TextStyle(color: Color(0xFF5DE0C5), fontSize: 11))])),
                ),
              ]),
              const SizedBox(height: 10),
              Text(_resultadoRuta.replaceAll('**', '').replaceAll('###', '').replaceAll('##', '').replaceAll('#', ''), style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.65)),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildChatHerramientas() {
    final esFeynman = _subModoHerramientas == 3;
    final color = esFeynman ? const Color(0xFF7C6AF7) : const Color(0xFFF7584A);
    final titulo = esFeynman ? 'Técnica Feynman' : 'Tutor Socrático';
    final descripcion = esFeynman
        ? 'Explícale el tema a la IA. Ella identificará tus vacíos con preguntas guía.'
        : 'La IA nunca te dará la respuesta directa. Te hará preguntas para que llegues solo.';
    final hint = esFeynman ? 'Empieza a explicar el tema...' : 'Escribe tu respuesta o pregunta...';

    if (!_chatHerramientasIniciado) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.18), const Color(0xFF0F0F14)]), borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(esFeynman ? Icons.psychology : Icons.question_answer, color: color, size: 22), const SizedBox(width: 8), Text(titulo, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16))]),
            const SizedBox(height: 8),
            Text(descripcion, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ])),
          const SizedBox(height: 16),
          TextField(controller: _temaHerramientasController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Ej: Termodinámica, Cálculo diferencial...', hintStyle: const TextStyle(color: Colors.white38), labelText: 'Tema que quieres trabajar', labelStyle: TextStyle(color: color), filled: true, fillColor: const Color(0xFF1E1E2A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _iniciarChatHerramientas, icon: Icon(esFeynman ? Icons.psychology : Icons.play_arrow, color: Colors.white, size: 18), label: Text('Iniciar ${esFeynman ? 'sesión Feynman' : 'sesión Socrática'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        ]),
      );
    }

    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: const Color(0xFF1E1E2A),
        child: Row(children: [
          Icon(esFeynman ? Icons.psychology : Icons.question_answer, color: color, size: 14),
          const SizedBox(width: 6),
          Text('$titulo — ${_temaHerramientasController.text}', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          const Spacer(),
          GestureDetector(onTap: () => setState(() { _chatHerramientas = []; _chatHerramientasIniciado = false; _temaHerramientasController.clear(); }), child: const Icon(Icons.refresh, color: Colors.white38, size: 18)),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          controller: _chatHerramientasScroll,
          padding: const EdgeInsets.all(12),
          itemCount: _chatHerramientas.length + (_cargandoChatHerramientas ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == _chatHerramientas.length) {
              return Padding(padding: const EdgeInsets.only(left: 8, bottom: 6), child: Row(children: [const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C6AF7))), const SizedBox(width: 8), Text(context.l10n.iaAnalyzing, style: const TextStyle(color: Colors.white38, fontSize: 12))]));
            }
            final msg = _chatHerramientas[i];
            final esUsuario = msg['role'] == 'user';
            return Align(
              alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                decoration: BoxDecoration(color: esUsuario ? color : const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(14)),
                child: Text(msg['text'] ?? '', style: TextStyle(color: esUsuario ? Colors.white : Colors.white70, fontSize: 13, height: 1.5)),
              ),
            );
          },
        ),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(color: const Color(0xFF1E1E2A), border: Border(top: BorderSide(color: color.withOpacity(0.2)))),
        child: Row(children: [
          Expanded(child: TextField(controller: _chatHerramientasController, style: const TextStyle(color: Colors.white, fontSize: 13), decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white38, fontSize: 13), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), filled: true, fillColor: const Color(0xFF0F0F14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)), onSubmitted: (_) => _enviarMensajeChatHerramientas())),
          const SizedBox(width: 8),
          GestureDetector(onTap: _enviarMensajeChatHerramientas, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.send, color: Colors.white, size: 18))),
        ]),
      ),
    ]);
  }

  Widget _buildSimulacro() {
    if (_cargandoSimulacro) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(color: Color(0xFF7C6AF7)), SizedBox(height: 16), Text('Generando simulacro...', style: TextStyle(color: Colors.white54))]));
    if (_simulacroTerminado) return _buildResultados();
    if (_preguntasSimulacro.isNotEmpty) return _buildPreguntaActual();
    return _buildConfigSimulacro();
  }

  Widget _buildConfigSimulacro() {
    final escenarios = CarreraService.escenarios(_carrera);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2A1F5E), Color(0xFF1A2A1F)]), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Icon(Icons.quiz, color: Color(0xFF7C6AF7), size: 28),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Simulacro de Examen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                _carrera.isNotEmpty ? 'Personalizado para $_carrera' : 'Pon a prueba tus conocimientos',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ])),
            if (_carrera.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C6AF7).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF7C6AF7).withOpacity(0.5)),
                ),
                child: Text(_carrera, style: const TextStyle(color: Color(0xFF7C6AF7), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
          ]),
        ),
        const SizedBox(height: 20),
        if (escenarios.isNotEmpty) ...[
          const Text('SUGERENCIAS PARA TU CARRERA', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: escenarios.map((e) => _TapScale(
                onTap: () => setState(() => _simulacroTemaController.text = e),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF7C6AF7).withOpacity(0.35)),
                  ),
                  child: Text(e, style: const TextStyle(color: Color(0xFF7C6AF7), fontSize: 12)),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        TextField(controller: _simulacroTemaController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Ej: Calculo II, Historia del Peru, Python', hintStyle: const TextStyle(color: Colors.white38), labelText: 'Tema del simulacro', labelStyle: const TextStyle(color: Color(0xFF7C6AF7)), filled: true, fillColor: const Color(0xFF1E1E2A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        const SizedBox(height: 12),
        TextField(controller: _cantidadController, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Ej: 10', hintStyle: const TextStyle(color: Colors.white38), labelText: 'Cantidad de preguntas', labelStyle: const TextStyle(color: Color(0xFF7C6AF7)), filled: true, fillColor: const Color(0xFF1E1E2A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        const SizedBox(height: 16),
        const Text('Nivel educativo', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 8),
        Row(children: _niveles.map((nivel) { final selected = _nivelSeleccionado == nivel; return Expanded(child: GestureDetector(onTap: () => setState(() => _nivelSeleccionado = nivel), child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: selected ? const Color(0xFF7C6AF7) : const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(10)), child: Center(child: Text(nivel, style: TextStyle(color: selected ? Colors.white : Colors.white54, fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal)))))); }).toList()),
        const SizedBox(height: 16),
        const Text('Dificultad', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 8),
        Row(children: _dificultades.map((dif) { final selected = _dificultadSeleccionada == dif; final color = dif == 'Básico' ? const Color(0xFF5DE0C5) : dif == 'Intermedio' ? const Color(0xFFF7A26A) : const Color(0xFFF7584A); return Expanded(child: GestureDetector(onTap: () => setState(() => _dificultadSeleccionada = dif), child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: selected ? color : const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(10), border: selected ? null : Border.all(color: color.withOpacity(0.3))), child: Center(child: Text(dif, style: TextStyle(color: selected ? Colors.white : color, fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal)))))); }).toList()),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _generarSimulacro, icon: const Icon(Icons.play_arrow, color: Colors.white), label: const Text('Iniciar Simulacro', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C6AF7), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
      ]),
    );
  }

  Widget _buildPreguntaActual() {
    final pregunta = _preguntasSimulacro[_preguntaActual];
    final opciones = List<String>.from(pregunta['opciones'] ?? []);
    final respuestaActual = _respuestasUsuario[_preguntaActual];
    final progreso = (_preguntaActual + 1) / _preguntasSimulacro.length;
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Pregunta ${_preguntaActual + 1} de ${_preguntasSimulacro.length}', style: const TextStyle(color: Colors.white54, fontSize: 12)), Text('$_nivelSeleccionado · $_dificultadSeleccionada', style: const TextStyle(color: Color(0xFF7C6AF7), fontSize: 12))]),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progreso, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C6AF7)), minHeight: 6)),
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF7C6AF7).withOpacity(0.3))), child: Text(pregunta['pregunta']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5, fontWeight: FontWeight.w600))),
      const SizedBox(height: 16),
      ...opciones.map((opcion) { final letra = opcion.isNotEmpty ? opcion.substring(0, 1) : ''; final selected = respuestaActual == opcion; return GestureDetector(onTap: () => _responderPregunta(opcion), child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: selected ? const Color(0xFF7C6AF7).withOpacity(0.2) : const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? const Color(0xFF7C6AF7) : const Color(0xFF2E2E3E), width: selected ? 2 : 1)), child: Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: selected ? const Color(0xFF7C6AF7) : const Color(0xFF0F0F14), borderRadius: BorderRadius.circular(8)), child: Center(child: Text(letra, style: TextStyle(color: selected ? Colors.white : Colors.white54, fontWeight: FontWeight.bold)))), const SizedBox(width: 12), Expanded(child: Text(opcion.length > 2 ? opcion.substring(2).trim() : opcion, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 14)))]))); }),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: respuestaActual != null ? _siguientePregunta : null, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C6AF7), disabledBackgroundColor: const Color(0xFF2E2E3E), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(_preguntaActual < _preguntasSimulacro.length - 1 ? 'Siguiente pregunta' : 'Ver resultados', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
    ]));
  }

  Widget _buildResultados() {
    final correctas = _puntaje;
    final total = _preguntasSimulacro.length;
    final porcentaje = total > 0 ? (correctas / total * 100).round() : 0;
    final color = porcentaje >= 70 ? const Color(0xFF5DE0C5) : porcentaje >= 50 ? const Color(0xFFF7A26A) : const Color(0xFFF7584A);
    final mensaje = porcentaje >= 70 ? '¡Excelente!' : porcentaje >= 50 ? '¡Bien! Puedes mejorar' : 'Sigue practicando';
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.2), const Color(0xFF0F0F14)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))), child: Column(children: [Text(porcentaje >= 70 ? '🎉' : porcentaje >= 50 ? '👍' : '💪', style: const TextStyle(fontSize: 48)), const SizedBox(height: 8), Text(mensaje, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text('$correctas de $total correctas', style: const TextStyle(color: Colors.white54, fontSize: 14)), const SizedBox(height: 12), Text('$porcentaje%', style: TextStyle(color: color, fontSize: 48, fontWeight: FontWeight.bold))])),
      const SizedBox(height: 20),
      const Text('Revisión de respuestas', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
      const SizedBox(height: 12),
      ..._preguntasSimulacro.asMap().entries.map((entry) { final i = entry.key; final p = entry.value; final correcta = p['correcta']?.toString().trim().toUpperCase() ?? ''; final respuesta = _respuestasUsuario[i]?.trim().toUpperCase() ?? ''; final esCorrecta = respuesta.startsWith(correcta); final opciones = List<String>.from(p['opciones'] ?? []); final opcionCorrecta = opciones.firstWhere((o) => o.toUpperCase().startsWith(correcta), orElse: () => ''); return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12), border: Border.all(color: esCorrecta ? const Color(0xFF5DE0C5).withOpacity(0.4) : const Color(0xFFF7584A).withOpacity(0.4))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(esCorrecta ? Icons.check_circle : Icons.cancel, color: esCorrecta ? const Color(0xFF5DE0C5) : const Color(0xFFF7584A), size: 18), const SizedBox(width: 8), Expanded(child: Text('${i + 1}. ${p['pregunta']}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)))]), const SizedBox(height: 8), if (!esCorrecta) ...[Text('Tu respuesta: ${_respuestasUsuario[i] ?? 'Sin respuesta'}', style: const TextStyle(color: Color(0xFFF7584A), fontSize: 12)), Text('Correcta: $opcionCorrecta', style: const TextStyle(color: Color(0xFF5DE0C5), fontSize: 12))] else Text('✓ ${_respuestasUsuario[i]}', style: const TextStyle(color: Color(0xFF5DE0C5), fontSize: 12)), if (p['explicacion'] != null) ...[const SizedBox(height: 6), Text('💡 ${p['explicacion']}', style: const TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic))]])); }),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => setState(() { _preguntasSimulacro = []; _respuestasUsuario = []; _simulacroTerminado = false; _preguntaActual = 0; _analisisDebilidades = ''; }), icon: const Icon(Icons.refresh, color: Colors.white), label: const Text('Nuevo simulacro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C6AF7), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
      const SizedBox(height: 8),
      if (_analisisDebilidades.isEmpty)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _analizandoDebilidades ? null : _analizarDebilidades,
            icon: _analizandoDebilidades
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF7A26A)))
                : const Icon(Icons.psychology, color: Color(0xFFF7A26A), size: 18),
            label: Text(_analizandoDebilidades ? 'Analizando...' : 'Analizar mis puntos débiles con IA', style: const TextStyle(color: Color(0xFFF7A26A), fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: Color(0xFFF7A26A)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
      if (_analisisDebilidades.isNotEmpty) ...[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF7A26A).withOpacity(0.4))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.psychology, color: Color(0xFFF7A26A), size: 16), SizedBox(width: 8), Text('Análisis de debilidades', style: TextStyle(color: Color(0xFFF7A26A), fontWeight: FontWeight.bold, fontSize: 13))]),
            const SizedBox(height: 10),
            Text(_analisisDebilidades.replaceAll('**', '').replaceAll('###', '').replaceAll('##', '').replaceAll('#', ''), style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6)),
          ]),
        ),
      ],
    ]));
  }

  Widget _buildTemasPopulares() {
    final temas = CarreraService.temasPopulares(_carrera);
    final label = _carrera.isNotEmpty ? 'TEMAS DE $_carrera'.toUpperCase() : 'TEMAS POPULARES';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
        if (_carrera.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF7C6AF7).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF7C6AF7).withOpacity(0.4)),
            ),
            child: Text(_carrera, style: const TextStyle(color: Color(0xFF7C6AF7), fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ],
      ]),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: temas.map((t) => _TapScale(
            onTap: () => setState(() => _temaController.text = t),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF7C6AF7).withOpacity(0.4)),
              ),
              child: Text(t, style: const TextStyle(color: Color(0xFF7C6AF7), fontSize: 12)),
            ),
          )).toList(),
        ),
      ),
    ]);
  }

  Widget _buildMapaVisual() {
    if (_mapaConceptual.isEmpty) {
      return const Center(child: Text('Sin mapa conceptual', style: TextStyle(color: Colors.white38)));
    }
    final root = _mapaConceptual.first;
    final children = _mapaConceptual.skip(1).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7C6AF7), Color(0xFF5A4ED4)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: const Color(0xFF7C6AF7).withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Text(root, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
        ),
        if (children.isNotEmpty) ...[
          Center(child: Container(width: 2, height: 20, color: const Color(0xFF7C6AF7))),
          SizedBox(
            height: 20,
            width: double.infinity,
            child: CustomPaint(painter: _MapaBranchPainter(children.length)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children.map((child) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A40),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF7C6AF7).withOpacity(0.55)),
                  ),
                  child: Text(child, style: const TextStyle(color: Color(0xFF7C6AF7), fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(10)),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Colors.white38, size: 13),
              SizedBox(width: 6),
              Text('Concepto principal y sus ramas clave', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapScale({required this.child, required this.onTap});

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _MapaBranchPainter extends CustomPainter {
  final int count;
  const _MapaBranchPainter(this.count);

  @override
  void paint(Canvas canvas, Size size) {
    if (count == 0) return;
    final paint = Paint()
      ..color = const Color(0xFF7C6AF7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final childW = size.width / count;
    final centers = List.generate(count, (i) => childW * i + childW / 2);
    if (centers.length > 1) {
      canvas.drawLine(Offset(centers.first, 0), Offset(centers.last, 0), paint);
    }
    for (final cx in centers) {
      canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}