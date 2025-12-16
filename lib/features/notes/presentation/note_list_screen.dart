import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../data/note_repository.dart';
import '../domain/note_model.dart';
import 'add_edit_note_screen.dart';
import 'note_detail_screen.dart';

class NoteListScreen extends ConsumerWidget {
  const NoteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(noteListProvider);
    final isDark = ref.watch(themeProvider);
    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey[50];
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Notes", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditNoteScreen())),
      ),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) return Center(child: Text("No notes yet", style: TextStyle(color: textColor)));
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.80, // Taller to fit date
            ),
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return _NoteCard(note: note, isDark: isDark);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NoteModel note;
  final bool isDark;

  const _NoteCard({required this.note, required this.isDark});

  String _getPlainText() {
    try {
      final json = jsonDecode(note.content);
      final doc = quill.Document.fromJson(json);
      return doc.toPlainText().trim();
    } catch (e) {
      return note.content; // Fallback for old plain text notes
    }
  }

  @override
  Widget build(BuildContext context) {
    Color cardColor = Color(note.colorValue);
    if (isDark && note.colorValue == 0xFFFFFFFF) {
      cardColor = const Color(0xFF1E1E1E);
    }
    final textColor = (isDark && note.colorValue == 0xFFFFFFFF) ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => NoteDetailScreen(noteId: note.id, initialNote: note)));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                _getPlainText(),
                overflow: TextOverflow.fade,
                style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.8), height: 1.4),
              ),
            ),
            const SizedBox(height: 8),
            // --- CREATION DATE ---
            Text(
              DateFormat('MMM d, yyyy').format(note.date),
              style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.5), fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}