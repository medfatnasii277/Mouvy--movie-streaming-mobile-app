import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  bool _isLoading = true;
  bool _isAuthenticated = false;
  late final StreamSubscription<AuthState> _authStateSubscription;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _checkAuthState();
    _setupAuthListener();
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  Future<void> _checkAuthState() async {
    final session = Supabase.instance.client.auth.currentSession;
    _isAuthenticated = session != null;
    _isLoading = false;
    notifyListeners();
  }

  void _setupAuthListener() {
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      final session = event.session;
      final wasAuthenticated = _isAuthenticated;
      _isAuthenticated = session != null;
      
      notifyListeners();
      
      // Handle navigation
      if (!wasAuthenticated && _isAuthenticated) {
        // Just logged in
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (route) => false);
      } else if (wasAuthenticated && !_isAuthenticated) {
        // Just logged out
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
      }
    });
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}