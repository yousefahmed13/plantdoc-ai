import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/plantdoc_theme.dart';
import 'screens/chat_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: PD.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const PlantDocApp());
}

class PlantDocApp extends StatelessWidget {
  const PlantDocApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlantDoc AI',
      debugShowCheckedModeBanner: false,
      theme: PD.theme(),
      home: const ChatScreen(),
    );
  }
}
