import 'package:flutter_test/flutter_test.dart';
import 'package:zinknote/model/project.dart';
import 'package:zinknote/model/task.dart';
import 'package:zinknote/model/task_priority.dart';
import 'package:zinknote/service/project_service.dart';

void main() {
  late List<Project> projects;
  late ProjectService service;

  setUp(() {
    projects = [];
    service = ProjectService(projects);
  });

  test('PS-01 valid project has no notes or tasks', () {
    final p = service.createProject('  Semester 1  ');
    expect(p.name, 'Semester 1');
    expect(p.notes, isEmpty);
    expect(p.tasks, isEmpty);
    expect(projects.single, same(p));
  });

  test('PS-02 blank project is rejected without mutation', () {
    expect(() => service.createProject('   '), throwsArgumentError);
    expect(projects, isEmpty);
  });

  test('PS-03 note can have empty body and belongs to project', () {
    final p = service.createProject('Course');
    final note = service.createNote(p.id, 'Lecture 1');
    expect(note.body, isEmpty);
    expect(p.notes.single, same(note));
  });

  test('PS-04 blank note title is rejected', () {
    final p = service.createProject('Course');
    expect(() => service.createNote(p.id, '\t '), throwsArgumentError);
    expect(p.notes, isEmpty);
  });

  test('PS-05 unknown project does not create note', () {
    expect(() => service.createNote('missing', 'Lecture'), throwsStateError);
    expect(projects, isEmpty);
  });

  test('PS-06 updating note changes content and update time', () {
    final p = service.createProject('Course');
    final note = service.createNote(p.id, 'First', body: 'Old');
    final oldUpdatedAt = note.updatedAt;
    final updated = service.updateNote(p.id, note.id, 'Second', body: 'New');
    expect(updated, same(note));
    expect(note.title, 'Second');
    expect(note.body, 'New');
    expect(note.updatedAt.isAfter(oldUpdatedAt), isTrue);
  });

  test('PS-07 unknown note ID leaves existing note unchanged', () {
    final p = service.createProject('Course');
    final note = service.createNote(p.id, 'Original');
    expect(
      () => service.updateNote(p.id, 'absent', 'Replacement'),
      throwsStateError,
    );
    expect(note.title, 'Original');
    expect(p.notes.length, 1);
  });

  test('PS-08 deleting selected note leaves other notes', () {
    final p = service.createProject('Course');
    final n1 = service.createNote(p.id, 'A');
    final n2 = service.createNote(p.id, 'B');
    service.deleteNote(p.id, n1.id);
    expect(p.notes, [same(n2)]);
  });

  test('PS-09 unknown note cannot delete another note', () {
    final p = service.createProject('Course');
    final note = service.createNote(p.id, 'Keep');
    expect(() => service.deleteNote(p.id, 'absent'), throwsStateError);
    expect(p.notes, [same(note)]);
  });

  test('PS-10 progress for project without tasks is zero', () {
    final p = service.createProject('Empty');
    expect(service.calculateProgress(p.id), 0.0);
  });

  test('PS-11 two of four completed tasks gives 50 percent', () {
    final p = service.createProject('Course');
    p.tasks.addAll([
      Task(id: 'task-1', title: 'Read chapter', isCompleted: true),
      Task(id: 'task-2', title: 'Review notes', isCompleted: true),
      Task(id: 'task-3', title: 'Write draft'),
      Task(id: 'task-4', title: 'Submit assignment'),
    ]);
    expect(service.calculateProgress(p.id), 50.0);
  });

  test('PS-12 reopening a task lowers progress', () {
    final p = service.createProject('Course');
    final task = Task(id: 'task-1', title: 'Write draft', isCompleted: true);
    p.addTask(task);
    p.addTask(Task(id: 'task-2', title: 'Review draft', isCompleted: true));
    expect(service.calculateProgress(p.id), 100.0);
    task.isCompleted = false;
    expect(service.calculateProgress(p.id), 50.0);
  });

  test('PS-13 only unfinished tasks in priority and date order', () {
    final p = service.createProject('Course');
    final other = service.createProject('Other course');
    final low = Task(
      id: 'low',
      title: 'Low',
      priority: TaskPriority.low,
      dueDate: DateTime(2026, 11, 30),
    );
    final medium = Task(id: 'medium', title: 'Medium');
    final laterHigh = Task(
      id: 'high-later',
      title: 'High later',
      priority: TaskPriority.high,
      dueDate: DateTime(2026, 12, 5),
    );
    final earlierHigh = Task(
      id: 'high-earlier',
      title: 'High earlier',
      priority: TaskPriority.high,
      dueDate: DateTime(2026, 12, 1),
    );
    final done = Task(
      id: 'done',
      title: 'Done',
      priority: TaskPriority.high,
      isCompleted: true,
    );
    p.tasks.addAll([medium, laterHigh, earlierHigh, done]);
    other.addTask(low);
    expect(service.getPriorityTasks(projects), [
      earlierHigh,
      laterHigh,
      medium,
      low,
    ]);
  });

  test('PS-14 undated tasks are last and empty list is safe', () {
    expect(service.getPriorityTasks(projects), isEmpty);
    final p = service.createProject('Course');
    final noDate = Task(
      id: 'undated',
      title: 'No due',
      priority: TaskPriority.low,
    );
    final dated = Task(
      id: 'dated',
      title: 'Dated',
      priority: TaskPriority.low,
      dueDate: DateTime(2026, 11, 30),
    );
    p.tasks.addAll([noDate, dated]);
    expect(service.getPriorityTasks(projects), [dated, noDate]);
    dated.isCompleted = true;
    noDate.isCompleted = true;
    expect(service.getPriorityTasks(projects), isEmpty);
  });
}
