import 'package:flutter/material.dart';

class DownloadingAnimationWidget extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final VoidCallback? onCancel;
  final String? message;
  final double size;

  const DownloadingAnimationWidget({
    super.key,
    required this.progress,
    this.onCancel,
    this.message,
    this.size = 100.0,
  });

  @override
  State<DownloadingAnimationWidget> createState() => _DownloadingAnimationWidgetState();
}

class _DownloadingAnimationWidgetState extends State<DownloadingAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
          ),

          // Progress circle
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              value: widget.progress,
              strokeWidth: 8.0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.progress < 1.0 ? Colors.blue : Colors.green,
              ),
            ),
          ),

          // Animated rotating border
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animation.value * 2 * 3.14159,
                child: Container(
                  width: widget.size + 10,
                  height: widget.size + 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 2.0,
                    ),
                  ),
                ),
              );
            },
          ),

          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.progress < 1.0 ? Icons.download : Icons.check,
                color: widget.progress < 1.0 ? Colors.blue : Colors.green,
                size: widget.size * 0.3,
              ),
              const SizedBox(height: 4),
              Text(
                widget.progress < 1.0
                    ? '${(widget.progress * 100).toInt()}%'
                    : 'Complete',
                style: TextStyle(
                  color: widget.progress < 1.0 ? Colors.blue : Colors.green,
                  fontSize: widget.size * 0.15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Cancel button
          if (widget.onCancel != null && widget.progress < 1.0)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: widget.onCancel,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),

          // Message
          if (widget.message != null)
            Positioned(
              bottom: -widget.size * 0.6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  widget.message!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
