import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmokeX - Home'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              await authProvider.signOut();
            },
          )
        ],
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'Welcome, ${user?.email ?? 'Guest'}',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}