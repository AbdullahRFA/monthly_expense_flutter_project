import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';
import '../data/note_repository.dart';
import '../domain/note_model.dart';
import 'add_edit_note_screen.dart';

class NoteDetailScreen extends ConsumerWidget {
  final String noteId;
  final NoteModel initialNote;

  const NoteDetailScreen({super.key, required this.noteId, required this.initialNote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteStreamProvider(noteId));
    final isDark = ref.watch(themeProvider);

    return noteAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text("Error: $e"))),
      data: (note) {

        Color bgColor = Color(note.colorValue);
        if (isDark && note.colorValue == 0xFFFFFFFF) {
          bgColor = const Color(0xFF1E1E1E);
        }
        final textColor = (isDark && note.colorValue == 0xFFFFFFFF) ? Colors.white : Colors.black87;

        quill.QuillController _controller;
        try {
          final json = jsonDecode(note.content);
          _controller = quill.QuillController(
            document: quill.Document.fromJson(json),
            selection: const TextSelection.collapsed(offset: 0),
          );
        } catch (e) {
          _controller = quill.QuillController(
            document: quill.Document()..insert(0, note.content),
            selection: const TextSelection.collapsed(offset: 0),
          );
        }

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: textColor),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditNoteScreen(noteToEdit: note)));
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  _confirmDelete(context, ref);
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: quill.QuillEditor.basic(
                    controller: _controller,
                    configurations: quill.QuillEditorConfigurations(
                      autoFocus: false,
                      expands: false,
                      enableInteractiveSelection: false,
                      // Fixed: Added missing HorizontalSpacing(0, 0)
                      customStyles: quill.DefaultStyles(
                        paragraph: quill.DefaultTextBlockStyle(
                            TextStyle(fontSize: 18, height: 1.6, color: textColor),
                            const quill.HorizontalSpacing(0, 0), // <--- MISSING ARGUMENT ADDED
                            const quill.VerticalSpacing(0, 0),
                            const quill.VerticalSpacing(0, 0),
                            null
                        ),
                      ),
                    ),
                  ),
                ),

                const Divider(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Created: ${DateFormat('MMM d, yyyy').format(note.date)}",
                      style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6), fontStyle: FontStyle.italic),
                    ),
                    Text(
                      "Edited: ${DateFormat('h:mm a').format(note.lastEdited)}",
                      style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Note?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              ref.read(noteRepositoryProvider).deleteNote(noteId);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}