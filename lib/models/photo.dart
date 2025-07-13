import 'dart:ui';
import 'package:flutter/material.dart';

class Spot {
  Offset position;
  double radius;
  Spot({required this.position, required this.radius});

  // Optional: Serialization methods if you save/load spots
  Map<String, dynamic> toJson() => {
    'dx': position.dx,
    'dy': position.dy,
    'radius': radius,
  };

  factory Spot.fromJson(Map<String, dynamic> json) => Spot(
    position: Offset(json['dx'], json['dy']),
    radius: json['radius'],
  );
}

class Photo {
  String path;
  String moleName;
  String dateTaken;
  List<Spot> spots;

  Photo({
    required this.path,
    required this.moleName,
    required this.dateTaken,
    List<Spot>? spots,
  }) : spots = spots ?? [];

  // Optional: Serialization methods
  Map<String, dynamic> toJson() => {
    'path': path,
    'moleName': moleName,
    'dateTaken': dateTaken,
    'spots': spots.map((s) => s.toJson()).toList(),
  };

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
    path: json['path'],
    moleName: json['moleName'],
    dateTaken: json['dateTaken'],
    spots: (json['spots'] as List<dynamic>?)
        ?.map((s) => Spot.fromJson(s))
        .toList() ?? [],
  );
}