import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/main.dart';
import 'package:uzme/widgets/auth/glass_text_field.dart';

/// Register form content with glassmorphism design.
///
/// Phase E1: every new account is created with [BaseUserRole.client]
/// (Artiste). Studios / engineers switch role from Settings post-signup,
/// after seeing the role-comparison screen — that decouples "joining the
/// app" from "committing to a supplier role" and removes the friction
/// of an upfront role chip selector.
class RegisterFormContent extends StatefulWidget {
  const RegisterFormContent({super.key});

  @override
  State<RegisterFormContent> createState() => _RegisterFormContentState();
}

class _RegisterFormContentState extends State<RegisterFormContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  // Hard-coded — every signup creates a `client` user. See class docs.
  static const BaseUserRole _defaultRole = BaseUserRole.client;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoadingState;
        final isGoogleLoading = state is AuthGoogleLoadingState;
        final isAppleLoading = state is AuthAppleLoadingState;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              _buildHeader(l10n),
              const SizedBox(height: 24),
              _buildSocialButtons(isGoogleLoading, isAppleLoading),
              const SizedBox(height: 20),
              _buildDivider(l10n),
              const SizedBox(height: 20),
              _buildForm(isLoading, l10n),
              const SizedBox(height: 24),
              _buildLoginLink(l10n),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final iconColor = isDark ? Colors.white : cs.onSurface;
    final containerBg = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : cs.surfaceContainerHigh;
    final containerBg2 = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : cs.surfaceContainerHigh;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.3) : cs.outlineVariant;

    Widget iconContainer = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [containerBg, containerBg2],
              )
            : null,
        color: isDark ? null : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.white.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2)]
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Center(
        child: FaIcon(FontAwesomeIcons.userPlus, color: iconColor, size: 28),
      ),
    );

    return Column(
      children: [
        isDark
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: iconContainer,
                ),
              )
            : iconContainer,
        const SizedBox(height: 20),
        Text(
          l10n.createAccount,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : cs.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.joinCommunity,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white.withValues(alpha: 0.75) : cs.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons(bool isGoogleLoading, bool isAppleLoading) {
    return Row(
      children: [
        Expanded(
          child: GlassSocialButton(
            icon: FontAwesomeIcons.google,
            label: 'Google',
            isLoading: isGoogleLoading,
            onPressed: () => _socialSignIn('google'),
          ),
        ),
        if (Platform.isIOS) ...[
          const SizedBox(width: 16),
          Expanded(
            child: GlassSocialButton(
              icon: FontAwesomeIcons.apple,
              label: 'Apple',
              isLoading: isAppleLoading,
              onPressed: () => _socialSignIn('apple'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDivider(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final lineColor = isDark ? Colors.white.withValues(alpha: 0.3) : cs.outlineVariant;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.transparent, lineColor]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            l10n.orByEmail,
            style: TextStyle(
              color: isDark ? Colors.white.withValues(alpha: 0.6) : cs.onSurface.withValues(alpha: 0.5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [lineColor, Colors.transparent]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(bool isLoading, AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          GlassTextField(
            controller: _nameController,
            // Always artist signup at this stage — see _defaultRole.
            hint: l10n.stageNameOrName,
            prefixIcon: FontAwesomeIcons.user,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v?.isEmpty ?? true) return l10n.nameRequired;
              if (v!.length < 2) return l10n.minCharacters(2);
              return null;
            },
          ),
          const SizedBox(height: 16),
          GlassTextField(
            controller: _emailController,
            hint: l10n.emailHint,
            prefixIcon: FontAwesomeIcons.envelope,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v?.isEmpty ?? true) return l10n.emailRequired;
              if (!v!.contains('@')) return l10n.emailInvalid;
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildPasswordField(l10n),
          const SizedBox(height: 16),
          _buildConfirmField(l10n),
          const SizedBox(height: 24),
          GlassButton(
            label: l10n.createMyAccount,
            isLoading: isLoading,
            onPressed: _register,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return GlassTextField(
      controller: _passwordController,
      hint: l10n.passwordHint,
      prefixIcon: FontAwesomeIcons.lock,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      suffixIcon: IconButton(
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        icon: FaIcon(
          _obscurePassword ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
          size: 16,
          color: isDark ? Colors.white.withValues(alpha: 0.6) : cs.onSurfaceVariant,
        ),
      ),
      validator: (v) {
        if (v?.isEmpty ?? true) return l10n.passwordRequired;
        if (v!.length < 6) return l10n.minCharacters(6);
        return null;
      },
    );
  }

  Widget _buildConfirmField(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return GlassTextField(
      controller: _confirmController,
      hint: l10n.confirmPassword,
      prefixIcon: FontAwesomeIcons.lock,
      obscureText: _obscureConfirm,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _register(),
      suffixIcon: IconButton(
        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
        icon: FaIcon(
          _obscureConfirm ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
          size: 16,
          color: isDark ? Colors.white.withValues(alpha: 0.6) : cs.onSurfaceVariant,
        ),
      ),
      validator: (v) {
        if (v?.isEmpty ?? true) return l10n.confirmationRequired;
        if (v != _passwordController.text) return l10n.passwordsDontMatch;
        return null;
      },
    );
  }

  Widget _buildLoginLink(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.alreadyHaveAccount,
          style: TextStyle(
            color: isDark ? Colors.white.withValues(alpha: 0.75) : cs.onSurface.withValues(alpha: 0.6),
            fontSize: 15,
          ),
        ),
        TextButton(
          onPressed: () => context.pop(),
          style: TextButton.styleFrom(
            foregroundColor: isDark ? Colors.white : cs.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            l10n.signIn,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  void _register() {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    preferencesService.setSavedEmail(email);

    // Default role = client (Artiste). The user can later switch from
    // Settings → Comparateur de rôles. The `stageName` extra is set
    // because new accounts start as artists.
    context.read<AuthBloc>().add(SignUpWithEmailEvent(
          email: email,
          password: _passwordController.text,
          name: _nameController.text.trim(),
          role: _defaultRole,
          extraData: {'stageName': _nameController.text.trim()},
        ));
  }

  void _socialSignIn(String provider) {
    // Default role applied server-side via CompleteSocialSignUpEvent
    // dispatched from register_screen / login_screen on receipt of
    // AuthNeedsRoleSelectionState. Phase E1: that handler hard-codes
    // BaseUserRole.client.
    if (provider == 'google') {
      context.read<AuthBloc>().add(const SignInWithGoogleEvent());
    } else if (provider == 'apple') {
      context.read<AuthBloc>().add(const SignInWithAppleEvent());
    }
  }
}
