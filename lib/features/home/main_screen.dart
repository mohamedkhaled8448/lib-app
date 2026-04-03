// lib/features/home/main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_service.dart';
import '../../models/book.dart';
import '../../providers/user_provider.dart';
import '../../providers/book_provider.dart';
import '../../services/favorite_service.dart';
import 'home_tab.dart';
import 'search_tab.dart';
import 'my_books_tab.dart';
import '../profile/profile_tab.dart';
import '../rooms/rooms_tab.dart';
import '../../providers/room_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  List<Book> _books = [];
  bool _isLoading = true;
  String? _loadError;

  final Set<String> _checkedOutBookIds = {};
  final Set<String> _favoriteBookIds = {};

  /// Books whose favorite toggle is currently being processed.
  /// Prevents duplicate rapid taps from firing multiple API calls.
  final Set<String> _processingFavoriteIds = {};

  @override
  void initState() {
    super.initState();
    _loadBooks();
    
    // Load local mock rooms
    Future.microtask(() {
      if (mounted) {
        context.read<RoomProvider>().loadMockRooms();
      }
    });
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final books = await ApiService.getBooks();
      if (mounted) {
        setState(() {
          _books = books;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = 'Failed to load books. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  List<Book> get _checkedOutBooks =>
      _books.where((book) => _checkedOutBookIds.contains(book.id)).toList();

  Future<void> _checkoutBook(Book book) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser == null) return;

    final bookProvider = context.read<BookProvider>();
    try {
      await ApiService.checkoutBook(userProvider.currentUser!.id, book.id);
      setState(() {
        if (book.availableCopies > 0) {
          book.availableCopies--;
          _checkedOutBookIds.add(book.id);
        }
      });
      await bookProvider.onBookCheckedOut(book);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checked out "${book.title}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _returnBook(String bookId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser == null) return;

    final book = _books.firstWhere((b) => b.id == bookId);
    final bookProvider = context.read<BookProvider>();
    try {
      await ApiService.returnBook(userProvider.currentUser!.id, bookId);
      setState(() {
        book.availableCopies++;
        _checkedOutBookIds.remove(bookId);
      });
      await bookProvider.onBookReturned(book);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Returned "${book.title}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorite(String bookId) async {
    // Prevent duplicate concurrent actions on the same book.
    if (_processingFavoriteIds.contains(bookId)) return;

    final wasFavorite = _favoriteBookIds.contains(bookId);

    // 1. Mark as processing & update UI instantly (optimistic update).
    setState(() {
      _processingFavoriteIds.add(bookId);
      if (wasFavorite) {
        _favoriteBookIds.remove(bookId);
      } else {
        _favoriteBookIds.add(bookId);
      }
    });

    try {
      if (wasFavorite) {
        await FavoriteService.removeFavorite(
          bookId: bookId,
          favoriteIds: _favoriteBookIds,
        );
      } else {
        await FavoriteService.addFavorite(
          bookId: bookId,
          favoriteIds: _favoriteBookIds,
        );
      }

      if (mounted) {
        final message = wasFavorite ? 'Removed from favorites' : 'Added to favorites';
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    wasFavorite ? Icons.star_border : Icons.star,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(message),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
      }
    } catch (e) {
      // Rollback optimistic update on failure.
      if (mounted) {
        setState(() {
          if (wasFavorite) {
            _favoriteBookIds.add(bookId);
          } else {
            _favoriteBookIds.remove(bookId);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not update favorites. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingFavoriteIds.remove(bookId));
      }
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadBooks,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final userProvider = Provider.of<UserProvider>(context);
    if (userProvider.currentUser == null) {
      return const Center(child: Text('User not logged in'));
    }

    final screens = [
      HomeTab(
        books: _books,
        user: userProvider.currentUser!,
        checkedOutBookIds: _checkedOutBookIds,
        favoriteBookIds: _favoriteBookIds,
        onCheckout: _checkoutBook,
        onToggleFavorite: _toggleFavorite,
        onRefresh: _loadBooks,
      ),
      SearchTab(
        books: _books,
        checkedOutBookIds: _checkedOutBookIds,
        favoriteBookIds: _favoriteBookIds,
        onCheckout: _checkoutBook,
        onToggleFavorite: _toggleFavorite,
        onRefresh: _loadBooks,
      ),
      MyBooksTab(
        checkedOutBooks: _checkedOutBooks,
        onReturn: _returnBook,
        onRefresh: _loadBooks,
      ),
      const RoomsTab(),
      ProfileTab(
        user: userProvider.currentUser!,
        checkedOutCount: _checkedOutBookIds.length,
        onRefresh: _loadBooks,
      ),
    ];

    return IndexedStack(
      index: _currentIndex,
      children: screens,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: (_isLoading || _loadError != null)
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.book_outlined),
                  activeIcon: Icon(Icons.book),
                  label: 'My Books',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.meeting_room_outlined),
                  activeIcon: Icon(Icons.meeting_room),
                  label: 'Rooms',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }
}
