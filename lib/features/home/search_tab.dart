import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../widgets/book_details_sheet.dart';
import '../../widgets/mobile_book_card.dart';

class SearchTab extends StatefulWidget {
  final List<Book> books;
  final Set<String> checkedOutBookIds;
  final Set<String> favoriteBookIds;
  final Function(Book) onCheckout;

  /// Async callback so the book card / details sheet can show a loading state.
  final Future<void> Function(String bookId) onToggleFavorite;
  final Future<void> Function() onRefresh;

  const SearchTab({
    super.key,
    required this.books,
    required this.checkedOutBookIds,
    required this.favoriteBookIds,
    required this.onCheckout,
    required this.onToggleFavorite,
    required this.onRefresh,
  });

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<String> get _categories {
    final cats = widget.books.map((b) => b.category).toSet().toList()..sort();
    return ['All', ...cats];
  }

  List<Book> get _filteredBooks {
    return widget.books.where((book) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          book.title.toLowerCase().contains(q) ||
          book.author.toLowerCase().contains(q) ||
          book.isbn.contains(_searchQuery);

      final matchesCategory =
          _selectedCategory == 'All' || book.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _showBookDetails(Book book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookDetailsSheet(
        book: book,
        isCheckedOut: widget.checkedOutBookIds.contains(book.id),
        isFavorite: widget.favoriteBookIds.contains(book.id),
        onCheckout: () {
          Navigator.pop(context);
          widget.onCheckout(book);
        },
        // Wrap so the sheet's internal state drives the animation,
        // and the parent state is updated via onToggleFavorite.
        onToggleFavorite: () => widget.onToggleFavorite(book.id),
      ),
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter by Category',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                return FilterChip(
                  label: Text(category),
                  selected: category == _selectedCategory,
                  onSelected: (_) {
                    setState(() => _selectedCategory = category);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBooks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Books'),
        actions: [
          IconButton(
            onPressed: widget.onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).appBarTheme.backgroundColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) =>
                      setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search books, authors...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _showCategoryFilter,
                      icon: const Icon(Icons.filter_list, size: 18),
                      label: Text('Category: $_selectedCategory'),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${filtered.length} results',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: widget.onRefresh,
              child: filtered.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No books found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => setState(() {
                                    _searchQuery = '';
                                    _selectedCategory = 'All';
                                  }),
                                  child: const Text('Clear filters'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final book = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: MobileBookCard(
                            book: book,
                            isCheckedOut:
                                widget.checkedOutBookIds.contains(book.id),
                            isFavorite:
                                widget.favoriteBookIds.contains(book.id),
                            onTap: () => _showBookDetails(book),
                            onToggleFavorite: () =>
                                widget.onToggleFavorite(book.id),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
