// lib/providers/room_provider.dart
import 'package:flutter/material.dart';
import '../models/room.dart';
import '../services/notification_service.dart';

/// Model for a room booking, used internally by [RoomProvider].
class RoomBooking {
  final String id;
  final String roomId;
  final String roomName;
  final String userId;
  final String userName;
  final DateTime startTime;
  final DateTime endTime;

  const RoomBooking({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.userId,
    required this.userName,
    required this.startTime,
    required this.endTime,
  });
}

/// Manages study-room booking state and related notifications.
class RoomProvider extends ChangeNotifier {
  final NotificationService _notifications = NotificationService();

  final List<RoomBooking> _bookings = [];
  List<Room> _rooms = [];

  List<RoomBooking> get bookings => List.unmodifiable(_bookings);
  List<Room> get rooms => List.unmodifiable(_rooms);

  // --- Notification ID helpers ---
  int _confirmId(String bookingId) => bookingId.hashCode & 0x7FFFFFFF;
  int _reminderId(String bookingId) => (_confirmId(bookingId) + 1) & 0x7FFFFFFF;
  int _cancelId(String bookingId) => (_confirmId(bookingId) + 2) & 0x7FFFFFFF;

  /// Load mock rooms (replace with API call later)
  void loadMockRooms() {
    _rooms = [
      Room(
        id: '1',
        name: 'Study Room A',
        capacity: 4,
        location: 'Floor 2, Room 201',
        amenities: ['Whiteboard', 'WiFi', 'Power Outlets'],
        imageUrl:
            'https://images.unsplash.com/photo-1497366754035-f200968a6e72',
        isAvailable: true,
      ),
      Room(
        id: '2',
        name: 'Conference Room B',
        capacity: 8,
        location: 'Floor 3, Room 305',
        amenities: ['Projector', 'Whiteboard', 'WiFi', 'Conference Phone'],
        imageUrl:
            'https://images.unsplash.com/photo-1497366811353-6870744d04b2',
        isAvailable: true,
      ),
    ];
    notifyListeners();
  }

  /// Book a room: persists the booking, fires a confirmation notification, and
  /// schedules a 30-minute reminder before [startTime].
  Future<bool> bookRoom({
    required String roomId,
    required String roomName,
    required String userId,
    required String userName,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final booking = RoomBooking(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: roomId,
      roomName: roomName,
      userId: userId,
      userName: userName,
      startTime: startTime,
      endTime: endTime,
    );

    _bookings.add(booking);

    // Update room availability
    final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex != -1) {
      final room = _rooms[roomIndex];
      _rooms[roomIndex] = Room(
        id: room.id,
        name: room.name,
        capacity: room.capacity,
        location: room.location,
        amenities: room.amenities,
        imageUrl: room.imageUrl,
        isAvailable: false,
      );
    }

    notifyListeners();

    // 1. Instant confirmation
    await _notifications.showNotification(
      id: _confirmId(booking.id),
      title: 'Room Booked ✅',
      body:
          '$roomName reserved from ${_formatTime(startTime)} to ${_formatTime(endTime)}.',
    );

    // 2. Scheduled 30-min reminder
    final reminderTime = startTime.subtract(const Duration(minutes: 30));
    if (reminderTime.isAfter(DateTime.now())) {
      await _notifications.scheduleNotification(
        id: _reminderId(booking.id),
        title: 'Room Booking Reminder ⏰',
        body: 'Your $roomName session starts in 30 minutes.',
        scheduledTime: reminderTime,
      );
    }

    return true;
  }

  /// Cancel a booking: removes it, cancels the pending reminder, and fires a
  /// cancellation confirmation.
  Future<bool> cancelBooking(String bookingId) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return false;

    final booking = _bookings[index];

    // Update room availability
    final roomIndex = _rooms.indexWhere((r) => r.id == booking.roomId);
    if (roomIndex != -1) {
      final room = _rooms[roomIndex];
      _rooms[roomIndex] = Room(
        id: room.id,
        name: room.name,
        capacity: room.capacity,
        location: room.location,
        amenities: room.amenities,
        imageUrl: room.imageUrl,
        isAvailable: true,
      );
    }

    _bookings.removeAt(index);
    notifyListeners();

    // Cancel the 30-min reminder
    await _notifications.cancelNotification(_reminderId(bookingId));

    // Cancellation confirmation
    await _notifications.showNotification(
      id: _cancelId(bookingId),
      title: 'Booking Cancelled ❌',
      body: 'Your reservation for ${booking.roomName} has been cancelled.',
    );

    return true;
  }

  List<RoomBooking> getUserBookings(String userId) {
    return _bookings.where((b) => b.userId == userId).toList();
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
