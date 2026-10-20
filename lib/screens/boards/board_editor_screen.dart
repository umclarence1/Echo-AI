import 'package:flutter/material.dart';
import '../../models/prepared_board.dart';
import '../../models/vocabulary_item.dart';
import '../../services/app_settings.dart';
import '../../services/board_repository.dart';
import '../../services/board_vocabulary.dart';
import '../../services/language_scope.dart';
import '../../services/user_data_store.dart';
import '../../widgets/vocabulary_grid.dart';
import '../library_screen.dart';
import 'board_dialogs.dart';

class BoardEditorScreen extends StatefulWidget {
  final PreparedBoard board;
  final BoardRepository repository;
  final bool isNew;
  const BoardEditorScreen({
    super.key,
    required this.board,
    required this.repository,
    this.isNew = false,
  });
  @override
  State<BoardEditorScreen> createState() => _BoardEditorScreenState();
}

class _BoardEditorScreenState extends State<BoardEditorScreen> {
  late PreparedBoard _board = widget.board;
  late bool _dirty = widget.isNew;
  bool _saving = false;
  bool _leaving = false;

  void _change(PreparedBoard board) => setState(() {
    _board = board;
    _dirty = true;
  });

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.repository.save(_board);
      if (!mounted) return;
      setState(() {
        _dirty = false;
        _saving = false;
        _leaving = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('boards_save_error'))));
    }
  }

  Future<void> _exit() async {
    if (_saving || _leaving) return;
    if (_dirty &&
        !await boardConfirm(
          context,
          context.tr('boards_unsaved'),
          context.tr('boards_discard_message'),
          context.tr('boards_discard'),
        )) {
      return;
    }
    if (!mounted) return;
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _rename() async {
    final title = await boardNameDialog(
      context,
      context.tr('boards_rename'),
      initial: _board.title,
    );
    if (title != null && mounted) _change(_board.copyWith(title: title));
  }

  Future<void> _sectionName([int? index]) async {
    final title = await boardNameDialog(
      context,
      context.tr(
        index == null ? 'boards_add_section' : 'boards_rename_section',
      ),
      initial: index == null ? '' : _board.sections[index].title,
    );
    if (title == null || !mounted) return;
    final sections = [..._board.sections];
    if (index == null) {
      sections.add(
        BoardSection(id: PreparedBoard.newId(), title: title, items: []),
      );
    } else {
      sections[index] = sections[index].copyWith(title: title);
    }
    _change(_board.copyWith(sections: sections));
  }

  void _updateItems(int index, List<VocabularyItem> items) {
    final sections = [..._board.sections];
    sections[index] = sections[index].copyWith(items: items);
    _change(_board.copyWith(sections: sections));
  }

  void _pickWords(int index) {
    final section = _board.sections[index];
    final words = <String, VocabularyItem>{
      for (final item in BoardVocabulary.items) item.id: item,
      for (final item in UserDataStore.loadPeople()) item.id: item,
      for (final item in UserDataStore.loadFavorites()) item.id: item,
      for (final c in UserDataStore.loadCustomContexts())
        for (final item in c.vocabulary) item.id: item,
      for (final item in section.items) item.id: item,
    }.values.toList();
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LibraryScreen(
          items: words,
          categoryName: (text) =>
              BoardVocabulary.label(text, AppSettings.language.value.code),
          labelBuilder: (item) => BoardVocabulary.label(
            item.label,
            AppSettings.language.value.code,
          ),
          secondaryLabelBuilder: (item) =>
              AppSettings.language.value.isEnglish ? null : item.label,
          onItemTap: (_) {},
          initialSelection: section.items.map((i) => i.id).toSet(),
          onSelectionDone: (chosen) {
            final selected = chosen.map((i) => i.id).toSet();
            final existing = section.items.map((i) => i.id).toSet();
            _updateItems(index, [
              ...section.items.where((i) => selected.contains(i.id)),
              ...chosen.where((i) => !existing.contains(i.id)),
            ]);
          },
        ),
      ),
    );
  }

  Future<void> _sectionAction(int index, String action) async {
    if (action == 'rename') {
      await _sectionName(index);
      return;
    }
    if (action == 'delete') {
      final confirmed = await boardConfirm(
        context,
        context.tr('boards_delete_section'),
        context.tr('boards_delete_section_message'),
        context.tr('delete'),
      );
      if (!confirmed || !mounted) return;
      final sections = [..._board.sections]..removeAt(index);
      _change(_board.copyWith(sections: sections));
      return;
    }
    final sections = [..._board.sections];
    final destination = action == 'up' ? index - 1 : index + 1;
    final section = sections.removeAt(index);
    sections.insert(destination, section);
    _change(_board.copyWith(sections: sections));
  }

  Future<void> _tileAction(int sectionIndex, int index, String action) async {
    final items = [..._board.sections[sectionIndex].items];
    if (action == 'remove') {
      items.removeAt(index);
      _updateItems(sectionIndex, items);
      return;
    }
    if (action == 'move') {
      final destination = await showDialog<int>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: Text(context.tr('boards_move_section')),
          children: [
            for (var i = 0; i < _board.sections.length; i++)
              if (i != sectionIndex)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogContext, i),
                  child: Text(_board.sections[i].title),
                ),
          ],
        ),
      );
      if (destination == null || !mounted) return;
      final item = items.removeAt(index);
      final sections = [..._board.sections];
      sections[sectionIndex] = sections[sectionIndex].copyWith(items: items);
      final target = sections[destination];
      sections[destination] = target.copyWith(
        items: [
          ...target.items,
          if (!target.items.any((i) => i.id == item.id)) item,
        ],
      );
      _change(_board.copyWith(sections: sections));
      return;
    }
    final destination = action == 'earlier' ? index - 1 : index + 1;
    final item = items.removeAt(index);
    items.insert(destination, item);
    _updateItems(sectionIndex, items);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _leaving || (!_dirty && !_saving),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _exit();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(_board.title),
        actions: [
          IconButton(
            onPressed: _saving ? null : _rename,
            tooltip: context.tr('boards_rename'),
            icon: const Icon(Icons.edit_outlined),
          ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(context.tr(_saving ? 'boards_saving' : 'boards_save')),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text(context.tr('boards_editor_hint')),
            const SizedBox(height: 8),
            if (_board.sections.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  context.tr('boards_no_sections'),
                  textAlign: TextAlign.center,
                ),
              ),
            for (var s = 0; s < _board.sections.length; s++) _sectionCard(s),
            OutlinedButton.icon(
              onPressed: () => _sectionName(),
              icon: const Icon(Icons.add),
              label: Text(context.tr('boards_add_section')),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );

  Widget _sectionCard(int sectionIndex) {
    final section = _board.sections[sectionIndex];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: context.tr('boards_section_options'),
                  onSelected: (action) => _sectionAction(sectionIndex, action),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'rename',
                      child: Text(context.tr('boards_rename_section')),
                    ),
                    if (sectionIndex > 0)
                      PopupMenuItem(
                        value: 'up',
                        child: Text(context.tr('boards_move_up')),
                      ),
                    if (sectionIndex < _board.sections.length - 1)
                      PopupMenuItem(
                        value: 'down',
                        child: Text(context.tr('boards_move_down')),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(context.tr('boards_delete_section')),
                    ),
                  ],
                ),
              ],
            ),
            if (section.items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(context.tr('boards_no_words')),
              ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: section.items.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                mainAxisExtent: 170,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final item = section.items[index];
                return Column(
                  children: [
                    Expanded(
                      child: Semantics(
                        child: VocabularyTile(
                          item: item,
                          label: BoardVocabulary.label(
                            item.label,
                            AppSettings.language.value.code,
                          ),
                          onTap: () => _pickWords(sectionIndex),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              '${index + 1}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: context.tr('boards_word_options'),
                            onSelected: (action) =>
                                _tileAction(sectionIndex, index, action),
                            itemBuilder: (_) => [
                              if (index > 0)
                                PopupMenuItem(
                                  value: 'earlier',
                                  child: Text(
                                    context.tr('boards_move_earlier'),
                                  ),
                                ),
                              if (index < section.items.length - 1)
                                PopupMenuItem(
                                  value: 'later',
                                  child: Text(context.tr('boards_move_later')),
                                ),
                              if (_board.sections.length > 1)
                                PopupMenuItem(
                                  value: 'move',
                                  child: Text(
                                    context.tr('boards_move_section'),
                                  ),
                                ),
                              PopupMenuItem(
                                value: 'remove',
                                child: Text(context.tr('boards_remove_word')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            TextButton.icon(
              onPressed: () => _pickWords(sectionIndex),
              icon: const Icon(Icons.grid_view),
              label: Text(context.tr('boards_choose_words')),
            ),
          ],
        ),
      ),
    );
  }
}
