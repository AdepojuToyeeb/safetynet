import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'FIREBASE_API_KEY', obfuscate: true)
  static final String firebaseApiKey = _Env.firebaseApiKey;
  @EnviedField(varName: 'ANDROID_APP_ID', obfuscate: true)
  static final String androidAppId = _Env.androidAppId;
  @EnviedField(varName: 'IOS_APP_ID', obfuscate: true)
  static final String iosAppId = _Env.iosAppId;
  @EnviedField(varName: 'WEB_APP_ID', obfuscate: true)
  static final String webAppId = _Env.webAppId;
}
