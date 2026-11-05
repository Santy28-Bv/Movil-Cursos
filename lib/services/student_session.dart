import 'package:flutter/foundation.dart';
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
  List<Course> get cart => List.unmodifiable(_cart.values);
  List<StudentNotice> get notices => List.unmodifiable(_notices);
  int get totalCents => _cart.values.fold(
    0,
    (sum, course) => sum + (course.price! * 100).round(),
  );
  int get unreadCount => _notices.where((n) => !n.isRead).length;

  void bindUser(String? id) {
    if (_userId == id) return;
    _userId = id;
    _generation++;
    _noticeVersion++;
    _cart.clear();
    _notices = [];
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
    _cart[course.id] = course;
    notifyListeners();
  }

  void removeFromCart(String id) {
    _cart.remove(id);
    notifyListeners();
  }

  Future<void> refreshNotices(
    Future<List<StudentNotice>> Function() load,
  ) async {
    if (_userId == null) return;
    final generation = _generation;
    final version = ++_noticeVersion;
    final result = await load();
    if (generation != _generation || version != _noticeVersion) return;
    _notices = result;
    notifyListeners();
  }

  Future<void> markRead(String id, Future<void> Function() save) async {
    if (_userId == null) throw StateError('Inicia sesión.');
    final generation = _generation;
    await save();
    if (generation != _generation) return;
    _noticeVersion++;
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
    _notices = _notices.map((n) => ids.contains(n.id) ? n.read() : n).toList();
    notifyListeners();
  }
}
