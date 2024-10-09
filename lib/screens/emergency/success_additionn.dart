import 'package:flutter/material.dart';
import 'package:safetynet/widget/custom_next_button.dart';

class SuccesfulEmergency extends StatelessWidget {
  const SuccesfulEmergency({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Add rounded corners
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2), // Shadow position
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 90),
      child: SingleChildScrollView(
        // Wrap with SingleChildScrollView
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Emergency Contact Added',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'A request has been sent to your emergency contact to join SafetyNet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            CustomNextButton(
                onPressed: () {}, text: "Go to Menu", enabled: true)
          ],
        ),
      ),
    );
  }
}
