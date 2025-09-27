import 'package:flutter/material.dart';
import 'package:vu_mcqs_app/models/subject.dart';

class SubjectListItem extends StatelessWidget {
  final Subject subject;
  final bool isAdded;
  final bool isAdding;
  final bool isRemoving;
  final bool isDownloading;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  const SubjectListItem({
    super.key,
    required this.subject,
    required this.isAdded,
    this.isAdding = false,
    this.isRemoving = false,
    this.isDownloading = false,
    this.onAdd,
    this.onRemove,
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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      elevation: 0,
      clipBehavior: Clip.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
        leading: Icon(
          Icons.menu_book,
          size: 24,
          color: _getRandomColor(subject.subCode),
        ),
        title: Text(
          subject.subCode.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: Theme.of(context).textTheme.titleLarge?.color ?? Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            letterSpacing: 0.5,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subject.subName,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodyMedium?.color ?? Theme.of(context).textTheme.bodyLarge?.color ?? Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: isAdding
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : isDownloading
                ? const SizedBox(
                    width: 80,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 4),
                        Text('Downloading...', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  )
                : isAdded
                    ? isRemoving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : SizedBox(
                           width: 70,
                           height: 32,
                           child: TextButton(
                             onPressed: onRemove != null ? () => onRemove!() : null,
                             style: TextButton.styleFrom(
                               backgroundColor: Colors.grey,
                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                               shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(20),
                               ),
                               textStyle: const TextStyle(
                                 fontSize: 12,
                                 fontWeight: FontWeight.w600,
                               ),
                             ),
                             child: const Text('Added'),
                           ),
                         )
                    : SizedBox(
                       width: 60,
                       height: 32,
                       child: TextButton(
                         onPressed: onAdd != null ? () => onAdd!() : null,
                         style: TextButton.styleFrom(
                           foregroundColor: Colors.white,
                           backgroundColor: Colors.green,
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(20),
                           ),
                           textStyle: const TextStyle(
                             fontSize: 12,
                             fontWeight: FontWeight.w600,
                           ),
                         ),
                         child: const Text('Add'),
                       ),
                     ),
      ),
    );
  }
}
