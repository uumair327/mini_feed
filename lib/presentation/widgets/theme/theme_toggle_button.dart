import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/theme/theme_cubit.dart';

/// A button widget for toggling between light and dark themes
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({
    super.key,
    this.showLabel = false,
    this.iconSize = 24.0,
  });

  final bool showLabel;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        final themeCubit = context.read<ThemeCubit>();
        
        if (showLabel) {
          return TextButton.icon(
            onPressed: () => themeCubit.toggleTheme(),
            icon: _buildIcon(themeMode),
            label: Text(themeCubit.currentThemeName),
          );
        }
        
        return IconButton(
          onPressed: () => themeCubit.toggleTheme(),
          icon: _buildIcon(themeMode),
          iconSize: iconSize,
          tooltip: 'Switch to ${_getNextThemeName(themeMode)} theme',
        );
      },
    );
  }

  Widget _buildIcon(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return Icon(
          Icons.light_mode,
          size: iconSize,
        );
      case ThemeMode.dark:
        return Icon(
          Icons.dark_mode,
          size: iconSize,
        );
      case ThemeMode.system:
        return Icon(
          Icons.brightness_auto,
          size: iconSize,
        );
    }
  }

  String _getNextThemeName(ThemeMode currentMode) {
    switch (currentMode) {
      case ThemeMode.light:
        return 'dark';
      case ThemeMode.dark:
        return 'light';
      case ThemeMode.system:
        return 'light';
    }
  }
}

/// A more comprehensive theme selector with all three options
class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        final themeCubit = context.read<ThemeCubit>();
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Light'),
              trailing: themeMode == ThemeMode.light
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => themeCubit.setLightTheme(),
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark'),
              trailing: themeMode == ThemeMode.dark
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => themeCubit.setDarkTheme(),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('System'),
              trailing: themeMode == ThemeMode.system
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => themeCubit.setSystemTheme(),
            ),
          ],
        );
      },
    );
  }
}

/// A segmented button for theme selection (Material 3 style)
class ThemeSegmentedButton extends StatelessWidget {
  const ThemeSegmentedButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        final themeCubit = context.read<ThemeCubit>();
        
        return SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment<ThemeMode>(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode),
              label: Text('Light'),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode),
              label: Text('Dark'),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.system,
              icon: Icon(Icons.brightness_auto),
              label: Text('System'),
            ),
          ],
          selected: {themeMode},
          onSelectionChanged: (Set<ThemeMode> selection) {
            final selectedMode = selection.first;
            switch (selectedMode) {
              case ThemeMode.light:
                themeCubit.setLightTheme();
                break;
              case ThemeMode.dark:
                themeCubit.setDarkTheme();
                break;
              case ThemeMode.system:
                themeCubit.setSystemTheme();
                break;
            }
          },
        );
      },
    );
  }
}