import 'package:flutter_map/flutter_map.dart';

enum Type {WASHROOM, FOUNTAIN, COMBO}


class MarkerState extends Marker {
  final Map<String, dynamic> metadata;
  int listPos;
  final Type facilityType;

  MarkerState({super.key, required super.point, required super.child, required this.metadata, required this.listPos, required this.facilityType, super.width, super.height, super.rotate, super.alignment});

}