import '../model/project.dart';
import '../model/subtask.dart';
import '../model/task.dart';
import '../model/task_priority.dart';

///services share the same `List<Project>` to work on the same in-memory data.
class TaskService {
  static int _nextTaskNumber = 1;
  final List<Project> projects;

  TaskService(this.projects);

  Task createTask(
    String projectId,
    String title, {
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
  }) {
    final project = _projectOrThrow(projectId);
    final validTitle = _requireNonBlank(title, 'Task title');
    final task = Task(
      id: _unusedTaskId(),
      title: validTitle,
      dueDate: dueDate,
      priority: priority,
    );
    project.addTask(task);
    return task;
  }

  ///replaces the task details, pass null to clear its due date.
  Task updateTask(
    String projectId,
    String taskId,
    String title, {
    required DateTime? dueDate,
    required TaskPriority priority,
  }) {
    final project = _projectOrThrow(projectId);
    final task = _projectTaskOrThrow(project, taskId);
    task.title = _requireNonBlank(title, 'Task title');
    task.dueDate = dueDate;
    task.priority = priority;
    return task;
  }

  void deleteTask(String projectId, String taskId) {
    final project = _projectOrThrow(projectId);
    final task = _projectTaskOrThrow(project, taskId);
    project.tasks.remove(task);
  }

  Subtask addSubtask(String taskId, String title) {
    final task = _taskOrThrow(taskId);
    final validTitle = _requireNonBlank(title, 'Subtask title');
    final subtask = Subtask(id: _unusedSubtaskId(), title: validTitle);
    task.addSubtask(subtask);
    return subtask;
  }

  void setSubtaskCompleted(String taskId, String subtaskId, bool value) {
    final task = _taskOrThrow(taskId);
    Subtask? selected;
    for (final subtask in task.subtasks) {
      if (subtask.id == subtaskId) {
        selected = subtask;
        break;
      }
    }
    if (selected == null) {
      throw StateError('Subtask not found: $subtaskId');
    }
    selected.setCompleted(value);
  }

  void setTaskCompleted(String taskId, bool value) {
    final task = _taskOrThrow(taskId);
    if (value && task.hasIncompleteSubtasks()) {
      throw StateError('Finish all subtasks before completing this task');
    }
    task.isCompleted = value;
  }

  //compare calendar dates not hours/minutes.
  bool isOverdue(Task task, DateTime referenceDate) {
    if (task.isCompleted || task.dueDate == null) return false;
    final due = task.dueDate!;
    final dueDay = DateTime(due.year, due.month, due.day);
    final today = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    return dueDay.isBefore(today);
  }

  Project _projectOrThrow(String id) {
    for (final project in projects) {
      if (project.id == id) return project;
    }
    throw StateError('Project not found: $id');
  }

  Task _projectTaskOrThrow(Project project, String id) {
    final task = project.findTask(id);
    if (task == null) throw StateError('Task not found: $id');
    return task;
  }

  Task _taskOrThrow(String id) {
    for (final project in projects) {
      final task = project.findTask(id);
      if (task != null) return task;
    }
    throw StateError('Task not found: $id');
  }

  String _unusedTaskId() {
    //avoid reusing generated task IDs after deletion.
    var id = 'task-${_nextTaskNumber++}';
    while (projects.any((project) => project.findTask(id) != null)) {
      id = 'task-${_nextTaskNumber++}';
    }
    return id;
  }

  String _unusedSubtaskId() {
    var number = 1;
    while (projects.any(
      (project) => project.tasks.any(
        (task) =>
            task.subtasks.any((subtask) => subtask.id == 'subtask-$number'),
      ),
    )) {
      number++;
    }
    return 'subtask-$number';
  }

  String _requireNonBlank(String text, String fieldName) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw ArgumentError('$fieldName cannot be blank');
    return trimmed;
  }
}
