import 'package:flutter/material.dart';
import '../models/book.dart';

/// A card that displays a book summary with an interactive favorite button.
///
/// The card itself is responsible for its own "processing" visual state so
/// that the UI never freezes waiting for a parent rebuild.
class MobileBookCard extends StatefulWidget {
  final Book book;
  final bool isCheckedOut;
  final bool isFavorite;
  final VoidCallback onTap;

  /// Optional async callback invoked when the user taps the star button.
  /// If null, the star button is hidden.
  final Future<void> Function()? onToggleFavorite;

  const MobileBookCard({
    super.key,
    required this.book,
    required this.isCheckedOut,
    this.isFavorite = false,
    required this.onTap,
    this.onToggleFavorite,
  });

  @override
  State<MobileBookCard> createState() => _MobileBookCardState();
}

class _MobileBookCardState extends State<MobileBookCard>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleFavoriteTap() async {
    if (_isProcessing || widget.onToggleFavorite == null) return;
    setState(() => _isProcessing = true);
    _animController.forward(from: 0.0);
    try {
      await widget.onToggleFavorite!();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Book Cover ────────────────────────────────────────────────
              Stack(
                children: [
                  Container(
                    width: 96,
                    height: 128,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.book.coverImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(Icons.book,
                              size: 40,
                              color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
                  if (!widget.book.isAvailable)
                    Container(
                      width: 96,
                      height: 128,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Out',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  if (widget.isCheckedOut)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Yours',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  // Favorite badge on the cover (read-only indicator)
                  if (widget.isFavorite && !widget.isCheckedOut)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.star,
                            color: Colors.amber.shade600, size: 16),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              // ── Book Info ─────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with favorite button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.book.title,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // ── Favourite Button ──────────────────────────────
                        if (widget.onToggleFavorite != null)
                          ScaleTransition(
                            scale: _scaleAnim,
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: _isProcessing
                                  ? Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.primary,
                                      ),
                                    )
                                  : IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        transitionBuilder: (child, anim) =>
                                            ScaleTransition(
                                                scale: anim, child: child),
                                        child: Icon(
                                          widget.isFavorite
                                              ? Icons.star
                                              : Icons.star_border,
                                          key: ValueKey(widget.isFavorite),
                                          color: widget.isFavorite
                                              ? Colors.amber.shade600
                                              : colorScheme.onSurface
                                                  .withValues(alpha: 0.4),
                                          size: 22,
                                        ),
                                      ),
                                      tooltip: widget.isFavorite
                                          ? 'Remove from favorites'
                                          : 'Add to favorites',
                                      onPressed: _handleFavoriteTap,
                                    ),
                            ),
                          ),
                        // ─────────────────────────────────────────────────
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.book.author,
                      style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color:
                                colorScheme.outline.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(widget.book.category,
                          style: const TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(widget.book.rating.toString(),
                                style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.book,
                              size: 16,
                              color: widget.book.isAvailable
                                  ? colorScheme.onSurface
                                      .withValues(alpha: 0.6)
                                  : colorScheme.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.book.availableCopies}/${widget.book.totalCopies}',
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.book.isAvailable
                                    ? colorScheme.onSurface
                                        .withValues(alpha: 0.6)
                                    : colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
