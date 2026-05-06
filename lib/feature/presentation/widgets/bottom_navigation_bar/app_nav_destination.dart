import 'package:flutter/material.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

typedef AppNavDestinationLabelBuilder = String Function(AppLocalizations l10n);

class AppNavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final AppNavDestinationLabelBuilder labelBuilder;

  const AppNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.labelBuilder,
  });

  static const items = <AppNavDestination>[
    AppNavDestination(
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder,
      labelBuilder: _notesLabel,
    ),
    AppNavDestination(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      labelBuilder: _settingsLabel,
    ),
  ];

  static String _notesLabel(AppLocalizations l10n) => l10n.navNotes;

  static String _settingsLabel(AppLocalizations l10n) => l10n.navSettings;
}
