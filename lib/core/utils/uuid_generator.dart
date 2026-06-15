import 'package:uuid/uuid.dart';

/// Centralized UUID generation for offline-first entity identifiers.
abstract interface class UuidGenerator {
  String generate();
}

final class UuidGeneratorImpl implements UuidGenerator {
  UuidGeneratorImpl({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  @override
  String generate() => _uuid.v4();
}
