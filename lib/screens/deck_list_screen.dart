import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_grimoire/providers/deck_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_grimoire/models/deck.dart';

class DeckListScreen extends ConsumerStatefulWidget {
  const DeckListScreen({super.key});

  @override
  ConsumerState<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends ConsumerState<DeckListScreen> {
  final _nameController = TextEditingController();

  final List<String> _formats = [
    'Commander',
    'Standard',
    'Modern',
    'Pioneer',
    'Pauper',
    'Legacy',
    'Vintage',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createNewDeck(String format) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_nameController.text.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('decks')
          .add({
            'name': _nameController.text.trim(),
            'format': format,
            'createdAt': Timestamp.now(),
          });

      if (mounted) {
        Navigator.of(context).pop();
        _nameController.clear();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao criar deck: $e');
      }
    }
  }

  Future<void> _updateDeck(
    String deckId,
    String newName,
    String newFormat,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (newName.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('decks')
          .doc(deckId)
          .update({'name': newName, 'format': newFormat});
      if (mounted) {
        Navigator.of(context).pop();
        _nameController.clear();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao atualizar deck: $e');
      }
    }
  }

  Future<void> _deleteDeck(String deckId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('decks')
          .doc(deckId)
          .delete();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao excluir deck: $e');
      }
    }
  }

  void _showCreateDeckDialog() {
    _nameController.clear();
    String? selectedFormat = _formats.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Novo Deck'),
              content: _buildDeckForm(setDialogState, (newValue) {
                setDialogState(() {
                  selectedFormat = newValue;
                });
              }, selectedFormat),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (selectedFormat != null) {
                      _createNewDeck(selectedFormat!);
                    }
                  },
                  child: const Text('Criar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditDeckDialog(Deck deck) {
    _nameController.text = deck.name;
    String? selectedFormat = deck.format;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar Deck'),
              content: _buildDeckForm(setDialogState, (newValue) {
                setDialogState(() {
                  selectedFormat = newValue;
                });
              }, selectedFormat),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (selectedFormat != null) {
                      _updateDeck(
                        deck.id,
                        _nameController.text.trim(),
                        selectedFormat!,
                      );
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

  void _showDeleteDialog(String deckId, String deckName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir Deck'),
          content: Text(
            'Tem certeza que deseja excluir o deck "$deckName"?\nEsta ação não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                _deleteDeck(deckId);
                Navigator.of(context).pop();
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeckForm(
    void Function(void Function()) setDialogState,
    void Function(String?) onChanged,
    String? selectedFormat,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nome do Deck',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: selectedFormat,
          decoration: const InputDecoration(
            labelText: 'Formato',
            border: OutlineInputBorder(),
          ),
          items: _formats.map((String format) {
            return DropdownMenuItem<String>(value: format, child: Text(format));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final decksAsyncValue = ref.watch(deckListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDeckDialog,
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
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              childAspectRatio: 3 / 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: decks.length,
            itemBuilder: (context, index) {
              final deck = decks[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    // TODO: Ir para a tela de detalhes do deck
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deck.name,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          deck.format,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () {
                                _showEditDeckDialog(deck);
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: () {
                                _showDeleteDialog(deck.id, deck.name);
                              },
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
