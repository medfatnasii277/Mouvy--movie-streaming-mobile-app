import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/floating_dots.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? profileIcon;
  double _opacity = 1.0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('profile_icon')
          .eq('id', user.id)
          .single();
      setState(() {
        profileIcon = response['profile_icon'] as String?;
      });
    }
  }

  void _onProfileTap() {
    if (_isAnimating) return;
    setState(() {
      _isAnimating = true;
      _opacity = 0.0;
    });
    Future.delayed(const Duration(milliseconds: 300), () async {
      await Navigator.pushNamed(context, '/movies');
      setState(() {
        _opacity = 1.0;
        _isAnimating = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mouvy'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Floating dots animation background
          const FloatingDots(
            numberOfDots: 25,
            dotColor: Color(0xFF00FF7F),
            dotSize: 3.0,
            animationDuration: Duration(seconds: 12),
          ),
          // Main content
          Column(
            children: [
              // Welcome header
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Welcome back, ${user?.userMetadata?['username'] ?? user?.email?.split('@')[0] ?? 'Guest'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Profile icon in center
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _onProfileTap,
                    child: AnimatedOpacity(
                      opacity: _opacity,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: profileIcon != null
                              ? DecorationImage(
                                  image: NetworkImage(profileIcon!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: Colors.grey[800],
                        ),
                        child: profileIcon == null
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}