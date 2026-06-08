import 'dart:async';
import 'dart:convert';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final AppState state;

  const TaskDetailScreen({super.key, required this.task, required this.state});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late final TextEditingController _titleCtrl;
  late TaskSection _section;
  late final EditorState _editorState;
  StreamSubscription? _editorSub;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _section = widget.task.section;

    final bodyJson = widget.task.bodyJson;
    if (bodyJson != null && bodyJson.isNotEmpty) {
      try {
        final jsonMap = jsonDecode(bodyJson) as Map<String, dynamic>;
        _editorState = EditorState(document: Document.fromJson(jsonMap));
      } catch (_) {
        _editorState = EditorState.blank(withInitialText: true);
      }
    } else {
      _editorState = EditorState.blank(withInitialText: true);
    }

    _titleCtrl.addListener(_scheduleSave);
    _editorSub =
        _editorState.transactionStream.listen((_) => _scheduleSave());
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), _persist);
  }

  void _persist() {
    final newTitle = _titleCtrl.text.trim();
    final bodyJson = jsonEncode(_editorState.document.toJson());
    widget.state.updateTask(
      widget.task.id,
      title: newTitle.isNotEmpty ? newTitle : null,
      section: _section,
      bodyJson: bodyJson,
    );
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _persist();
    _editorSub?.cancel();
    _titleCtrl.removeListener(_scheduleSave);
    _titleCtrl.dispose();
    _editorState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.beige,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, isDark),
            _buildTitle(context, isDark),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 2, 22, 10),
              child: Text(
                'Last modified by ${widget.task.lastModifiedBy} ${widget.task.timeAgo}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: isDark
                  ? AppColors.white.withOpacity(0.06)
                  : AppColors.brownDark.withOpacity(0.07),
            ),
            Expanded(
              child: MobileToolbarV2(
                toolbarHeight: 48,
                backgroundColor:
                    isDark ? AppColors.darkCard : AppColors.beigeCard,
                foregroundColor: isDark
                    ? AppColors.beigeCard.withOpacity(0.65)
                    : AppColors.brownDark.withOpacity(0.65),
                iconColor:
                    isDark ? AppColors.beigeCard : AppColors.brownDark,
                itemHighlightColor:
                    isDark ? AppColors.brownMedium : AppColors.brownDark,
                editorState: _editorState,
                toolbarItems: [
                  textDecorationMobileToolbarItemV2,
                  linkMobileToolbarItem,
                  blocksMobileToolbarItem,
                ],
                child: AppFlowyEditor(
                  editorState: _editorState,
                  editorStyle: _editorStyle(isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios,
              size: 20,
              color: isDark ? AppColors.brownMedium : AppColors.brownDark,
            ),
          ),
          const Spacer(),
          // Section toggle chip
          GestureDetector(
            onTap: () => setState(() {
              _section = _section == TaskSection.today
                  ? TaskSection.tomorrow
                  : TaskSection.today;
              _scheduleSave();
            }),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.brownMedium.withOpacity(0.15)
                    : AppColors.brownDark.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? AppColors.brownMedium.withOpacity(0.35)
                      : AppColors.brownDark.withOpacity(0.18),
                ),
              ),
              child: Text(
                _section == TaskSection.today ? 'Today' : 'Tomorrow',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.brownMedium : AppColors.brownDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              widget.state.deleteTask(widget.task.id);
              Navigator.pop(context);
            },
            child: Icon(
              Icons.delete_outline,
              size: 20,
              color: isDark
                  ? AppColors.beigeCard.withOpacity(0.35)
                  : AppColors.brownDark.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
      child: TextField(
        controller: _titleCtrl,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.beigeCard : AppColors.brownDark,
          fontFamily: 'Chillax',
        ),
        maxLines: null,
        decoration: InputDecoration(
          hintText: 'Task title',
          hintStyle: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.beigeCard.withOpacity(0.2)
                : AppColors.brownDark.withOpacity(0.2),
            fontFamily: 'Chillax',
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  EditorStyle _editorStyle(bool isDark) {
    return EditorStyle.mobile(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      cursorColor: isDark ? AppColors.brownMedium : AppColors.brownDark,
      selectionColor: (isDark ? AppColors.brownMedium : AppColors.brownDark)
          .withOpacity(0.25),
      textStyleConfiguration: TextStyleConfiguration(
        text: TextStyle(
          color: isDark
              ? AppColors.beigeCard.withOpacity(0.85)
              : AppColors.brownDark.withOpacity(0.85),
          fontSize: 15,
          height: 1.6,
          fontFamily: 'GeneralSans',
        ),
        bold: const TextStyle(fontWeight: FontWeight.w700),
        italic: const TextStyle(fontStyle: FontStyle.italic),
        underline: const TextStyle(decoration: TextDecoration.underline),
        strikethrough:
            const TextStyle(decoration: TextDecoration.lineThrough),
        href: TextStyle(
          color: isDark ? AppColors.brownMedium : AppColors.brown,
          decoration: TextDecoration.underline,
        ),
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: isDark ? AppColors.brownMedium : AppColors.brownDark,
          backgroundColor: isDark
              ? AppColors.darkCardLight
              : AppColors.brownDark.withOpacity(0.07),
        ),
      ),
    );
  }
}
