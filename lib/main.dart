import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode &&
      const bool.fromEnvironment('USE_EMULATORS', defaultValue: true)) {
    final host = defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
  }
  runApp(const CloudQuestApp());
}

class CloudQuestApp extends StatelessWidget {
  const CloudQuestApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Cloud Quest',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    ),
    home: StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Authentication unavailable.')),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == null
            ? const SignInPage()
            : QuestPage(user: snapshot.data!);
      },
    ),
  );
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false;
  String? error;
  Future<void> authenticate(bool register) async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => error = 'Enter an email and password.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (register) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => error = e.message ?? 'Authentication failed.');
      }
    } catch (_) {
      if (mounted) setState(() => error = 'Unable to connect. Try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cloud Quest')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.auto_awesome, size: 64),
            const SizedBox(height: 16),
            Text(
              'Welcome, adventurer!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: busy ? null : () => authenticate(false),
              child: const Text('Sign in'),
            ),
            OutlinedButton(
              onPressed: busy ? null : () => authenticate(true),
              child: const Text('Create account'),
            ),
            if (busy) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    ),
  );
}

class QuestPage extends StatefulWidget {
  final User user;
  const QuestPage({super.key, required this.user});
  @override
  State<QuestPage> createState() => _QuestPageState();
}

class _QuestPageState extends State<QuestPage> {
  final question = TextEditingController();
  bool busy = false;
  String? reply, status;
  DocumentReference<Map<String, dynamic>> get progress =>
      FirebaseFirestore.instance.doc('users/${widget.user.uid}/progress/today');
  Future<void> invoke(String name) async {
    if (busy) return;
    if (name == 'askQuestCoach' && question.text.trim().isEmpty) {
      setState(() => status = 'Enter a question first.');
      return;
    }
    setState(() {
      busy = true;
      status = null;
    });
    try {
      final result = await FirebaseFunctions.instance.httpsCallable(name).call(
        <String, dynamic>{
          if (name == 'askQuestCoach') 'question': question.text.trim(),
          if (name == 'completeToday') 'challengeId': 'today',
        },
      );
      if (!mounted) return;
      final data = Map<String, dynamic>.from(result.data as Map);
      setState(() {
        if (name == 'askQuestCoach') {
          reply = data['reply']?.toString() ?? 'No hint available.';
        } else {
          status = data['alreadyCompleted'] == true
              ? 'Already completed — your reward is safe!'
              : 'Quest completed! +10 points and First Quest badge.';
        }
      });
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        setState(
          () => status = 'Service unavailable (${e.code}). Please retry.',
        );
      }
    } catch (_) {
      if (mounted) setState(() => status = 'Unable to connect. Please retry.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    question.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Cloud Quest'),
      actions: [
        IconButton(
          tooltip: 'Sign out',
          onPressed: () async => FirebaseAuth.instance.signOut(),
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Signed in: ${widget.user.email ?? widget.user.uid}'),
        const SizedBox(height: 16),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .doc('challenges/today')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Unable to load today’s challenge.');
            }
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final data = snapshot.data!.data();
            if (data == null) {
              return const Text(
                'Today’s challenge is missing. Run the seed script.',
              );
            }
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title']?.toString() ?? 'Today’s Quest',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(data['prompt']?.toString() ?? ''),
                  ],
                ),
              ),
            );
          },
        ),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: progress.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Unable to load progress.');
            }
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final data = snapshot.data!.data();
            return Card(
              child: ListTile(
                title: Text('Points: ${data?['points'] ?? 0}'),
                subtitle: Text(
                  data?['completed'] == true
                      ? 'Badge: First Quest'
                      : 'Quest not completed',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text('Quest Coach', style: Theme.of(context).textTheme.titleLarge),
        TextField(
          controller: question,
          maxLength: 300,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Ask for a hint'),
        ),
        OutlinedButton(
          onPressed: busy ? null : () => invoke('askQuestCoach'),
          child: const Text('Get hint'),
        ),
        if (reply != null)
          Padding(padding: const EdgeInsets.all(12), child: Text(reply!)),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: busy ? null : () => invoke('completeToday'),
          child: const Text('Complete challenge'),
        ),
        if (status != null)
          Padding(padding: const EdgeInsets.all(12), child: Text(status!)),
        if (busy) const Center(child: CircularProgressIndicator()),
      ],
    ),
  );
}
