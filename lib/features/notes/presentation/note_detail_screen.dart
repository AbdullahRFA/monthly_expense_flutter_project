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

        // 1. Adaptive Color Logic
        Color bgColor = Color(note.colorValue);
        bool isDefaultColor = note.colorValue == 0xFFFFFFFF;

        if (isDark && isDefaultColor) {
          bgColor = const Color(0xFF1E1E1E);
        }

        final textColor = (isDark && isDefaultColor) ? Colors.white : Colors.black87;
        final metaColor = textColor.withOpacity(0.6);

        // 2. Quill Controller Setup (FIXED: Set readOnly here)
        quill.QuillController _controller;
        try {
          final json = jsonDecode(note.content);
          _controller = quill.QuillController(
            document: quill.Document.fromJson(json),
            selection: const TextSelection.collapsed(offset: 0),
            readOnly: true, // <--- ADDED THIS
          );
        } catch (e) {
          _controller = quill.QuillController(
            document: quill.Document()..insert(0, note.content),
            selection: const TextSelection.collapsed(offset: 0),
            readOnly: true, // <--- ADDED THIS
          );
        }

        return Scaffold(
          backgroundColor: bgColor,
          // 3. Edit Action as FAB for better reachability
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditNoteScreen(noteToEdit: note)));
            },
            backgroundColor: textColor,
            foregroundColor: bgColor, // Invert colors for contrast
            child: const Icon(Icons.edit_outlined),
          ),
          body: Hero(
            tag: 'note_${note.id}',
            child: Material(
              color: Colors.transparent,
              child: CustomScrollView(
                slivers: [
                  // 4. Minimalist AppBar
                  SliverAppBar(
                    backgroundColor: bgColor,
                    iconTheme: IconThemeData(color: textColor),
                    elevation: 0,
                    pinned: true,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: "Delete Note",
                        onPressed: () => _confirmDelete(context, ref),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),

                  // 5. Content Body
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            note.title.isNotEmpty ? note.title : "Untitled",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Metadata Row
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 14, color: metaColor),
                              const SizedBox(width: 6),
                              Text(
                                "Edited ${DateFormat('MMM d, h:mm a').format(note.lastEdited)}",
                                style: TextStyle(fontSize: 13, color: metaColor, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 12),
                              Container(width: 4, height: 4, decoration: BoxDecoration(color: metaColor, shape: BoxShape.circle)),
                              const SizedBox(width: 12),
                              Text(
                                "Created ${DateFormat('MMM d').format(note.date)}",
                                style: TextStyle(fontSize: 13, color: metaColor),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),
                          const Divider(height: 1, thickness: 0.5),
                          const SizedBox(height: 30),

                          // Rich Text Content
                          quill.QuillEditor.basic(
                            controller: _controller,
                            configurations: quill.QuillEditorConfigurations(
                              autoFocus: false,
                              expands: false,
                              enableInteractiveSelection: true, // Allow copying text
                              // enableEditor: false, // <--- REMOVED (Deprecated)
                              customStyles: quill.DefaultStyles(
                                paragraph: quill.DefaultTextBlockStyle(
                                    TextStyle(
                                        fontSize: 18,
                                        height: 1.6,
                                        color: textColor.withOpacity(0.9)
                                    ),
                                    const quill.HorizontalSpacing(0, 0),
                                    const quill.VerticalSpacing(0, 0),
                                    const quill.VerticalSpacing(0, 0),
                                    null
                                ),
                              ),
                            ),
                          ),

                          // Bottom padding for FAB
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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