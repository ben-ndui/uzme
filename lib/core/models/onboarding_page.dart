import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Model for an onboarding page content
class OnboardingPage extends Equatable {
  final String titleKey;
  final String descriptionKey;
  final FaIconData icon;
  final Color? iconColor;

  const OnboardingPage({
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    this.iconColor,
  });

  @override
  List<Object?> get props => [titleKey, descriptionKey, icon, iconColor];
}

/// Enum for onboarding phases
enum OnboardingPhase {
  content,
  locationPermission,
  notificationPermission,
  termsAcceptance,
}
