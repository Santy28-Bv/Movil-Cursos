import 'dart:async';
import 'package:academix/models/course.dart';
import 'package:academix/models/student_data.dart';
import 'package:academix/services/student_session.dart';
import 'package:flutter_test/flutter_test.dart';

Course paid(String id, num? price) => Course(
  id: id,
  title: id,
  description: '',
  category: '',
  imageUrl: '',
  price: price,
);

void main() {
  test('carrito deduplica, suma centavos y elimina sin inscribir', () {
    final session = StudentSession()..bindUser('ana');
    session.addToCart(paid('a', 10.10));
    session.addToCart(paid('a', 10.10));
    session.addToCart(paid('b', 20.20));
    expect(session.cart.length, 2);
    expect(session.totalCents, 3030);
    session.removeFromCart('a');
    expect(session.totalCents, 2020);
  });

  test('carrito rechaza invitado, gratis y precio desconocido', () {
    final session = StudentSession();
    expect(() => session.addToCart(paid('a', 10)), throwsStateError);
    session.bindUser('ana');
    for (final price in [null, 0, -1, double.nan, double.infinity]) {
      expect(() => session.addToCart(paid('a', price)), throwsStateError);
    }
    expect(session.cart, isEmpty);
  });

  test('cambiar de cuenta borra carrito y descarta avisos tardíos', () async {
    final session = StudentSession()..bindUser('ana');
    session.addToCart(paid('a', 10));
    final pending = Completer<List<StudentNotice>>();
    final load = session.refreshNotices(() => pending.future);
    session.bindUser('luis');
    pending.complete([
      StudentNotice.fromJson({'id': '1', 'title': 'Privado'}),
    ]);
    await load;
    expect(session.cart, isEmpty);
    expect(session.notices, isEmpty);
  });

  test(
    'lecturas individual y global actualizan contador tras guardar',
    () async {
      final session = StudentSession()..bindUser('ana');
      await session.refreshNotices(
        () async => [
          StudentNotice.fromJson({'id': '1', 'title': 'Uno'}),
          StudentNotice.fromJson({'id': '2', 'title': 'Dos'}),
        ],
      );
      expect(session.unreadCount, 2);
      await session.markRead('1', () async {});
      expect(session.unreadCount, 1);
      await session.markAllRead(() async {});
      expect(session.unreadCount, 0);
    },
  );

  test('un error al guardar no oculta un aviso sin leer', () async {
    final session = StudentSession()..bindUser('ana');
    await session.refreshNotices(
      () async => [
        StudentNotice.fromJson({'id': '1'}),
      ],
    );
    await expectLater(
      session.markRead('1', () async => throw StateError('red')),
      throwsStateError,
    );
    expect(session.unreadCount, 1);
  });

  test('respuesta anterior no revierte una lectura confirmada', () async {
    final session = StudentSession()..bindUser('ana');
    await session.refreshNotices(
      () async => [
        StudentNotice.fromJson({'id': '1'}),
      ],
    );
    final pending = Completer<List<StudentNotice>>();
    final load = session.refreshNotices(() => pending.future);
    await session.markRead('1', () async {});
    pending.complete([
      StudentNotice.fromJson({'id': '1'}),
    ]);
    await load;
    expect(session.unreadCount, 0);
  });
}
