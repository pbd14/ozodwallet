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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      // name: 'Ozod Mobile Web',
      // options: DefaultFirebaseOptions.currentPlatform,
      options: FirebaseOptions(
        apiKey: "AIzaSyCAJV40XWhTSjHECwJ-FvyP6tvEPcAOlS8",
        authDomain: "ozod-finance.firebaseapp.com",
        projectId: "ozod-finance",
        storageBucket: "ozod-finance.appspot.com",
        messagingSenderId: "31089423786",
        appId: "1:31089423786:web:2f103a290b0e7703fd27d3",
        measurementId: "G-5HF2H01K93",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  await FirebaseAppCheck.instance.activate(
    webRecaptchaSiteKey: '6Lca8MokAAAAAEiXVuUN55eK3ixX5gZ6CxtJGrpk',
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
