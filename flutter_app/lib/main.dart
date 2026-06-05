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

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final prefs = await SharedPreferences.getInstance();
  final savedUserId = prefs.getString('userId');
  final savedServer = prefs.getString('serverUrl');

  runApp(LoveLinkApp(
    initialUserId: savedUserId,
    serverUrl: savedServer,
  ));
}

class LoveLinkApp extends StatelessWidget {
  final String? initialUserId;
  final String? serverUrl;
  const LoveLinkApp({super.key, this.initialUserId, this.serverUrl});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CallProvider(),
      child: MaterialApp(
        title: 'LoveLink',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: (initialUserId != null && serverUrl != null)
            ? HomeScreen(userId: initialUserId!, serverUrl: serverUrl!)
            : const SetupScreen(),
      ),
    );
  }
}
