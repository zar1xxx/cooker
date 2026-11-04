import 'package:flutter/material.dart';

class CookingScreen extends StatelessWidget {
  const CookingScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Режим готовки')),
      body: Center(
        child: Text(
          'Режим готовки ($recipeId)',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
