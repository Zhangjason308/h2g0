import 'package:flutter/material.dart';

class bottom_bar extends StatelessWidget {
  final Map<String, dynamic> metadata;
  final ScrollController scrollController;
  final VoidCallback onClose;
  final VoidCallback onDirections;

  const bottom_bar({
    Key? key,
    required this.metadata,
    required this.scrollController,
    required this.onClose, 
    required this.onDirections
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
                Expanded(
                  child: Text(
                    metadata['name'] ?? 'No Name',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.fade
                    ),
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
                Text(metadata['address'] ?? 'No Address', textAlign: TextAlign.left),
                if (metadata['telephone'] != null)
                Text('Telephone: ${metadata['telephone']}', textAlign: TextAlign.left),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [ElevatedButton.icon(
                    onPressed: onDirections,
                    icon: Icon(Icons.directions),
                    label: Text("Directions"),),]
                ),
                const SizedBox(height: 16),
                const Divider(),
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
                
                if (metadata['hours'] != null) Text('Hours: ${metadata['hours']}'),
                if (metadata['inout'] != null) Text('Inside or Outside?: ${metadata['inout']}'),
                if (metadata['yearround'] != null) Text('Year Round?: ${metadata['yearround']}'),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
