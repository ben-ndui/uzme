import 'package:flutter/material.dart';

/// Sélecteur de durée de session, en heures (1 à 8h).
class SessionDurationSelector extends StatelessWidget {
  static const List<int> hoursOptions = [1, 2, 3, 4, 6, 8];

  final int selectedHours;
  final ValueChanged<int> onChanged;

  const SessionDurationSelector({
    super.key,
    required this.selectedHours,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: hoursOptions.map((hours) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text('${hours}h'),
            selected: selectedHours == hours,
            onSelected: (_) => onChanged(hours),
          ),
        );
      }).toList(),
    );
  }
}
