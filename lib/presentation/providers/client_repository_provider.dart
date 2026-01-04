import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/client_repository.dart';
import '../../data/repositories/client_repository_impl.dart';

/// Repository Provider - Dependency Injection
final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepositoryImpl();
});

