import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/course_feed_controller.dart';
import '../screens/courses/course_detail_screen.dart';
import '../screens/courses/my_courses_screen.dart';
import '../services/student_session.dart';
import '../repositories/student_repository.dart';
import '../repositories/profile_repository.dart';
import 'student/organizations_screen.dart';
import 'student/help_screen.dart';
import 'student/prices_screen.dart';
import 'student/verify_certificate_screen.dart';
import '../widgets/student/student_guard.dart';
import 'student/cart_screen.dart';
import 'student/profile_screen.dart';
import 'student/certificates_screen.dart';
import 'student/notifications_screen.dart';
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
import '../widgets/home/featured_courses.dart';
import '../widgets/home/catalog_filters.dart';
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
  late final ApiCourseRepository _courseRepository;

  late final CourseFeedController _feed;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();

    _courseRepository = ApiCourseRepository(Supabase.instance.client);
    _feed = CourseFeedController(repository: _courseRepository);

    _scrollController.addListener(_checkCatalogEnd);
    _feed.addListener(_afterFeedUpdate);

    // El Home existe con o sin sesión. Actualizamos los controles y el
    // catálogo al cambiar permisos para no conservar datos de otra sesión.
    final auth = Supabase.instance.client.auth;
    _activeUserId = auth.currentUser?.id;
    _isAuthenticated = _activeUserId != null;
    StudentSession.instance.bindUser(_activeUserId);
    StudentSession.instance.addListener(_studentChanged);
    _lifecycle = AppLifecycleListener(onResume: _refreshNotices);
    _refreshNotices();
    _refreshProfile();
    _authSubscription = auth.onAuthStateChange.listen((state) {
      if (!mounted) return;
      final signedIn = state.session?.user != null;
      final nextUserId = state.session?.user.id;
      if (_activeUserId != nextUserId) {
        _activeUserId = nextUserId;
        // No mezclar matrícula o tareas de una cuenta con otra.
        StudentSession.instance.bindUser(nextUserId);
        _refreshNotices();
        _refreshProfile();
        setState(() => _isAuthenticated = signedIn);
        _feed.refresh();
      }
    }, onError: (Object error, StackTrace stack) {});

    _feed.loadMore();
  }

  void _studentChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshNotices() async {
    if (_activeUserId == null) return;
    try {
      await StudentSession.instance.refreshUnreadCount(
        StudentRepository(Supabase.instance.client).unreadNoticeCount,
      );
    } catch (_) {
      // La pantalla de avisos permite reintentar y muestra el error de consulta.
    }
  }

  Future<void> _refreshProfile() async {
    if (_activeUserId == null) return;
    try {
      final profile = await ProfileRepository(Supabase.instance.client).get();
      StudentSession.instance.updateProfileName(
        '${profile['id']}',
        '${profile['fullName'] ?? ''}',
      );
    } catch (_) {
      /* Mi información permite reintentar la consulta. */
    }
  }

  void _openPublic(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _openStudent(WidgetBuilder builder) {
    if (!_isAuthenticated) {
      _openAccountMenu();
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => StudentGuard(builder: builder)));
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

  // =====================================================
  // AUTENTICACIÓN Y MENÚ DE CUENTA
  // =====================================================

  void _openLogin() {
    Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute<bool>(builder: (_) => const LoginScreen()));
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
    _openStudent((_) => const MyCoursesScreen());
  }

  void _openAccountMenu() {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      // Un visitante puede elegir iniciar sesión o registrarse.
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder:
            (sheetContext) => GuestAccountSheet(
              onHelp: (i) {
                Navigator.pop(sheetContext);
                _openPublic(HelpScreen(initialIndex: i));
              },
              onPrices: () {
                Navigator.pop(sheetContext);
                _openPublic(const PricesScreen());
              },
              onVerify: () {
                Navigator.pop(sheetContext);
                _openPublic(const VerifyCertificateScreen());
              },
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

    _refreshProfile();
    final fullName = StudentSession.instance.profileName;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => AccountMenuSheet(
            name: fullName.isEmpty ? 'Mi cuenta' : fullName,
            email: user.email ?? '',
            onMyCourses: _openMyCourses,
            onHelp: (i) => _openPublic(HelpScreen(initialIndex: i)),
            onPrices: () => _openPublic(const PricesScreen()),
            onVerify: () => _openPublic(const VerifyCertificateScreen()),
            onInformation: () => _openStudent((_) => const ProfileScreen()),
            onOrganizations:
                () => _openStudent((_) => const OrganizationsScreen()),
            onCart: () => _openStudent((_) => const CartScreen()),
            onCertificates:
                () => _openStudent((_) => const CertificatesScreen()),
            onNotifications:
                () => _openStudent((_) => const NotificationsScreen()),
            onSignOut: () => _signOut(),
            onSwitchAccount: () => _signOut(switchAccount: true),
          ),
    );
  }

  Future<void> _signOut({bool switchAccount = false}) async {
    try {
      await _authService.logout();

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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course)),
    );
  }

  // =====================================================
  // LIBERAR RECURSOS
  // =====================================================

  @override
  void dispose() {
    _lifecycle.dispose();
    _authSubscription.cancel();
    StudentSession.instance.removeListener(_studentChanged);
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ================================================
      // NAVBAR INFERIOR
      // ================================================
      bottomNavigationBar: HomeNavigation(
        onHome: _scrollToTop,
        onCourses: _scrollToCourses,
        onProfile: _openAccountMenu,
        onMyCourses: _openMyCourses,
        isAuthenticated: _isAuthenticated,
        onCart: () => _openStudent((_) => const CartScreen()),
        cartCount: StudentSession.instance.cart.length,
      ),

      body: SafeArea(
        child: AnimatedBuilder(
          animation: _feed,
          builder: (context, _) {
            return RefreshIndicator(
              color: AcademixColors.purple,
              onRefresh: () async {
                await Future.wait([_feed.refresh(), _refreshNotices()]);
              },

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
                          onNotifications:
                              () => _openStudent(
                                (_) => const NotificationsScreen(),
                              ),
                          unreadCount: StudentSession.instance.unreadCount,
                          unreadCountKnown:
                              StudentSession.instance.unreadCountKnown,
                        ),

                        // Portada.
                        HomeHero(onExplore: _scrollToCourses),

                        // Estadísticas.
                        const HomeStats(),
                        FeaturedCourses(
                          repository: _courseRepository,
                          onOpen: _showCourse,
                        ),

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

                        CatalogFilters(
                          repository: _courseRepository,
                          onChanged: () {
                            _feed.refresh();
                          },
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
