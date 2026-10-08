import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../providers/providers.dart';

bool redirectIfSignedOut(BuildContext context) {
  if (context.read<AuthProvider>().isAuthenticated) return false;
  context.go(AppRoutes.welcome);
  return true;
}
