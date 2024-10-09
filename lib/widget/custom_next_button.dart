import 'package:flutter/material.dart';

class CustomNextButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final bool enabled;

  const CustomNextButton({
    super.key,
    required this.onPressed,
    required this.text,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(52, 52, 52, 1),
            offset: Offset(6, 8),
            blurRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          disabledBackgroundColor: Colors.grey, // Color when disabled
          disabledForegroundColor: Colors.white60,  
          backgroundColor: const Color.fromRGBO(25, 118, 210, 1),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
