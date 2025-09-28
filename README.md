# Mini E-Commerce Flutter App

A Flutter-based mobile application demonstrating core e-commerce functionalities including product browsing, category filtering, cart management, user authentication, and wishlist features. This app emphasizes a clean architecture, state management with BLoC, and offline capabilities.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
    - [State Management](#state-management)
    - [Data Layer](#data-layer)
    - [Offline Support](#offline-support)
- [Tech Stack & Dependencies](#tech-stack--dependencies)
- [Setup Instructions](#setup-instructions)
    - [Prerequisites](#prerequisites)
    - [Installation](#installation)
    - [Running the App](#running-the-app)
- [Testing](#testing)
- [CI/CD](#cicd)
- [Screenshots (Optional)](#screenshots-optional)
- [Future Enhancements (Optional)](#future-enhancements-optional)
- [Author](#author)

## Overview

This project is a mini e-commerce application built with Flutter. It aims to showcase best practices in mobile app development, including:
- User authentication (login/signup) using a dummy API.
- Displaying products fetched from an API, with support for categories.
- Caching product data for offline access.
- Implementing cart and wishlist functionalities with local persistence.
- A responsive UI that adapts to different screen sizes.
- Theme switching (light/dark mode).

The primary goal was to build a feature-rich yet maintainable application leveraging modern Flutter development patterns.

## Features

- **User Authentication:**
    - Login with dummy credentials.
    - User session persistence.
    - Basic signup flow (if implemented).
- **Product Browsing:**
    - Display featured products on the home screen.
    - View products by category.
    - Product detail screen.
    - Search functionality (UI placeholder, core logic can be discussed).
- **Offline Caching:**
    - Products are cached locally using SQLite for offline browsing.
    - Graceful handling of network unavailability.
- **Cart Management:**
    - Add/remove products to/from the cart.
    - Update product quantity in the cart.
    - Cart data persists locally (using SharedPreferences or SQLite).
- **Wishlist:**
    - Add/remove products to/from the wishlist.
    - Wishlist data persists locally.
- **UI/UX:**
    - Responsive design for various screen sizes.
    - Light and Dark theme support.
    - Intuitive navigation.
- **State Management:**
    - BLoC (Business Logic Component) pattern for managing application state.

## Architecture

The application follows a layered architecture to separate concerns and improve maintainability.

### Core Layers:

1.  **Presentation Layer (UI):**
    *   Built with Flutter widgets.
    *   Responsible for rendering UI and capturing user input.
    *   Interacts with BLoCs to display data and dispatch events.
    *   Screens: `SplashScreen`, `LoginScreen`, `HomeScreen`, `ProductDetailScreen`, `CartScreen`, `CategoriesScreen`, `ProfileScreen`, etc.

2.  **Business Logic Layer (BLoC):**
    *   Uses the `flutter_bloc` package.
    *   Contains BLoCs (`AuthBloc`, `ProductBloc`, `CartBloc`, `WishlistBloc`, `SignUpBloc`) that manage the state for different features.
    *   BLoCs receive events from the UI and interact with repositories/services to fetch or manipulate data, then emit new states to the UI.
    *   This decouples UI from data sources and business rules.

3.  **Data Layer:**
    *   **Repositories:** Act as a single source of truth for data. They abstract the origin of the data (network, local cache, etc.).
        *   `CachingProductRepository`: Manages product data, fetching from the network via `NetworkProductRepository` (Dio-based) and caching locally using `DatabaseHelper` (SQLite). It handles offline fallback.
        *   `AuthRepository` (implicitly part of `AuthBloc` logic using `ApiHelper`): Handles user authentication against the dummy API.
        *   Cart & Wishlist data is managed directly by their respective BLoCs using `SharedPreferences` for local persistence.
    *   **Data Sources:**
        *   **Remote:** `ApiHelper` (using `http` or `dio`) interacts with the `dummyjson.com` API.
        *   **Local:**
            *   `DatabaseHelper` (using `sqflite`): For caching product data.
            *   `SharedPreferences`: For storing user session, cart, wishlist, and theme preferences.
    *   **Models:** Plain Dart objects (`UserModel`, `ProductModel`, `CategoryModel`) representing the data structures.

### State Management

- **BLoC (`flutter_bloc`)**: Chosen for its robustness, testability, and clear separation of business logic from UI. It helps manage complex state changes predictably.
    - `AuthBloc`: Manages authentication state, user session.
    - `ProductBloc`: Manages product fetching (including categories and featured products), loading states, and errors.
    - `CartBloc`: Manages cart items and state.
    - `WishlistBloc`: Manages wishlist items and state.
    - `SignUpBloc`: Manages the state for the user registration process.
- **Provider (`provider` package)**: Used for dependency injection (making BLoCs and other services available down the widget tree) and for simpler state management like `ThemeProvider`.

### Data Layer Approach

- **Repository Pattern:** To abstract data sources. `CachingProductRepository` is a key example, providing a unified API for product data while handling the complexities of network fetching, caching, and offline support.
- **API Interaction:** `ApiHelper` class encapsulates HTTP requests to the dummy API, handling common tasks like setting headers and parsing responses.
- **Local Persistence:**
    - `sqflite` (via `DatabaseHelper`) for structured product data, enabling efficient querying and offline availability.
    - `shared_preferences` for simpler key-value data like user tokens, cart/wishlist (if not using SQLite for them), and theme settings due to its ease of use for such data.

### Offline Support

- **Product Caching:** `CachingProductRepository` first checks for local (SQLite) data. If unavailable, stale, or a force refresh is requested, it fetches from the network and updates the cache. If offline, it serves data directly from the cache.
- **Cart & Wishlist:** Data is stored locally using `SharedPreferences`, making it available and modifiable offline. (Note: Synchronization with a backend upon reconnection is a future enhancement not covered in the basic setup).
- **Connectivity Check:** The `connectivity_plus` package is integrated into `CachingProductRepository` to determine network status before attempting network calls.
- **UI Feedback:** The app aims to provide feedback when operating offline or when data is being served from the cache.

## Tech Stack & Dependencies

- **Flutter SDK:** (Specify your version, e.g., 3.19.x)
- **Dart:** (Specify your version)
- **State Management:**
    - `flutter_bloc`: For BLoC pattern.
    - `provider`: For dependency injection and ThemeProvider.
- **Networking:**
    - `http` (or `dio` if you used it): For making API calls.
    - `connectivity_plus`: To check network status.
- **Local Storage:**
    - `sqflite`: For SQLite database (product caching).
    - `shared_preferences`: For key-value storage.
- **Data Models & Equality:**
    - `equatable`: For simplifying value equality in models.
- **Navigation:** Flutter's built-in Navigator.
- **Linting:** (e.g., `flutter_lints` or your preferred linter)
- **API:** `dummyjson.com` for product and user data.

## Setup Instructions

### Prerequisites

- Flutter SDK: Version [Your Flutter Version, e.g., 3.19.0] or higher.
- Dart SDK: Version [Your Dart Version] or higher.
- An IDE like Android Studio or VS Code with Flutter plugins.
- An Android Emulator/iOS Simulator or a physical device.

### Installation

1.      Directory: C:\Users\samik\mini_ecom


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----         9/28/2025   6:34 PM                .dart_tool
d-----         9/28/2025   6:33 PM                android
d-----         9/28/2025   6:33 PM                ios
d-----         9/28/2025   6:33 PM                lib
d-----         9/28/2025   6:33 PM                linux
d-----         9/28/2025   6:33 PM                macos
d-----         9/28/2025   6:33 PM                test
d-----         9/28/2025   6:33 PM                web
d-----         9/28/2025   6:33 PM                windows
-a----         9/28/2025   6:34 PM           5836 .flutter-plugins-dependencies
-a----         9/28/2025   6:33 PM            748 .gitignore
-a----         9/28/2025   6:33 PM           1751 .metadata
-a----         9/28/2025   6:33 PM           1448 analysis_options.yaml
-a----         9/28/2025   6:33 PM            187 devtools_options.yaml
-a----         9/28/2025   6:33 PM          17316 pubspec.lock
-a----         9/28/2025   6:33 PM           4169 pubspec.yaml
-a----         9/28/2025   6:33 PM            568 README.md
    