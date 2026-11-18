import '../model/note.dart';
import '../model/project.dart';
import '../model/task.dart';

class ProjectService {
  final List<Project> projects;

  ProjectService(this.projects);

  Project createProject(String name) {
    final validName = _requireNonBlank(name, 'Project name');
    final project = Project(id: _unusedProjectId(), name: validName);
    projects.add(project);
    return project;
  }

  Note createNote(String projectId, String title, {String body = ''}) {
    final project = _projectOrThrow(projectId);
    final validTitle = _requireNonBlank(title, 'Note title');
    final note = Note(id: _unusedNoteId(), title: validTitle, body: body);
    project.addNote(note);
    return note;
  }

  Note updateNote(
    String projectId,
    String noteId,
    String title, {
    String body = '',
  }) {
    final project = _projectOrThrow(projectId);
    final note = project.findNote(noteId);
    if (note == null) throw StateError('Note not found: $noteId');
    final validTitle = _requireNonBlank(title, 'Note title');
    note.editContent(validTitle, body);
    return note;
  }

  void deleteNote(String projectId, String noteId) {
    final project = _projectOrThrow(projectId);
    final note = project.findNote(noteId);
    if (note == null) throw StateError('Note not found: $noteId');
    project.notes.remove(note);
  }

  double calculateProgress(String projectId) {
    final project = _projectOrThrow(projectId);
    if (project.tasks.isEmpty) return 0.0;
    final completed = project.tasks.where((task) => task.isCompleted).length;
    return completed / project.tasks.length * 100;
  }

  //highest priority first then earliest due date then undated items, returns a new list and 
  //does not rearrange any project's task collection.
  List<Task> getPriorityTasks(List<Project> sourceProjects) {
    final result = sourceProjects
        .expand((project) => project.tasks)
        .where((task) => !task.isCompleted)
        .toList();
    result.sort((a, b) {
      final byPriority = b.priority.index.compareTo(a.priority.index);
      if (byPriority != 0) return byPriority;
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
    return result;
  }

  Project _projectOrThrow(String id) {
    for (final project in projects) {
      if (project.id == id) return project;
    }
    throw StateError('Project not found: $id');
  }

  String _unusedProjectId() {
    var number = 1;
    while (projects.any((p) => p.id == 'project-$number')) {
      number++;
    }
    return 'project-$number';
  }

  String _unusedNoteId() {
    var number = 1;
    while (projects.any(
      (project) => project.notes.any((note) => note.id == 'note-$number'),
    )) {
      number++;
    }
    return 'note-$number';
  }

  String _requireNonBlank(String text, String fieldName) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw ArgumentError('$fieldName cannot be blank');
    return trimmed;
  }
}
