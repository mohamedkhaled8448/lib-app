import 'package:flutter/material.dart';
import '../models/room.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback onReserve;

  const RoomCard({
    super.key,
    required this.room,
    required this.onReserve,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Room Image & Status Badge
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  room.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Icon(Icons.meeting_room,
                          size: 48, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: room.isAvailable
                        ? Colors.green.shade600
                        : colorScheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    room.isAvailable ? 'Available' : 'Reserved',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Room Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        room.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Up to ${room.capacity}',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(
                      room.location,
                      style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Amenities
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: room.amenities.map((amenity) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        amenity,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                
                // Reserve Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: room.isAvailable ? onReserve : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(room.isAvailable ? 'Reserve Room' : 'Currently Unavailable'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
