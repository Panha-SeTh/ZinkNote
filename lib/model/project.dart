import 'note.dart';
import 'task.dart';

class Project {
  final String id;
  String name;
  final List<Note> notes;
  final List<Task> tasks;

  Project({
    required this.id,
    required this.name,
    List<Note>? notes,
    List<Task>? tasks,
  })  : notes = notes ?? [],
        tasks = tasks ?? [];

  void addNote(Note note) => notes.add(note);
  void addTask(Task task) => tasks.add(task);

  Note? findNote(String noteId) {
    for (final note in notes) {
      if (note.id == noteId) return note;
    }
    return null;
  }

  Task? findTask(String taskId) {
    for (final task in tasks) {
      if (task.id == taskId) return task;
    }
    return null;
  }
}
