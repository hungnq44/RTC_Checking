import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rtc_checking/route/route_name.dart';

import '../features/checking/view/bloc/checking_bloc.dart';
import '../features/checking/view/pages/checking_screen.dart';
import '../injection.dart';

class RouteApp {
  static final router = GoRouter(
    initialLocation: RouteName.checkingScreen,
    routes: [
      //---(Checking)---//
      ShellRoute(
        builder: (context, state, child) {
          return BlocProvider.value(value: getIt<CheckingBloc>(), child: child);
        },
        routes: [
          GoRoute(
            path: RouteName.checkingScreen,
            builder: (context, state) => const CheckingScreen(),
          ),
        ],
      ),
    ],
  );
}
