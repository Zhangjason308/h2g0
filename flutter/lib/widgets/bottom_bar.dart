import 'package:flutter/material.dart';
import 'package:h2g0/models/marker_state.dart';
import 'package:url_launcher/url_launcher_string.dart';


class bottom_bar extends StatelessWidget {
  final Map<String, dynamic> metadata;
  final Type? type;
  final Map navList;
  final ScrollController scrollController;
  final VoidCallback onClose;
  final VoidCallback onDirections;
  final VoidCallback removeDropped;

  const bottom_bar({
    super.key,
    required this.metadata,
    required this.type,
    required this.navList,
    required this.scrollController,
    required this.onClose, 
    required this.onDirections,
    required this.removeDropped
  });


  

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
      child: DefaultTabController(
        length: (navList['dest'] != null) ? 2 : 1,
        child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // TAB BAR //
                  TabBar(tabs: [
                    Tab(icon: Icon(Icons.info),),
                    if (navList['dest'] != null)Tab(icon: Icon(Icons.directions),),
                  ]),

                  SizedBox(
                    height: 500,
                    child: TabBarView(children: [
                      ListView(
                        physics: NeverScrollableScrollPhysics(), // Place information
                        children: [
                          Row(
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
                          Text(metadata['address'] ?? 'No Address', textAlign: TextAlign.left),
                          if (metadata['telephone'] != null)
                          Text('Telephone: ${metadata['telephone']}', textAlign: TextAlign.left),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              if (metadata['name'] != "Dropped Pin") ElevatedButton.icon(
                              onPressed: onDirections,
                              icon: Icon(Icons.directions),
                              label: Text("Directions"),),
                              if (metadata['name'] == "Dropped Pin")ElevatedButton.icon(
                              onPressed: removeDropped,
                              icon: Icon(Icons.close),
                              label: Text("Remove Pin"),),]
                          ),
                          const SizedBox(height: 16),
                            const Divider(),
                            if (type==Type.WASHROOM)Text("Season", style: TextStyle(fontSize: 18)),
                            if (type==Type.WASHROOM) SizedBox(height: 16),
                            if (type==Type.WASHROOM && metadata['seasonal'] == '0') Text("${' ' * 5} Open Year Round"),
                            if (type==Type.WASHROOM && metadata['seasonal'] == '1') Text("${' ' * 5} Open From ${metadata['seasonstart']} to ${metadata['seasonend']}"),
                            const SizedBox(height: 16),
                            if (type==Type.WASHROOM) Divider(),
                            if (type==Type.WASHROOM)Text("Hours of Operation", style: TextStyle(fontSize: 18)),
                            if (type==Type.WASHROOM) SizedBox(height: 16),
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
                                Text('${' ' * 5} ${day[0].toUpperCase()}${day.substring(1)}: ${metadata['hours $day open']} to ${metadata['hours $day close']}'),
                            
                            if (metadata['hours'] != null) Text('Hours: ${metadata['hours']}', style: TextStyle(fontSize: 16)),
                            if (metadata['inout'] != null) Text('Inside or Outside?: ${metadata['inout']}', style: TextStyle(fontSize: 16)),
                            if (metadata['yearround'] != null) Text('Year Round?: ${metadata['yearround']}', style: TextStyle(fontSize: 16)),
                            if (metadata['buildingtype'] != null) Text('Type: ${metadata['buildingtype']}', style: TextStyle(fontSize: 16)),
                            if (metadata['buildingdesc'] != null) Text('${metadata['buildingdesc']}', style: TextStyle(fontSize: 16)),
                            if (type == Type.FOUNTAIN) SizedBox(height: 16),
                            if (type != Type.WASHROOM && metadata['link'] != null) Row(
                              children: [
                                ElevatedButton.icon(onPressed: () => launchUrlString(metadata['link']), icon: Icon(Icons.info), label: Text("More Info"),),
                              ],
                            ),
                          const SizedBox(height: 16),
                          ],
                        ),
                        
                      if (navList['dest'] != null) ListView(
                            children: navList['nav'],
                      ),
                      ],
                    ),
                  )
                  ]
                  )
                  
                  
                // 
          ),
        );
  }
}
