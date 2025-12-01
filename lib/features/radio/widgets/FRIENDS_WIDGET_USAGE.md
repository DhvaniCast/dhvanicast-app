# Friends List Widget - Usage Guide

## Widget Location
`lib/features/radio/widgets/friends_list_widget.dart`

## Description
Ye ek reusable widget hai jo friends list ko display karta hai. Aap ise **kisi bhi screen** pe use kar sakte hain.

## How to Use

### 1. Import the Widget
```dart
import 'package:harborleaf_radio_app/features/radio/widgets/friends_list_widget.dart';
```

### 2. Prepare Friends Data
```dart
List<Map<String, dynamic>> friendsList = [
  {
    'name': 'John Doe',
    'avatar': '👤',
    'isOnline': true,
    'state': 'California',
    'status': 'Active on frequency 505.1',
  },
  {
    'name': 'Jane Smith',
    'avatar': '🎧',
    'isOnline': false,
    'state': 'New York',
    'status': 'Offline',
  },
];
```

### 3. Use the Widget

#### Option A: As a Full Screen
```dart
class FriendsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FriendsListWidget(
        friends: friendsList,
        onClose: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
```

#### Option B: As a Bottom Sheet
```dart
void _showFriendsList(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.75,
      child: FriendsListWidget(
        friends: friendsList,
        onClose: () {
          Navigator.pop(context);
        },
      ),
    ),
  );
}
```

#### Option C: As an Animated Overlay
```dart
class YourScreen extends StatefulWidget {
  @override
  _YourScreenState createState() => _YourScreenState();
}

class _YourScreenState extends State<YourScreen> {
  bool _showFriends = false;
  List<Map<String, dynamic>> _friendsList = [];

  void _toggleFriendsList() {
    setState(() {
      _showFriends = !_showFriends;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Your main content
          YourMainContent(),
          
          // Friends list overlay
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
            bottom: _showFriends ? 0 : -600,
            left: 0,
            right: 0,
            height: 600,
            child: FriendsListWidget(
              friends: _friendsList,
              onClose: _toggleFriendsList,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleFriendsList,
        child: Icon(Icons.group),
      ),
    );
  }
}
```

## Widget Properties

### Required Parameters:
- `friends`: `List<Map<String, dynamic>>` - Friends data list
- `onClose`: `VoidCallback` - Function to call when close button is pressed

### Friends Data Structure:
Each friend should be a Map with these keys:
```dart
{
  'name': String,        // Friend's name (required)
  'avatar': String,      // Emoji or icon (default: '👤')
  'isOnline': bool,      // Online status (default: false)
  'state': String,       // Location/state (optional)
  'status': String,      // Status message (optional)
}
```

## Features

✅ Responsive design
✅ Dark theme with neon accents
✅ Online/Offline indicators
✅ Empty state handling
✅ Smooth animations
✅ Call button (placeholder)
✅ More options button (placeholder)

## Customization

### To implement Call functionality:
Edit line ~210 in `friends_list_widget.dart`:
```dart
IconButton(
  onPressed: () {
    // Your call implementation here
    Navigator.pushNamed(context, '/call', arguments: friend);
  },
  icon: const Icon(Icons.phone, color: Color(0xFF00ff88), size: 22),
),
```

### To implement More Options:
Edit line ~220 in `friends_list_widget.dart`:
```dart
IconButton(
  onPressed: () {
    // Show options menu
    showModalBottomSheet(
      context: context,
      builder: (context) => YourOptionsMenu(friend: friend),
    );
  },
  icon: const Icon(Icons.more_vert, color: Colors.white54, size: 22),
),
```

## Example: Using in a Separate Friends Screen

```dart
import 'package:flutter/material.dart';
import 'package:harborleaf_radio_app/features/radio/widgets/friends_list_widget.dart';

class FriendsScreen extends StatefulWidget {
  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    // Load friends from API or local storage
    setState(() {
      _friends = [
        // Your friends data
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF1a1a1a),
      body: SafeArea(
        child: FriendsListWidget(
          friends: _friends,
          onClose: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
```

## Navigation Setup

Add route in your main.dart:
```dart
routes: {
  '/friends': (context) => FriendsScreen(),
  // ... other routes
}
```

Then navigate from anywhere:
```dart
Navigator.pushNamed(context, '/friends');
```

## Notes

- Widget is **completely independent** and reusable
- No dependencies on radio screen
- Can be used anywhere in the app
- Easy to customize colors and styling
- Built with Flutter's best practices

---

**Widget Ready ✅**
Use it anywhere you want!
