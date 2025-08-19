// Widget racine qui affiche un splash tant que Firebase n'est pas prêt
import 'package:flutter/material.dart';
import 'main.dart';

class ChurchFlowAppWithSplash extends StatelessWidget {
  final bool firebaseReady;
  const ChurchFlowAppWithSplash({super.key, required this.firebaseReady});

  @override
  Widget build(BuildContext context) {
    if (!firebaseReady) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        debugShowCheckedModeBanner: false,
      );
    }
    return const ChurchFlowApp();
  }
}
