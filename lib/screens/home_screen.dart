import 'package:flutter/material.dart';
import 'activity_screen.dart';
import 'feed_screen.dart';
import 'profile.dart';
import 'reels_screen.dart';
import 'search_screen.dart';
import 'chat_screen.dart';
import 'twitter_shell_screen.dart';
import 'login_screen.dart';
import 'select_post_type_screen.dart';
import 'create_story_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const FeedScreen(),
    const SearchScreen(),
    const ReelsScreen(),
    const ActivityScreen(),
    const ProfileScreen(),
    const ChatScreen(),
    const TwitterShellScreen(),
    const SelectPostTypeScreen(),
    const CreateStoryScreen(),
  ];

  bool get isLargeScreen => MediaQuery.of(context).size.width >= 1100;

  int _getNavigationIndex(int index) {
    return index > 2 ? index - 1 : index;
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await AuthService.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logout failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Ruviel - Instagram Clone"),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Row(
        children: [
          if (isLargeScreen)
            NavigationRail(
              selectedIndex: _getNavigationIndex(_selectedIndex),
              onDestinationSelected: (index) {
                if (index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SelectPostTypeScreen(),
                    ),
                  );
                  return;
                }
                
                if (index == 7) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TwitterShellScreen(),
                    ),
                  );
                  return;
                }
                
                setState(() {
                  _selectedIndex = index > 2 ? index - 1 : index;
                });
              },
              extended: false,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.search),
                  label: Text('Search'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.add_box_outlined),
                  label: Text('Create'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.video_library),
                  label: Text('Reels'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.favorite_border),
                  label: Text('Activity'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  label: Text('Profile'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.chat_bubble_outline),
                  label: Text('Chat'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.edit),
                  label: Text('Tweet'),
                ),
              ],
            ),
          Expanded(
            child: _selectedIndex < _screens.length
                ? _screens[_selectedIndex]
                : _screens[0],
          ),
        ],
      ),
      bottomNavigationBar: isLargeScreen
          ? null
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _getNavigationIndex(_selectedIndex),
              selectedItemColor: theme.colorScheme.onBackground,
              unselectedItemColor: theme.disabledColor,
              onTap: (index) {
                if (index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SelectPostTypeScreen(),
                    ),
                  );
                  return;
                }
                
                if (index == 7) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TwitterShellScreen(),
                    ),
                  );
                  return;
                }
                
                setState(() {
                  _selectedIndex = index > 2 ? index - 1 : index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: "Home",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: "Search",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_box_outlined),
                  activeIcon: Icon(Icons.add_box),
                  label: "Create",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.video_library),
                  label: "Reels",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_border),
                  label: "Activity",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: "Profile",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  label: "Chat",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.edit),
                  label: "Tweet",
                ),
              ],
            ),
    );
  }
}