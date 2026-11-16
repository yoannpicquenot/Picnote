import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/themes/colors.dart';
import '../../core/ui/buttons.dart';
import '../../core/ui/pn_icon.dart';
import '../../core/ui/sheet.dart';
import 'note_delta.dart';

/// A new table: a header row and two empty rows, two columns.
const newTableCells = [
  ['', ''],
  ['', ''],
  ['', ''],
];

/// The embed holding [cells].
BlockEmbed tableBlockEmbed(List<List<String>> cells) => CustomBlockEmbed(tableEmbed, jsonEncode(cells));

/// Draws a table embed in the note. Tapping it edits it in a sheet; the
/// first row is the header.
class TableEmbedBuilder extends EmbedBuilder {
  const TableEmbedBuilder({required this.onEdit});

  /// Opens the editor for the table at [offset] in the document.
  final void Function(int offset, List<List<String>> cells) onEdit;

  @override
  String get key => tableEmbed;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final node = embedContext.node;
    final cells = tableCells(node.value.data);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: embedContext.readOnly ? null : () => onEdit(node.documentOffset, cells),
        child: NoteTableView(cells: cells),
      ),
    );
  }

  @override
  String toPlainText(Embed node) => tableCells(node.value.data).map((r) => r.join('\t')).join('\n');
}

/// The table as the note shows it, scrolling sideways when wide.
class NoteTableView extends StatelessWidget {
  const NoteTableView({super.key, required this.cells});

  final List<List<String>> cells;

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) return const SizedBox.shrink();
    const border = BorderSide(color: PnColors.line);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: PnColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: const TableBorder(horizontalInside: border, verticalInside: border),
          children: [
            for (final (i, row) in cells.indexed)
              TableRow(
                decoration: BoxDecoration(color: i == 0 ? PnColors.peach : PnColors.snow),
                children: [
                  for (final cell in row)
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 72, maxWidth: 220),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Text(
                          cell,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w500,
                            color: i == 0 ? PnColors.terraDark : PnColors.ink,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// What [TableSheet] pops: the new cells, or null to delete the table.
typedef TableEdit = ({List<List<String>>? cells});

/// Edits a table cell by cell; rows and columns can be added or removed.
class TableSheet extends StatefulWidget {
  const TableSheet({super.key, required this.cells});

  final List<List<String>> cells;

  @override
  State<TableSheet> createState() => _TableSheetState();
}

class _TableSheetState extends State<TableSheet> {
  late final List<List<TextEditingController>> _rows = [
    for (final row in (widget.cells.isEmpty ? newTableCells : widget.cells))
      [for (final c in row) TextEditingController(text: c)],
  ];

  int get _width => _rows.first.length;

  @override
  void dispose() {
    for (final c in _rows.expand((r) => r)) {
      c.dispose();
    }
    super.dispose();
  }

  void _addRow() => setState(() => _rows.add([for (var i = 0; i < _width; i++) TextEditingController()]));

  void _addColumn() => setState(() {
    for (final r in _rows) {
      r.add(TextEditingController());
    }
  });

  void _removeRow(int i) => setState(() {
    for (final c in _rows.removeAt(i)) {
      c.dispose();
    }
  });

  void _removeColumn(int k) => setState(() {
    for (final r in _rows) {
      r.removeAt(k).dispose();
    }
  });

  void _save() => Navigator.pop<TableEdit>(context, (
    cells: [
      for (final r in _rows) [for (final c in r) c.text.trim()],
    ],
  ));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget remove(String label, VoidCallback? onTap) => IconButton(
      tooltip: label,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: PnIcon(PnIcons.close, size: 16, color: onTap == null ? PnColors.grey500 : PnColors.muted),
    );
    return PnSheet(
      title: l10n.tableTitle,
      footer: PnButton(label: l10n.save, onPressed: _save),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A remove button over each column.
              Row(
                children: [
                  for (var k = 0; k < _width; k++)
                    SizedBox(
                      width: 140,
                      child: Center(child: remove(l10n.tableRemoveColumn, _width > 1 ? () => _removeColumn(k) : null)),
                    ),
                ],
              ),
              for (final (i, row) in _rows.indexed)
                Row(
                  children: [
                    for (final c in row)
                      Container(
                        width: 136,
                        margin: const EdgeInsets.fromLTRB(0, 0, 4, 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: i == 0 ? PnColors.peach : PnColors.cream,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: c,
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w500,
                            color: i == 0 ? PnColors.terraDark : PnColors.ink,
                          ),
                          decoration: InputDecoration.collapsed(
                            hintText: i == 0 ? l10n.tableHeaderHint : '',
                            hintStyle: const TextStyle(color: PnColors.placeholder),
                          ),
                        ),
                      ),
                    remove(l10n.tableRemoveRow, _rows.length > 1 ? () => _removeRow(i) : null),
                  ],
                ),
            ],
          ),
        ),
        Row(
          children: [
            LinkButton(label: l10n.tableAddRow, onPressed: _addRow),
            const SizedBox(width: 20),
            LinkButton(label: l10n.tableAddColumn, onPressed: _addColumn),
            const Spacer(),
            LinkButton(
              label: l10n.delete,
              color: PnColors.danger,
              onPressed: () => Navigator.pop<TableEdit>(context, (cells: null)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Edits the table at [offset] of [controller]'s document.
Future<void> editTable(BuildContext context, QuillController controller, int offset, List<List<String>> cells) async {
  final edit = await showPnSheet<TableEdit>(context, TableSheet(cells: cells), editing: true);
  if (edit == null) return;
  final next = edit.cells;
  if (next == null) {
    // The embed and its line, unless it is the last one (a document always
    // ends with a newline).
    final last = offset + 1 >= controller.document.length - 1;
    controller.replaceText(offset, last ? 1 : 2, '', TextSelection.collapsed(offset: offset));
  } else {
    controller.replaceText(offset, 1, tableBlockEmbed(next), null);
  }
}
