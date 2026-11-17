import 'package:flutter_test/flutter_test.dart';
import 'package:picnote/domain/models/note.dart';
import 'package:picnote/ui/note/widgets/note_delta.dart';
import 'package:picnote/ui/note/widgets/note_markdown.dart';

void main() {
  var next = 0;
  String newId() => 'md${next++}';

  const blocks = [
    NoteBlock(id: 'a', type: NoteBlockType.heading, text: 'Voyage', level: 2),
    NoteBlock(
      id: 'b',
      text: 'Très important demain',
      styles: [StyleRange(0, 4, InlineStyle.bold), StyleRange(5, 14, InlineStyle.italic)],
    ),
    NoteBlock(id: 'c', type: NoteBlockType.bullet, text: 'Montréal'),
    NoteBlock(id: 'd', type: NoteBlockType.todo, text: 'Passeports', done: true),
    NoteBlock(id: 'e', type: NoteBlockType.todo, text: 'Adaptateur'),
    NoteBlock(id: 'f', type: NoteBlockType.link, text: 'https://airbnb.com/rooms/1'),
    NoteBlock(
      id: 'g',
      type: NoteBlockType.table,
      cells: [
        ['Quoi', 'Prix'],
        ['Train', '120 €'],
      ],
    ),
  ];

  test('a note is copied as Markdown', () {
    expect(blocksToMarkdown(blocks), '''
## Voyage

**Très** *important* demain

- Montréal
- [x] Passeports
- [ ] Adaptateur

https://airbnb.com/rooms/1

| Quoi | Prix |
| --- | --- |
| Train | 120 € |''');
  });

  test('and pasted back as it was', () {
    expect(sameBlocks(markdownToBlocks(blocksToMarkdown(blocks), newId), blocks), isTrue);
  });

  test('an empty line of the note survives copy and paste', () {
    const withGap = [
      NoteBlock(id: 'a', text: 'Avant'),
      NoteBlock(id: 'b'),
      NoteBlock(id: 'c', type: NoteBlockType.bullet, text: 'Après'),
    ];
    expect(sameBlocks(markdownToBlocks(blocksToMarkdown(withGap), newId), withGap), isTrue);
  });

  test('a page copied from Notion', () {
    const notion = '''
# Week-end à Lyon

Réserver **vite**, c'est ~~cher~~ `complet` le 3\\*.

- Train
    - Aller vendredi
- [ ] Hôtel
- [x] Billets

> Penser aux bouchons

---

```
code gardé tel quel
```

<aside>
💡 Prendre le parapluie
</aside>

![](https://img.fr/a.png)


Fin''';
    final back = markdownToBlocks(notion, newId);
    expect(back.map((b) => (b.type, b.text)), [
      (NoteBlockType.heading, 'Week-end à Lyon'),
      (NoteBlockType.text, "Réserver vite, c'est cher complet le 3*."),
      (NoteBlockType.bullet, 'Train'),
      (NoteBlockType.bullet, 'Aller vendredi'),
      (NoteBlockType.todo, 'Hôtel'),
      (NoteBlockType.todo, 'Billets'),
      (NoteBlockType.text, 'Penser aux bouchons'),
      (NoteBlockType.text, 'code gardé tel quel'),
      (NoteBlockType.text, '💡 Prendre le parapluie'),
      (NoteBlockType.link, 'https://img.fr/a.png'),
      (NoteBlockType.text, ''),
      (NoteBlockType.text, 'Fin'),
    ]);
    expect(back[1].styles, [const StyleRange(9, 13, InlineStyle.bold)]);
    expect(back[5].done, isTrue);
  });

  test('Markdown from elsewhere: "*" bullets, "####" headings, links keep their text', () {
    final back = markdownToBlocks('#### Petit titre\n* un\nVoir [le site](https://x.fr) vite', newId);
    expect(back.map((b) => b.type), [NoteBlockType.heading, NoteBlockType.bullet, NoteBlockType.text]);
    expect(back.first.level, 4);
    expect(back.last.text, 'Voir le site vite');
  });
}
