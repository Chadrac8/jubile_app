import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../services/firebase_service.dart';


class FamiliesManagementPage extends StatefulWidget {
  const FamiliesManagementPage({Key? key}) : super(key: key);

  @override
  State<FamiliesManagementPage> createState() => _FamiliesManagementPageState();
}

class _FamiliesManagementPageState extends State<FamiliesManagementPage> {
  Future<void> _showFamilyForm({FamilyModel? family}) async {
    final nameController = TextEditingController(text: family?.name ?? '');
    final addressController = TextEditingController(text: family?.address ?? '');
    final phoneController = TextEditingController(text: family?.homePhone ?? '');
    final isEdit = family != null;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.family_restroom, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(isEdit ? 'Modifier la famille' : 'Créer une famille'),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la famille',
                    prefixIcon: Icon(Icons.home),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Nom requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Adresse',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              if (isEdit) {
                final updated = FamilyModel(
                  id: family.id,
                  name: nameController.text.trim(),
                  address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                  homePhone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                  headOfFamilyId: family.headOfFamilyId,
                  memberIds: family.memberIds,
                  createdAt: family.createdAt,
                  updatedAt: DateTime.now(),
                );
                await FirebaseService.updateFamily(updated);
              } else {
                final newFamily = FamilyModel(
                  id: '',
                  name: nameController.text.trim(),
                  address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                  homePhone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                  headOfFamilyId: null,
                  memberIds: [],
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                await FirebaseService.createFamily(newFamily);
              }
              if (mounted) Navigator.pop(context);
            },
            child: Text(isEdit ? 'Enregistrer' : 'Créer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFamily(FamilyModel family) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer la famille'),
        content: Text('Voulez-vous vraiment supprimer la famille "${family.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await FirebaseService.deleteFamily(family.id);
              Navigator.pop(context, true);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Famille supprimée.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des familles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter une famille',
            onPressed: () => _showFamilyForm(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFamilyForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle famille'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: StreamBuilder<List<FamilyModel>>(
        stream: FirebaseService.getFamiliesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune famille trouvée.'));
          }
          final families = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: families.length,
            separatorBuilder: (context, i) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final family = families[i];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 3,
                color: Theme.of(context).colorScheme.surface,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    child: const Icon(Icons.family_restroom, color: Color(0xFF6F61EF)),
                  ),
                  title: Text(
                    family.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (family.address != null && family.address!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Color(0xFF39D2C0)),
                              const SizedBox(width: 6),
                              Expanded(child: Text(family.address!)),
                            ],
                          ),
                        ),
                      if (family.homePhone != null && family.homePhone!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.phone, size: 16, color: Color(0xFF39D2C0)),
                              const SizedBox(width: 6),
                              Text(family.homePhone!),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.people, size: 16, color: Color(0xFF39D2C0)),
                            const SizedBox(width: 6),
                            Text('Membres: ${family.memberIds.length}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showFamilyForm(family: family);
                      } else if (value == 'delete') {
                        _deleteFamily(family);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Modifier'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Supprimer'),
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    final members = await Future.wait(
                      family.memberIds.map((id) => FirebaseService.getPerson(id)),
                    );
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text('Famille: ${family.name}'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (family.address != null) Text('Adresse: ${family.address}'),
                            if (family.homePhone != null) Text('Téléphone: ${family.homePhone}'),
                            const SizedBox(height: 8),
                            const Text('Membres:'),
                            ...members.whereType<PersonModel>().map((m) => Text('${m.firstName} ${m.lastName}')),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Fermer'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
