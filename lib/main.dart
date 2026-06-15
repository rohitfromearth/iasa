import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/auth/session_storage.dart';
import 'injection/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sessionStorage = await SessionStorage.create();

  runApp(
    MultiProvider(
      providers: Injection.providers(sessionStorage: sessionStorage),
      child: const App(),
    ),
  );
}
