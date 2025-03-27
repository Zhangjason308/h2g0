import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

enum Type {WASHROOM, FOUNTAIN, COMBO}


class MarkerState extends Marker {
  final String name;
  int listPos;
  final Type facilityType;

  MarkerState({super.key, required super.point, required super.child, required this.name, required this.listPos, required this.facilityType, super.width, super.height, super.rotate, super.alignment});

}