import 'package:ozodwallet/Services/languages/en.dart';
import 'package:ozodwallet/Services/languages/languages.dart';
import 'package:ozodwallet/Services/languages/ru.dart';
import 'package:ozodwallet/Services/languages/uz.dart';
import 'package:flutter/material.dart';

class AppLocalizationsDelegate extends LocalizationsDelegate<Languages> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  Future<Languages> load(Locale locale) => _load(locale);

  static Future<Languages> _load(Locale locale) async {
    switch (locale.languageCode) {
      case 'en':
        return LanguageEn();
      case 'ru':
        return LanguageRu();
      case 'uz':
        return LanguageUz();
      default:
        return LanguageEn();
    }
  }

  @override
  bool shouldReload(LocalizationsDelegate<Languages> old) => false;
}
