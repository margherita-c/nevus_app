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
  final String id;
  final String path;
  final DateTime dateTaken;  // Change from String to DateTime
  final String moleName;
  List<Spot> spots;

  Photo({
    required this.id,
    required this.path,
    required this.dateTaken,  // Now expects DateTime
    required this.moleName,
    List<Spot>? spots,
  }) : spots = spots ?? [];

  // Optional: Serialization methods
  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'dateTaken': dateTaken.toIso8601String(),  // Convert to string for storage
    'moleName': moleName,
    'spots': spots.map((s) => s.toJson()).toList(),
  };

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
    id: json['id'],
    path: json['path'],
    dateTaken: DateTime.parse(json['dateTaken']),  // Parse string back to DateTime
    moleName: json['moleName'],
    spots: (json['spots'] as List<dynamic>?)
        ?.map((s) => Spot.fromJson(s))
        .toList() ?? [],
  );
}