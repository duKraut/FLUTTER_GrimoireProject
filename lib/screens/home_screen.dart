import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_grimoire/screens/card_search_screen.dart';
import 'package:flutter_grimoire/screens/collection_screen.dart';
import 'package:flutter_grimoire/screens/deck_list_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DeckListScreen(),
    const CollectionScreen(),
    const CardSearchScreen(),
  ];

  final List<String> _pageTitles = [
    'Meus Decks',
    'Minha Coleção',
    'Buscar Cartas',
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_pageTitles[_selectedIndex])),
      drawer: Drawer(
        width: 180,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              height: 100,
              padding: const EdgeInsets.only(
                bottom: 20.0,
                left: 24.0,
                right: 24.0,
              ),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 107, 69, 179),
              ),
              child: SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    'Meu Grimório',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.black87,
                      fontSize: 28,
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.style_outlined),
              title: const Text('Decks'),
              selected: _selectedIndex == 0,
              onTap: () => _onDestinationSelected(0),
            ),
            ListTile(
              leading: const Icon(Icons.collections_bookmark_outlined),
              title: const Text('Coleção'),
              selected: _selectedIndex == 1,
              onTap: () => _onDestinationSelected(1),
            ),
            ListTile(
              leading: const Icon(Icons.search_outlined),
              title: const Text('Buscar'),
              selected: _selectedIndex == 2,
              onTap: () => _onDestinationSelected(2),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}
