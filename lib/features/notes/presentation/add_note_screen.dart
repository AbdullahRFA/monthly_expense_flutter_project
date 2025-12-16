import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../data/note_repository.dart';

class AddNoteScreen extends ConsumerWidget {
  const AddNoteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final isDark = ref.watch(themeProvider);
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          TextButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty || contentCtrl.text.isNotEmpty) {
                ref.read(noteRepositoryProvider).addNote(titleCtrl.text, contentCtrl.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Save", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleCtrl,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
              decoration: const InputDecoration(hintText: "Title", border: InputBorder.none),
            ),
            Expanded(
              child: TextField(
                controller: contentCtrl,
                style: TextStyle(fontSize: 16, color: textColor),
                maxLines: null,
                decoration: const InputDecoration(hintText: "Start typing...", border: InputBorder.none),
              ),
            ),
          ],
        ),
      ),
    );
  }
}