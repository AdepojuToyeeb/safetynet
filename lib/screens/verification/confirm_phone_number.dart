import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:safetynet/screens/verification/verification_succesful.dart';
import 'package:smart_auth/smart_auth.dart';
import 'package:flutter_timer_countdown/flutter_timer_countdown.dart';

class ConfirmPhoneNumber extends StatelessWidget {
  const ConfirmPhoneNumber({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Confirm Phone Number",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Kindly enter the 5-digit code sent that was sent to your number ending with 5729",
              style: TextStyle(
                fontSize: 15,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            const Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                FractionallySizedBox(
                  widthFactor: 1,
                  child: PinputWidget(),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "The code will expire in",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                TimerCountdown(
                  format: CountDownTimerFormat.minutesSeconds,
                  spacerWidth: 1,
                  endTime: DateTime.now().add(
                    const Duration(
                      minutes: 10,
                      seconds: 00,
                    ),
                  ),
                  
                  enableDescriptions: false,
                  onEnd: () {
                    print("Timer finished");
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              "Did not get a code? Resend Code",
              style: TextStyle(
                fontSize: 15,
                color: Color.fromRGBO(25, 118, 210, 1),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PinputWidget extends StatefulWidget {
  const PinputWidget({super.key});

  @override
  State<PinputWidget> createState() => _PinputExampleState();
}

class _PinputExampleState extends State<PinputWidget> {
  late final SmsRetriever smsRetriever;
  late final TextEditingController pinController;
  late final FocusNode focusNode;
  late final GlobalKey<FormState> formKey;

  @override
  void initState() {
    super.initState();
    formKey = GlobalKey<FormState>();
    pinController = TextEditingController();
    focusNode = FocusNode();

    /// In case you need an SMS autofill feature
    smsRetriever = SmsRetrieverImpl(
      SmartAuth(),
    );
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const fillColor = Color.fromRGBO(243, 246, 249, 0);
    const borderColor = Color.fromRGBO(23, 171, 144, 0.4);

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Color.fromRGBO(30, 60, 87, 1),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: borderColor),
      ),
    );

    /// Optionally you can use form to validate the Pinput
    return Form(
      key: formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Directionality(
            // Specify direction if desired
            textDirection: TextDirection.ltr,
            child: Pinput(
              length: 5,
              // You can pass your own SmsRetriever implementation based on any package
              // in this example we are using the SmartAuth
              smsRetriever: smsRetriever,
              controller: pinController,
              focusNode: focusNode,
              defaultPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black),
                ),
              ),
              separatorBuilder: (index) => const SizedBox(width: 17),
              validator: (value) {
                return value == '12345' ? null : 'Pin is incorrect';
              },

              hapticFeedbackType: HapticFeedbackType.lightImpact,
              onCompleted: (pin) {
                print('onCompleted: $pin');
                if (pin != '12345') {
                  return;
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VerificationSuccessScreen(),
                    ),
                  );
                }
              },
              onChanged: (value) {
                debugPrint('onChanged: $value');
              },
              cursor: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 9),
                    width: 22,
                    height: 1,
                    color: Colors.black,
                  ),
                ],
              ),
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black),
                ),
              ),
              submittedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: Colors.black),
                ),
              ),
              errorPinTheme: defaultPinTheme.copyBorderWith(
                border: Border.all(color: Colors.redAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// You, as a developer should implement this interface.
/// You can use any package to retrieve the SMS code. in this example we are using SmartAuth
class SmsRetrieverImpl implements SmsRetriever {
  const SmsRetrieverImpl(this.smartAuth);

  final SmartAuth smartAuth;

  @override
  Future<void> dispose() {
    return smartAuth.removeSmsListener();
  }

  @override
  Future<String?> getSmsCode() async {
    final signature = await smartAuth.getAppSignature();
    debugPrint('App Signature: $signature');
    final res = await smartAuth.getSmsCode(
      useUserConsentApi: true,
    );
    if (res.succeed && res.codeFound) {
      return res.code!;
    }
    return null;
  }

  @override
  bool get listenForMultipleSms => false;
}
