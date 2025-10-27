import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Define PriceUtils class
class PriceUtils {
  static String formatPrice(double price, {String currency = '\$'}) {
    return '$currency\${price.toStringAsFixed(2)}';
  }
  
  // Extract numeric value from price string with any currency symbol
  static double parsePrice(String priceString) {
    if (priceString.isEmpty) return 0.0;
    // Remove all currency symbols and non-numeric characters except decimal point
    String numericString = priceString.replaceAll(RegExp(r'[^\\d.]'), '');
    return double.tryParse(numericString) ?? 0.0;
  }
  
  // Detect currency symbol from price string
  static String detectCurrency(String priceString) {
    if (priceString.contains('₹')) return '₹';
    if (priceString.contains('\$')) return '\$';
    if (priceString.contains('€')) return '€';
    if (priceString.contains('£')) return '£';
    if (priceString.contains('¥')) return '¥';
    if (priceString.contains('₩')) return '₩';
    if (priceString.contains('₽')) return '₽';
    if (priceString.contains('₦')) return '₦';
    if (priceString.contains('₨')) return '₨';
    return '\$'; // Default to dollar
  }
  
  static double calculateDiscountPrice(double originalPrice, double discountPercentage) {
    return originalPrice * (1 - discountPercentage / 100);
  }
  
  static double calculateTotal(List<double> prices) {
    return prices.fold(0.0, (sum, price) => sum + price);
  }
  
  static double calculateTax(double subtotal, double taxRate) {
    return subtotal * (taxRate / 100);
  }
  
  static double applyShipping(double total, double shippingFee, {double freeShippingThreshold = 100.0}) {
    return total >= freeShippingThreshold ? total : total + shippingFee;
  }
}

// Cart item model
class CartItem {
  final String id;
  final String name;
  final double price;
  final double discountPrice;
  int quantity;
  final String? image;
  
  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.discountPrice = 0.0,
    this.quantity = 1,
    this.image,
  });
  
  double get effectivePrice => discountPrice > 0 ? discountPrice : price;
  double get totalPrice => effectivePrice * quantity;
}

// Cart manager
class CartManager extends ChangeNotifier {
  final List<CartItem> _items = [];
  
  List<CartItem> get items => List.unmodifiable(_items);
  
  void addItem(CartItem item) {
    final existingIndex = _items.indexWhere((i) => i.id == item.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }
  
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
  
  void updateQuantity(String id, int quantity) {
    final item = _items.firstWhere((i) => i.id == id);
    item.quantity = quantity;
    notifyListeners();
  }
  
  void clear() {
    _items.clear();
    notifyListeners();
  }
  
  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }
  
  double get totalWithTax {
    final tax = PriceUtils.calculateTax(subtotal, 8.0); // 8% tax
    return subtotal + tax;
  }
  
  double get finalTotal {
    return PriceUtils.applyShipping(totalWithTax, 5.99); // $5.99 shipping
  }
}

// Wishlist item model
class WishlistItem {
  final String id;
  final String name;
  final double price;
  final double discountPrice;
  final String? image;
  
  WishlistItem({
    required this.id,
    required this.name,
    required this.price,
    this.discountPrice = 0.0,
    this.image,
  });
  
  double get effectivePrice => discountPrice > 0 ? discountPrice : price;
}

// Wishlist manager
class WishlistManager extends ChangeNotifier {
  final List<WishlistItem> _items = [];
  
  List<WishlistItem> get items => List.unmodifiable(_items);
  
  void addItem(WishlistItem item) {
    if (!_items.any((i) => i.id == item.id)) {
      _items.add(item);
      notifyListeners();
    }
  }
  
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
  
  void clear() {
    _items.clear();
    notifyListeners();
  }
  
  bool isInWishlist(String id) {
    return _items.any((item) => item.id == id);
  }
}

