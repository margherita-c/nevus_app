// Create: lib/widgets/app_bar_title.dart
import 'package:flutter/material.dart';
import '../storage/user_storage.dart';

class AppBarTitle extends StatelessWidget {
  final String title;
  
  const AppBarTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final currentUser = UserStorage.currentUser;
    
    return Row(
      children: [
        Text(title),
        if (!currentUser.isGuest) ...[
          const Text(' - '),
          Text(
            currentUser.username,
            style: const TextStyle(fontWeight: FontWeight.normal),
          ),
        ] else if (title == 'Nevus App') ...[
          const Text(' - Guest'),
        ],
      ],
    );
  }
}