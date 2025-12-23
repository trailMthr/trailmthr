import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trailmthr_test2/features/notes/screens/note_editor_screen.dart';
import 'note_editor_screen.dart';

import '../providers/notes_provider.dart';
import '../models/note_model.dart';
import 'notes_list_screen.dart';

class NotesRootScreen extends StatefulWidget {
  const NotesRootScreen({super.key});

  @override
  State<NotesRootScreen> createState() => _NotesRootScreenState();
}

class _NotesRootScreenState extends State<NotesRootScreen> {
  int _tabIndex = 0; // 0 = Notes, 1 = Diary, 2 = Reminders

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _notesBackground,
      appBar: AppBar(
        backgroundColor: _notesBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _NotesTopPills(
            currentIndex: _tabIndex,
            onChanged: (i) => setState(() => _tabIndex = i),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_tabIndex) {
      case 0:
        return const NotesListScreen();
      case 1:
        return const DiaryListScreen();
      case 2:
        return const RemindersRootScreen();
      default:
        return const NotesListScreen();
    }
  }
}

// ─────────────────────────────────────────────
// Pill tab row (Style 3 — Palette C)
// ─────────────────────────────────────────────

class _NotesTopPills extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _NotesTopPills({
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _pillBarBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _PillButton(
            icon: Icons.notes,
            label: 'Notes',
            selected: currentIndex == 0,
            onTap: () => onChanged(0),
          ),
          _PillButton(
            icon: Icons.auto_awesome, // mushroom/psychedelic vibe later
            label: 'Diary',
            selected: currentIndex == 1,
            onTap: () => onChanged(1),
          ),
          _PillButton(
            icon: Icons.notifications,
            label: 'Reminders',
            selected: currentIndex == 2,
            onTap: () => onChanged(2),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? _pillActive : _pillInactive;
    final textColor = selected ? Colors.white : _pillText;
    final iconColor = selected ? Colors.white : _pillText;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Diary placeholder (we’ll flesh this out next)
// ─────────────────────────────────────────────

class DiaryListScreen extends StatelessWidget {
  const DiaryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Text(
          "Trail Diary coming soon:\n\n"
          "• Voice & video logs\n"
          "• Location-tagged entries\n"
          "• AI summaries & insights\n\n"
          "For now, use Notes for journaling.",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Reminders root — list view now, calendar later
// ─────────────────────────────────────────────

class RemindersRootScreen extends StatelessWidget {
  const RemindersRootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, _) {
        final all = notesProvider.notes;
        final reminders = all
            .where((n) => n.reminderEnabled && n.reminderTime != null)
            .toList()
          ..sort((a, b) => a.reminderTime!.compareTo(b.reminderTime!));

        if (reminders.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                "No reminders yet.\n\n"
                "Add a reminder to any note and it will show up here.",
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final now = DateTime.now();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            final n = reminders[index];
            final t = n.reminderTime!;
            final isPast = t.isBefore(now);

            return Card(
              color: _reminderCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                onTap: () {
                  // Open the full note editor when tapped
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NoteEditorScreen(note: n),
                    ),
                  );
                },
                leading: Icon(
                  isPast
                      ? Icons.notifications_off_outlined
                      : Icons.notifications_active_outlined,
                  color: isPast ? Colors.grey[600] : Colors.green[700],
                ),
                title: Text(
                  n.title.isEmpty ? 'Reminder' : n.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _formatReminderSubtitle(n),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  _formatTimeShort(t),
                  style: TextStyle(
                    fontSize: 12,
                    color: isPast ? Colors.grey[700] : Colors.black87,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _formatReminderSubtitle(Note n) {
    final content = n.content.trim();
    final base = content.isEmpty ? 'No note content' : content;
    if (base.length > 80) {
      return base.substring(0, 77) + '...';
    }
    return base;
  }

  static String _formatTimeShort(DateTime dt) {
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${dt.month}/${dt.day} ${dt.hour}:$mm';
  }
}

// ─────────────────────────────────────────────
// Palette C — Desert Mesa 🌵
// ─────────────────────────────────────────────

const _notesBackground = Color(0xFFF2E1D5); // sand
const _pillBarBackground = Color(0xFFE7D3C2); // slightly darker sand
const _pillActive = Color(0xFFC17F59); // rust orange
const _pillInactive = Color(0xFFF2E1D5); // sand
const _pillText = Color(0xFF4B331F); // dark clay
const _reminderCard = Color(0xFFEBD6C7);
