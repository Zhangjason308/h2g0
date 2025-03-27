import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final void Function(String)? onTabSelected;

  const ResponsiveAppBar({super.key, this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // If width is more than 600, show tabs; else show hamburger menu
      if (constraints.maxWidth > 600) {
        return Container(
          decoration: AppTheme.appBarGradient,
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('H2G0', style: AppTheme.appBarTitle),
            actions: [
              _buildTab(context, 'Map'),
              _buildTab(context, 'Tutorial'),
              _buildTab(context, 'Submission Form'),
              _buildTab(context, 'About Us'),
              _buildTab(context, 'Contact'),
            ],
          ),
        );
      } else {
        return Container(
          decoration: AppTheme.appBarGradient,
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('H2G0', style: AppTheme.appBarTitle),
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            ],
          ),
        );
      }
    });
  }

  Widget _buildTab(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextButton(
        onPressed: () => onTabSelected?.call(label),
        style: AppTheme.tabButtonStyle,
        child: Text(label, style: AppTheme.tabTextStyle),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
