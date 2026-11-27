import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/course.dart';
import '../models/student_data.dart';

/// Estado de sesión compartido: carrito y avisos nunca pasan a otra cuenta.
/// Conserva el patrón Singleton + Adapter del proyecto de notificaciones.
class StudentSession extends ChangeNotifier {
  static final instance = StudentSession();
  String? _userId;
  int _generation = 0;
  int _noticeVersion = 0;
  final Map<String, Course> _cart = {};
  List<StudentNotice> _notices = [];
  int? _unreadCount;
  String? _checkoutKey;
  bool _checkingOut = false;
  String _profileName = '';
  String? _profileAvatar;
  String get profileName => _profileName;
  String? get profileAvatar => _profileAvatar;
  void updateProfile(String owner, String name, String? avatarId) {
    if (_userId != owner) return;
    _profileName = name;
    _profileAvatar = avatarId;
    notifyListeners();
  }

  List<Course> get cart => List.unmodifiable(_cart.values);
  List<StudentNotice> get notices => List.unmodifiable(_notices);
  int get totalCents => _cart.values.fold(
    0,
    (sum, course) => sum + (course.price! * 100).round(),
  );
  int get unreadCount =>
      _unreadCount ?? _notices.where((n) => !n.isRead).length;
  bool get checkingOut => _checkingOut;
  bool get unreadCountKnown => _unreadCount != null;

  void bindUser(String? id) {
    if (_userId == id) return;
    _userId = id;
    _generation++;
    _noticeVersion++;
    _cart.clear();
    _notices = [];
    _unreadCount = null;
    _checkoutKey = null;
    _checkingOut = false;
    _profileName = '';
    _profileAvatar = null;
    notifyListeners();
  }

  void addToCart(Course course) {
    final price = course.price;
    if (_userId == null) {
      throw StateError('Inicia sesión para usar tu carrito.');
    }
    if (course.id.isEmpty || price == null || !price.isFinite || price <= 0) {
      throw StateError('Este curso no tiene un precio de compra disponible.');
    }
    if (_checkingOut || _cart.containsKey(course.id)) return;
    if (_cart.length >= 50) {
      throw StateError('El carrito admite hasta 50 cursos.');
    }
    _cart[course.id] = course;
    _checkoutKey = null;
    notifyListeners();
  }

  void removeFromCart(String id) {
    removeFromCartIds([id]);
  }

  void removeFromCartIds(Iterable<String> ids) {
    if (_checkingOut) return;
    final before = _cart.length;
    for (final id in ids) {
      _cart.remove(id);
    }
    if (before == _cart.length) return;
    _checkoutKey = null;
    notifyListeners();
  }

  /// Una respuesta perdida permite reintentar el mismo carrito con la misma clave.
  Future<T?> checkout<T>(
    Future<T> Function(List<String> ids, String key) confirm,
  ) async {
    if (_userId == null || _checkingOut || _cart.isEmpty) return null;
    final generation = _generation;
    final ids = List<String>.unmodifiable(_cart.keys);
    final key = _checkoutKey ??= const Uuid().v4();
    _checkingOut = true;
    notifyListeners();
    try {
      final result = await confirm(ids, key);
      if (generation != _generation) return null;
      _cart.clear();
      _checkoutKey = null;
      return result;
    } finally {
      if (generation == _generation) {
        _checkingOut = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshNotices(
    Future<List<StudentNotice>> Function() load, {
    Future<int> Function()? count,
  }) async {
    if (_userId == null) return;
    final generation = _generation;
    final version = ++_noticeVersion;
    final result = await load();
    if (generation != _generation || version != _noticeVersion) return;
    _notices = result;
    _unreadCount = null;
    notifyListeners();
    if (count != null) await refreshUnreadCount(count);
  }

  Future<void> refreshUnreadCount(Future<int> Function() load) async {
    if (_userId == null) return;
    final generation = _generation;
    final version = _noticeVersion;
    final result = await load();
    if (generation != _generation || version != _noticeVersion) return;
    _unreadCount = result;
    notifyListeners();
  }

  Future<void> markRead(String id, Future<void> Function() save) async {
    if (_userId == null) throw StateError('Inicia sesión.');
    final generation = _generation;
    await save();
    if (generation != _generation) return;
    _noticeVersion++;
    if (_unreadCount != null &&
        _notices.any((n) => n.id == id && !n.isRead) &&
        _unreadCount! > 0) {
      _unreadCount = _unreadCount! - 1;
    }
    _notices = _notices.map((n) => n.id == id ? n.read() : n).toList();
    notifyListeners();
  }

  Future<void> markAllRead(Future<void> Function() save) async {
    if (_userId == null) throw StateError('Inicia sesión.');
    final generation = _generation;
    final ids = _notices.map((n) => n.id).toSet();
    await save();
    if (generation != _generation) return;
    _noticeVersion++;
    _unreadCount = 0;
    _notices = _notices.map((n) => ids.contains(n.id) ? n.read() : n).toList();
    notifyListeners();
  }
}
