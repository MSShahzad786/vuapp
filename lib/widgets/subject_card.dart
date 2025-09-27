import 'package:flutter/material.dart';
import 'package:vu_mcqs_app/models/selected_subject.dart';

class SubjectCard extends StatelessWidget {
  final SelectedSubject subject;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onStatusToggle;

  const SubjectCard({
    super.key,
    required this.subject,
    required this.isActive,
    this.onTap,
    this.onStatusToggle,
  });

  Color _getRandomColor(String subCode) {
    final int hash = subCode.hashCode;
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
      Colors.deepOrange,
    ];
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Subject icon with better styling
                  Icon(
                    Icons.menu_book,
                    size: 28,
                    color: _getRandomColor(subject.subCode),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subject code with better styling
                        Text(
                          subject.subCode.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (!isActive) const SizedBox(height: 2),
                        // Subject name
                        Text(
                          subject.subName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Status badge with better styling
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () async {
                if (onStatusToggle != null) {
                  // Show confirmation dialog for active button
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Change Subject Status'),
                      content: Text('Are you sure you want to ${isActive ? 'deactivate' : 'activate'} this subject?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
                          child: Text(isActive ? 'Deactivate' : 'Activate'),
                        ),
                      ],
                    ),
                  ) ?? false;

                  if (confirmed) {
                    onStatusToggle!();
                  }
                }
              },
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'serif',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
