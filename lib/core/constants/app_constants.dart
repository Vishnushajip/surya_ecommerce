class AppConstants {
  static const String appName = 'SUN Associates';
  static const String appTagline = 'Premium Electrical & Hardware Solutions';
  static const String appVersion = '1.0.0';

  // Company Information
  static const String companyName = 'SUN Associates';
  static const String companyAddress = 'ATHOLI, ATHANI, PIN 673315, KOZHIKODE';
  static const String companyPhone = '+91 9846 203 813';
  static const String companyEmail = 'suryadigitalconnect@gmail.com';

  // WhatsApp Configuration
  static const String whatsappNumber = '919846203813';
  static const String whatsappMessage =
      'Hello! I would like to inquire about your products.';

  // Firebase Configuration
  static const String firebaseApiKey =
      'AIzaSyAnP4fvtQTDnjo0RsKOr54yiOJv0VFsPiQ';
  static const String firebaseAuthDomain = 'sunassociates-e01eb.firebaseapp.com';
  static const String firebaseProjectId = 'sunassociates-e01eb';
  static const String firebaseStorageBucket = 'sunassociates-e01eb.firebasestorage.app';
  static const String firebaseMessagingSenderId = '600497347289';
  static const String firebaseAppId =
      '1:600497347289:web:9ac8d7dfbd0d0c6d867cc8';
  static const String firebaseMeasurementId = 'G-4TB8NV236Y';

  // Collections
  static const String productsCollection = 'products';
  static const String feedbackCollection = 'product_feedback';
  static const String ordersCollection = 'orders';

  // Pagination
  static const int defaultPageSize = 10;
  static const int maxPageSize = 50;

  // Image Settings
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  // Cache Settings
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB

  // Review System
  static const Duration reviewTriggerDelay = Duration(hours: 24);
  static const int maxReviewLength = 500;
  static const int minReviewLength = 10;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Responsive Breakpoints
  static const double mobileBreakpoint = 700;
  static const double tabletBreakpoint = 1200;
  static const double desktopBreakpoint = 1200;

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // Border Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;

  // Product Categories
  static const List<String> productCategories = [
    'Electrical',
    'Hardware',
    'Lighting',
    'Tools',
    'Wires & Cables',
    'Switches & Sockets',
    'Fans',
    'Pumps',
    'Motors',
    'Safety Equipment',
  ];

  // Price Range for Filters
  static const double minPriceFilter = 0;
  static const double maxPriceFilter = 100000;

  // Search Settings
  static const int searchDebounceMs = 300;
  static const int maxSearchResults = 20;

  // Cart Settings
  static const int maxCartItemQuantity = 99;
  static const Duration cartPersistenceDuration = Duration(days: 30);

  // URLs
  static const String privacyPolicyUrl = 'https://sunassociates.com/privacy';
  static const String termsOfServiceUrl = 'https://sunassociates.com/terms';
  static const String refundPolicyUrl = 'https://sunassociates.com/refund';

  // Social Media
  static const String facebookUrl = 'https://facebook.com/sunassociates';
  static const String instagramUrl = 'https://instagram.com/sunassociates';
  static const String linkedinUrl =
      'https://linkedin.com/company/sunassociates';
  static const String twitterUrl = 'https://twitter.com/sunassociates';

  // SEO
  static const String defaultTitle =
      'SUN ASSOCIATES - Premium Electrical & Hardware Solutions';
  static const String defaultDescription =
      'Shop premium electrical and hardware products at SUN ASSOCIATES. Quality switches, fans, lighting, tools, and more with trusted service since 1995.';
  static const String defaultKeywords =
      'electrical, hardware, switches, fans, lighting, tools, mumbai, india';

  // Error Messages
  static const String genericErrorMessage =
      'Something went wrong. Please try again.';
  static const String networkErrorMessage =
      'Please check your internet connection.';
  static const String noDataMessage = 'No data available.';
  static const String loadingMessage = 'Loading...';

  // Success Messages
  static const String successMessage = 'Operation completed successfully!';
  static const String addedToCartMessage = 'Product added to cart!';
  static const String removedFromCartMessage = 'Product removed from cart!';
  static const String reviewSubmittedMessage = 'Thank you for your review!';

  // Validation Messages
  static const String requiredFieldMessage = 'This field is required.';
  static const String invalidEmailMessage =
      'Please enter a valid email address.';
  static const String invalidPhoneMessage =
      'Please enter a valid phone number.';
  static const String minLengthMessage = 'Minimum length is';
  static const String maxLengthMessage = 'Maximum length is';

  // Admin Settings
  static const bool enableDummyDataButton = true; // Set to false in production
  static const bool enableDebugMode = false; // Set to false in production
  static const bool enableAnalytics = true;

  // Feature Flags
  static const bool enableReviews = true;
  static const bool enableWishlist = false; // Future feature
  static const bool enableCompare = false; // Future feature
  static const bool enableGuestCheckout = true;

  // Performance Settings
  static const int imageQuality = 85;
  static const bool enableImageCompression = true;
  static const bool enableLazyLoading = true;
  static const bool enableVirtualScrolling = false; // Future feature
}

