import 'package:flutter_test/flutter_test.dart';
import '../lib/controllers/course_feed_controller.dart';
import '../lib/models/course.dart';
import '../lib/repositories/course_repository.dart';

class FakeCourses implements CourseRepository {
  FakeCourses(this.items);
  final List<Course> items;

  @override
  Future<CoursePage> fetchPublished({required int offset,
      required int limit, String search = ''}) async {
    final filtered = items.where((course) =>
        course.title.toLowerCase().contains(search.toLowerCase())).toList();
    final window = filtered.skip(offset).take(limit + 1).toList();
    return CoursePage(
      items: window.take(limit).toList(),
      hasMore: window.length > limit,
    );
  }
}

void main() {
  final courses = List.generate(13, (index) => Course(
      id: '$index', title: 'Curso $index', description: '',
      category: '', imageUrl: '', price: 10));

  test('pagina en bloques y se detiene al terminar', () async {
    final feed = CourseFeedController(repository: FakeCourses(courses));
    await feed.loadMore();
    expect(feed.courses.length, 6);
    expect(feed.hasMore, isTrue);
    await feed.loadMore();
    expect(feed.courses.length, 12);
    expect(feed.hasMore, isTrue);
    await feed.loadMore();
    expect(feed.courses.length, 13);
    expect(feed.hasMore, isFalse);
    feed.dispose();
  });

  test('una búsqueda reinicia resultados anteriores', () async {
    final feed = CourseFeedController(repository: FakeCourses(courses));
    await feed.loadMore();
    await feed.refresh(search: 'Curso 12');
    expect(feed.courses.length, 1);
    expect(feed.courses.single.title, 'Curso 12');
    feed.dispose();
  });
}
