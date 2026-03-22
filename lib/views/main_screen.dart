import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'home_view.dart';
import 'search_view.dart';
import 'premium_view.dart';
import 'library_view.dart';
import '../widgets/mini_player.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;
  
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      // If tapping the same tab, pop to the root
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final NavigatorState? navigator = _navigatorKeys[_selectedIndex].currentState;
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
        } else if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        } else {
          // If in Home and can't pop, we could close the app or let system handle it
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: _selectedIndex,
              children: [
                _buildTabNavigator(0, const HomeView()),
                _buildTabNavigator(1, const SearchView()),
                _buildTabNavigator(2, const LibraryView()),
                _buildTabNavigator(3, const PremiumView()),
              ],
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(),
            ),
          ],
        ),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            canvasColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.black.withOpacity(0.8),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Iconsax.home),
                activeIcon: Icon(Iconsax.home_15),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Iconsax.search_normal),
                activeIcon: Icon(Iconsax.search_normal_1),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Iconsax.music_playlist),
                activeIcon: Icon(Iconsax.music_playlist5),
                label: 'Library',
              ),
              BottomNavigationBarItem(
                icon: Icon(Iconsax.crown),
                activeIcon: Icon(Iconsax.crown5),
                label: 'Premium',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabNavigator(int index, Widget root) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: (context) => root);
      },
    );
  }
}
