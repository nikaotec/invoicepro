import '../entities/client.dart';
import '../../core/errors/failures.dart';

/// Abstract repository interface for Client operations
/// This follows Clean Architecture principles - domain layer doesn't depend on data layer
abstract class ClientRepository {
  /// Get all clients
  Future<({List<Client>? data, Failure? error})> getClients();

  /// Get client by ID
  Future<({Client? data, Failure? error})> getClientById(String id);

  /// Create a new client
  Future<({String? clientId, Failure? error})> createClient(Client client);

  /// Update an existing client
  Future<({bool success, Failure? error})> updateClient(Client client);

  /// Delete a client
  Future<({bool success, Failure? error})> deleteClient(String id);

  /// Search clients by query
  Future<({List<Client>? data, Failure? error})> searchClients(String query);
}

