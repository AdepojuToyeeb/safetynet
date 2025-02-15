import 'package:flutter/material.dart';
import 'package:safetynet/screens/auth/sign_up.dart';
// import 'package:safetynet/screens/verification/verify_phone.dart';

class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back_ios, color: Colors.white30),
      //     onPressed: () => Navigator.of(context).pop(),
      //   ),
      // ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/background.png', // Replace with your actual image path
            fit: BoxFit.cover,
          ),
          // Overlay
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon:
                        const Icon(Icons.arrow_back_ios, color: Colors.white30),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 20),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      // ElevatedButton.icon(
                      //   onPressed: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //           builder: (context) =>
                      //               const PhoneNumberScreen()),
                      //     );
                      //   },
                      //   icon: const Icon(
                      //     Icons.phone,
                      //     color: Colors.white,
                      //     size: 16,
                      //   ),
                      //   style: ElevatedButton.styleFrom(
                      //     minimumSize: const Size(double.infinity, 50),
                      //     shape: RoundedRectangleBorder(
                      //       borderRadius: BorderRadius.circular(25),
                      //     ),
                      //     backgroundColor:
                      //         const Color.fromRGBO(25, 118, 210, 1),
                      //   ),
                      //   label: Text(
                      //     'Use Phone Number',
                      //     style:
                      //         Theme.of(context).textTheme.titleMedium!.copyWith(
                      //               color: Colors.white,
                      //             ),
                      //   ),
                      // ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignupWidget()),
                          );
                        },
                        icon: const Icon(
                          Icons.mail_outlined,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Sign up with Email',
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    color: Colors.white,
                                  ),
                        ),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            backgroundColor: Colors.black),
                      ),
                      const SizedBox(height: 16),
                      // ElevatedButton.icon(
                      //   onPressed: () {},
                      //   icon: const Icon(Icons.g_translate_rounded,
                      //       color: Colors.black),
                      //   label: Text(
                      //     'Sign in with Google',
                      //     style:
                      //         Theme.of(context).textTheme.titleMedium!.copyWith(
                      //               color: Colors.black,
                      //             ),
                      //   ),
                      //   style: ElevatedButton.styleFrom(
                      //       minimumSize: const Size(double.infinity, 50),
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(25),
                      //       ),
                      //       backgroundColor: Colors.white),
                      // ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(text: 'By signing up, you agree to our '),
                        TextSpan(
                          text: 'Terms and Conditions',
                          style: TextStyle(
                            color: Colors.blueAccent, // Link color
                            decoration:
                                TextDecoration.underline, // Underline the text
                          ),
                        ),
                        TextSpan(text: '. See how we use your data in our '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: Colors.blueAccent, // Link color
                            decoration:
                                TextDecoration.underline, // Underline the text
                          ),
                        ),
                        TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
