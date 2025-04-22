import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/story_list_screen.dart';
import 'providers/story_provider.dart';
import 'utils/theme_config.dart';
import 'utils/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => StoryProvider(),
      child: const StoryBaseApp(),
    ),
  );
}

class StoryBaseApp extends StatelessWidget {
  const StoryBaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: ThemeConfig.lightTheme,
      darkTheme: ThemeConfig.lightTheme,
      themeMode: ThemeMode.system,
      home: const StoryListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}