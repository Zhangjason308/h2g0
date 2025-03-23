import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class MarkerState extends Marker {
  final String name;
  final int listPos;
  List<Widget>? children = const <Widget>[];

  MarkerState({super.key, required super.point, required super.child, required this.name, required this.listPos, super.width, super.height});

  
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }

}