import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// SQLite database helper for offline-first data storage
class DatabaseHelper {
  static const String _databaseName = 'invoicely_pro.db';
  static const int _databaseVersion = 2; // Bumped version

  // Table names
  static const String tableClients = 'clients';
  static const String tableInvoices = 'invoices';
  static const String tableInvoiceItems = 'invoice_items';
  static const String tablePayments = 'payments';
  static const String tableBusinessProfile = 'business_profile';
  static const String tableSyncQueue = 'sync_queue';
  static const String tableProducts = 'products';

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create clients table
    await db.execute('''
      CREATE TABLE $tableClients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT,
        taxId TEXT,
        address TEXT,
        city TEXT,
        state TEXT,
        country TEXT,
        postalCode TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        syncStatus INTEGER DEFAULT 0
      )
    ''');

    // Create invoices table
    await db.execute('''
      CREATE TABLE $tableInvoices (
        id TEXT PRIMARY KEY,
        clientId TEXT NOT NULL,
        invoiceNumber TEXT NOT NULL UNIQUE,
        date INTEGER NOT NULL,
        dueDate INTEGER NOT NULL,
        status TEXT NOT NULL,
        subtotal REAL NOT NULL,
        taxRate REAL NOT NULL,
        taxAmount REAL NOT NULL,
        discountAmount REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'USD',
        notes TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        syncStatus INTEGER DEFAULT 0,
        FOREIGN KEY (clientId) REFERENCES $tableClients (id)
      )
    ''');

    // Create invoice_items table
    await db.execute('''
      CREATE TABLE $tableInvoiceItems (
        id TEXT PRIMARY KEY,
        invoiceId TEXT NOT NULL,
        description TEXT NOT NULL,
        quantity REAL NOT NULL,
        unitPrice REAL NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (invoiceId) REFERENCES $tableInvoices (id) ON DELETE CASCADE
      )
    ''');

    // Create payments table
    await db.execute('''
      CREATE TABLE $tablePayments (
        id TEXT PRIMARY KEY,
        invoiceId TEXT NOT NULL,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
        method TEXT NOT NULL,
        notes TEXT,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (invoiceId) REFERENCES $tableInvoices (id) ON DELETE CASCADE
      )
    ''');

    // Create business_profile table
    await db.execute('''
      CREATE TABLE $tableBusinessProfile (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        logoPath TEXT,
        taxId TEXT,
        email TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        city TEXT,
        state TEXT,
        country TEXT,
        postalCode TEXT,
        website TEXT,
        defaultCurrency TEXT NOT NULL DEFAULT 'USD',
        defaultTaxRate REAL NOT NULL DEFAULT 0,
        invoicePrefix TEXT,
        nextInvoiceNumber INTEGER NOT NULL DEFAULT 1,
        bankName TEXT,
        bankAccountNumber TEXT,
        paymentTerms TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Create sync_queue table for offline sync
    await db.execute('''
      CREATE TABLE $tableSyncQueue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tableName TEXT NOT NULL,
        recordId TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        status INTEGER DEFAULT 0
      )
    ''');

    // Create products table
    await db.execute('''
      CREATE TABLE $tableProducts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        price REAL NOT NULL,
        icon TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Create indexes for performance
    await db.execute(
      'CREATE INDEX idx_invoices_clientId ON $tableInvoices (clientId)',
    );
    await db.execute(
      'CREATE INDEX idx_invoices_status ON $tableInvoices (status)',
    );
    await db.execute(
      'CREATE INDEX idx_invoices_dueDate ON $tableInvoices (dueDate)',
    );
    await db.execute(
      'CREATE INDEX idx_invoice_items_invoiceId ON $tableInvoiceItems (invoiceId)',
    );
    await db.execute(
      'CREATE INDEX idx_payments_invoiceId ON $tablePayments (invoiceId)',
    );
    await db.execute(
      'CREATE INDEX idx_sync_queue_status ON $tableSyncQueue (status)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE $tableProducts (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          price REAL NOT NULL,
          icon TEXT NOT NULL,
          colorValue INTEGER NOT NULL,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL
        )
      ''');
    }
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Clear all tables (useful for testing)
  Future<void> clearAllTables() async {
    final db = await database;
    await db.delete(tableSyncQueue);
    await db.delete(tablePayments);
    await db.delete(tableInvoiceItems);
    await db.delete(tableInvoices);
    await db.delete(tableClients);
    await db.delete(tableBusinessProfile);
  }
}
