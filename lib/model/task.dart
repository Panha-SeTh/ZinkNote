import 'subtask.dart';
import 'task_priority.dart';

class Task {
  final String id;
  String title;
  DateTime? dueDate;
  TaskPriority priority;
  bool isCompleted;
  final List<Subtask> subtasks;

  Task({
    required this.id,
    required this.title,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
    List<Subtask>? subtasks,
  }) : subtasks = subtasks ?? [];

  void addSubtask(Subtask subtask) {
    subtasks.add(subtask);
  }

  bool hasIncompleteSubtasks() =>
      subtasks.any((subtask) => !subtask.isCompleted);
}
