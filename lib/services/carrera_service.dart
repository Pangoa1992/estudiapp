class CarreraService {
  static const List<String> lista = [
    'Medicina',
    'Enfermería',
    'Odontología',
    'Farmacia',
    'Veterinaria',
    'Nutrición',
    'Ingeniería Civil',
    'Ingeniería Mecánica',
    'Ingeniería Electrónica',
    'Ingeniería Industrial',
    'Ingeniería de Sistemas',
    'Arquitectura',
    'Derecho',
    'Psicología',
    'Administración de Empresas',
    'Contabilidad',
    'Economía',
    'Marketing',
    'Comunicaciones',
    'Educación',
    'Biología',
    'Química',
    'Física',
    'Matemáticas',
    'Trabajo Social',
    'Otra',
  ];

  static String contextoIA(String carrera) {
    switch (carrera) {
      case 'Medicina':
        return 'Soy estudiante de Medicina. Usa terminología médica precisa. Incluye fisiopatología, diagnóstico diferencial, farmacología y casos clínicos reales cuando sea relevante.';
      case 'Enfermería':
        return 'Soy estudiante de Enfermería. Incluye protocolos de cuidado, signos vitales, administración de fármacos y atención al paciente.';
      case 'Odontología':
        return 'Soy estudiante de Odontología. Incluye anatomía dental, procedimientos odontológicos y patologías orales.';
      case 'Ingeniería Civil':
        return 'Soy estudiante de Ingeniería Civil. Incluye cálculo estructural, resistencia de materiales, mecánica de fluidos, topografía y diseño de infraestructura.';
      case 'Ingeniería Mecánica':
        return 'Soy estudiante de Ingeniería Mecánica. Incluye termodinámica, dinámica, resistencia de materiales y diseño de máquinas.';
      case 'Ingeniería Electrónica':
        return 'Soy estudiante de Ingeniería Electrónica. Incluye análisis de circuitos, electrónica digital y analógica, señales, sistemas y microcontroladores.';
      case 'Ingeniería Industrial':
        return 'Soy estudiante de Ingeniería Industrial. Incluye investigación de operaciones, gestión de calidad, logística y producción.';
      case 'Ingeniería de Sistemas':
        return 'Soy estudiante de Ingeniería de Sistemas. Incluye algoritmos, estructuras de datos, programación, redes, bases de datos y arquitectura de software.';
      case 'Derecho':
        return 'Soy estudiante de Derecho. Usa terminología jurídica formal. Incluye jurisprudencia, legislación vigente, casos judiciales y argumentación legal.';
      case 'Psicología':
        return 'Soy estudiante de Psicología. Incluye teorías psicológicas, DSM, técnicas terapéuticas y casos clínicos de salud mental.';
      case 'Administración de Empresas':
        return 'Soy estudiante de Administración. Incluye gestión estratégica, finanzas corporativas, marketing, RRHH y análisis de casos empresariales.';
      case 'Contabilidad':
        return 'Soy estudiante de Contabilidad. Incluye NIIF, contabilidad financiera, auditoría, costos y tributación.';
      case 'Arquitectura':
        return 'Soy estudiante de Arquitectura. Incluye diseño arquitectónico, estructuras, urbanismo y normativas de construcción.';
      default:
        return carrera.isNotEmpty ? 'Soy estudiante universitario de $carrera.' : '';
    }
  }

  static String rolIAEnCaso(String carrera) {
    switch (carrera) {
      case 'Medicina':         return 'paciente con síntomas clínicos reales';
      case 'Enfermería':       return 'paciente en urgencias que necesita atención';
      case 'Derecho':          return 'cliente que necesita asesoría legal urgente';
      case 'Psicología':       return 'paciente con un problema de salud mental';
      case 'Administración de Empresas': return 'cliente empresarial con un problema de gestión';
      case 'Ingeniería Civil': return 'supervisor de obra con un problema estructural';
      case 'Ingeniería Electrónica': return 'ingeniero de planta con un fallo de circuito';
      case 'Arquitectura':     return 'cliente que quiere diseñar un edificio';
      case 'Odontología':      return 'paciente con dolor dental urgente';
      case 'Veterinaria':      return 'dueño con una mascota enferma';
      default:                 return 'evaluador profesional del área';
    }
  }

  static List<String> escenarios(String carrera) {
    switch (carrera) {
      case 'Medicina':
        return ['Urgencias: dolor torácico', 'Diagnóstico diferencial', 'Pediatría: fiebre alta', 'Cirugía de emergencia', 'Caso oncológico'];
      case 'Enfermería':
        return ['Administración de medicamentos', 'Paro cardiorrespiratorio', 'Herida quirúrgica infectada', 'Paciente agitado', 'Alta hospitalaria'];
      case 'Derecho':
        return ['Audiencia oral penal', 'Contrato mercantil', 'Divorcio conflictivo', 'Demanda laboral', 'Defensa penal'];
      case 'Psicología':
        return ['Primera consulta clínica', 'Crisis de ansiedad', 'Depresión mayor', 'Violencia familiar', 'Terapia de pareja'];
      case 'Administración de Empresas':
        return ['Negociación con proveedor', 'Crisis financiera', 'Presentación a inversores', 'Conflicto laboral', 'Lanzamiento de producto'];
      case 'Ingeniería Civil':
        return ['Falla estructural en obra', 'Diseño de puente', 'Estudio de suelos', 'Control de calidad', 'Informe técnico'];
      case 'Ingeniería Electrónica':
        return ['Falla en circuito de potencia', 'Diseño de amplificador', 'Sistema embebido', 'Control PID', 'Diagnóstico de PCB'];
      case 'Arquitectura':
        return ['Diseño de vivienda social', 'Rehabilitación histórica', 'Centro comercial', 'Urbanismo sostenible', 'Licitación pública'];
      default:
        return ['Caso práctico general', 'Evaluación profesional', 'Situación de campo', 'Caso ético', 'Resolución de problemas'];
    }
  }
}
