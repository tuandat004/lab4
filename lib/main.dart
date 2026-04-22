import 'package:contacts_app/views/add_contact_page.dart';
import 'package:contacts_app/views/home.dart';
import 'package:contacts_app/views/login_page.dart';
import 'package:contacts_app/views/sign_up_page.dart';
import 'package:contacts_app/views/update_contact_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'controllers/auth_services.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? firebaseError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    firebaseError = e;
  }
  runApp(MyApp(firebaseError: firebaseError));
}

class MyApp extends StatelessWidget {
  final Object? firebaseError;

  const MyApp({super.key, this.firebaseError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contacts App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.soraTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8896A),
        ),
        useMaterial3: true,
      ),
      routes: {
        "/": (context) => firebaseError != null
            ? _InitializationErrorView(
                message: firebaseError is UnsupportedError
                    ? "Firebase is not configured for this platform yet."
                    : "Unable to start Firebase. Please check your configuration.",
              )
            : const CheckUser(),
        "/home": (context) => const Homepage(),
        "/signup": (context) => const SignUpPage(),
        "/login": (context) => const LoginPage(),
        "/add": (context) => const AddContactPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == "/update") {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => UpdateContactPage(
              docId: args['docId'],
              currentName: args['name'],
              currentPhone: args['phone'],
              currentEmail: args['email'],
            ),
          );
        }
        return null;
      },
    );
  }
}



class _InitializationErrorView extends StatelessWidget {
  final String message;

  const _InitializationErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: Color(0xFFE8896A),
              ),
              const SizedBox(height: 16),
              Text(
                "Contacts App",
                style: GoogleFonts.sora(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                  fontSize: 14,
                  color: const Color(0xFF5F5A57),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CheckUser extends StatefulWidget {
  const CheckUser({super.key});

  @override
  State<CheckUser> createState() => _CheckUserState();
}

class _CheckUserState extends State<CheckUser> {
  @override
  void initState() {
    super.initState();

    AuthService().isLoggedIn().then((value) {
      if (!mounted) return;
      if (value) {
        Navigator.pushReplacementNamed(context, "/home");
      } else {
        Navigator.pushReplacementNamed(context, "/login");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFF8F5),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE8896A),
        ),
      ),
    );
  }
}
