import 'package:flutter/material.dart';
import 'package:nullbyte/core/theme/app_theme.dart';
import 'package:nullbyte/features/active_session/domain/command_registry.dart';

/// Bar horizontal berisi suggestion command dan navigasi history.
class CommandSuggestions extends StatelessWidget {
  const CommandSuggestions({
    super.key,
    required this.registry,
    required this.currentInput,
    required this.onSuggestionTap,
    required this.onHistoryPrev,
    required this.onHistoryNext,
  });

  final CommandRegistry registry;
  final String currentInput;
  final ValueChanged<String> onSuggestionTap;
  final VoidCallback onHistoryPrev;
  final VoidCallback onHistoryNext;

  @override
  Widget build(BuildContext context) {
    final prefix = currentInput.trim().split(' ').first;
    final suggestions = registry.getSuggestions(prefix);

    return Container(
      height: 36,
      color: AppTheme.surfaceContainerLow,
      child: Row(
        children: [
          _NavButton(icon: Icons.keyboard_arrow_up, onTap: onHistoryPrev),
          _NavButton(icon: Icons.keyboard_arrow_down, onTap: onHistoryNext),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: AppTheme.outlineVariant,
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                return _SuggestionChip(
                  label: suggestions[index],
                  onTap: () => onSuggestionTap(suggestions[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: Icon(icon, size: 18, color: AppTheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: const BoxDecoration(color: AppTheme.surfaceContainerHigh),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 11,
            color: AppTheme.primaryContainer,
          ),
        ),
      ),
    );
  }
}
