import 'package:flutter/material.dart';
import 'package:safetynet/screens/emergency/emergency_contacts_screen.dart';

class EmergencySetupScreen extends StatelessWidget {
  const EmergencySetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Let\'s set up your new account.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              _buildOptionTile(
                icon: Icons.person_add_outlined,
                title: 'Add Emergency Contacts',
                subtitle:
                    'Select people to be contacted immediately in case of any emergencies.',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const EmergencyContactsScreen(),
                  ));
                },
              ),
              const SizedBox(height: 40),
              // _buildOptionTile(
              //   icon: Icons.lock_outline,
              //   title: 'Set Emergency Pin',
              //   subtitle:
              //       'To cancel your alerts and activate/deactivate other alerts',
              //   onTap: () {
              //     // Implement your functionality here
              //   },
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.black),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
