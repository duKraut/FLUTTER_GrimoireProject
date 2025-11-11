import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_grimoire/providers/auth_provider.dart';
import 'package:flutter_grimoire/screens/home_screen.dart';
import 'package:flutter_grimoire/screens/login_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) {
        if (user != null) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
      loading: () {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      error: (error, stackTrace) {
        return Scaffold(body: Center(child: Text('Erro: $error')));
      },
    );
  }
}
