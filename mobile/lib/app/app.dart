import 'package:flutter/material.dart';

import 'app_config.dart';

const _appTitle = 'Cuentas Claras';
const _shellReadyMessage = 'Mobile shell ready';
const _signedOutMessage = 'Sign in to access your group';
const _configuredMessage =
    'Routing configuration is ready for the next integration slice.';

class App extends StatelessWidget {
  const App({super.key, this.config = AppConfig.fromEnvironment});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final statusMessage = config.hasRoutingConfiguration
        ? _configuredMessage
        : _signedOutMessage;

    return MaterialApp(
      title: _appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4338CA)),
        scaffoldBackgroundColor: const Color(0xFFFFF9F2),
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _appTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  const Text(_shellReadyMessage),
                  const SizedBox(height: 8),
                  Text(statusMessage),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
