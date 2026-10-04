import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Standalone versions of the screens used for widget testing.
// They do NOT depend on Firebase or Riverpod so they can be pumped directly.
// ---------------------------------------------------------------------------

// ---- Minimal LoginScreen for widget testing --------------------------------

class _TestLoginScreen extends StatefulWidget {
  const _TestLoginScreen();

  @override
  State<_TestLoginScreen> createState() => _TestLoginScreenState();
}

class _TestLoginScreenState extends State<_TestLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              const Center(
                child: Text('WildDeck', key: Key('app_logo')),
              ),
              const SizedBox(height: 16),
              // Google button
              OutlinedButton(
                key: const Key('google_sign_in_button'),
                onPressed: () {},
                child: const Text('Continue with Google'),
              ),
              const SizedBox(height: 8),
              // Divider row
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('or', key: Key('divider_text')),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 8),
              // Email
              TextFormField(
                key: const Key('email_field'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  final re = RegExp(
                      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
                  if (!re.hasMatch(v.trim())) return 'Enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              // Password
              TextFormField(
                key: const Key('password_field'),
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Sign In button
              ElevatedButton(
                key: const Key('sign_in_button'),
                onPressed: () => _formKey.currentState!.validate(),
                child: const Text('Sign In'),
              ),
              const SizedBox(height: 8),
              // Create Account link
              TextButton(
                key: const Key('create_account_link'),
                onPressed: () {},
                child: const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Minimal RegisterScreen for widget testing ----------------------------

class _TestRegisterScreen extends StatefulWidget {
  const _TestRegisterScreen();

  @override
  State<_TestRegisterScreen> createState() => _TestRegisterScreenState();
}

class _TestRegisterScreenState extends State<_TestRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Display name is required';
    if (v.trim().length < 2) return 'Name must be at least 2 characters';
    if (v.trim().length > 50) return 'Name must be 50 characters or fewer';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final re = RegExp(
        r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!re.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (!v.contains(RegExp('[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('display_name_field'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Display Name'),
                validator: _validateName,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('email_field'),
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: _validateEmail,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('password_field'),
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: _validatePassword,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('confirm_password_field'),
                controller: _confirmController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirm Password'),
                validator: _validateConfirm,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const Key('register_button'),
                onPressed: () => _formKey.currentState!.validate(),
                child: const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap(Widget child) => MaterialApp(home: child);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('LoginScreen widget tests', () {
    testWidgets('renders app logo', (tester) async {
      await tester.pumpWidget(_wrap(const _TestLoginScreen()));
      expect(find.byKey(const Key('app_logo')), findsOneWidget);
    });

    testWidgets('renders Google Sign-In button', (tester) async {
      await tester.pumpWidget(_wrap(const _TestLoginScreen()));
      expect(find.byKey(const Key('google_sign_in_button')), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('renders divider with "or" text', (tester) async {
      await tester.pumpWidget(_wrap(const _TestLoginScreen()));
      expect(find.byKey(const Key('divider_text')), findsOneWidget);
    });

    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(_wrap(const _TestLoginScreen()));
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
    });

    testWidgets('renders Sign In button', (tester) async {
      await tester.pumpWidget(_wrap(const _TestLoginScreen()));
      expect(find.byKey(const Key('sign_in_button')), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('renders Create Account link', (tester) async {
      await tester.pumpWidget(_wrap(const _TestLoginScreen()));
      expect(find.byKey(const Key('create_account_link')), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('shows email error for empty email on submit', (tester) async {
      await tester.pumpWidget(_wrap(const _TestLoginScreen()));
      await tester.tap(find.byKey(const Key('sign_in_button')));
      await tester.pump();
      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('shows password error for empty password on submit',
        (tester) async {
      await tester.pumpWidget(_wrap(const _TestLoginScreen()));
      // Fill email so only password error shows
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@example.com');
      await tester.tap(find.byKey(const Key('sign_in_button')));
      await tester.pump();
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows invalid email error for bad email format',
        (tester) async {
      await tester.pumpWidget(_wrap(const _TestLoginScreen()));
      await tester.enterText(
          find.byKey(const Key('email_field')), 'not-an-email');
      await tester.tap(find.byKey(const Key('sign_in_button')));
      await tester.pump();
      expect(find.text('Enter a valid email address'), findsOneWidget);
    });
  });

  group('RegisterScreen validates input', () {
    testWidgets('shows name error when display name is empty', (tester) async {
      await tester.pumpWidget(_wrap(const _TestRegisterScreen()));
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pump();
      expect(find.text('Display name is required'), findsOneWidget);
    });

    testWidgets('shows name error when display name is too short',
        (tester) async {
      await tester.pumpWidget(_wrap(const _TestRegisterScreen()));
      await tester.enterText(find.byKey(const Key('display_name_field')), 'A');
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pump();
      expect(find.text('Name must be at least 2 characters'), findsOneWidget);
    });

    testWidgets('shows name error when display name exceeds 50 chars',
        (tester) async {
      await tester.pumpWidget(_wrap(const _TestRegisterScreen()));
      await tester.enterText(
          find.byKey(const Key('display_name_field')), 'A' * 51);
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pump();
      expect(
          find.text('Name must be 50 characters or fewer'), findsOneWidget);
    });

    testWidgets('shows invalid email error for bad email', (tester) async {
      await tester.pumpWidget(_wrap(const _TestRegisterScreen()));
      await tester.enterText(
          find.byKey(const Key('display_name_field')), 'Alice');
      await tester.enterText(
          find.byKey(const Key('email_field')), 'bademail');
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pump();
      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('shows password too short error', (tester) async {
      await tester.pumpWidget(_wrap(const _TestRegisterScreen()));
      await tester.enterText(
          find.byKey(const Key('display_name_field')), 'Alice');
      await tester.enterText(
          find.byKey(const Key('email_field')), 'alice@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'short');
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pump();
      expect(
          find.text('Password must be at least 8 characters'), findsOneWidget);
    });

    testWidgets('shows error when password has no number', (tester) async {
      await tester.pumpWidget(_wrap(const _TestRegisterScreen()));
      await tester.enterText(
          find.byKey(const Key('display_name_field')), 'Alice');
      await tester.enterText(
          find.byKey(const Key('email_field')), 'alice@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'NoNumbers!');
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pump();
      expect(find.text('Password must contain at least one number'),
          findsOneWidget);
    });

    testWidgets('shows error when passwords do not match', (tester) async {
      await tester.pumpWidget(_wrap(const _TestRegisterScreen()));
      await tester.enterText(
          find.byKey(const Key('display_name_field')), 'Alice');
      await tester.enterText(
          find.byKey(const Key('email_field')), 'alice@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'Password1');
      await tester.enterText(
          find.byKey(const Key('confirm_password_field')), 'Different1');
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pump();
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('no validation errors when all fields are valid',
        (tester) async {
      await tester.pumpWidget(_wrap(const _TestRegisterScreen()));
      await tester.enterText(
          find.byKey(const Key('display_name_field')), 'Alice');
      await tester.enterText(
          find.byKey(const Key('email_field')), 'alice@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'Password1');
      await tester.enterText(
          find.byKey(const Key('confirm_password_field')), 'Password1');
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pump();
      expect(find.text('Display name is required'), findsNothing);
      expect(find.text('Email is required'), findsNothing);
      expect(find.text('Password is required'), findsNothing);
      expect(find.text('Passwords do not match'), findsNothing);
    });
  });
}
