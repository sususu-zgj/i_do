import 'dart:io';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:i_do/data/home_data_.dart';
import 'package:i_do/data/note.dart';
import 'package:i_do/data/searcher.dart';
import 'package:i_do/data/setting.dart';
import 'package:i_do/page/home_page.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

///
/// NoteEditPage
/// HomePage


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await Setting().load();
  await Noter().load();
  await HomeData().load();
  Searcher().load(Noter().data);
  Noter().addListener(() {
    Searcher().search();
    debugPrint('Searcher updated from Noter changes.');
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<Setting>.value(value: Setting()),
        ChangeNotifierProvider<Noter>.value(value: Noter()),
        ChangeNotifierProvider<HomeData>.value(value: HomeData()),
        ChangeNotifierProvider<Searcher>.value(value: Searcher(),)
      ],
      child: const MainApp(),
    )
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  //static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    final setting = context.watch<Setting>();
    return MaterialApp(
      title: 'I Do',
      theme:  FlexThemeData.light(scheme: setting.colorScheme),
      darkTheme:  FlexThemeData.dark(scheme: setting.colorScheme),
      themeMode: setting.themeMode,
      home: const HomePage(),
    );
  }
}

