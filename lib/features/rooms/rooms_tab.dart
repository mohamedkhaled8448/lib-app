import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/room.dart';
import '../../providers/room_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/room_card.dart';
import '../../widgets/reservation_card.dart';

class RoomsTab extends StatelessWidget {
  const RoomsTab({super.key});

  void _handleReserve(BuildContext context, Room room) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to reserve a room')),
      );
      return;
    }

    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    
    // Simple mock reservation: 1 hour from now
    final startTime = DateTime.now().add(const Duration(minutes: 5));
    final endTime = startTime.add(const Duration(hours: 1));

    try {
      await roomProvider.bookRoom(
        roomId: room.id,
        roomName: room.name,
        userId: user.id,
        userName: user.firstName,
        startTime: startTime,
        endTime: endTime,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${room.name} has been reserved!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to reserve room. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _handleCancel(BuildContext context, String bookingId) async {
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    
    try {
      await roomProvider.cancelBooking(bookingId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reservation cancelled successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to cancel reservation.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Study Rooms'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Available Rooms'),
              Tab(text: 'My Reservations'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRoomsList(),
            _buildReservationsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsList() {
    return Consumer<RoomProvider>(
      builder: (context, provider, child) {
        final rooms = provider.rooms;
        
        if (rooms.isEmpty) {
          return const Center(child: Text('No rooms available at the moment.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return RoomCard(
              room: room,
              onReserve: () => _handleReserve(context, room),
            );
          },
        );
      },
    );
  }

  Widget _buildReservationsList() {
    return Consumer2<RoomProvider, UserProvider>(
      builder: (context, roomProvider, userProvider, child) {
        final user = userProvider.currentUser;
        if (user == null) {
          return const Center(child: Text('Please log in to view reservations.'));
        }

        final userBookings = roomProvider.getUserBookings(user.id);

        if (userBookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No active reservations.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: userBookings.length,
          itemBuilder: (context, index) {
            final booking = userBookings[index];
            return ReservationCard(
              booking: booking,
              onCancel: () => _handleCancel(context, booking.id),
            );
          },
        );
      },
    );
  }
}
