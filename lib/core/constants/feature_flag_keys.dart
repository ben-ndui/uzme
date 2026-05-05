/// Centralised catalogue of every feature flag the uzme code expects to
/// resolve. Two purposes:
///
/// 1. Code surfaces import these constants instead of magic strings:
///    ```dart
///    if (featureFlagsService.isEnabled(user, FeatureFlagKeys.aiAssistant.key))
///    ```
///    Renames are picked up by the compiler, typos can't compile, and the
///    catalogue is the single source of truth for "what flag keys exist".
///
/// 2. The admin UI (FeatureFlagEditSheet) reads [FeatureFlagKeys.all] to
///    show a dropdown selector — admins pick a known spec and the form
///    pre-fills key/title/description/category. They can still type a
///    custom key for flags pending future features.
///
/// When you add a new gated feature in the code, register its spec here
/// AND wrap the call site with `featureFlagsService.isEnabled(...)`.
class FeatureFlagSpec {
  final String key;
  final String title;
  final String description;
  final String category;
  const FeatureFlagSpec({
    required this.key,
    required this.title,
    required this.description,
    required this.category,
  });
}

class FeatureFlagKeys {
  FeatureFlagKeys._();

  // ===== AI =====

  static const aiAssistant = FeatureFlagSpec(
    key: 'ai_assistant',
    title: 'AI Assistant',
    description:
        'Chat AI Claude pour conseils et brainstorming. Coût Anthropic API.',
    category: 'ai',
  );

  static const aiAssistantPro = FeatureFlagSpec(
    key: 'ai_assistant_pro',
    title: 'AI Assistant Pro',
    description:
        'Quotas étendus et fonctionnalités avancées du chat AI '
        '(historique, suggestions, fine-tuning prompts).',
    category: 'ai',
  );

  // ===== Premium / Payments =====

  static const stripeConnectOnboarding = FeatureFlagSpec(
    key: 'stripe_connect_onboarding',
    title: 'Stripe Connect studios',
    description:
        'Onboarding Stripe Connect pour studios partenaires. Sensible '
        'côté App Review Apple.',
    category: 'premium',
  );

  static const calendarGoogleSync = FeatureFlagSpec(
    key: 'calendar_google_sync',
    title: 'Sync Google Calendar',
    description:
        'OAuth + sync bidirectionnel avec Google Calendar du studio. '
        'Candidat tier premium.',
    category: 'premium',
  );

  static const digitalCard = FeatureFlagSpec(
    key: 'digital_card',
    title: 'Carte digitale + QR',
    description:
        'Cartes digitales partageables + scanner QR. Feature secondaire, '
        'beta candidate.',
    category: 'premium',
  );

  // ===== Marketplace =====

  static const proProfile = FeatureFlagSpec(
    key: 'pro_profile',
    title: 'Pro profile (marketplace)',
    description:
        'Profils freelance pour ingénieurs, marketplace de services. '
        'Module entier, beta candidate.',
    category: 'marketplace',
  );

  static const teamManagement = FeatureFlagSpec(
    key: 'team_management',
    title: 'Team management',
    description:
        'Multi-équipe pour studios + assignation engineers. Studios '
        'avancés.',
    category: 'marketplace',
  );

  static const autoPublishInsta = FeatureFlagSpec(
    key: 'auto_publish_insta',
    title: 'Auto-publish Instagram',
    description:
        'Publication automatique IG depuis le calendar. Bloqué App '
        'Review Meta — démarrage en Pioneer-only.',
    category: 'marketplace',
  );

  // ===== Discovery / Social =====

  static const favorites = FeatureFlagSpec(
    key: 'favorites',
    title: 'Favoris',
    description: 'Sauvegarder studios / engineers / artists en favoris.',
    category: 'social',
  );

  static const networkScreen = FeatureFlagSpec(
    key: 'network_screen',
    title: 'Network / community',
    description: 'Écran network — fil communautaire entre users.',
    category: 'social',
  );

  static const discoverMap = FeatureFlagSpec(
    key: 'discover_map',
    title: 'Map de discovery globale',
    description: 'Discovery cross-radius. Si on veut limiter par version.',
    category: 'social',
  );

  // ===== Workflow avancés =====

  static const engineerAvailability = FeatureFlagSpec(
    key: 'engineer_availability',
    title: 'Engineer availability',
    description: 'Calendrier de disponibilité côté engineer (workflow avancé).',
    category: 'workflow',
  );

  static const notificationsAdvanced = FeatureFlagSpec(
    key: 'notifications_advanced',
    title: 'Notifs avancées',
    description:
        'Banners in-app, deep-links riches, regroupements. Différencie de '
        'la stack basic.',
    category: 'workflow',
  );

  /// Liste plate de toutes les specs — utilisée par l'admin UI pour
  /// proposer un dropdown selector au moment de la création.
  static const all = <FeatureFlagSpec>[
    aiAssistant,
    aiAssistantPro,
    stripeConnectOnboarding,
    calendarGoogleSync,
    digitalCard,
    proProfile,
    teamManagement,
    autoPublishInsta,
    favorites,
    networkScreen,
    discoverMap,
    engineerAvailability,
    notificationsAdvanced,
  ];

  /// Lookup une spec par sa clé technique. Renvoie null si la clé n'est
  /// pas dans le catalogue (= flag créé custom par l'admin pour une
  /// feature pas encore codée, ou flag legacy).
  static FeatureFlagSpec? lookup(String key) {
    for (final spec in all) {
      if (spec.key == key) return spec;
    }
    return null;
  }

  /// True si la clé fait partie du catalogue. Sert au "Catalogué" badge
  /// dans la list view admin.
  static bool isCatalogued(String key) => lookup(key) != null;
}