final List<Map<String, dynamic>> productCards = [
  {
    'productName': 'green coffee',
    'imageAsset': 'data:image/png;base64,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',
    'price': '\$299',
    'discountPrice': '\$199',
  },
  {
    'productName': 'blue coffee',
    'imageAsset': 'data:image/png;base64,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',
    'price': '220',
    'discountPrice': '600',
  }
];


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Generated E-commerce App',
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: Colors.blue,
      appBarTheme: const AppBarTheme(
        elevation: 4,
        shadowColor: Colors.black38,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      cardTheme: const CardThemeData(
        elevation: 3,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        filled: true,
        fillColor: Colors.grey,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    ),
    home: const HomePage(),
    debugShowCheckedModeBanner: false,
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PageController _pageController;
  int _currentPageIndex = 0;
  final CartManager _cartManager = CartManager();
  final WishlistManager _wishlistManager = WishlistManager();
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _filteredProducts = List.from(productCards);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) => setState(() => _currentPageIndex = index);

  void _onItemTapped(int index) {
    setState(() => _currentPageIndex = index);
    _pageController.jumpToPage(index);
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProducts = List.from(productCards);
      } else {
        _filteredProducts = productCards.where((product) {
          final productName = (product['productName'] ?? '').toString().toLowerCase();
          final price = (product['price'] ?? '').toString().toLowerCase();
          final discountPrice = (product['discountPrice'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return productName.contains(searchLower) || price.contains(searchLower) || discountPrice.contains(searchLower);
        }).toList();
      }
    });
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'home':
        return Icons.home;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'favorite':
        return Icons.favorite;
      case 'person':
        return Icons.person;
      default:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _currentPageIndex,
      children: [
        _buildHomePage(),
        _buildCartPage(),
        _buildWishlistPage(),
        _buildProfilePage(),
      ],
    ),
    bottomNavigationBar: _buildBottomNavigationBar(),
  );

  Widget _buildHomePage() {
    return Column(
      children: [
                  Container(
                    color: Color(0xff2196f3),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.store, size: 32, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'karupatti coffee',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Stack(
                          children: [
                            const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                            if (_cartManager.items.isNotEmpty)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${_cartManager.items.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Stack(
                          children: [
                            const Icon(Icons.favorite, color: Colors.white, size: 20),
                            if (_wishlistManager.items.isNotEmpty)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${_wishlistManager.items.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (searchQuery) {
                            // Search functionality for filtering products
                            setState(() {
                              // This would filter the product grid based on search query
                              // Searching by product name (case-insensitive) or price
                            });
                          },
                          decoration: InputDecoration(
                            hintText: ' green coffee, blue coffee',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: const Icon(Icons.filter_list),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Search by product name or price (e.g., "Product Name" or "\$299")',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                  Container(
                    height: 160,
                    child: Stack(
                      children: [
                        Container(color: Color(0xFFBDBDBD)),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'karupatti coffee',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4.0,
                                      color: Colors.black,
                                      offset: Offset(1.0, 1.0),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text('by now', style: const TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'coffee',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 120,
                          child: Stack(
                            children: [
                              ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: 2,
                                itemBuilder: (context, index) => Container(
                                  width: 80,
                                  margin: const EdgeInsets.only(right: 12, left: 6, top: 6, bottom: 6),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Color(0xf8f5f5),
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child:                                         smallCards[index]['imageAsset'] != null
                                            ? Image.network(
                                                smallCards[index]['imageAsset'],
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                              )
                                            : const Icon(Icons.image, size: 30, color: Colors.grey)
                                        ,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        smallCards[index]['categoryName'] ?? 'Category',
                                        style: const TextStyle(fontSize: 10),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (true true)
                                        Column(
                                          children: [                                            Text(
                                              'pink coffee: 25',
                                              style: const TextStyle(fontSize: 8),
                                            ),
                                          ,                                             Text(
                                              'price: 35',
                                              style: const TextStyle(fontSize: 8),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 24,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.white.withOpacity(0.8),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: const Icon(Icons.chevron_left, color: Colors.blue, size: 16),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 24,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerRight,
                                      end: Alignment.centerLeft,
                                      colors: [
                                        Colors.white.withOpacity(0.8),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: const Icon(Icons.chevron_right, color: Colors.blue, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 200,
                            autoPlay: true,
                            autoPlayInterval: Duration(seconds: 3),
                            autoPlayAnimationDuration: const Duration(milliseconds: 800),
                            autoPlayCurve: Curves.fastOutSlowIn,
                            enlargeCenterPage: true,
                            scrollDirection: Axis.horizontal,
                            enableInfiniteScroll: true,
                            viewportFraction: 0.8,
                            enlargeFactor: 0.3,
                          ),
                          items: [
                            Builder(
                              builder: (BuildContext context) => Container(
                                width: 300,
                                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Icon(Icons.image, size: 40, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                                                const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 6.0, height: 6.0, margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.4))),
                          ],
                        ),
                        
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Color(0xFFFFFFFF),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                                                Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Selected Category: Pack',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: 2,
                          itemBuilder: (context, index) {
                            final product = productCards[index];
                            final productId = 'product_$index';
                            final isInWishlist = _wishlistManager.isInWishlist(productId);
                            return Card(
                              elevation: 3,
                              color: Color(0xFFFFFFFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                          ),
                                          child:                                           product['imageAsset'] != null
                                              ? (product['imageAsset'] != null && product['imageAsset'].isNotEmpty
                                              ? (product['imageAsset'].startsWith('data:image/')
                                                  ? Image.memory(
                                                      base64Decode(product['imageAsset'].split(',')[1]),
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => Container(
                                                        color: Colors.grey[300],
                                                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                                      ),
                                                    )
                                                  : Image.network(
                                                      product['imageAsset'],
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => Container(
                                                        color: Colors.grey[300],
                                                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                                      ),
                                                    ))
                                              : Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                                ))
                                              : Container(
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.image, size: 40),
                                          )
                                          ,
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: IconButton(
                                            onPressed: () {
                                              if (isInWishlist) {
                                                _wishlistManager.removeItem(productId);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Removed from wishlist')),
                                                );
                                              } else {
                                                final wishlistItem = WishlistItem(
                                                  id: productId,
                                                  name: product['productName'] ?? 'Product',
                                                  price: double.tryParse(product['price']?.replaceAll('\$','') ?? '0') ?? 0.0,
                                                  discountPrice: product['discountPrice'] != null && product['discountPrice'].isNotEmpty
                                                      ? double.tryParse(product['discountPrice'].replaceAll('\$','') ?? '0') ?? 0.0
                                                      : 0.0,
                                                  image: product['imageAsset'],
                                                );
                                                _wishlistManager.addItem(wishlistItem);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Added to wishlist')),
                                                );
                                              }
                                            },
                                            icon: Icon(
                                              isInWishlist ? Icons.favorite : Icons.favorite_border,
                                              color: isInWishlist ? Colors.red : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['productName'] ?? 'Product Name',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                PriceUtils.formatPrice(
                                                                                                    product['discountPrice'] != null && product['discountPrice'].isNotEmpty
                                                      ? PriceUtils.parsePrice(product['discountPrice'])
                                                      : PriceUtils.parsePrice(product['price'] ?? '0')
                                                  ,
                                                  currency:                                                   product['discountPrice'] != null && product['discountPrice'].isNotEmpty
                                                      ? PriceUtils.detectCurrency(product['discountPrice'])
                                                      : PriceUtils.detectCurrency(product['price'] ?? '\$0')
                                                  
                                                ),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: product['discountPrice'] != null ? Colors.blue : Colors.black,
                                                ),
                                              ),
                                                                                            if (product['discountPrice'] != null && product['price'] != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 6.0),
                                                  child: Text(
                                                    PriceUtils.formatPrice(PriceUtils.parsePrice(product['price'] ?? '0'), currency: PriceUtils.detectCurrency(product['price'] ?? '\$0')),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      decoration: TextDecoration.lineThrough,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ),
                                              
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              Icon(Icons.star_border, color: Colors.amber, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                product['rating'] ?? '4.0',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                final cartItem = CartItem(
                                                  id: productId,
                                                  name: product['productName'] ?? 'Product',
                                                  price:                                                   product['discountPrice'] != null && product['discountPrice'].isNotEmpty
                                                      ? double.tryParse(product['discountPrice'].replaceAll('\$', '')) ?? 0.0
                                                      : double.tryParse(product['price']?.replaceAll('\$', '') ?? '0') ?? 0.0
                                                  ,
                                                  discountPrice:                                                   product['discountPrice'] != null && product['discountPrice'].isNotEmpty
                                                      ? double.tryParse(product['discountPrice'].replaceAll('\$', '')) ?? 0.0
                                                      : 0.0
                                                  ,
                                                  image: product['imageAsset'],
                                                );
                                                _cartManager.addItem(cartItem);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Added to cart')),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  
                                                ),
                                              ),
                                              child: const Text(
                                                'Add to Cart',
                                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'list',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'good product',
                          style: const TextStyle(fontSize: 12, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.store, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'My Store',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(child: Text('123 Main St', style: TextStyle(fontSize: 12))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.email, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(child: Text('support@example.com', style: TextStyle(fontSize: 12))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.phone, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(child: Text('(123) 456-7890', style: TextStyle(fontSize: 12))),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'Â© 2023 My Store. All rights reserved.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Share this product',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade700,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.facebook, color: Colors.white, size: 18),
                                    onPressed: () {},
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text('Facebook', style: TextStyle(fontSize: 10)),
                              ],
                            ),
                            Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.alternate_email, color: Colors.white, size: 18),
                                    onPressed: () {},
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text('Twitter', style: TextStyle(fontSize: 10)),
                              ],
                            ),
                            Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade600,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.message, color: Colors.white, size: 18),
                                    onPressed: () {},
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text('WhatsApp', style: TextStyle(fontSize: 10)),
                              ],
                            ),
                            Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade600,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.link, color: Colors.white, size: 18),
                                    onPressed: () {},
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text('Copy Link', style: TextStyle(fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        automaticallyImplyLeading: false,
      ),
      body: _cartManager.items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Your cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _cartManager.items.length,
                    itemBuilder: (context, index) {
                      final item = _cartManager.items[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: item.image != null && item.image!.isNotEmpty
                                    ? (item.image!.startsWith('data:image/')
                                    ? Image.memory(
                                  base64Decode(item.image!.split(',')[1]),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                                )
                                    : Image.network(
                                  item.image!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                                ))
                                    : const Icon(Icons.image),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(PriceUtils.formatPrice(item.effectivePrice)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (item.quantity > 1) {
                                        _cartManager.updateQuantity(item.id, item.quantity - 1);
                                      } else {
                                        _cartManager.removeItem(item.id);
                                      }
                                    },
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Text('${item.quantity}', style: const TextStyle(fontSize: 16)),
                                  IconButton(
                                    onPressed: () {
                                      _cartManager.updateQuantity(item.id, item.quantity + 1);
                                    },
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: const Border(top: BorderSide(color: Colors.grey)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                          Text(PriceUtils.formatPrice(_cartManager.subtotal), style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax (8%):', style: TextStyle(fontSize: 16)),
                          Text(PriceUtils.formatPrice(PriceUtils.calculateTax(_cartManager.subtotal, 8.0)), style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Shipping:', style: TextStyle(fontSize: 16)),
                          Text(PriceUtils.formatPrice(5.99), style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(PriceUtils.formatPrice(_cartManager.finalTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          child: const Text('Checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWishlistPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        automaticallyImplyLeading: false,
      ),
      body: _wishlistManager.items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Your wishlist is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _wishlistManager.items.length,
              itemBuilder: (context, index) {
                final item = _wishlistManager.items[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: item.image != null && item.image!.isNotEmpty
                          ? (item.image!.startsWith('data:image/')
                          ? Image.memory(
                        base64Decode(item.image!.split(',')[1]),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                      )
                          : Image.network(
                        item.image!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                      ))
                          : const Icon(Icons.image),
                    ),
                    title: Text(item.name),
                    subtitle: Text(PriceUtils.formatPrice(item.effectivePrice)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            final cartItem = CartItem(
                              id: item.id,
                              name: item.name,
                              price: item.price,
                              discountPrice: item.discountPrice,
                              image: item.image,
                            );
                            _cartManager.addItem(cartItem);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to cart')),
                            );
                          },
                          icon: const Icon(Icons.shopping_cart),
                        ),
                        IconButton(
                          onPressed: () {
                            _wishlistManager.removeItem(item.id);
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProfilePage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [            const Text(
              'User Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'Enter your name',
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Phone',
                hintText: 'Enter your phone number',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile saved')),
                );
              },
              child: const Text('Save Profile'),
            ),          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentPageIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Wishlist',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentPageIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Wishlist',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
