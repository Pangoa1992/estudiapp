import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
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
import 'package:google_mobile_ads/google_mobile_ads.dart'; // ── NUEVO

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

  // ── NUEVO ──────────────────────────────────────────────
  InterstitialAd? _interstitialAd;
  int _contadorUsos = 0;

  void _cargarIntersticial() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-6530298594670805/6956014522', // ← reemplaza con tu ID real de AdMob
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) => _interstitialAd = null,
      ),
    );
  }

  void _mostrarIntersticial() {
    _contadorUsos++;
    if (_contadorUsos % 3 == 0 && _interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _cargarIntersticial();
    }
  }
  // ── FIN NUEVO ──────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _cargarHistorialChat();
    _cargarIntersticial(); // ── NUEVO
  }

  @override
  void dispose() {
    _interstitialAd?.dispose(); // ── NUEVO
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
        ? 'Eres un tutor universitario experto. Analiza esta imagen y además responde lo siguiente: "$preguntaExtra". Resuelve TODO paso a paso en español. Se claro y didactico.'
        : 'Eres un tutor universitario experto. Analiza esta imagen y resuelve TODO lo que veas paso a paso en español. Se claro y didactico.';
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
      final XFile? imagen = await _picker.pickImage(source: source, imageQuality: 70, maxWidth: 1024);
      if (imagen == null) return;
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
      setState(() { _respuestaImagen = ''; _cargandoImagen = true; });
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      const maxBytes = 5 * 1024 * 1024;
      if (bytes.length > maxBytes) {
        setState(() { _respuestaImagen = 'El PDF es demasiado grande (máx. 5 MB).'; _cargandoImagen = false; });
        return;
      }
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
    setState(() { _cargandoDocumento = true; _documentoGenerado = ''; });
    final respuesta = await _llamarIATexto(
      'Eres un escritor academico universitario experto. '
      'Genera una $_tipoDocumento completa sobre: "${_documentoController.text}". '
      'Incluye: introduccion, desarrollo con puntos clave, conclusion y referencias. '
      'Usa lenguaje academico formal en español. Minimo 500 palabras.',
    );
    setState(() { _documentoGenerado = respuesta ?? 'Error al generar. Intenta de nuevo.'; _cargandoDocumento = false; });
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
      Directory dir;
      if (Platform.isAndroid) {
        final androidDownloads = Directory('/storage/emulated/0/Download');
        dir = await androidDownloads.exists() ? androidDownloads : await getApplicationDocumentsDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      final file = File('${dir.path}/EstudiApp_$_tipoDocumento.pdf');
      await file.writeAsBytes(bytes);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF guardado en Descargas')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _generarSimulacro() async {
    if (_simulacroTemaController.text.isEmpty) return;
    final tema = _simulacroTemaController.text;
    final cantidad = int.tryParse(_cantidadController.text) ?? 5;
    setState(() { _cargandoSimulacro = true; _preguntasSimulacro = []; _respuestasUsuario = []; _simulacroTerminado = false; _preguntaActual = 0; });
    final (respuesta, _) = await _llamarIA(
      'Genera un simulacro de examen de "$tema" para nivel $_nivelSeleccionado con dificultad $_dificultadSeleccionada. '
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
      setState(() => _simulacroTerminado = true);
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
    final tema = _temaController.text;
    final dias = _diasController.text.isEmpty ? '7' : _diasController.text;
    setState(() {
      _cargando = true; _error = ''; _resumen = '';
      _preguntas = []; _flashcards = []; _tips = [];
      _planEstudio = []; _ejercicios = []; _mapaConceptual = [];
      _preguntasAbiertas = []; _ejerciciosAbiertos = [];
      _chatMensajes = [];
      _temaActual = tema;
      _progreso = 'Generando resumen y preguntas...';
    });
    final (respuesta1, error1) = await _llamarIA(
      'Soy estudiante con examen de "$tema" en $dias dias. Responde SOLO con JSON valido. '
      'Formato: {"resumen": "3 parrafos", "preguntas": [{"pregunta": "p1", "respuesta": "r1"}, {"pregunta": "p2", "respuesta": "r2"}, {"pregunta": "p3", "respuesta": "r3"}, {"pregunta": "p4", "respuesta": "r4"}, {"pregunta": "p5", "respuesta": "r5"}], "flashcards": [{"pregunta": "c1", "respuesta": "d1"}, {"pregunta": "c2", "respuesta": "d2"}, {"pregunta": "c3", "respuesta": "d3"}, {"pregunta": "c4", "respuesta": "d4"}]}. Todo en español.',
    );
    if (respuesta1 == null) { setState(() { _error = error1 ?? 'Error al generar.'; _cargando = false; _progreso = ''; }); return; }
    setState(() => _progreso = 'Generando plan y ejercicios...');
    final (respuesta2, error2) = await _llamarIA(
      'Soy estudiante con examen de "$tema" en $dias dias. Responde SOLO con JSON valido. '
      'Formato: {"tips": ["t1","t2","t3","t4","t5"], "plan": ["Dia 1: a","Dia 2: a","Dia 3: a","Dia 4: a"], "ejercicios": [{"problema": "e1", "solucion": "s1"}, {"problema": "e2", "solucion": "s2"}], "mapa": ["concepto","sub1","sub2","sub3","sub4"]}. Todo en español.',
    );
    if (respuesta2 == null) { setState(() { _error = error2 ?? 'Error al generar plan.'; _cargando = false; _progreso = ''; }); return; }
    final preguntas = List<Map<String, String>>.from((respuesta1['preguntas'] ?? []).map((e) => Map<String, String>.from((e as Map).map((k, v) => MapEntry(k.toString(), v.toString())))));
    final ejercicios = List<Map<String, String>>.from((respuesta2['ejercicios'] ?? []).map((e) => Map<String, String>.from((e as Map).map((k, v) => MapEntry(k.toString(), v.toString())))));
    final flashcards = List<Map<String, String>>.from((respuesta1['flashcards'] ?? []).map((e) => Map<String, String>.from((e as Map).map((k, v) => MapEntry(k.toString(), v.toString())))));
    setState(() {
      _resumen = respuesta1['resumen']?.toString() ?? '';
      _preguntas = preguntas; _flashcards = flashcards;
      _tips = List<String>.from((respuesta2['tips'] ?? []).map((e) => e.toString()));
      _planEstudio = List<String>.from((respuesta2['plan'] ?? []).map((e) => e.toString()));
      _ejercicios = ejercicios;
      _mapaConceptual = List<String>.from((respuesta2['mapa'] ?? []).map((e) => e.toString()));
      _preguntasAbiertas = List.filled(preguntas.length, false);
      _ejerciciosAbiertos = List.filled(ejercicios.length, false);
      _cargando = false; _progreso = '';
    });
    _mostrarIntersticial(); // ── NUEVO: muestra anuncio al generar contenido
    final iaUser = FirebaseAuth.instance.currentUser;
    if (iaUser != null) {
      FirebaseFirestore.instance.collection('logros').doc(iaUser.uid).set(
        {'obtenidos': FieldValue.arrayUnion(['ia_1'])}, SetOptions(merge: true),
      );
    }
  }

  // ── El resto del build y widgets permanece igual ──────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F14),
        title: const Row(children: [
          Text('Estudiar con IA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          SizedBox(width: 6),
          Icon(Icons.lock, color: Color(0xFF5DE0C5), size: 14),
        ]),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_chatMensajes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
              tooltip: 'Limpiar chat',
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
            child: Row(children: [
              _modoBtn('Estudiar', Icons.book, 0),
              _modoBtn('Scanner', Icons.camera_alt, 1),
              _modoBtn('Docs', Icons.description, 2),
              _modoBtn('Simulacro', Icons.quiz, 3),
            ]),
          ),
          Expanded(child: _modoActual == 0 ? _buildEstudio() : _modoActual == 1 ? _buildScanner() : _modoActual == 2 ? _buildDocumento() : _buildSimulacro()),
        ],
      ),
    );
  }

  Widget _modoBtn(String label, IconData icono, int index) {
    final selected = _modoActual == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _modoActual = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: selected ? const Color(0xFF7C6AF7) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Icon(icono, color: selected ? Colors.white : Colors.white38, size: 16),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white38, fontSize: 10)),
          ]),
        ),
      ),
    );
  }

  Widget _buildScanner() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('PASO 1 — ¿Qué necesitas?', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF7C6AF7).withOpacity(0.4))),
          child: TextField(
            controller: _preguntaScannerController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3, minLines: 1,
            decoration: const InputDecoration(hintText: 'Ej: Resúmeme esto, Resuelve los ejercicios...', hintStyle: TextStyle(color: Colors.white38, fontSize: 13), contentPadding: EdgeInsets.all(14), border: InputBorder.none),
          ),
        ),
        const SizedBox(height: 16),
        const Text('PASO 2 — Carga archivo o envía solo texto', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: GestureDetector(onTap: () => _tomarFoto(ImageSource.camera), child: _scanBtn('Cámara', Icons.camera_alt, const Color(0xFF7C6AF7), true))),
          const SizedBox(width: 8),
          Expanded(child: GestureDetector(onTap: () => _tomarFoto(ImageSource.gallery), child: _scanBtn('Galería', Icons.photo_library, const Color(0xFF7C6AF7), false))),
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
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.send, color: Color(0xFF5DE0C5), size: 18),
              SizedBox(width: 8),
              Text('Enviar solo texto (sin imagen)', style: TextStyle(color: Color(0xFF5DE0C5), fontSize: 13, fontWeight: FontWeight.w600)),
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
          const Center(child: Text('Analizando...', style: TextStyle(color: Colors.white54))),
        ],
        if (_respuestaImagen.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF5DE0C5).withOpacity(0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [Icon(Icons.auto_awesome, color: Color(0xFF5DE0C5), size: 16), SizedBox(width: 8), Text('Respuesta de la IA', style: TextStyle(color: Color(0xFF5DE0C5), fontWeight: FontWeight.bold))]),
              const SizedBox(height: 12),
              Text(_respuestaImagen.replaceAll('###', '').replaceAll('##', '').replaceAll('#', '').replaceAll('**', '').replaceAll('*', ''), style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setState(() { _respuestaImagen = ''; _imagenSeleccionada = null; _preguntaScannerController.clear(); }),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFF7C6AF7).withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF7C6AF7).withOpacity(0.3))),
                  child: const Center(child: Text('Nueva consulta', style: TextStyle(color: Color(0xFF7C6AF7), fontSize: 13, fontWeight: FontWeight.w600))),
                ),
              ),
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
              SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [_tabBtn('Resumen', 0), _tabBtn('Preguntas', 1), _tabBtn('Flashcards', 2), _tabBtn('Tips', 3), _tabBtn('Plan', 4), _tabBtn('Ejercicios', 5), _tabBtn('Mapa', 6)])),
            ],
          ]),
        ),
        if (_resumen.isNotEmpty) Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 0), child: _buildContenido())),
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
      case 2: return ListView.builder(itemCount: _flashcards.length, itemBuilder: (context, i) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${_flashcards[i]['pregunta'] ?? ''}', style: const TextStyle(color: Color(0xFF7C6AF7), fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 8), const Divider(color: Colors.white12), const SizedBox(height: 8), Text('${_flashcards[i]['respuesta'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5))])));
      case 3: return ListView.builder(itemCount: _tips.length, itemBuilder: (context, i) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12)), child: Text('💡 ${_tips[i]}', style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5))));
      case 4: return ListView.builder(itemCount: _planEstudio.length, itemBuilder: (context, i) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF7C6AF7).withOpacity(0.3))), child: Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFF7C6AF7), borderRadius: BorderRadius.circular(8)), child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))), const SizedBox(width: 12), Expanded(child: Text(_planEstudio[i], style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5)))])));
      case 5: return ListView.builder(itemCount: _ejercicios.length, itemBuilder: (context, i) => GestureDetector(onTap: () => setState(() => _ejerciciosAbiertos[i] = !_ejerciciosAbiertos[i]), child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text('📝 ${_ejercicios[i]['problema'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))), Icon(_ejerciciosAbiertos[i] ? Icons.expand_less : Icons.expand_more, color: const Color(0xFF5DE0C5))]), if (_ejerciciosAbiertos[i]) ...[const SizedBox(height: 8), const Divider(color: Colors.white12), const SizedBox(height: 8), Text('${_ejercicios[i]['solucion'] ?? ''}', style: const TextStyle(color: Color(0xFF5DE0C5), fontSize: 13, height: 1.5))]]))));
      case 6: return SingleChildScrollView(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1E1E2A), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _mapaConceptual.asMap().entries.map((entry) { final i = entry.key; final concepto = entry.value; return Padding(padding: EdgeInsets.only(left: i == 0 ? 0 : 16, bottom: 8), child: Row(children: [if (i > 0) ...[Container(width: 2, height: 20, color: const Color(0xFF7C6AF7)), const SizedBox(width: 8)], Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: i == 0 ? const Color(0xFF7C6AF7) : const Color(0xFF1A1A40), borderRadius: BorderRadius.circular(8)), child: Text(concepto, style: TextStyle(color: i == 0 ? Colors.white : const Color(0xFF7C6AF7), fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal, fontSize: i == 0 ? 15 : 13))))])); }).toList())));
      default: return const SizedBox();
    }
  }

  Widget _buildSimulacro() {
    if (_cargandoSimulacro) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(color: Color(0xFF7C6AF7)), SizedBox(height: 16), Text('Generando simulacro...', style: TextStyle(color: Colors.white54))]));
    if (_simulacroTerminado) return _buildResultados();
    if (_preguntasSimulacro.isNotEmpty) return _buildPreguntaActual();
    return _buildConfigSimulacro();
  }

  Widget _buildConfigSimulacro() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2A1F5E), Color(0xFF1A2A1F)]), borderRadius: BorderRadius.circular(16)), child: const Row(children: [Icon(Icons.quiz, color: Color(0xFF7C6AF7), size: 28), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Simulacro de Examen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), Text('Pon a prueba tus conocimientos', style: TextStyle(color: Colors.white54, fontSize: 12))]))])),
        const SizedBox(height: 20),
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
      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => setState(() { _preguntasSimulacro = []; _respuestasUsuario = []; _simulacroTerminado = false; _preguntaActual = 0; }), icon: const Icon(Icons.refresh, color: Colors.white), label: const Text('Nuevo simulacro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C6AF7), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
    ]));
  }
}