import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/router/route_names.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                AppConstants.appName,
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => context.push(RouteNames.createRoom),
                child: const Text('Crear sala'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.push(RouteNames.joinRoom),
                child: const Text('Unirse a sala'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.push(RouteNames.settings),
                child: const Text('Ajustes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
