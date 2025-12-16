import 'package:cloud_firestore/cloud_firestore.dart';

class TodoModel {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime date;

  TodoModel({required this.id, required this.title, required this.isCompleted, required this.date});

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
    'date': Timestamp.fromDate(date),
  };

  factory TodoModel.fromMap(Map<String, dynamic> map) => TodoModel(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    isCompleted: map['isCompleted'] ?? false,
    date: (map['date'] as Timestamp).toDate(),
  );
}