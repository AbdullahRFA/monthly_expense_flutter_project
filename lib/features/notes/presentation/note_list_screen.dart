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

    // Modern Background Colors
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF2F4F7);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.edit_outlined),
        label: const Text("New Note", style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditNoteScreen())),
      ),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) return _buildEmptyState(isDark);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Modern Floating App Bar
              SliverAppBar(
                floating: true,
                pinned: true,
                snap: false,
                backgroundColor: bgColor,
                surfaceTintColor: bgColor,
                elevation: 0,
                title: Text("My Notes", style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 28)),
                centerTitle: false,
                actions: [
                  IconButton(
                    icon: Icon(Icons.search, color: textColor),
                    onPressed: () {}, // Future: Search
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // 2. Note Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final note = notes[index];
                      return _NoteCard(note: note, isDark: isDark);
                    },
                    childCount: notes.length,
                  ),
                ),
              ),

              // Bottom Spacer for FAB
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e", style: TextStyle(color: textColor))),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outline, size: 80, color: isDark ? Colors.grey[800] : Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            "Capture your ideas",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
        ],
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
      return note.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Color Logic
    Color cardColor = Color(note.colorValue);
    bool isDefaultColor = note.colorValue == 0xFFFFFFFF;

    // Adapt default white for dark mode
    if (isDark && isDefaultColor) {
      cardColor = const Color(0xFF1E1E1E);
    }

    final textColor = (isDark && isDefaultColor) ? Colors.white : Colors.black87;
    final dateColor = (isDark && isDefaultColor) ? Colors.grey[500] : Colors.black54;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    // 2. Formatting
    final plainText = _getPlainText();
    final hasTitle = note.title.trim().isNotEmpty;
    final hasContent = plainText.isNotEmpty;

    return Hero(
      tag: 'note_${note.id}', // Make sure to use same tag in Detail Screen if you want animation
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => NoteDetailScreen(noteId: note.id, initialNote: note)));
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              // Add border only if color is default (to separate from background)
              border: isDefaultColor ? Border.all(color: borderColor, width: 1) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                if (hasTitle)
                  Text(
                    note.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        height: 1.2
                    ),
                  ),

                if (hasTitle && hasContent) const SizedBox(height: 8),

                // Content Preview
                Expanded(
                  child: Text(
                    hasContent ? plainText : "Empty note",
                    maxLines: 6,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(hasContent ? 0.85 : 0.5),
                        height: 1.4,
                        fontStyle: hasContent ? FontStyle.normal : FontStyle.italic
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Smart Date Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(note.date),
                      style: TextStyle(fontSize: 11, color: dateColor, fontWeight: FontWeight.w600),
                    ),
                    if (note.colorValue != 0xFFFFFFFF) // Show simple pin/icon if colored
                      Icon(Icons.circle, size: 8, color: Colors.black.withOpacity(0.1))
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays < 1 && now.day == date.day) {
      return DateFormat('h:mm a').format(date); // 2:30 PM
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE').format(date); // Monday
    } else {
      return DateFormat('MMM d').format(date); // Oct 24
    }
  }
}