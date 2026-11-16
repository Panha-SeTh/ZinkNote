import 'task_priority.dart';

//temporary task model for the project and note work
class Task {
  final String id;
  String title;
  DateTime? dueDate;
  TaskPriority priority;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
  });
}
