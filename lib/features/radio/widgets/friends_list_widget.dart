import 'package:flutter/material.dart';

class FriendsListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> friends;
  final VoidCallback onClose;
  final Function(Map<String, dynamic>)? onCallFriend;

  const FriendsListWidget({
    Key? key,
    required this.friends,
    required this.onClose,
    this.onCallFriend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF2a2a2a),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.group, color: Color(0xFF00ff88)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Friends List',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${friends.length} friend${friends.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Friends List
          Expanded(
            child: friends.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No friends yet',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Start connecting with users!',
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      return _buildFriendItem(friend);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendItem(Map<String, dynamic> friend) {
    final friendId = friend['_id'] ?? friend['id'] ?? '';
    final name = friend['name'] ?? 'Unknown';
    final avatar = friend['avatar'] ?? '👤';
    final isOnline = friend['isOnline'] ?? false;
    final state = friend['state'] ?? '';
    final status = friend['status'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00ff88).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF00ff88).withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isOnline
                      ? const Color(0xFF00ff88)
                      : const Color(0xFF555555),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(avatar, style: const TextStyle(fontSize: 24)),
              ),
            ),
            // Online indicator
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00ff88),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2a2a2a),
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.isNotEmpty)
              Text(
                '📍 $state',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            if (status.isNotEmpty)
              Text(
                status,
                style: TextStyle(
                  color: isOnline
                      ? const Color(0xFF00ff88)
                      : const Color(0xFF888888),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Call button
            IconButton(
              onPressed: () {
                if (onCallFriend != null) {
                  onCallFriend!({
                    '_id': friendId,
                    'id': friendId,
                    'name': name,
                    'avatar': avatar,
                    'isOnline': isOnline,
                  });
                }
              },
              icon: const Icon(Icons.phone, color: Color(0xFF00ff88), size: 22),
            ),
            // More options
            IconButton(
              onPressed: () {
                // TODO: Implement more options
                print('More options for $name');
              },
              icon: const Icon(
                Icons.more_vert,
                color: Colors.white54,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
