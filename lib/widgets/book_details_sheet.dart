import 'package:flutter/material.dart';
import '../models/book.dart';

class BookDetailsSheet extends StatefulWidget {
  final Book book;
  final bool isCheckedOut;
  final bool isFavorite;
  final VoidCallback onCheckout;

  /// Called when user taps the favorite button.
  /// The callback receives the bookId.  Using a Future allows the sheet
  /// to show a loading indicator while the operation completes.
  final Future<void> Function() onToggleFavorite;

  const BookDetailsSheet({
    super.key,
    required this.book,
    required this.isCheckedOut,
    required this.isFavorite,
    required this.onCheckout,
    required this.onToggleFavorite,
  });

  @override
  State<BookDetailsSheet> createState() => _BookDetailsSheetState();
}

class _BookDetailsSheetState extends State<BookDetailsSheet>
    with SingleTickerProviderStateMixin {
  late bool _isFavorite;
  bool _isProcessing = false;

  /// Animation controller for the star scale bounce.
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleToggleFavorite() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _isFavorite = !_isFavorite; // Optimistic update
    });

    // Play bounce animation
    _animController.forward(from: 0.0);

    try {
      await widget.onToggleFavorite();
    } catch (_) {
      // Revert optimistic update on error
      if (mounted) {
        setState(() => _isFavorite = !_isFavorite);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Book Details',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        // ── Animated Favorite Button ──────────────────────
                        ScaleTransition(
                          scale: _scaleAnim,
                          child: IconButton(
                            tooltip: _isFavorite
                                ? 'Remove from favorites'
                                : 'Add to favorites',
                            // Disable the tap target while processing
                            onPressed:
                                _isProcessing ? null : _handleToggleFavorite,
                            icon: _isProcessing
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.primary,
                                    ),
                                  )
                                : AnimatedSwitcher(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    transitionBuilder: (child, anim) =>
                                        ScaleTransition(
                                            scale: anim, child: child),
                                    child: Icon(
                                      _isFavorite
                                          ? Icons.star
                                          : Icons.star_border,
                                      key: ValueKey(_isFavorite),
                                      color: _isFavorite
                                          ? Colors.amber.shade600
                                          : colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                      size: 28,
                                    ),
                                  ),
                          ),
                        ),
                        // ─────────────────────────────────────────────────
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Book Cover
                    Center(
                      child: Container(
                        width: 192,
                        height: 256,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.book.coverImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(Icons.book,
                                    size: 64,
                                    color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      widget.book.title,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.book.author,
                      style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface.withValues(alpha: 0.6)),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(widget.book.category),
                          backgroundColor: colorScheme.primaryContainer,
                        ),
                        Chip(
                          avatar: const Icon(Icons.star,
                              color: Colors.amber, size: 16),
                          label: Text('${widget.book.rating} / 5.0'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Info rows
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.calendar_today,
                            label: 'Published',
                            value: widget.book.publishYear.toString(),
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.numbers,
                            label: 'ISBN',
                            value: widget.book.isbn,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.book,
                            label: 'Availability',
                            value:
                                '${widget.book.availableCopies} of ${widget.book.totalCopies} available',
                            valueColor: widget.book.isAvailable
                                ? Colors.green
                                : colorScheme.error,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'About this book',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.book.description,
                      style: TextStyle(
                        color:
                            colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Bottom Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                        color:
                            colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.isCheckedOut || !widget.book.isAvailable
                          ? null
                          : widget.onCheckout,
                      style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16)),
                      child: Text(
                        widget.isCheckedOut
                            ? 'Already Checked Out'
                            : widget.book.isAvailable
                                ? 'Checkout Book'
                                : 'Currently Unavailable',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: colorScheme.onSurface.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                    fontSize: 14,
                    color:
                        colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
