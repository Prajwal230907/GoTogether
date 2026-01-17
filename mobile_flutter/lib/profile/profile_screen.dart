import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'profile_viewmodel.dart';
import '../data/models.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileViewModelProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: () {
               context.push('/edit-profile');
            },
            child: const Text('Edit'),
          ),
        ],
      ),
      body: profileState.when(
        data: (user) {
          if (user == null) {
              return const Center(child: Text("User profile not found."));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(profileViewModelProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildHeader(context, user),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Account'),
                _buildInfoTile(context, Icons.phone, 'Phone', user.phone),
                if (user.email.isNotEmpty)
                  _buildInfoTile(context, Icons.email, 'Email', user.email),
                if (user.collegeId != null && user.collegeId!.isNotEmpty)
                  _buildInfoTile(context, Icons.badge, 'College ID', user.collegeId!),
                
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Emergency Contacts'),
                if (user.emergencyContacts.isEmpty)
                   Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('No emergency contacts added.', style: TextStyle(color: Colors.grey[600])),
                   ),
                ...user.emergencyContacts.map((c) => ListTile(
                  leading: const Icon(Icons.contact_phone),
                  title: Text(c.name),
                  subtitle: Text(c.phone),
                )),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextButton.icon(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        context.push('/edit-profile');
                      }, 
                      label: const Text("Manage Contacts")
                  ),
                ),

                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Actions'),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Log out'),
                  onTap: () async {
                    await ref.read(profileViewModelProvider.notifier).logout();
                    if (context.mounted) context.go('/auth');
                  },
                ),
                 ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete account', style: TextStyle(color: Colors.red)),
                  onTap: () => _showDeleteConfirmation(context, ref),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
     return Column(
       children: [
         CircleAvatar(
           radius: 50,
           backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
           child: user.photoUrl == null ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 32)) : null,
         ),
         const SizedBox(height: 16),
         Text(user.name.isNotEmpty ? user.name : "No Name", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
         const SizedBox(height: 4),
         if (user.email.isNotEmpty)
            Text(user.email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
         const SizedBox(height: 8),
         Row(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Chip(
               label: Text(user.role.toUpperCase()), 
               backgroundColor: Theme.of(context).colorScheme.primaryContainer,
               labelStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
             ),
             if (user.role == 'driver') ...[
               const SizedBox(width: 8),
               Chip(
                 avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                 label: Text(user.rating.toStringAsFixed(1)),
               ),
               const SizedBox(width: 8),
               Chip(
                  label: Text('${user.tripsCompleted} Trips'),
               ),
             ]
           ],
         )
       ],
     );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('This will delete your account, rides, and data. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(profileViewModelProvider.notifier).deleteAccount();
              if (context.mounted) context.go('/auth');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
