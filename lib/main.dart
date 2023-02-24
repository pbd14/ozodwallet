import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ozodwallet/Screens/MainScreen/main_screen.dart';
import 'package:ozodwallet/Services/languages/applocalizationsdelegate.dart';
import 'package:ozodwallet/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:overlay_support/overlay_support.dart';
import 'Services/languages/locale_constant.dart';

// Firebase app ids
// web       1:631128095988:web:d61e719234a144cd51b2a1
// android   1:631128095988:android:8196f18eab8bdd5551b2a1
// ios       1:631128095988:ios:61ba2b2aad3e2bb051b2a1
// macos     1:631128095988:ios:61ba2b2aad3e2bb051b2a1

// SHA1: 19:15:92:FA:6D:EE:79:89:88:63:7A:59:5C:45:75:83:30:26:74:33
// SHA256: 33:88:C5:61:62:CC:38:A9:CC:FE:3A:37:0A:17:70:2C:4F:86:BF:47:4B:6A:75:DF:3C:88:AD:0D:8D:07:E5:5A

// Google Play
// SHA-1 //66:99:4E:FE:1B:25:93:AA:BA:31:44:6E:4C:F8:66:7D:02:48:E3:06
// SHA-256 //B6:54:36:BC:64:A2:CB:BE:F1:97:5F:CB:AB:FB:DF:F7:58:65:35:C9:EC:E3:2F:87:F6:2C:60:57:72:E6:2C:71
// SHA-1 //85:62:C9:57:DC:0B:27:CF:22:6C:C8:84:74:BD:C1:B7:0C:46:CF:95
// SHA-256 //54:A8:97:A4:60:18:36:88:6B:65:0E:F0:D5:96:17:0A:14:B2:E5:30:30:C6:F3:4F:53:E2:7B:25:08:B9:D5:72


// Google recaptcha
// Site key 6LdDv4YkAAAAAFCYjHfRbYyYKg8Xci89hWdVuLg-
// Secret key 6LdDv4YkAAAAAL2sVGCBBBjUG7BZIJfbTtZiWmwx


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // FirebaseFunctions functions = FirebaseFunctions.instance;
  if (kIsWeb) {
    await Firebase.initializeApp(
      // name: 'Ozod Mobile Web',
      // options: DefaultFirebaseOptions.currentPlatform,
      options: FirebaseOptions(
        apiKey: 'AIzaSyCDoHs_7O-lZ2PCXW30XBrNkw2IICCsay4',
        appId: '1:631128095988:web:d61e719234a144cd51b2a1',
        messagingSenderId: '631128095988',
        projectId: 'ozod-loyalty',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  await FirebaseAppCheck.instance.activate(
    webRecaptchaSiteKey: 'recaptcha-v3-site-key',
    // Default provider for Android is the Play Integrity provider. You can use the "AndroidProvider" enum to choose
    // your preferred provider. Choose from:
    // 1. debug provider
    // 2. safety net provider
    // 3. play integrity provider
    androidProvider: AndroidProvider.debug,
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  static void setLocale(BuildContext context, Locale newLocale) {
    var state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    getLocale().then((locale) {
      setState(() {
        _locale = locale;
      });
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return OverlaySupport(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ozod Wallet',
        locale: _locale,
        theme: ThemeData(
            primaryColor: primaryColor, scaffoldBackgroundColor: whiteColor),
        home: MainScreen(),
        supportedLocales: const [
          Locale('en', ''),
          Locale('ru', ''),
          Locale('uz', ''),
        ],
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: (locale, supportedLocales) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale?.languageCode &&
                supportedLocale.countryCode == locale?.countryCode) {
              return supportedLocale;
            }
          }
          return supportedLocales.first;
        },
      ),
    );
  }
}
