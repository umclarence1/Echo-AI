import 'package:flutter/material.dart';
import '../../models/prepared_board.dart';
import '../../services/board_repository.dart';
import '../../services/language_scope.dart';
import 'board_dialogs.dart';
import 'board_editor_screen.dart';
import 'board_present_screen.dart';

class BoardsScreen extends StatefulWidget {
  final BoardRepository? repository;
  const BoardsScreen({super.key, this.repository});
  @override
  State<BoardsScreen> createState() => _BoardsScreenState();
}

class _BoardsScreenState extends State<BoardsScreen> {
  late final BoardRepository _repository =
      widget.repository ?? BoardRepository();
  List<PreparedBoard> _boards = [];
  bool _loading = true;
  bool _failed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final boards = await _repository.load();
      if (mounted) {
        setState(() {
          _boards = boards;
          _failed = false;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _create() async {
    final title = await boardNameDialog(context, context.tr('boards_create'));
    if (title == null || !mounted) return;
    final now = DateTime.now();
    await _edit(
      PreparedBoard(
        id: PreparedBoard.newId(),
        title: title,
        sections: [],
        createdAt: now,
        updatedAt: now,
      ),
      isNew: true,
    );
  }

  Future<void> _edit(PreparedBoard board, {bool isNew = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => BoardEditorScreen(
          board: board,
          repository: _repository,
          isNew: isNew,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _action(PreparedBoard board, String action) async {
    if (_busy) return;
    if (action == 'edit') {
      await _edit(board);
      return;
    }
    if (action == 'delete') {
      final confirmed = await boardConfirm(
        context,
        context.tr('boards_delete'),
        context.tr('boards_delete_message', {'name': board.title}),
        context.tr('delete'),
      );
      if (!confirmed || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      if (action == 'delete') {
        await _repository.delete(board.id);
      } else {
        await _repository.save(
          board.duplicate(
            context.tr('boards_copy_name', {'name': board.title}),
          ),
        );
      }
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('boards_save_error'))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('boards_title'))),
    floatingActionButton: _loading || _failed || _busy
        ? null
        : FloatingActionButton.extended(
            onPressed: _create,
            icon: const Icon(Icons.add),
            label: Text(context.tr('boards_create')),
          ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _failed
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.tr('boards_load_error')),
                TextButton(
                  onPressed: _load,
                  child: Text(context.tr('boards_retry')),
                ),
              ],
            ),
          )
        : _boards.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                context.tr('boards_empty'),
                textAlign: TextAlign.center,
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            itemCount: _boards.length,
            itemBuilder: (context, index) {
              final board = _boards[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.dashboard_outlined),
                  title: Text(board.title),
                  subtitle: Text(
                    context.tr('boards_summary', {
                      'sections': '${board.sections.length}',
                      'words':
                          '${board.sections.fold<int>(0, (sum, section) => sum + section.items.length)}',
                    }),
                  ),
                  onTap: _busy ? null : () => _edit(board),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: context.tr('boards_present'),
                        icon: const Icon(Icons.play_circle_outline),
                        onPressed: _busy || board.sections.isEmpty
                            ? null
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      BoardPresentScreen(board: board),
                                ),
                              ),
                      ),
                      PopupMenuButton<String>(
                        enabled: !_busy,
                        onSelected: (value) => _action(board, value),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(context.tr('boards_edit')),
                          ),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Text(context.tr('boards_duplicate')),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(context.tr('delete')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
  );
}
