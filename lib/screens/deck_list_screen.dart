import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_grimoire/models/deck.dart';
import 'package:flutter_grimoire/providers/deck_provider.dart';
import 'package:flutter_grimoire/screens/deck_detail_screen.dart';

class DeckListScreen extends ConsumerStatefulWidget {
  const DeckListScreen({super.key});

  @override
  ConsumerState<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends ConsumerState<DeckListScreen> {
  final List<String> _formatOptions = [
    'Standard',
    'Modern',
    'Commander',
    'Legacy',
    'Vintage',
    'Pauper',
    'Pioneer',
  ];

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _showAddDeckDialog() async {
    if (_userId == null) return;
    if (!context.mounted) return;

    final nameController = TextEditingController();
    String? selectedFormat = _formatOptions[0];
    final formKey = GlobalKey<FormState>();

    final collectionRef = _firestore
        .collection('users')
        .doc(_userId!)
        .collection('decks');

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Adicionar Novo Deck'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Deck',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira um nome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedFormat,
                      decoration: const InputDecoration(labelText: 'Formato'),
                      items: _formatOptions.map((String format) {
                        return DropdownMenuItem<String>(
                          value: format,
                          child: Text(format),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setDialogState(() {
                          selectedFormat = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor, selecione um formato';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      await collectionRef.add({
                        'name': nameController.text.trim(),
                        'format': selectedFormat,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditDeckDialog(Deck deck) async {
    if (_userId == null) return;
    if (!context.mounted) return;

    final nameController = TextEditingController(text: deck.name);
    String? selectedFormat = deck.format;
    final formKey = GlobalKey<FormState>();

    final docRef = _firestore
        .collection('users')
        .doc(_userId!)
        .collection('decks')
        .doc(deck.id);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar Deck'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Deck',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira um nome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedFormat,
                      decoration: const InputDecoration(labelText: 'Formato'),
                      items: _formatOptions.map((String format) {
                        return DropdownMenuItem<String>(
                          value: format,
                          child: Text(format),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setDialogState(() {
                          selectedFormat = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor, selecione um formato';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      await docRef.update({
                        'name': nameController.text.trim(),
                        'format': selectedFormat,
                      });
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteDeck(String deckId) async {
    if (_userId == null) return;
    if (!context.mounted) return;

    final docRef = _firestore
        .collection('users')
        .doc(_userId!)
        .collection('decks')
        .doc(deckId);

    bool confirmDelete =
        await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Excluir Deck'),
            content: const Text(
              'Tem certeza que deseja excluir este deck? Esta ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmDelete) {
      await docRef.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final decksAsyncValue = ref.watch(deckListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDeckDialog,
        child: const Icon(Icons.add),
      ),
      body: decksAsyncValue.when(
        data: (decks) {
          if (decks.isEmpty) {
            return const Center(
              child: Text('Você ainda não criou nenhum deck.'),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 3 / 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: decks.length,
            itemBuilder: (context, index) {
              final deck = decks[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // ***** ALTERAÇÃO AQUI *****
                        builder: (context) => DeckDetailScreen(deckId: deck.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deck.name,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              deck.format,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showEditDeckDialog(deck),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              color: Theme.of(context).colorScheme.error,
                              onPressed: () => _deleteDeck(deck.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Ocorreu um erro: $error')),
      ),
    );
  }
}
