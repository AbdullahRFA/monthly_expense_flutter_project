import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../data/note_repository.dart';
import '../domain/note_model.dart';

class AddEditNoteScreen extends ConsumerStatefulWidget {
  final NoteModel? noteToEdit;
  const AddEditNoteScreen({super.key, this.noteToEdit});

  @override
  ConsumerState<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends ConsumerState<AddEditNoteScreen> {
  final _titleController = TextEditingController();
  late quill.QuillController _quillController;

  int _selectedColor = 0xFFFFFFFF; // Default White
  bool _isLoading = false;

  final List<int> _colors = [
    0xFFFFFFFF, // White
    0xFFF28B82, // Red
    0xFFFBBC04, // Orange
    0xFFFFF475, // Yellow
    0xFFCCFF90, // Green
    0xFFA7FFEB, // Teal
    0xFFCBF0F8, // Blue
    0xFFAECBFA, // Dark Blue
    0xFFD7AEFB, // Purple
    0xFFE6C9A8, // Brown
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    if (widget.noteToEdit != null) {
      _titleController.text = widget.noteToEdit!.title;
      _selectedColor = widget.noteToEdit!.colorValue;

      try {
        final json = jsonDecode(widget.noteToEdit!.content);
        _quillController = quill.QuillController(
          document: quill.Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        _quillController = quill.QuillController(
          document: quill.Document()..insert(0, widget.noteToEdit!.content),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } else {
      _quillController = quill.QuillController.basic();
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    final contentJson = jsonEncode(_quillController.document.toDelta().toJson());
    final plainText = _quillController.document.toPlainText().trim();

    if (_titleController.text.trim().isEmpty && plainText.isEmpty) {
      Navigator.pop(context);
      return;
    }

    try {
      if (widget.noteToEdit == null) {
        await ref.read(noteRepositoryProvider).addNote(
          _titleController.text.trim(),
          contentJson,
          _selectedColor,
        );
      } else {
        final updated = NoteModel(
          id: widget.noteToEdit!.id,
          title: _titleController.text.trim(),
          content: contentJson,
          date: widget.noteToEdit!.date,
          lastEdited: DateTime.now(),
          colorValue: _selectedColor,
        );
        await ref.read(noteRepositoryProvider).updateNote(updated);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);

    Color bgColor = Color(_selectedColor);
    if (isDark && _selectedColor == 0xFFFFFFFF) {
      bgColor = const Color(0xFF1E1E1E);
    }
    final textColor = (isDark && _selectedColor == 0xFFFFFFFF) ? Colors.white : Colors.black87;

    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _save,
              child: Text("Save", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
            )
          ],
        ),
        bottomNavigationBar: _buildColorPalette(isDark),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _titleController,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                decoration: InputDecoration(
                  hintText: "Title",
                  hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                  border: InputBorder.none,
                ),
              ),
            ),
            const Divider(),

            // --- UPDATED TOOLBAR CONFIGURATION ---
            quill.QuillSimpleToolbar(
              controller: _quillController,
              configurations: quill.QuillSimpleToolbarConfigurations(
                showFontFamily: false,
                showSearchButton: false,
                showIndent: false,
                showInlineCode: false,
                toolbarIconAlignment: WrapAlignment.start,
                // Fixed: Use buttonOptions to set icon colors
                buttonOptions: quill.QuillSimpleToolbarButtonOptions(
                  base: quill.QuillToolbarBaseButtonOptions(
                    iconTheme: quill.QuillIconTheme(
                      iconButtonUnselectedData: quill.IconButtonData(
                        color: textColor.withOpacity(0.7),
                      ),
                      iconButtonSelectedData: quill.IconButtonData(
                        color: Colors.teal,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: quill.QuillEditor.basic(
                  controller: _quillController,
                  configurations: quill.QuillEditorConfigurations(
                    placeholder: "Start typing...",
                    autoFocus: false,
                    expands: false,
                    padding: const EdgeInsets.only(bottom: 20),
                    // Fixed: Added missing HorizontalSpacing(0, 0)
                    customStyles: quill.DefaultStyles(
                      paragraph: quill.DefaultTextBlockStyle(
                          TextStyle(fontSize: 16, color: textColor, height: 1.5),
                          const quill.HorizontalSpacing(0, 0), // <--- MISSING ARGUMENT ADDED
                          const quill.VerticalSpacing(0, 0),
                          const quill.VerticalSpacing(0, 0),
                          null
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPalette(bool isDark) {
    return Container(
      height: 60,
      color: isDark ? Colors.black26 : Colors.transparent,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final colorInt = _colors[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedColor = colorInt),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Color(colorInt),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selectedColor == colorInt ? Colors.black87 : Colors.grey.withOpacity(0.3),
                  width: _selectedColor == colorInt ? 2 : 1,
                ),
              ),
              child: _selectedColor == colorInt ? const Icon(Icons.check, color: Colors.black87) : null,
            ),
          );
        },
      ),
    );
  }
}