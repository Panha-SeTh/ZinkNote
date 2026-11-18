import 'package:flutter_test/flutter_test.dart';
import 'package:zinknote/model/project.dart';
import 'package:zinknote/model/task_priority.dart';
import 'package:zinknote/service/project_service.dart';
import 'package:zinknote/service/task_service.dart';

void main() {
  late List<Project> projects;
  late ProjectService projectService;
  late TaskService service;
  late Project project;

  setUp(() {
    projects = [];
    projectService = ProjectService(projects);
    service = TaskService(projects);
    project = projectService.createProject('Course');
  });

  test('TS-01 task accepts no due date and keeps priority', () {
    final task = service.createTask(
      project.id,
      'Assignment',
      priority: TaskPriority.high,
    );
    expect(task.dueDate, isNull);
    expect(task.priority, TaskPriority.high);
    expect(project.tasks, [same(task)]);
  });

  test('TS-02 blank task title is rejected', () {
    expect(() => service.createTask(project.id, '  '), throwsArgumentError);
    expect(project.tasks, isEmpty);
  });

  test('TS-03 unknown project rejects task without mutation', () {
    expect(() => service.createTask('absent', 'Task'), throwsStateError);
    expect(project.tasks, isEmpty);
  });

  test('TS-04 valid subtask starts incomplete', () {
    final task = service.createTask(project.id, 'Task');
    final subtask = service.addSubtask(task.id, 'Step 1');
    expect(subtask.isCompleted, isFalse);
    expect(task.subtasks, [same(subtask)]);
  });

  test('TS-05 blank subtask title is rejected', () {
    final task = service.createTask(project.id, 'Task');
    expect(() => service.addSubtask(task.id, ' '), throwsArgumentError);
    expect(task.subtasks, isEmpty);
  });

  test('TS-06 subtask can be completed and reopened', () {
    final task = service.createTask(project.id, 'Task');
    final subtask = service.addSubtask(task.id, 'Step 1');
    service.setSubtaskCompleted(task.id, subtask.id, true);
    expect(subtask.isCompleted, isTrue);
    service.setSubtaskCompleted(task.id, subtask.id, false);
    expect(subtask.isCompleted, isFalse);
  });

  test('TS-07 missing subtask ID preserves current statuses', () {
    final task = service.createTask(project.id, 'Task');
    final subtask = service.addSubtask(task.id, 'Step 1');
    expect(
      () => service.setSubtaskCompleted(task.id, 'missing', true),
      throwsStateError,
    );
    expect(subtask.isCompleted, isFalse);
  });

  test('TS-08 task with unfinished subtask cannot be completed', () {
    final task = service.createTask(project.id, 'Task');
    service.addSubtask(task.id, 'Step 1');
    expect(() => service.setTaskCompleted(task.id, true), throwsStateError);
    expect(task.isCompleted, isFalse);
  });

  test('TS-09 task without subtasks can be completed', () {
    final task = service.createTask(project.id, 'Task');
    service.setTaskCompleted(task.id, true);
    expect(task.isCompleted, isTrue);
  });

  test('TS-10 task with finished subtasks can complete and reopen', () {
    final task = service.createTask(project.id, 'Task');
    final first = service.addSubtask(task.id, 'A');
    final second = service.addSubtask(task.id, 'B');
    service.setSubtaskCompleted(task.id, first.id, true);
    service.setSubtaskCompleted(task.id, second.id, true);
    service.setTaskCompleted(task.id, true);
    expect(task.isCompleted, isTrue);
    service.setTaskCompleted(task.id, false);
    expect(task.isCompleted, isFalse);
  });

  test('TS-11 yesterday is overdue when task is incomplete', () {
    final task = service.createTask(
      project.id,
      'Task',
      dueDate: DateTime(2026, 11, 14, 23, 50),
    );
    expect(service.isOverdue(task, DateTime(2026, 11, 15, 0, 1)), isTrue);
  });

  test('TS-12 due today, no date, or completed is not overdue', () {
    final today = DateTime(2026, 11, 15, 10);
    final dueToday = service.createTask(
      project.id,
      'Due today',
      dueDate: DateTime(2026, 11, 15, 1),
    );
    final undated = service.createTask(project.id, 'Undated');
    final completed = service.createTask(
      project.id,
      'Completed',
      dueDate: DateTime(2026, 11, 12),
    );
    service.setTaskCompleted(completed.id, true);
    expect(service.isOverdue(dueToday, today), isFalse);
    expect(service.isOverdue(undated, today), isFalse);
    expect(service.isOverdue(completed, today), isFalse);
  });

  test('TS-13 a completed task can gain a new incomplete subtask', () {
    final task = service.createTask(project.id, 'Task');
    service.setTaskCompleted(task.id, true);
    final subtask = service.addSubtask(task.id, 'New');
    expect(task.subtasks, [same(subtask)]);
    expect(subtask.isCompleted, isFalse);
    expect(task.isCompleted, isTrue);
  });

  test('TS-14 reopening a subtask changes only the selected subtask', () {
    final task = service.createTask(project.id, 'Task');
    final subtask = service.addSubtask(task.id, 'Step');
    final other = service.addSubtask(task.id, 'Another step');
    service.setSubtaskCompleted(task.id, subtask.id, true);
    service.setSubtaskCompleted(task.id, other.id, true);
    service.setTaskCompleted(task.id, true);

    service.setSubtaskCompleted(task.id, subtask.id, false);
    expect(subtask.isCompleted, isFalse);
    expect(other.isCompleted, isTrue);
    expect(task.isCompleted, isTrue);
  });

  test('updating a task changes its title, due date, and priority', () {
    final task = service.createTask(project.id, 'Original');
    final subtask = service.addSubtask(task.id, 'Step');
    service.setSubtaskCompleted(task.id, subtask.id, true);
    service.setTaskCompleted(task.id, true);
    final dueDate = DateTime(2026, 11, 20);

    final updated = service.updateTask(
      project.id,
      task.id,
      '  Revised  ',
      dueDate: dueDate,
      priority: TaskPriority.high,
    );
    expect(project.tasks, [same(updated)]);
    expect(updated, same(task));
    expect(task.title, 'Revised');
    expect(task.dueDate, dueDate);
    expect(task.priority, TaskPriority.high);
    expect(task.isCompleted, isTrue);
    expect(task.subtasks, [same(subtask)]);

    service.updateTask(
      project.id,
      task.id,
      task.title,
      dueDate: null,
      priority: task.priority,
    );
    expect(task.dueDate, isNull);
  });

  test('invalid task edits leave the original details intact', () {
    final otherProject = projectService.createProject('Other course');
    final dueDate = DateTime(2026, 11, 20);
    final task = service.createTask(project.id, 'Original', dueDate: dueDate);

    expect(
      () => service.updateTask(
        project.id,
        task.id,
        '   ',
        dueDate: null,
        priority: TaskPriority.high,
      ),
      throwsArgumentError,
    );
    expect(
      () => service.updateTask(
        otherProject.id,
        task.id,
        'Revised',
        dueDate: null,
        priority: TaskPriority.high,
      ),
      throwsStateError,
    );
    expect(task.title, 'Original');
    expect(task.dueDate, dueDate);
    expect(task.priority, TaskPriority.medium);
  });

  test('deleting a task removes it from the project and progress', () {
    final task = service.createTask(project.id, 'Remove');
    final retained = service.createTask(project.id, 'Keep');
    service.setTaskCompleted(task.id, true);
    expect(projectService.calculateProgress(project.id), 50.0);

    service.deleteTask(project.id, task.id);
    expect(project.tasks, [same(retained)]);
    expect(projectService.calculateProgress(project.id), 0.0);
    final replacement = TaskService(projects).createTask(project.id, 'New');
    expect(replacement.id, isNot(task.id));
    expect(() => service.deleteTask(project.id, task.id), throwsStateError);
    expect(project.tasks, [same(retained), same(replacement)]);
  });

  test(
    'deleting a task from the wrong project leaves both projects intact',
    () {
      final otherProject = projectService.createProject('Other course');
      final task = service.createTask(project.id, 'Keep');
      final otherTask = service.createTask(otherProject.id, 'Also keep');

      expect(
        () => service.deleteTask(otherProject.id, task.id),
        throwsStateError,
      );
      expect(project.tasks, [same(task)]);
      expect(otherProject.tasks, [same(otherTask)]);
    },
  );
}
