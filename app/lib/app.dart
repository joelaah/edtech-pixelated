import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bitwise_academy/core/di/injection.dart';
import 'package:bitwise_academy/core/router/app_router.dart';
import 'package:bitwise_academy/core/theme/app_theme.dart';
import 'package:bitwise_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bitwise_academy/features/exam_library/presentation/bloc/exam_bloc.dart';
import 'package:bitwise_academy/features/exam_library/presentation/bloc/attempt_bloc.dart';

/// Root application widget.
///
/// Provides the [AuthBloc] at the top of the widget tree so that
/// the router redirect can read auth state, and all child pages
/// can access it.
class RimsApp extends StatefulWidget {
  const RimsApp({super.key});

  @override
  State<RimsApp> createState() => _RimsAppState();
}

class _RimsAppState extends State<RimsApp> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>()..add(const AuthCheckRequested());
    _router = buildRouter(_authBloc);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<ExamBloc>(
          create: (_) => getIt<ExamBloc>()..add(const LoadExamsRequested()),
        ),
        BlocProvider<AttemptBloc>(
          create: (_) => getIt<AttemptBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'RIMS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
