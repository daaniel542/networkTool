import 'package:flutter/material.dart';
import '../features/network/network_screen.dart';
import '../features/password/password_screen.dart';
import '../features/converter/converter_screen.dart';

/// Width at which the layout switches from mobile bottom-nav to desktop rail.
const double _kDesktopBreakpoint = 720.0;

/// Top-level responsive layout shell.
///
/// On wide screens (≥ [_kDesktopBreakpoint]) it renders a persistent
/// [NavigationRail] on the left. On narrow screens it shows a [NavigationBar]
/// at the bottom. The active screen fills the remaining space.
class ResponsiveShell extends StatefulWidget {
  const ResponsiveShell({super.key});

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    (label: 'Network Tools', icon: Icons.wifi_outlined, selectedIcon: Icons.wifi),
    (label: 'Password Gen', icon: Icons.lock_outlined, selectedIcon: Icons.lock),
    (label: 'Encoding', icon: Icons.code_outlined, selectedIcon: Icons.code),
  ];

  // Screens are instantiated once here. Controllers are obtained via
  // Provider.of<T> inside each screen — no need to pass them as constructor
  // arguments, which also means this list does not need to be const.
  final _screens = const [
    NetworkScreen(),
    PasswordScreen(),
    ConverterScreen(),
  ];

  void _onDestinationSelected(int index) =>
      setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _kDesktopBreakpoint) {
          return _DesktopScaffold(
            destinations: _destinations,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            child: _screens[_selectedIndex],
          );
        }
        return _MobileScaffold(
          destinations: _destinations,
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
          child: _screens[_selectedIndex],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop — NavigationRail sidebar
// ---------------------------------------------------------------------------

class _DesktopScaffold extends StatelessWidget {
  const _DesktopScaffold({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  final List<({String label, IconData icon, IconData selectedIcon})> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            minExtendedWidth: 210,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            leading: const _AppLogo(),
            destinations: destinations
                .map((d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile — NavigationBar at the bottom
// ---------------------------------------------------------------------------

class _MobileScaffold extends StatelessWidget {
  const _MobileScaffold({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  final List<({String label, IconData icon, IconData selectedIcon})> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations
            .map((d) => NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                ))
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App logo / brand mark in the sidebar header
// ---------------------------------------------------------------------------

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Icon(Icons.router_outlined, color: color, size: 22),
          const SizedBox(width: 10),
          Text(
            'Net Utility\nToolkit',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              height: 1.4,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
