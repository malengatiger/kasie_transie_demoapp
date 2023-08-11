import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart' as fb;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

import 'package:kasie_transie_demoapp/ui/association_list.dart';
import 'package:kasie_transie_library/bloc/theme_bloc.dart';
import 'package:kasie_transie_library/utils/base_initializer.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/error_handler.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_library/widgets/splash_page.dart';
import 'package:page_transition/page_transition.dart';

import 'firebase_options.dart';

late fb.FirebaseApp firebaseApp;
fb.User? fbAuthedUser;
var themeIndex = 0;

const mx = '🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵 KasieTransie DemoDriver : main 🔵🔵';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  firebaseApp = await fb.Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
  pp('\n\n$mx '
      ' Firebase App has been initialized: ${firebaseApp.name}, checking for authed current user\n');
  fbAuthedUser = fb.FirebaseAuth.instance.currentUser;
  final vehicle = await prefs.getUser();
  if (vehicle == null) {
    pp('$mx  this user has NOT been initialized yet ${E.redDot}');
  } else {
    pp('$mx  this user has been initialized! ${E.leaf}: ${vehicle.toJson()}');
  }


  baseInitializer.initialize();
  errorHandler.sendErrors();
  runApp(const DemoDriverApp());
}

class DemoDriverApp extends StatelessWidget {
  const DemoDriverApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        pp('$mx 🌀🌀🌀🌀 Tap detected; should dismiss keyboard ...');
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: StreamBuilder(
          stream: themeBloc.localeAndThemeStream,
          builder: (ctx, snapshot) {
            if (snapshot.hasData) {
              pp('🔵🔵🔵'
                  'build: theme index has changed to ${snapshot.data!.themeIndex}'
                  '  and locale is ${snapshot.data!.locale.toString()}');
              themeIndex = snapshot.data!.themeIndex;
            }

            return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'DemoDriver',
                theme: themeBloc.getTheme(themeIndex).lightTheme,
                darkTheme: themeBloc.getTheme(themeIndex).darkTheme,
                themeMode: ThemeMode.system,
                navigatorObservers: [
                  FirebaseAnalyticsObserver(
                      analytics: FirebaseAnalytics.instance),
                ],
                home: AnimatedSplashScreen(
                  splash: const SplashWidget(),
                  animationDuration: const Duration(milliseconds: 2000),
                  curve: Curves.easeInCirc,
                  splashIconSize: 160.0,
                  nextScreen: const AssociationList(),
                  splashTransition: SplashTransition.fadeTransition,
                  pageTransitionType: PageTransitionType.leftToRight,
                  backgroundColor: Colors.cyan.shade900,
                ));
          }),
    );
  }
}
