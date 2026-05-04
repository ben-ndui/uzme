import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uzme/core/models/pioneer_program.dart';
import 'package:uzme/main.dart' show pioneerService;

/// SuperAdmin screen — full detail of a Pioneer cohort. Streams the
/// program doc for live status changes, fetches a leaderboard preview
/// on demand, and exposes the distribute / archive / activate actions.
class PioneerProgramDetailScreen extends StatefulWidget {
  final String programId;
  const PioneerProgramDetailScreen({super.key, required this.programId});

  @override
  State<PioneerProgramDetailScreen> createState() =>
      _PioneerProgramDetailScreenState();
}

class _PioneerProgramDetailScreenState
    extends State<PioneerProgramDetailScreen> {
  Future<List<PioneerLeaderboardEntry>>? _leaderboardFuture;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cohort Pioneer')),
      body: FutureBuilder<PioneerProgram?>(
        future: pioneerService.fetchProgram(widget.programId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final program = snapshot.data;
          if (program == null) {
            return const Center(child: Text('Cohort introuvable'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Header(program: program),
              const SizedBox(height: 16),
              _ConfigCard(program: program),
              const SizedBox(height: 16),
              _LeaderboardSection(
                programId: program.id,
                future: _leaderboardFuture,
                onRefresh: () => setState(() {
                  _leaderboardFuture =
                      pioneerService.previewLeaderboard(program.id, limit: 30);
                }),
              ),
              const SizedBox(height: 24),
              _Actions(
                program: program,
                busy: _busy,
                onActivate: () => _activate(program),
                onDistribute: () => _distribute(program),
                onArchive: () => _archive(program),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _activate(PioneerProgram program) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await pioneerService.updateProgram(
        program.id,
        status: PioneerProgramStatus.active,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Programme activé')),
      );
      if (mounted) setState(() {});
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _distribute(PioneerProgram program) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await _confirmDialog(
      title: 'Distribuer maintenant ?',
      message:
          'Les ${program.targetCount} meilleurs scores recevront le badge Pioneer. '
          'Cette action est irréversible.',
      confirmLabel: 'Distribuer',
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      final count = await pioneerService.distributeProgram(program.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text('$count Pioneers distribués 🚀'),
          backgroundColor: Colors.green,
        ),
      );
      if (mounted) setState(() {});
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _archive(PioneerProgram program) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await _confirmDialog(
      title: 'Archiver le cohort ?',
      message:
          'Le cohort sera marqué comme archivé. Les badges déjà distribués '
          'sont conservés sur les utilisateurs.',
      confirmLabel: 'Archiver',
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await pioneerService.archiveProgram(program.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Cohort archivé')),
      );
      if (mounted) setState(() {});
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }
}

class _Header extends StatelessWidget {
  final PioneerProgram program;
  const _Header({required this.program});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('d MMMM yyyy', 'fr_FR');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(program.name, style: theme.textTheme.headlineSmall),
        if (program.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            program.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            _StatusPill(status: program.status),
            const SizedBox(width: 8),
            Text(
              'Échéance ${df.format(program.deadline)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final PioneerProgramStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      PioneerProgramStatus.draft => ('Brouillon', Colors.grey),
      PioneerProgramStatus.active => ('Actif', Colors.green),
      PioneerProgramStatus.distributed => ('Distribué', Colors.blue),
      PioneerProgramStatus.archived => ('Archivé', Colors.orange),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  final PioneerProgram program;
  const _ConfigCard({required this.program});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _RowItem(label: 'Top N', value: '${program.targetCount}'),
            _RowItem(
              label: 'Pondérations',
              value: 'sessions×${program.weights.confirmedSessions} · '
                  'messages×${program.weights.messagesSent} · '
                  'jours×${program.weights.activeDays}',
            ),
            if (program.distributedAt != null)
              _RowItem(
                label: 'Distribué',
                value:
                    '${program.distributedCount ?? 0} Pioneers le ${DateFormat('d MMM yyyy', 'fr_FR').format(program.distributedAt!)}',
              ),
          ],
        ),
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final String value;
  const _RowItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _LeaderboardSection extends StatelessWidget {
  final String programId;
  final Future<List<PioneerLeaderboardEntry>>? future;
  final VoidCallback onRefresh;

  const _LeaderboardSection({
    required this.programId,
    required this.future,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Top 30 — preview live',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 16),
                  tooltip: 'Recalculer',
                  onPressed: onRefresh,
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (future == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Tap ↻ pour calculer le classement',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              )
            else
              FutureBuilder<List<PioneerLeaderboardEntry>>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: LinearProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Erreur : ${snapshot.error}',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    );
                  }
                  final entries = snapshot.data ?? const [];
                  if (entries.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Aucun utilisateur éligible pour l\'instant',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: entries
                        .map((e) => _LeaderboardRow(entry: e))
                        .toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final PioneerLeaderboardEntry entry;
  const _LeaderboardRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name, style: theme.textTheme.bodyMedium),
                Text(
                  '${entry.confirmedSessions} sessions · ${entry.messagesSent} msg · ${entry.activeDays} jours',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.score}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final PioneerProgram program;
  final bool busy;
  final VoidCallback onActivate;
  final VoidCallback onDistribute;
  final VoidCallback onArchive;

  const _Actions({
    required this.program,
    required this.busy,
    required this.onActivate,
    required this.onDistribute,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        if (program.status == PioneerProgramStatus.draft)
          FilledButton.icon(
            onPressed: busy ? null : onActivate,
            icon: const FaIcon(FontAwesomeIcons.play, size: 14),
            label: const Text('Activer'),
          ),
        if (program.status == PioneerProgramStatus.draft ||
            program.status == PioneerProgramStatus.active)
          FilledButton.icon(
            onPressed: busy ? null : onDistribute,
            icon: const FaIcon(FontAwesomeIcons.rocket, size: 14),
            label: const Text('Distribuer maintenant'),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
          ),
        if (program.status != PioneerProgramStatus.archived)
          OutlinedButton.icon(
            onPressed: busy ? null : onArchive,
            icon: const FaIcon(FontAwesomeIcons.boxArchive, size: 14),
            label: const Text('Archiver'),
          ),
      ],
    );
  }
}
