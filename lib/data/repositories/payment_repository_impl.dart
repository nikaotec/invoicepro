import 'package:sqflite/sqflite.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/local/database_helper.dart';
import '../models/payment_model.dart';

/// Implementation of PaymentRepository using SQLite
class PaymentRepositoryImpl implements PaymentRepository {
  final DatabaseHelper _dbHelper;

  PaymentRepositoryImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<({List<Payment>? data, Failure? error})> getPaymentsByInvoiceId(
    String invoiceId,
  ) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tablePayments,
        where: 'invoiceId = ?',
        whereArgs: [invoiceId],
        orderBy: 'date DESC, createdAt DESC',
      );

      final payments = maps.map((map) => PaymentModel.fromMap(map)).toList();
      return (data: payments, error: null);
    } catch (e) {
      return (
        data: null,
        error: DatabaseFailure('Failed to get payments: ${e.toString()}')
      );
    }
  }

  @override
  Future<({Payment? data, Failure? error})> getPaymentById(String id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tablePayments,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        return (
          data: null,
          error: NotFoundFailure('Payment with id $id not found')
        );
      }

      final payment = PaymentModel.fromMap(maps.first);
      return (data: payment, error: null);
    } catch (e) {
      return (
        data: null,
        error: DatabaseFailure('Failed to get payment: ${e.toString()}')
      );
    }
  }

  @override
  Future<({String? paymentId, Failure? error})> createPayment(
    Payment payment,
  ) async {
    try {
      final db = await _dbHelper.database;
      final paymentMap = PaymentModel.toMap(payment);

      await db.insert(
        DatabaseHelper.tablePayments,
        paymentMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return (paymentId: payment.id, error: null);
    } catch (e) {
      return (
        paymentId: null,
        error: DatabaseFailure('Failed to create payment: ${e.toString()}')
      );
    }
  }

  @override
  Future<({bool success, Failure? error})> updatePayment(Payment payment) async {
    try {
      final db = await _dbHelper.database;
      final paymentMap = PaymentModel.toMap(payment);

      final count = await db.update(
        DatabaseHelper.tablePayments,
        paymentMap,
        where: 'id = ?',
        whereArgs: [payment.id],
      );

      if (count == 0) {
        return (
          success: false,
          error: NotFoundFailure('Payment with id ${payment.id} not found')
        );
      }

      return (success: true, error: null);
    } catch (e) {
      return (
        success: false,
        error: DatabaseFailure('Failed to update payment: ${e.toString()}')
      );
    }
  }

  @override
  Future<({bool success, Failure? error})> deletePayment(String id) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.delete(
        DatabaseHelper.tablePayments,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        return (
          success: false,
          error: NotFoundFailure('Payment with id $id not found')
        );
      }

      return (success: true, error: null);
    } catch (e) {
      return (
        success: false,
        error: DatabaseFailure('Failed to delete payment: ${e.toString()}')
      );
    }
  }

  @override
  Future<({double? totalPaid, Failure? error})> getTotalPaidByInvoiceId(
    String invoiceId,
  ) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tablePayments,
        columns: ['amount'],
        where: 'invoiceId = ?',
        whereArgs: [invoiceId],
      );

      double totalPaid = 0.0;
      for (final map in maps) {
        totalPaid += (map['amount'] as num).toDouble();
      }

      return (totalPaid: totalPaid, error: null);
    } catch (e) {
      return (
        totalPaid: null,
        error: DatabaseFailure('Failed to get total paid: ${e.toString()}')
      );
    }
  }
}


