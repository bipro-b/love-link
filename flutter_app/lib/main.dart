import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/call_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Immersive UI
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final prefs = await SharedPreferences.getInstance();
  final savedUserId = prefs.getString('userId');

  runApp(LoveLinkApp(initialUserId: savedUserId));
}

class LoveLinkApp extends StatelessWidget {
  final String? initialUserId;
  const LoveLinkApp({super.key, this.initialUserId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CallProvider(),
      child: MaterialApp(
        title: 'LoveLink',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: initialUserId != null
            ? HomeScreen(userId: initialUserId!)
            : const SetupScreen(),
      ),
    );
  }
}
