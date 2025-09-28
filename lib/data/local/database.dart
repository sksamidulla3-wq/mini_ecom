import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _database;

  // --- Table and Column Names ---
  static const String tableProducts = 'products';
  static const String columnId = 'id'; // Local DB ID (Primary Key)
  static const String columnApiId = 'apiId'; // Product ID from your API (should be unique)
  static const String columnTitle = 'title';  static const String columnDescription = 'description';
  static const String columnPrice = 'price';
  static const String columnDiscountPercentage = 'discountPercentage';
  static const String columnImageUrl = 'imageUrl';
  static const String columnCategory = 'category';
  static const String columnLastUpdated = 'lastUpdated'; // ISO8601 String or INTEGER (timestamp)

  // --- ADDED CONSTANTS FOR EXAMPLE COLUMNS ---
  static const String columnRating = 'rating';
  static const String columnStock = 'stock';
  static const String columnBrand = 'brand';
  // static const String columnImages = 'images'; // (e.g., as JSON string) - If you plan to store multiple images


  static const String tableCart = 'cart';
  static const String columnCartId = 'cartId'; // Local cart item PK
  static const String columnCartProductId = 'productId'; // FK to products.apiId
  static const String columnQuantity = 'quantity';
  static const String columnPriceAtAdd = 'priceAtAdd';
  static const String columnToBeSynced = 'toBeSynced'; // 0 or 1

  static const String tableWishlist = 'wishlist';
  static const String columnWishlistId = 'wishlistId'; // Local wishlist item PK
  static const String columnWishlistProductId = 'productId'; // FK to products.apiId

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_ecom.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
   CREATE TABLE $tableProducts (
     $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
     $columnApiId INTEGER UNIQUE NOT NULL,
     $columnTitle TEXT NOT NULL,     $columnDescription TEXT,
     $columnPrice REAL NOT NULL,
     $columnDiscountPercentage REAL, 
     $columnImageUrl TEXT,          
     $columnCategory TEXT,          
     $columnLastUpdated TEXT NOT NULL
     , $columnBrand TEXT
     , $columnRating REAL
     , $columnStock INTEGER
   ) 
 ''');

    // ... rest of the _onCreate method for cart and wishlist tables ...
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
    print("DatabaseHelper: Tables Created (or _onCreate called for version $version)");
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("DatabaseHelper: Upgrading database from version $oldVersion to $newVersion");
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE $tableProducts ADD COLUMN $columnDiscountPercentage REAL;");
        print("DatabaseHelper: Added '$columnDiscountPercentage' to '$tableProducts' table.");

        // Example: If you were also adding brand, rating, stock in version 2:
        // await db.execute("ALTER TABLE $tableProducts ADD COLUMN $columnBrand TEXT;");
        // await db.execute("ALTER TABLE $tableProducts ADD COLUMN $columnRating REAL;");
        // await db.execute("ALTER TABLE $tableProducts ADD COLUMN $columnStock INTEGER;");
        // print("DatabaseHelper: Also added brand, rating, stock to '$tableProducts' table.");

      } catch (e) {
        print("DatabaseHelper: Error upgrading products table: $e");
      }
    }
    // if (oldVersion < 3) { /* Migrations for version 3 */ }
  }

  // --- Product CRUD ---
  // ... (rest of your CRUD methods remain unchanged) ...
  Future<int> insertProduct(Map<String, dynamic> productMap) async {
    final db = await database;
    return await db.insert(tableProducts, productMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertProducts(List<Map<String, dynamic>> productMaps) async {
    final db = await database;
    Batch batch = db.batch();
    for (var map in productMaps) {
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

  // Cart CRUD
  Future<int> insertCartItem(Map<String, dynamic> cartItemMap) async {
    final db = await database;
    return await db.insert(tableCart, cartItemMap);
  }

  Future<List<Map<String, dynamic>>> getCartItems() async {
    final db = await database;
    return await db.query(tableCart);
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

  // Wishlist CRUD
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
