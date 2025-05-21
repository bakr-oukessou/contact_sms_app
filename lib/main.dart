import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'models/contact_model.dart';

import 'services/firebase_service.dart';
import 'services/contact_service.dart';
import 'services/sms_service.dart';
import 'services/favorites_service.dart';
import 'services/sync_service.dart';

import 'views/contacts_view.dart';
import 'views/sms_view.dart';
import 'views/favorites_view.dart';
import 'views/backup_restore_view.dart';
import 'views/contact_detail_view.dart';
import 'views/auth_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  runApp(
    MultiProvider(
      providers: [
      ChangeNotifierProvider<FirebaseService>(create: (_) => FirebaseService()),
      ChangeNotifierProvider<ContactService>(create: (_) => ContactService()),
      ChangeNotifierProvider<SmsService>(create: (_) => SmsService()),
      ChangeNotifierProvider<FavoritesService>(create: (_) => FavoritesService()),
      ChangeNotifierProvider<SyncService>(create: (_) => SyncService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contacts & SMS Backup',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      initialRoute: '/auth', // <-- Change this from '/auth' to '/home'
      routes: {
        '/auth': (context) => const AuthView(),
        '/home': (context) => const HomeView(),
        '/contacts': (context) => const ContactsView(),
        '/sms': (context) => const SmsView(),
        '/favorites': (context) => const FavoritesView(),
        '/backup': (context) => const BackupRestoreView(),
        '/contact-details': (context) {
          final contact = ModalRoute.of(context)!.settings.arguments as Contact;
          return ContactDetailView(contact: contact);
        },
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const ContactsView(),
    const SmsView(),
    const FavoritesView(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    final userId = firebaseService.getCurrentUser()?.uid;
    if (userId != null) {
      try {
        // Initialize services
        await Provider.of<ContactService>(context, listen: false).initializeUserData(userId);
        await Provider.of<SmsService>(context, listen: false).initializeUserData(userId);
        
        // Load data
        await Provider.of<ContactService>(context, listen: false).syncContacts(userId);
        await Provider.of<SmsService>(context, listen: false).syncSms(userId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error initializing data: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts & SMS Backup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: () => Navigator.pushNamed(context, '/backup'),
            tooltip: 'Backup/Restore',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'SMS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await Provider.of<FirebaseService>(context, listen: false).signOut();
      Navigator.pushReplacementNamed(context, '/auth');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: $e')),
      );
    }
  }
}

// class AuthView extends StatelessWidget {
//   const AuthView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               'Contacts & SMS Backup',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 40),
//             Image.asset('assets/images/backup.png', width: 150),
//             const SizedBox(height: 40),
//             const Text('Sign in with Google to continue'),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () async {
//                 final user = await AuthService().signInWithGoogle();
//                 if (user != null) {
//                   Navigator.pushReplacementNamed(context, '/home');
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Sign in failed')),
//                   );
//                 }
//               },
//               child: Text('Sign in with Google'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _signInWithGoogle(BuildContext context) async {
//     try {
//       final user = await Provider.of<FirebaseService>(context, listen: false)
//           .signInWithGoogle();
//       print('Signed in user: $user');
//       if (user != null) {
//         // Initialize services after login
//         await Provider.of<ContactService>(context, listen: false)
//             .getDeviceContacts();
//         await Provider.of<SmsService>(context, listen: false).getDeviceSms();
//         await Provider.of<FavoritesService>(context, listen: false)
//             .getAllFavorites();
//         Navigator.pushReplacementNamed(context, '/home');
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Google sign-in failed.')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Sign in failed: $e')),
//       );
//     }
//   }
// }