class AppStrings {
  // Navigation
  static const String home = 'Home';
  static const String about = 'About';
  static const String products = 'Products';
  static const String contact = 'Contact';
  static const String cart = 'Cart';
  static const String search = 'Search';

  // Actions
  static const String addToCart = 'Add to Cart';
  static const String buyNow = 'Buy Now';
  static const String viewDetails = 'View Details';
  static const String exploreProducts = 'Explore Products';
  static const String whatsappEnquiry = 'WhatsApp Enquiry';
  static const String payNow = 'Pay Now';
  static const String checkout = 'Checkout';
  static const String continueShopping = 'Continue Shopping';

  // Product Details
  static const String description = 'Description';
  static const String category = 'Category';
  static const String price = 'Price';
  static const String rating = 'Rating';
  static const String inStock = 'In Stock';
  static const String outOfStock = 'Out of Stock';
  static const String relatedProducts = 'Related Products';
  static const String productDetails = 'Product Details';
  static const String specifications = 'Specifications';

  // Cart
  static const String shoppingCart = 'Shopping Cart';
  static const String item = 'Item';
  static const String items = 'Items';
  static const String quantity = 'Quantity';
  static const String total = 'Total';
  static const String subtotal = 'Subtotal';
  static const String grandTotal = 'Grand Total';
  static const String removeFromCart = 'Remove from Cart';
  static const String cartIsEmpty = 'Your cart is empty';

  // Checkout
  static const String billingDetails = 'Billing Details';
  static const String orderSummary = 'Order Summary';
  static const String placeOrder = 'Place Order';
  static const String orderSuccess = 'Order Placed Successfully!';

  // Contact
  static const String getInTouch = 'Get in Touch';
  static const String contactUs = 'Contact Us';
  static const String sendUsMessage = 'Send us a message';
  static const String yourName = 'Your Name';
  static const String yourEmail = 'Your Email';
  static const String yourMessage = 'Your Message';
  static const String sendMessage = 'Send Message';

  // About
  static const String aboutUs = 'About Us';
  static const String ourStory = 'Our Story';
  static const String yearsOfTrust = 'Years of Trust';
  static const String whyChooseUs = 'Why Choose Us';

  // Reviews
  static const String customerReviews = 'Customer Reviews';
  static const String writeReview = 'Write a Review';
  static const String yourReview = 'Your Review';
  static const String submitReview = 'Submit Review';
  static const String noReviews = 'No reviews yet';

  // Filters
  static const String filter = 'Filter';
  static const String filters = 'Filters';
  static const String sortBy = 'Sort By';
  static const String categoryFilter = 'Category';
  static const String priceFilter = 'Price';
  static const String ratingFilter = 'Rating';
  static const String newest = 'Newest';
  static const String priceLowToHigh = 'Price: Low to High';
  static const String priceHighToLow = 'Price: High to Low';
  static const String ratingHighToLow = 'Rating: High to Low';

  // Common
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String save = 'Save';
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String close = 'Close';
  static const String ok = 'OK';
  static const String yes = 'Yes';
  static const String no = 'No';

  // Admin
  static const String seedDemoProducts = 'Seed Demo Products';
  static const String adminPanel = 'Admin Panel';
  static const String dashboard = 'Dashboard';
}
