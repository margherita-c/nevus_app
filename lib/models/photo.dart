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
  final String id;           // Add this line
  final String path;
  final String dateTaken;
  final String moleName;
  List<Spot> spots;

  Photo({
    required this.id,        // Add this parameter
    required this.path,
    required this.dateTaken,
    required this.moleName,
    List<Spot>? spots,
  }) : spots = spots ?? [];

  // Optional: Serialization methods
  Map<String, dynamic> toJson() => {
    'id': id,              // Add this line
    'path': path,
    'dateTaken': dateTaken,
    'moleName': moleName,
    'spots': spots.map((s) => s.toJson()).toList(),
  };

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
    id: json['id'],        // Add this line
    path: json['path'],
    dateTaken: json['dateTaken'],
    moleName: json['moleName'],
    spots: (json['spots'] as List<dynamic>?)
        ?.map((s) => Spot.fromJson(s))
        .toList() ?? [],
  );
}