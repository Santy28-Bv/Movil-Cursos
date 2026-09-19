import '../models/course.dart';

/// El repositorio CursosWeb utiliza estos cursos como mocks (no como datos de
/// Supabase). Se incluyen aquí para poder visualizar el catálogo aunque la BD
/// real todavía no tenga tabla/política para los cursos públicos.
/// Las actividades de práctica son demostrativas y no provienen de CursosWeb.
const cursosWebDemo = <Course>[
  Course(
    id: 'course-web-full-stack',
    title: 'Master en Desarrollo Web Full-Stack Moderno',
    description: 'Crea aplicaciones modernas de frontend a backend con un flujo profesional.',
    category: 'Desarrollo Web', price: 89.99, imageUrl: '',
    instructor: 'Dr. Roberto Silva', level: 'Intermedio', durationHours: 45,
    rating: 4.9, isDemo: true,
    learningOutcomes: ['Construir interfaces con React y TypeScript.',
      'Diseñar APIs REST mantenibles.', 'Desplegar una aplicación completa.'],
    requirements: ['HTML y CSS básicos', 'Acceso a internet'],
    modules: [
      CourseModule(id: 'web-module-1', title: 'Fundamentos y herramientas', lessons: [
        CourseLesson(id: 'web-lesson-1', title: 'Bienvenida y entorno', durationMinutes: 14,
          task: 'Describe qué herramientas necesitarás para tu proyecto web.'),
        CourseLesson(id: 'web-lesson-2', title: 'Git y flujo de trabajo', durationMinutes: 28),
      ]),
      CourseModule(id: 'web-module-2', title: 'Frontend con React', lessons: [
        CourseLesson(id: 'web-lesson-3', title: 'Componentes y estado', durationMinutes: 42,
          task: 'Explica con tus palabras qué es un componente reutilizable.'),
        CourseLesson(id: 'web-lesson-4', title: 'Consumo de una API', durationMinutes: 36),
      ]),
    ],
  ),
  Course(
    id: 'course-ui-ux',
    title: 'Diseño de Interfaces (UI) de Alto Impacto',
    description: 'Diseña productos digitales claros, accesibles y visualmente consistentes.',
    category: 'Diseño UI/UX', price: 65.50, imageUrl: '',
    instructor: 'Elena Martínez', level: 'Principiante', durationHours: 28,
    rating: 4.8, isDemo: true,
    learningOutcomes: ['Crear wireframes', 'Construir un sistema visual', 'Evaluar accesibilidad'],
    modules: [CourseModule(id: 'ui-module-1', title: 'Principios de diseño de producto', lessons: [
      CourseLesson(id: 'ui-lesson-1', title: 'Jerarquía visual', durationMinutes: 25,
        task: 'Redacta tres reglas para mejorar la jerarquía visual de una pantalla.'),
      CourseLesson(id: 'ui-lesson-2', title: 'Color y tipografía', durationMinutes: 34),
    ])],
  ),
  Course(
    id: 'course-machine-learning',
    title: 'Master en Machine Learning y Deep Learning con Python',
    description: 'Construye modelos de IA capaces de resolver problemas reales con Python.',
    category: 'Inteligencia Artificial', price: 49.99, imageUrl: '',
    instructor: 'Dr. Alejandro Ruiz', level: 'Avanzado', durationHours: 42,
    rating: 4.9, isDemo: true,
    learningOutcomes: ['Preprocesar datos', 'Entrenar modelos', 'Evaluar resultados'],
    modules: [
      CourseModule(id: 'ml-module-1', title: 'Introducción al Machine Learning', lessons: [
        CourseLesson(id: 'ml-lesson-1', title: '¿Qué es el aprendizaje automático?', durationMinutes: 13,
          task: 'Describe un ejemplo cotidiano de aprendizaje automático.'),
        CourseLesson(id: 'ml-lesson-2', title: 'Tipos de aprendizaje', durationMinutes: 15),
        CourseLesson(id: 'ml-lesson-3', title: 'Configuración del entorno', durationMinutes: 18),
      ]),
      CourseModule(id: 'ml-module-2', title: 'Fundamentos matemáticos y preprocesamiento', lessons: [
        CourseLesson(id: 'ml-lesson-4', title: 'Preparación de datos', durationMinutes: 38),
        CourseLesson(id: 'ml-lesson-5', title: 'Selección de variables', durationMinutes: 31),
      ]),
      CourseModule(id: 'ml-module-3', title: 'Clasificación y regresión', lessons: [
        CourseLesson(id: 'ml-lesson-6', title: 'Regresión y evaluación', durationMinutes: 44),
      ]),
    ],
  ),
  Course(
    id: 'course-marketing', title: 'Estrategias de Marketing Digital 2026',
    description: 'Diseña campañas medibles y conecta con audiencias en canales digitales.',
    category: 'Marketing', price: 45, imageUrl: '',
    instructor: 'Sofía Castro', level: 'Principiante', durationHours: 20,
    rating: 4.7, isDemo: true,
    learningOutcomes: ['Definir una estrategia digital', 'Interpretar métricas'],
  ),
  Course(
    id: 'course-python-data', title: 'Python para Ciencia de Datos y Análisis',
    description: 'Analiza, transforma y visualiza datos con el ecosistema de Python.',
    category: 'Programación', price: 75, imageUrl: '',
    instructor: 'Lucas Benítez', level: 'Intermedio', durationHours: 50,
    rating: 4.8, isDemo: true,
    learningOutcomes: ['Usar Pandas', 'Visualizar datos', 'Construir notebooks'],
  ),
  Course(
    id: 'course-database-optimization', title: 'Optimización de Bases de Datos SQL/NoSQL',
    description: 'Diseña consultas eficientes y diagnostica cuellos de botella en bases de datos.',
    category: 'Bases de Datos', price: 95, imageUrl: '',
    instructor: 'Andrea Soler', level: 'Avanzado', durationHours: 35,
    rating: 4.6, isDemo: true,
    learningOutcomes: ['Leer planes de ejecución', 'Diseñar índices', 'Monitorear rendimiento'],
  ),
];
