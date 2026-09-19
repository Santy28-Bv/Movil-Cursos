import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/course_feed_controller.dart';
import '../screens/courses/course_detail_screen.dart';
import '../screens/courses/my_courses_screen.dart';
import '../services/demo_learning_store.dart';
import '../models/course.dart';
import '../repositories/course_repository.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'services/auth_service.dart';
import '../theme/academix_colors.dart';

// Widgets de cuenta
import '../widgets/home/auth/account_menu_sheet.dart';
import '../widgets/home/auth/guest_account_sheet.dart';

// Widgets del Home
import '../widgets/home/course_card.dart';
import '../widgets/home/course_catalog_header.dart';
import '../widgets/home/course_feed_state.dart';
import '../widgets/home/home_cta.dart';
import '../widgets/home/home_footer.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/home_hero.dart';
import '../widgets/home/home_navigation.dart';
import '../widgets/home/home_stats.dart';
import '../widgets/home/learning_steps_section.dart';
import '../widgets/home/testimonials_section.dart';

/// Pantalla principal de Academix.
/// Organiza las secciones del Home y controla la navegación.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  final _catalogAnchor = GlobalKey();
  final _catalogEnd = GlobalKey();

  final AuthService _authService = AuthService();
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isAuthenticated = false;
  String? _activeUserId;
  late final SupabaseCourseRepository _courseRepository;

  late final CourseFeedController _feed;

  @override
  void initState() {
    super.initState();

    _courseRepository = SupabaseCourseRepository(Supabase.instance.client);
    _feed = CourseFeedController(repository: _courseRepository);

    _scrollController.addListener(_checkCatalogEnd);
    _feed.addListener(_afterFeedUpdate);

    // El Home existe con o sin sesión. Actualizamos los controles y el
    // catálogo al cambiar permisos para no conservar datos de otra sesión.
    final auth = Supabase.instance.client.auth;
    _activeUserId = auth.currentUser?.id;
    _isAuthenticated = _activeUserId != null;
    _authSubscription = auth.onAuthStateChange.listen((state) {
      if (!mounted) return;
      final signedIn = state.session?.user != null;
      final nextUserId = state.session?.user.id;
      if (_activeUserId != nextUserId) {
        _activeUserId = nextUserId;
        // No mezclar matrícula o tareas de una cuenta con otra.
        DemoLearningStore.instance.clear();
        _courseRepository.resetSource();
        setState(() => _isAuthenticated = signedIn);
        _feed.refresh();
      }
    });

    _feed.loadMore();
  }

  // =====================================================
  // CONTROL DEL CATÁLOGO Y SCROLL INFINITO
  // =====================================================

  void _afterFeedUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkCatalogEnd();
      }
    });
  }

  /// Carga más cursos cuando el usuario se acerca
  /// al final de las tarjetas.
  void _checkCatalogEnd() {
    if (!mounted ||
        !_scrollController.hasClients ||
        _feed.isLoading ||
        !_feed.hasMore ||
        _feed.error != null) {
      return;
    }

    final render = _catalogEnd.currentContext?.findRenderObject();

    if (render is! RenderBox || !render.hasSize) {
      return;
    }

    final screenY = render.localToGlobal(Offset.zero).dy;

    if (screenY <= MediaQuery.sizeOf(context).height + 450) {
      _feed.loadMore();
    }
  }

  // =====================================================
  // NAVEGACIÓN
  // =====================================================

  /// Desplazarse hasta los cursos.
  void _scrollToCourses() {
    final target = _catalogAnchor.currentContext;

    if (target == null) return;

    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.02,
    );
  }

  /// Volver al inicio de Academix.
  void _scrollToTop() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  /// Mensaje para funcionalidades pendientes.
  void _comingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label estará disponible próximamente.')),
    );
  }

  // =====================================================
  // AUTENTICACIÓN Y MENÚ DE CUENTA
  // =====================================================

  void _openLogin() {
    Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const LoginScreen()),
    );
  }

  void _openRegister() {
    if (_isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya tienes una sesión iniciada.')),
      );
      _scrollToCourses();
      return;
    }
    Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const RegisterScreen()),
    );
  }

  void _openMyCourses() {
    if (!_isAuthenticated) {
      _openAccountMenu();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MyCoursesScreen()),
    );
  }

  void _openAccountMenu() {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      // Un visitante puede elegir iniciar sesión o registrarse.
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: AcademixColors.card,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) => GuestAccountSheet(
          onLogin: () {
            Navigator.of(sheetContext).pop();
            _openLogin();
          },
          onRegister: () {
            Navigator.of(sheetContext).pop();
            _openRegister();
          },
        ),
      );
      return;
    }

    final firstName = (user.userMetadata?['nombres'] ?? '').toString();
    final lastName = (user.userMetadata?['apellido_paterno'] ?? '').toString();
    final fullName = '$firstName $lastName'.trim();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AcademixColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AccountMenuSheet(
        name: fullName.isEmpty ? 'Usuario Academix' : fullName,
        email: user.email ?? '',
        onMyCourses: _openMyCourses,
        onSignOut: () => _signOut(),
        onSwitchAccount: () => _signOut(switchAccount: true),
      ),
    );
  }

  Future<void> _signOut({bool switchAccount = false}) async {
    try {
      await _authService.logout();
      DemoLearningStore.instance.clear();

      // El Home público permanece como raíz después de cerrar sesión.
      if (mounted && switchAccount) _openLogin();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fue posible cerrar sesión. Intenta nuevamente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // =====================================================
  // DETALLE PREVIO DE CURSOS
  // =====================================================

  void _showCourse(Course course) {
    // Información pública: el detalle no requiere iniciar sesión.
    // La inscripción y las lecciones se protegen dentro del detalle.
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CourseDetailScreen(course: course),
    ));
  }

  // =====================================================
  // LIBERAR RECURSOS
  // =====================================================

  @override
  void dispose() {
    _authSubscription.cancel();
    _feed.removeListener(_afterFeedUpdate);
    _feed.dispose();

    _scrollController.dispose();
    _searchController.dispose();

    super.dispose();
  }

  // =====================================================
  // INTERFAZ PRINCIPAL
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AcademixColors.background,

      // ================================================
      // NAVBAR INFERIOR
      // ================================================
      bottomNavigationBar: HomeNavigation(
        onHome: _scrollToTop,
        onCourses: _scrollToCourses,
        onProfile: _openAccountMenu,
        onMyCourses: _openMyCourses,
        isAuthenticated: _isAuthenticated,
      ),

      body: SafeArea(
        child: AnimatedBuilder(
          animation: _feed,
          builder: (context, _) {
            return RefreshIndicator(
              color: AcademixColors.purple,
              onRefresh: _feed.refresh,

              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),

                slivers: [
                  // ====================================
                  // HEADER, HERO, ESTADÍSTICAS Y BUSCADOR
                  // ====================================
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,

                      children: [
                        // Encabezado con acceso a cuenta.
                        HomeHeader(
                          onProfile: _openAccountMenu,
                          isAuthenticated: _isAuthenticated,
                        ),

                        // Portada.
                        HomeHero(onExplore: _scrollToCourses),

                        // Estadísticas.
                        const HomeStats(),

                        // Encabezado y búsqueda de cursos.
                        CourseCatalogHeader(
                          key: _catalogAnchor,
                          searchController: _searchController,
                          currentSearch: _feed.search,

                          onSearch: (value) {
                            if (value.trim() != _feed.search) {
                              _feed.refresh(search: value);

                              _scrollToCourses();
                            }
                          },
                        ),
                        if (_feed.isDemo)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38254D),
                                border: Border.all(color: AcademixColors.purple),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(_feed.notice ?? 'Catálogo de demostración',
                                  style: const TextStyle(color: Colors.white70,
                                      fontSize: 12)),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ====================================
                  // CATÁLOGO CON SCROLL INFINITO
                  // ====================================
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),

                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final course = _feed.courses[index];

                        return CourseCard(
                          key: ValueKey(course.id.isEmpty ? index : course.id),
                          course: course,
                          onTap: () => _showCourse(course),
                        );
                      }, childCount: _feed.courses.length),
                    ),
                  ),

                  // ====================================
                  // ESTADO DE CARGA DEL CATÁLOGO
                  // ====================================
                  SliverToBoxAdapter(
                    child: CourseFeedState(
                      key: _catalogEnd,
                      isLoading: _feed.isLoading,
                      hasMore: _feed.hasMore,
                      isEmpty: _feed.courses.isEmpty,
                      error: _feed.error,
                      onRetry: _feed.retry,
                    ),
                  ),

                  // ====================================
                  // SECCIONES INFERIORES
                  // ====================================
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,

                      children: [
                        // Cómo funciona Academix.
                        const LearningStepsSection(),

                        // Testimonios.
                        const TestimonialsSection(),

                        // Llamado a la acción.
                        HomeCta(
                          onExplore: _scrollToCourses,
                          onRegister: _openRegister,
                        ),

                        // Pie de página.
                        const HomeFooter(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
