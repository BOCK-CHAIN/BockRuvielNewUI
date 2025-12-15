import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final AuthService _authService = AuthService();

  final List<Widget> _screens = [
    const FeedScreen(),
    const SearchScreen(),
    const ReelsScreen(),
    const ActivityScreen(),
    const ProfileScreen(),
    const ChatScreen(),
  ];

  // Helper to convert screen index to navigation index
  // Navigation has: [Home, Search, Create, Reels, Activity, Profile, Chat, Tweet]
  // Screens array has: [Home, Search, Reels, Activity, Profile, Chat, Tweet]
  int _getNavigationIndex(int screenIndex) {
    // After index 1 (Search), add 1 for Create button
    return screenIndex >= 2 ? screenIndex + 1 : screenIndex;
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: isLargeScreen
          ? null
          : AppBar(
              backgroundColor: theme.appBarTheme.backgroundColor,
              elevation: 0.5,
              title: Text(
                "Ruviel",
                style: theme.appBarTheme.titleTextStyle,
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.logout, color: theme.iconTheme.color),
                  tooltip: "Logout",
                  onPressed: () => _logout(context),
                ),
              ],
            ),
      body: Row(
        children: [
          // NavigationRail for large screens
          if (isLargeScreen)
            NavigationRail(
              selectedIndex: _getNavigationIndex(_selectedIndex),
              onDestinationSelected: (index) {
                // Special handling for Create button (index 2)
                if (index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SelectPostTypeScreen()),
                  );
                  return;
                }

                // Tweet button (index 7) opens Twitter/X mode screen
                if (index == 7) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TwitterShellScreen()),
                  );
                  return;
                }

                // Adjust index: after Create (index 2), subtract 1
                setState(() {
                  _selectedIndex = index > 2 ? index - 1 : index;
                });
              },
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: IconThemeData(
                color: theme.colorScheme.onBackground,
                size: 28,
              ),
              unselectedIconTheme: IconThemeData(
                color: theme.disabledColor,
              ),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Home')),
                NavigationRailDestination(icon: Icon(Icons.search), selectedIcon: Icon(Icons.search_rounded), label: Text('Search')),
                NavigationRailDestination(icon: Icon(Icons.add_box_outlined), selectedIcon: Icon(Icons.add_box), label: Text('Create')),
                NavigationRailDestination(icon: Icon(Icons.video_library_outlined), selectedIcon: Icon(Icons.video_library), label: Text('Reels')),
                NavigationRailDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: Text('Activity')),
                NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profile')),
                NavigationRailDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat), label: Text('Chat')),
                NavigationRailDestination(icon: Icon(Icons.edit), selectedIcon: Icon(Icons.edit_note), label: Text('Tweet')),
              ],
              trailing: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  tooltip: "Logout",
                  onPressed: () => _logout(context),
                ),
              ),
            ),

          Expanded(
            child: isLargeScreen
                ? (_selectedIndex < _screens.length
                    ? _screens[_selectedIndex]
                    : _screens[0])
                : GestureDetector(
                    onHorizontalDragEnd: (details) {
                      // Only handle gestures from home feed on mobile
                      if (_selectedIndex != 0) return;
                      final velocity = details.primaryVelocity ?? 0;

                      if (velocity < -200) {
                        // Swipe left → Create Story
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateStoryScreen(),
                          ),
                        );
                      } else if (velocity > 200) {
                        // Swipe right → Chat screen
                        setState(() {
                          _selectedIndex = 5; // ChatScreen index in _screens
                        });
                      }
                    },
                    child: _selectedIndex < _screens.length
                        ? _screens[_selectedIndex]
                        : _screens[0],
                  ),
          ),
        ],
      ),

      // Bottom nav for small screens
      bottomNavigationBar: isLargeScreen
          ? null
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _getNavigationIndex(_selectedIndex),
              selectedItemColor: theme.colorScheme.onBackground,
              unselectedItemColor: theme.disabledColor,
              onTap: (index) {
                // Special handling for Create button (index 2)
                if (index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SelectPostTypeScreen()),
                  );
                  return;
                }

                // Tweet button (index 7) opens Twitter/X mode screen
                if (index == 7) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TwitterShellScreen()),
                  );
                  return;
                }

                // Adjust index: after Create (index 2), subtract 1
                setState(() {
                  _selectedIndex = index > 2 ? index - 1 : index;
                });
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_box_outlined),
                  activeIcon: Icon(Icons.add_box),
                  label: "Create",
                ),
                BottomNavigationBarItem(icon: Icon(Icons.video_library), label: "Reels"),
                BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: "Activity"),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
                BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Chat"),
                BottomNavigationBarItem(icon: Icon(Icons.edit), label: "Tweet"),
              ],
            ),
    );
  }
}
