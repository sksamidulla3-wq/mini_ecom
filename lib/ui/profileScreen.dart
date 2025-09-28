import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth%20bloc/auth_bloc.dart';
import '../../data/models/user_model.dart';
import 'onboarding/login.dart';
import './wishlist_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Logout'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
                print("ProfileScreen: Dispatching LogoutRequested to AuthBloc.");
                context.read<AuthBloc>().add(LogoutRequested());
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        elevation: 1,
        centerTitle: true,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          print("ProfileScreen AuthBlocListener received state: ${state.runtimeType}");
          // **CORRECTED LISTENER CONDITION**
          if (state is AuthInitial && state.isLoggedOut) {
            print("ProfileScreen AuthBlocListener: Navigating to LoginScreen due to logout.");
            // Ensure this context is still valid for navigation.
            // Using rootNavigator: true can be helpful if ProfileScreen is deeply nested.
            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
            );
          }
        },
        builder: (context, authState) {
          print("ProfileScreen AuthBlocBuilder building for state: ${authState.runtimeType}");
          if (authState is AuthSuccess) {
            final UserModel user = authState.user;
            return _buildUserProfile(context, user, textTheme, colorScheme);
          } else if (authState is AuthLoading && authState.isRestoringSession) {
            // This might be shown briefly if navigating to ProfileScreen while session is still being checked
            return const Center(child: CircularProgressIndicator());
          } else if (authState is AuthLoading && authState.isLoggingOut) {
            // Show a loading indicator specifically for the logout process
            return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Logging out..."),
                  ],
                )
            );
          }
          // If the state is AuthInitial (and not specifically isLoggedOut, which the listener handles by navigating away)
          // or AuthFailure, or any other non-AuthSuccess/non-AuthLoading state,
          // the listener should have already navigated away if it was due to a successful logout.
          // If we reach here and the user is not authenticated (e.g., app started, user never logged in, and directly navigated to Profile somehow),
          // it's an inconsistent state for ProfileScreen.
          // The listener *should* handle navigation to LoginScreen for explicit logouts.
          // For other cases (e.g., AuthFailure, or AuthInitial without isLoggedOut flag),
          // this screen shouldn't typically be reachable or would show an error/redirect.
          // Returning an empty container or a simple loading indicator is a fallback
          // as the navigation should take precedence.
          print("ProfileScreen: Fallback in builder. State: $authState. Navigation should have occurred if logout.");
          return const Center(child: CircularProgressIndicator()); // Fallback while navigation occurs
        },
      ),
    );
  }

  // _buildUserProfile remains the same
  Widget _buildUserProfile(
      BuildContext context,
      UserModel user,
      TextTheme textTheme,
      ColorScheme colorScheme,
      ) {
    // ... (your existing _buildUserProfile implementation)
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(user.image),
                backgroundColor: colorScheme.surfaceVariant,
                onBackgroundImageError: (exception, stackTrace) {
                  print("Error loading profile image: $exception");
                },
                child: user.image.isEmpty
                    ? Icon(Icons.person, size: 60, color: colorScheme.onSurfaceVariant)
                    : null,
              ),
              Material(
                color: colorScheme.primary,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Edit Profile Picture (not implemented)")),
                    );
                  },
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Icon(Icons.edit, size: 18, color: colorScheme.onPrimary),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "${user.firstName} ${user.lastName}",
            style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            user.email,
            style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          if (user.username.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              "@${user.username}",
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.secondary),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 28),
          _buildProfileOptionTile(context, icon: Icons.edit_outlined, title: "Edit Profile", onTap: () { /* ... */ }),
          _buildProfileOptionTile(context, icon: Icons.list_alt_outlined, title: "My Orders", onTap: () { /* ... */ }),
          _buildProfileOptionTile(context, icon: Icons.favorite_border_rounded, title: "My Wishlist", onTap: () => Navigator.push(context,MaterialPageRoute(builder: (context) => const WishlistScreen()))),
          _buildProfileOptionTile(context, icon: Icons.location_on_outlined, title: "Shipping Addresses", onTap: () { /* ... */ }),
          _buildProfileOptionTile(context, icon: Icons.payment_outlined, title: "Payment Methods", onTap: () { /* ... */ }),
          _buildProfileOptionTile(context, icon: Icons.settings_outlined, title: "Settings", onTap: () { /* ... */ }),
          const Divider(height: 28, thickness: 1),
          _buildProfileOptionTile(
            context,
            icon: Icons.logout_outlined,
            title: "Logout",
            textColor: colorScheme.error,
            iconColor: colorScheme.error,
            onTap: () => _showLogoutDialog(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // _buildLoggedOutView is no longer directly used by the builder if navigation is prompt
  // Widget _buildLoggedOutView(...) { ... } // You can remove this or keep it as a dead code fallback

  // _buildProfileOptionTile remains the same
  Widget _buildProfileOptionTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        Color? textColor,
        Color? iconColor,
      }) {
    // ... (your existing _buildProfileOptionTile implementation)
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: iconColor ?? colorScheme.primary, size: 26),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
