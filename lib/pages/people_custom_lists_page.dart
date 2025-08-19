import 'package:flutter/material.dart';
import '../theme.dart';

class PeopleCustomListsPage extends StatelessWidget {
  const PeopleCustomListsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listes personnalisées'),
      ),
      body: const Center(
        child: Text('La fonctionnalité SmartList a été supprimée de cette application.'),
      ),
    );
  }
}