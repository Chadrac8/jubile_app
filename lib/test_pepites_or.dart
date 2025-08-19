import 'package:flutter/material.dart';
import 'theme.dart';
import 'models/pepite_or_model.dart';
import 'services/pepite_or_firebase_service.dart';

/// Page de test pour créer quelques pépites d'or d'exemple
class TestPepitesOrPage extends StatelessWidget {
  const TestPepitesOrPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Pépites d\'Or'),
        backgroundColor: const Color(0xFF8B4513)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _creerPepitesExemple(context),
              child: const Text('Créer des Pépites d\'Exemple')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _afficherPepites(context),
              child: const Text('Afficher toutes les Pépites')),
          ])));
  }

  Future<void> _creerPepitesExemple(BuildContext context) async {
    try {
      // Pépite 1: Foi
      final pepite1 = PepiteOrModel(
        id: '',
        theme: 'Foi',
        description: 'La foi qui déplace les montagnes et transforme les cœurs',
        auteur: 'admin',
        nomAuteur: 'Administrateur',
        citations: [
          CitationModel(
            id: 'c1',
            texte: 'Car nous marchons par la foi et non par la vue.',
            auteur: 'Apôtre Paul',
            reference: '2 Corinthiens 5:7',
            ordre: 1),
          CitationModel(
            id: 'c2',
            texte: 'Si vous aviez de la foi comme un grain de sénevé, vous diriez à cette montagne: Transporte-toi d\'ici là, et elle se transporterait; rien ne vous serait impossible.',
            auteur: 'Jésus-Christ',
            reference: 'Matthieu 17:20',
            ordre: 2),
        ],
        tags: ['foi', 'confiance', 'miracle', 'puissance'],
        estPubliee: true,
        dateCreation: DateTime.now());

      // Pépite 2: Amour
      final pepite2 = PepiteOrModel(
        id: '',
        theme: 'Amour',
        description: 'L\'amour de Dieu révélé et partagé avec notre prochain',
        auteur: 'admin',
        nomAuteur: 'Administrateur',
        citations: [
          CitationModel(
            id: 'c3',
            texte: 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.',
            auteur: 'Jésus-Christ',
            reference: 'Jean 3:16',
            ordre: 1),
          CitationModel(
            id: 'c4',
            texte: 'L\'amour est patient, il est plein de bonté; l\'amour n\'est point envieux; l\'amour ne se vante point, il ne s\'enfle point d\'orgueil.',
            auteur: 'Apôtre Paul',
            reference: '1 Corinthiens 13:4',
            ordre: 2),
          CitationModel(
            id: 'c5',
            texte: 'Il n\'y a pas de plus grand amour que de donner sa vie pour ses amis.',
            auteur: 'Jésus-Christ',
            reference: 'Jean 15:13',
            ordre: 3),
        ],
        tags: ['amour', 'sacrifice', 'bonté', 'patience'],
        estPubliee: true,
        dateCreation: DateTime.now());

      // Pépite 3: Espérance
      final pepite3 = PepiteOrModel(
        id: '',
        theme: 'Espérance',
        description: 'L\'espérance qui ne trompe point et qui ancre notre âme',
        auteur: 'admin',
        nomAuteur: 'Administrateur',
        citations: [
          CitationModel(
            id: 'c6',
            texte: 'Or, l\'espérance ne trompe point, parce que l\'amour de Dieu est répandu dans nos cœurs par le Saint-Esprit qui nous a été donné.',
            auteur: 'Apôtre Paul',
            reference: 'Romains 5:5',
            ordre: 1),
          CitationModel(
            id: 'c7',
            texte: 'Car je connais les projets que j\'ai formés sur vous, dit l\'Éternel, projets de paix et non de malheur, afin de vous donner un avenir et de l\'espérance.',
            auteur: 'Jérémie',
            reference: 'Jérémie 29:11',
            ordre: 2),
        ],
        tags: ['espérance', 'avenir', 'paix', 'promesse'],
        estPubliee: true,
        dateCreation: DateTime.now());

      // Créer les pépites
      await PepiteOrFirebaseService.creerPepiteOr(pepite1);
      await PepiteOrFirebaseService.creerPepiteOr(pepite2);
      await PepiteOrFirebaseService.creerPepiteOr(pepite3);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('3 pépites d\'or créées avec succès !'),
            backgroundColor: AppTheme.successColor));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor));
      }
    }
  }

  Future<void> _afficherPepites(BuildContext context) async {
    try {
      // Utiliser le stream pour obtenir les données
      final stream = PepiteOrFirebaseService.obtenirPepitesOrPublieesStream();
      final pepites = await stream.first;
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Pépites Trouvées'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: pepites.length,
                itemBuilder: (context, index) {
                  final pepite = pepites[index];
                  return ListTile(
                    title: Text(pepite.theme),
                    subtitle: Text(pepite.description),
                    trailing: Text('${pepite.citations.length} citations'));
                })),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer')),
            ]));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor));
      }
    }
  }
}
