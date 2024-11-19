import 'dart:convert';
import 'package:flutter/material.dart';

class Helpers {
  static int findLen(String word) {
    return word
        .replaceAll(RegExp(r'[~!@#$%^&*()_+`{}|<>?;:./,=\-a-zA-Z]'), "")
        .length;
  }

  static Widget toImage(String? thumbnail) {
    String placeholder =
        "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==";
    if (thumbnail?.isEmpty ?? true) {
      thumbnail = placeholder;
    } else {
      if (thumbnail!.length % 4 > 0) {
        thumbnail += '=' * (4 - thumbnail.length % 4);
      }
    }
    final byteImage = base64.decode(thumbnail);
    return Image.memory(byteImage, scale: 0.80);
  }

  static getFlag(String? countryCode) {
    return countryCode?.toUpperCase().replaceAllMapped(RegExp(r'[A-Z]'),
        (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) + 127397));
  }

  static bool checkIfEmailIsValid(String email) {
    // Define a regular expression pattern for a valid email address
    final RegExp emailRegex = RegExp(
      r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$',
    );

    // Use the RegExp's 'hasMatch' method to check if the email matches the pattern
    return emailRegex.hasMatch(email);
  }

  static bool checkIfPasswordIsValid(String password) {
    // Define a regular expression pattern for a valid email address
    final passwordRegex = RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[!@#$%^&*()_+{}|:;<>,.?/~]).{8,}$',
    );

    // Use the RegExp's 'hasMatch' method to check if the email matches the pattern
    return passwordRegex.hasMatch(password);
  }

  static String getGreeting() {
    var now = TimeOfDay.now();

    if (now.hour >= 5 && now.hour < 12) {
      return 'Good Morning';
    } else if (now.hour >= 12 && now.hour < 18) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  static String replaceUnderscoreAndCapitalise(String text) {
    List<String> words = text.split('_'); // Split the text by underscores
    List<String> capitalizedWords = [];

    for (String word in words) {
      if (word.isNotEmpty) {
        String capitalizedWord =
            word.substring(0, 1).toUpperCase() + word.substring(1);
        capitalizedWords.add(capitalizedWord);
      }
    }

    return capitalizedWords
        .join(' '); // Join the words back together with spaces
  }

  static String timeElapsed(String givenTime) {
    if (givenTime.isEmpty) {
      return 'unknown';
    }

    DateTime currentTime = DateTime.now();
    DateTime parsedTime;

    try {
      parsedTime = DateTime.parse(givenTime);
      // Add an hour to the parsed time
      parsedTime = parsedTime.add(const Duration(hours: 1));
    } catch (e) {
      return 'invalid date format';
    }

    Duration difference = currentTime.difference(parsedTime);

    if (difference.inDays >= 7) {
      int weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays >= 30) {
      int months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'just now';
    }
  }
}
