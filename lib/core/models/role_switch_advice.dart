import 'package:equatable/equatable.dart';
import 'package:smoothandesign_package/smoothandesign.dart';

/// Advice returned by the `getRoleSwitchAdvice` callable. Maps the
/// strict-JSON response from Claude into a typed object the UI can
/// render directly.
class RoleSwitchAdvice extends Equatable {
  /// The role the AI recommends. Always one of the 3 switchable roles
  /// (`client`/`admin`/`worker`).
  final BaseUserRole recommendedRole;

  /// True when [recommendedRole] equals [currentRole]. The UI uses this
  /// to render a green "Tu es bien placé" callout instead of a switch
  /// CTA — semantically distinct from "AI failed to suggest anything".
  final bool staying;

  /// The user's role at the moment the advice was computed. Useful for
  /// the UI when [staying] is false to pair "from X to Y" copy.
  final BaseUserRole currentRole;

  /// 2-3 sentence personalized reasoning. Already trimmed server-side
  /// to <= 600 chars.
  final String reasoning;

  /// Up to 3 short bullet points (<= 80 chars each) summarizing the
  /// reasons. May be empty when the deterministic fallback fires.
  final List<String> highlights;

  const RoleSwitchAdvice({
    required this.recommendedRole,
    required this.staying,
    required this.currentRole,
    required this.reasoning,
    this.highlights = const [],
  });

  factory RoleSwitchAdvice.fromMap(Map<String, dynamic> map) {
    return RoleSwitchAdvice(
      recommendedRole: _roleFromKey(map['recommendedRole']?.toString()) ??
          BaseUserRole.client,
      staying: map['staying'] == true,
      currentRole: _roleFromKey(map['currentRole']?.toString()) ??
          BaseUserRole.client,
      reasoning: (map['reasoning'] ?? '').toString(),
      highlights: (map['highlights'] as List? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }

  static BaseUserRole? _roleFromKey(String? key) {
    if (key == null) return null;
    for (final r in BaseUserRole.values) {
      if (r.name == key) return r;
    }
    return null;
  }

  @override
  List<Object?> get props =>
      [recommendedRole, staying, currentRole, reasoning, highlights];
}
