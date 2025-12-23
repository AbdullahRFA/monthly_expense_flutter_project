import 'package:cloud_firestore/cloud_firestore.dart';

class TaskGroupModel {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;

  TaskGroupModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TaskGroupModel.fromMap(Map<String, dynamic> map) {
    return TaskGroupModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}