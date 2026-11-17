import 'package:flutter_test/flutter_test.dart';
import 'package:academix/config/learning_schema.dart';

void main() {
  test('detecta el código de PostgREST cuando una tabla no existe', () {
    expect(LearningSchema.isMissingTableCode('PGRST205'), isTrue);
    expect(LearningSchema.isMissingTableCode('42P01'), isTrue);
  });

  test('no confunde errores de autenticación o permisos con tabla ausente', () {
    expect(LearningSchema.isMissingTableCode('42501'), isFalse);
    expect(LearningSchema.isMissingTableCode('PGRST301'), isFalse);
    expect(LearningSchema.isMissingTableCode(null), isFalse);
  });
}
