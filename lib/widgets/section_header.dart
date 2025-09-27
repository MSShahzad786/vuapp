import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color color;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isActiveSubjects = title == 'Active Subjects';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (icon != null && !isActiveSubjects) ...[
            Icon(
              icon,
              color: color.withOpacity(0.7),
              size: 18,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: isActiveSubjects ? 14 : 14, // Decreased from 18 to 14
              fontWeight: isActiveSubjects ? FontWeight.w600 : FontWeight.w500, // Slightly less bold
              color: isActiveSubjects ? Theme.of(context).colorScheme.onSurface : color.withOpacity(0.8),
              letterSpacing: 0.5,
              fontFamily: 'serif',
            ),
          ),
        ],
      ),
    );
  }
}
