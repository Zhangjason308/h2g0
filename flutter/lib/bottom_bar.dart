import 'package:flutter/material.dart';

class bottom_bar extends StatelessWidget {
  final Map<String, dynamic> metadata;
  final ScrollController scrollController;
  final VoidCallback onClose;

  const bottom_bar({
    Key? key,
    required this.metadata,
    required this.scrollController,
    required this.onClose, 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // Gray drag handle
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Title + close button row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  metadata['name'] ?? 'No Name',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose, // ✅ Triggers bottom sheet to hide
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                Text(metadata['address'] ?? 'No Address'),
                if (metadata['telephone'] != null)
                  Text('Telephone: ${metadata['telephone']}'),
                const SizedBox(height: 16),

                for (var day in [
                  'monday',
                  'tuesday',
                  'wednesday',
                  'thursday',
                  'friday',
                  'saturday',
                  'sunday'
                ])
                  if (metadata['hours $day open'] != null)
                    Text('Open on ${day[0].toUpperCase()}${day.substring(1)}: ${metadata['hours $day open']}'),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
