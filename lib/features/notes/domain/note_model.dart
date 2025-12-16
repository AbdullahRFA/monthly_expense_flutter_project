import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String title;
  final String content;
  final DateTime date;

  NoteModel({required this.id, required this.title, required this.content, required this.date});

  Map<String, dynamic> toMap() => {
    'id': id, 'title': title, 'content': content, 'date': Timestamp.fromDate(date),
  };

  factory NoteModel.fromMap(Map<String, dynamic> map) => NoteModel(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    content: map['content'] ?? '',
    date: (map['date'] as Timestamp).toDate(),
  );
}