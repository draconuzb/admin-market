import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user.dart';
import '../../providers.dart';

enum AuthStatus { unknown, unauthenticated, pending, authenticated }

class AuthState {
  const AuthState(this.status, [this.user]);
  final AuthStatus status;
  final AppUser? user;

  bool get isLoggedIn => status == AuthStatus.authenticated || status == AuthStatus.pending;
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Kick off session restore AFTER build completes — scheduling with a
    // microtask avoids mutating state during build (which Riverpod forbids and
    // would otherwise leave the app stuck on the splash screen).
    Future.microtask(_restore);
    return const AuthState(AuthStatus.unknown);
  }

  Future<void> _restore() async {
    final storage = ref.read(tokenStorageProvider);
    if (!storage.hasSession) {
      state = const AuthState(AuthStatus.unauthenticated);
      return;
    }
    await refreshUser();
  }

  /// Fetches /auth/me and maps status to the auth state.
  Future<void> refreshUser() async {
    try {
      final user = await ref.read(authRepositoryProvider).me();
      state = AuthState(
        user.isActive ? AuthStatus.authenticated : AuthStatus.pending,
        user,
      );
    } catch (_) {
      await ref.read(tokenStorageProvider).clear();
      state = const AuthState(AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String phone, String password) async {
    final (access, refreshToken) = await ref.read(authRepositoryProvider).login(phone, password);
    await ref.read(tokenStorageProvider).saveTokens(access, refreshToken);
    await refreshUser();
  }

  void markLoggedOut() {
    state = const AuthState(AuthStatus.unauthenticated);
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AuthState(AuthStatus.unauthenticated);
  }
}
