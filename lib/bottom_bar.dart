import 'package:flutter/material.dart';

class bottom_bar extends StatelessWidget {
  final Map<String, dynamic> metadata;
  final ScrollController scrollController; // ✅ Add scroll controller

  const bottom_bar({Key? key, required this.metadata, required this.scrollController}) : super(key: key);

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
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  metadata['name'] ?? 'No Name',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
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
