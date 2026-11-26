import { execFileSync } from 'node:child_process';
import type { ExtensionReviewSnapshotNote, HunkExtensionAPI } from 'hunkdiff/extension';

function formatRange(side: string, range?: readonly [number, number]) {
  if (!range) {
    return '';
  }

  return range[0] === range[1] ? ` ${side}:${range[0]}` : ` ${side}:${range[0]}-${range[1]}`;
}

function formatNote(note: ExtensionReviewSnapshotNote, path: string) {
  const where = `${path}${formatRange('new', note.anchor.newRange)}${formatRange('old', note.anchor.oldRange)}`;
  const parent = note.parentId ? ` (reply to [${note.parentId}])` : '';
  const body = [note.summary, note.rationale].filter(Boolean).join('\n\n').replaceAll('\n', '\n  ');

  return `- [${note.id}] ${where}${parent}: ${body}`;
}

export default function submit(hunk: HunkExtensionAPI) {
  const block = process.env.HUNK_CALLBACK_BLOCK;

  if (!block) {
    return;
  }

  const sent = new Map<string, string>();

  hunk.registerCommand({ id: 'submit', title: 'Submit review', key: 'S' }, (ctx) => {
    const snapshot = ctx.review.snapshot();

    if (!snapshot) {
      ctx.notify('The review is unavailable', 'error');
      return;
    }

    const paths = new Map(snapshot.files.map((file) => [file.fileKey, file.path]));
    const notes = snapshot.notes
      .flatMap((note) => {
        const path = paths.get(note.fileKey);

        return note.source === 'user' && path !== undefined ? [{ id: note.id, text: formatNote(note, path) }] : [];
      })
      .filter((note) => sent.get(note.id) !== note.text);
    const message = notes.length ? ['Hunk notes:', ...notes.map((note) => note.text)].join('\n') : 'Hunk notes: none';

    execFileSync('rex', ['send', '-b', block, message]);
    execFileSync('rex', ['send-key', '-b', block, 'enter']);

    for (const note of notes) {
      sent.set(note.id, note.text);
    }

    ctx.notify('Review submitted');
  });
}
