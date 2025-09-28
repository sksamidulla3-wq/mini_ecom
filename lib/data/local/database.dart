import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper{
  static Database? _database;

  // --- Table and Column Names ---
  static const String tableProducts = 'products';
  static const String columnId = 'id'; // Local DB ID (Primary Key)
  static const String columnApiId = 'apiId'; // Product ID from your API (should be unique)
  static const String columnTitle = 'title';
  static const String columnDescription = 'description';
  static const String columnPrice = 'price';
  static const String columnImageUrl = 'imageUrl';
  static const String columnCategory = 'category';
  static const String columnLastUpdated = 'lastUpdated'; // ISO8601 String or INTEGER (timestamp)

  static const String tableCart = 'cart';
  static const String columnCartId = 'cartId'; // Local cart item PK
  static const String columnCartProductId = 'productId'; // FK to products.apiId
  static const String columnQuantity = 'quantity';
  static const String columnPriceAtAdd = 'priceAtAdd';
  static const String columnToBeSynced = 'toBeSynced'; // 0 or 1

  static const String tableWishlist = 'wishlist';
  static const String columnWishlistId = 'wishlistId'; // Local wishlist item PK
  static const String columnWishlistProductId = 'productId'; // FK to products.apiId
  // No need for toBeSynced for wishlist if it's client-first then sync to server

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_ecom.db');
    return await openDatabase(
      path,
      version: 1, // Increment on schema changes
      onCreate: _onCreate,
      // onUpgrade: _onUpgrade, // Handle schema migrations here
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
     CREATE TABLE $tableProducts (
       $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
       $columnApiId INTEGER UNIQUE NOT NULL,
       $columnTitle TEXT NOT NULL,
       $columnDescription TEXT,
       $columnPrice REAL NOT NULL,
       $columnImageUrl TEXT,
       $columnCategory TEXT,
       $columnLastUpdated TEXT NOT NULL 
     )
   ''');

    await db.execute('''
     CREATE TABLE $tableCart (
       $columnCartId INTEGER PRIMARY KEY AUTOINCREMENT,
       $columnCartProductId INTEGER NOT NULL,
       $columnQuantity INTEGER NOT NULL,
       $columnPriceAtAdd REAL NOT NULL,
       $columnToBeSynced INTEGER DEFAULT 0, 
       FOREIGN KEY ($columnCartProductId) REFERENCES $tableProducts($columnApiId)
     )
   ''');

    await db.execute('''
     CREATE TABLE $tableWishlist (
       $columnWishlistId INTEGER PRIMARY KEY AUTOINCREMENT,
       $columnWishlistProductId INTEGER NOT NULL UNIQUE, 
       FOREIGN KEY ($columnWishlistProductId) REFERENCES $tableProducts($columnApiId)
     )
   ''');
    print("DatabaseHelper: Tables Created");
  }

  // --- Product CRUD ---
  Future<int> insertProduct(Map<String, dynamic> productMap) async {
    final db = await database;
    // Use insert with conflictAlgorithm.replace to handle existing products (based on apiId uniqueness)
    return await db.insert(tableProducts, productMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertProducts(List<Map<String, dynamic>> productMaps) async {
    final db = await database;
    Batch batch = db.batch();
    for (var map in productMaps) {
      // To ensure uniqueness on apiId and replace if exists, we might need to query first
      // or handle this at a higher level by checking if product exists before inserting.
      // A simpler approach for batch with replace on a unique key is to do individual inserts
      // in a transaction if performance is not an issue for moderate amounts of data.
      // For true "insert or replace" on a unique key in batch, sqflite batch doesn't directly support it.
      // A common workaround:
      batch.insert(tableProducts, map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await database;
    return await db.query(tableProducts, orderBy: '$columnApiId ASC');
  }

  Future<Map<String, dynamic>?> getProductByApiId(int apiId) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableProducts,
      where: '$columnApiId = ?',
      whereArgs: [apiId],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<int> clearAllProducts() async {
    final db = await database;
    return await db.delete(tableProducts);
  }


  // --- Cart CRUD ---
  Future<int> insertCartItem(Map<String, dynamic> cartItemMap) async {
    final db = await database;
    return await db.insert(tableCart, cartItemMap);
  }

  Future<List<Map<String, dynamic>>> getCartItems() async {
    final db = await database;
    // Example: Join with products table to get product details for cart items
    // final String query = '''
    //   SELECT c.*, p.$columnTitle, p.$columnImageUrl
    //   FROM $tableCart c
    //   INNER JOIN $tableProducts p ON c.$columnCartProductId = p.$columnApiId
    // ''';
    // return await db.rawQuery(query);
    return await db.query(tableCart); // Simpler for now, join in repository
  }

  Future<int> updateCartItemQuantity(int cartProductId, int quantity) async {
    final db = await database;
    return await db.update(
      tableCart,
      {columnQuantity: quantity},
      where: '$columnCartProductId = ?',
      whereArgs: [cartProductId],
    );
  }
  Future<Map<String, dynamic>?> getCartItemByProductId(int productId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableCart,
      where: '$columnCartProductId = ?',
      whereArgs: [productId],
      limit: 1,
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }


  Future<int> removeCartItem(int cartProductId) async {
    final db = await database;
    return await db.delete(
      tableCart,
      where: '$columnCartProductId = ?',
      whereArgs: [cartProductId],
    );
  }
  Future<void> clearCart() async {
    final db = await database;
    await db.delete(tableCart);
  }
  // Add methods for toBeSynced for cart items

  // --- Wishlist CRUD ---
  Future<int> insertWishlistItem(int productId) async {
    final db = await database;
    return await db.insert(tableWishlist, {columnWishlistProductId: productId}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, dynamic>>> getWishlistProductIds() async {
    final db = await database;
    return await db.query(tableWishlist, columns: [columnWishlistProductId]);
  }

  Future<int> removeWishlistItem(int productId) async {
    final db = await database;
    return await db.delete(
      tableWishlist,
      where: '$columnWishlistProductId = ?',
      whereArgs: [productId],
    );
  }
  Future<void> clearWishlist() async {
    final db = await database;
    await db.delete(tableWishlist);
  }
}