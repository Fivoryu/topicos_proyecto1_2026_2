import 'dart:async';

import 'package:flutter/material.dart';

import '../data/auth/auth_repository.dart';
import '../data/auth/auth_transport.dart';
import '../data/repositories/group_repository.dart';
import '../presentation/auth/session_cubit.dart';
import '../presentation/group/group_cubit.dart';
import '../presentation/group/group_screen.dart';
import 'app_config.dart';

const _appTitle = 'Cuentas Claras';

typedef GroupCubitFactory = GroupCubit Function(String groupId);

/// Composition root for the authenticated first mobile slice.
///
/// Production builds use [AppConfig.fromEnvironment] and create the transport,
/// repositories, and cubits here. Widget tests can inject a [SessionCubit] and
/// [GroupReader] so they never need secure storage or a live API.
class App extends StatefulWidget {
  const App({
    super.key,
    this.config = AppConfig.fromEnvironment,
    this.authTransport,
    this.authRepository,
    this.sessionCubit,
    this.groupReader,
    this.groupCubitFactory,
  });

  final AppConfig config;
  final AuthTransport? authTransport;
  final AuthRepository? authRepository;
  final SessionCubit? sessionCubit;
  final GroupReader? groupReader;
  final GroupCubitFactory? groupCubitFactory;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  SessionCubit? _sessionCubit;
  GroupCubitFactory? _groupCubitFactory;
  AuthTransport? _ownedTransport;
  StreamSubscription<SessionState>? _sessionSubscription;
  GroupCubit? _groupCubit;
  String? _groupCubitId;
  var _ownsSessionCubit = false;

  @override
  void initState() {
    super.initState();
    _composeDependencies();
    final sessionCubit = _sessionCubit;
    if (sessionCubit == null) return;

    _sessionSubscription = sessionCubit.stream.listen(_onSessionChanged);
    unawaited(sessionCubit.restoreSession());
  }

  void _composeDependencies() {
    final configured = widget.config.hasRoutingConfiguration;
    final transport =
        widget.authTransport ??
        (configured ? AuthTransport(baseUrl: widget.config.apiBaseUrl) : null);
    if (widget.authTransport == null && transport != null) {
      _ownedTransport = transport;
    }

    _sessionCubit = widget.sessionCubit;
    if (_sessionCubit == null) {
      final repository =
          widget.authRepository ??
          (transport == null ? null : AuthRepository.fromTransport(transport));
      if (repository != null) {
        _sessionCubit = SessionCubit(repository: repository);
        _ownsSessionCubit = true;
      }
    }

    _groupCubitFactory = widget.groupCubitFactory;
    if (_groupCubitFactory == null && widget.groupReader != null) {
      final reader = widget.groupReader!;
      _groupCubitFactory = (groupId) =>
          GroupCubit(reader: reader, groupId: groupId);
    }
    if (_groupCubitFactory == null && transport != null) {
      final reader = GroupRepository.fromTransport(transport);
      _groupCubitFactory = (groupId) =>
          GroupCubit(reader: reader, groupId: groupId);
    }
  }

  void _onSessionChanged(SessionState state) {
    if (state.status != SessionStatus.authenticated) {
      _disposeGroupCubit();
    }
    if (mounted) setState(() {});
  }

  GroupCubit? _groupCubitFor(String? groupId) {
    final normalizedGroupId = groupId?.trim();
    if (_groupCubit != null && _groupCubitId == normalizedGroupId) {
      return _groupCubit;
    }
    _disposeGroupCubit();
    final factory = _groupCubitFactory;
    if (factory == null ||
        normalizedGroupId == null ||
        normalizedGroupId.isEmpty) {
      return null;
    }
    final cubit = factory(normalizedGroupId);
    _groupCubit = cubit;
    _groupCubitId = normalizedGroupId;
    return cubit;
  }

  void _disposeGroupCubit() {
    final cubit = _groupCubit;
    _groupCubit = null;
    _groupCubitId = null;
    if (cubit != null) unawaited(cubit.close());
  }

  Widget _home() {
    final sessionCubit = _sessionCubit;
    if (sessionCubit == null) return const _ConfigurationScreen();

    final state = sessionCubit.state;
    return switch (state.status) {
      SessionStatus.unknown => const _LoadingScreen(),
      SessionStatus.authenticating => _LoginScreen(
        sessionCubit: sessionCubit,
        isSubmitting: true,
        errorMessage: state.errorMessage,
      ),
      SessionStatus.signedOut => _LoginScreen(
        sessionCubit: sessionCubit,
        errorMessage: state.errorMessage,
      ),
      SessionStatus.sessionExpired => _LoginScreen(
        sessionCubit: sessionCubit,
        errorMessage: 'Your session expired. Please sign in again.',
      ),
      SessionStatus.authenticated => _AuthenticatedScreen(
        role: state.role ?? 'unknown',
        groupCubit: _groupCubitFor(state.activeGroupId),
        onLogout: sessionCubit.logout,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4338CA)),
        scaffoldBackgroundColor: const Color(0xFFFFF9F2),
        useMaterial3: true,
      ),
      home: _home(),
    );
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _disposeGroupCubit();
    if (_ownsSessionCubit) unawaited(_sessionCubit?.close());
    _ownedTransport?.dio.close(force: true);
    super.dispose();
  }
}

class _ConfigurationScreen extends StatelessWidget {
  const _ConfigurationScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Mobile configuration is missing. Provide API_BASE_URL and GROUP_ID.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Restoring session…'),
          ],
        ),
      ),
    ),
  );
}

class _LoginScreen extends StatefulWidget {
  const _LoginScreen({
    required this.sessionCubit,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final SessionCubit sessionCubit;
  final bool isSubmitting;
  final String? errorMessage;

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginNameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _loginNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    unawaited(
      widget.sessionCubit.login(
        loginName: _loginNameController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _appTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to access your group',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _loginNameController,
                    enabled: !widget.isSubmitting,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Login name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter your login name.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !widget.isSubmitting,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: widget.isSubmitting
                        ? null
                        : (_) => _submit(),
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your password.'
                        : null,
                  ),
                  if (widget.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        widget.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: widget.isSubmitting ? null : _submit,
                    child: widget.isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _AuthenticatedScreen extends StatelessWidget {
  const _AuthenticatedScreen({
    required this.role,
    required this.groupCubit,
    required this.onLogout,
  });

  final String role;
  final GroupCubit? groupCubit;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(_appTitle),
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('Role: $role'),
          ),
        ),
        TextButton(onPressed: onLogout, child: const Text('Log out')),
      ],
    ),
    body: groupCubit == null
        ? const _ConfigurationScreen()
        : GroupScreen(cubit: groupCubit!),
  );
}
