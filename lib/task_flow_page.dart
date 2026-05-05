import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'data.dart';
import 'goal_calendar_page.dart';

const _uuid = Uuid();

// ------------ TaskFlowPage ------------
class TaskFlowPage extends StatefulWidget {
  final Goal goal;
  const TaskFlowPage({super.key, required this.goal});

  @override
  State<TaskFlowPage> createState() => _TaskFlowPageState();
}

class _TaskFlowPageState extends State<TaskFlowPage> {
  late Box<Task> _taskBox;
  late List<Task> _tasks;

  bool _showingCelebration = false;
  Task? _justCompletedTask;

  @override
  void initState() {
    super.initState();
    _taskBox = Hive.box<Task>('tasks');
    _refreshTasks();
  }

  void _refreshTasks() {
    _tasks = _taskBox.values
        .where((t) => t.goalId == widget.goal.id)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  Task? get _currentTask {
    _refreshTasks();
    return _tasks.cast<Task?>().firstWhere(
          (t) => !t!.completed,
          orElse: () => null,
        );
  }

  void _completeTask(Task task) {
    task.completed = true;
    task.completedDate = DateTime.now();
    task.save();

    final achievementBox = Hive.box<AchievementRecord>('achievements');
    achievementBox.add(AchievementRecord(
      id: _uuid.v4(),
      taskTitle: task.title,
      goalName: widget.goal.name,
      goalColor: widget.goal.colorValue,
      completedAt: DateTime.now(),
    ));

    setState(() {
      _justCompletedTask = task;
      _showingCelebration = true;
    });
  }

  Future<void> _showAddDialog() async {
    final controller = TextEditingController();
    DateTime? selectedDate;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF2B2B2B),
          title: const Text('添加任务', style: TextStyle(color: Color(0xFFDDDDDD))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Color(0xFFDDDDDD)),
                decoration: const InputDecoration(
                  hintText: '任务描述...',
                  hintStyle: TextStyle(color: Color(0x88DDDDDD)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0x44DDDDDD)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0x88DDDDDD)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_today, size: 20, color: Color(0x88DDDDDD)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                  Text(
                    selectedDate != null
                        ? DateFormat('MM/dd').format(selectedDate!)
                        : '无截止日期',
                    style: const TextStyle(color: Color(0x88DDDDDD)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消', style: TextStyle(color: Color(0x88DDDDDD))),
            ),
            TextButton(
              onPressed: () {
                final title = controller.text.trim();
                if (title.isNotEmpty) {
                  Navigator.pop(ctx, {
                    'title': title,
                    'dueDate': selectedDate,
                  });
                }
              },
              child: const Text('添加', style: TextStyle(color: Color(0xFFDDDDDD))),
            ),
          ],
        ),
      ),
    );

    if (result != null && result['title'] != null) {
      _addTask(result['title'] as String, dueDate: result['dueDate'] as DateTime?);
    }
  }

  void _addTask(String title, {DateTime? dueDate}) {
    final maxOrder = _tasks.isEmpty
        ? 0
        : _tasks.map((t) => t.order).reduce((a, b) => a > b ? a : b);
    final newTask = Task(
      id: _uuid.v4(),
      goalId: widget.goal.id,
      title: title,
      completed: false,
      order: maxOrder + 1,
      dueDate: dueDate,
    );
    _taskBox.add(newTask);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentTask;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/waterball_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // 顶部导航（仅返回键）
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Color(0x88FFFFFF), size: 22),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: current == null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('当前没有任务',
                                    style: TextStyle(color: Color(0x88FFFFFF), fontSize: 14)),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.list_alt,
                                          color: Color(0x88FFFFFF)),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => TaskListPage(
                                              goalId: widget.goal.id,
                                              taskBox: _taskBox,
                                              onChanged: () => setState(() {}),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 24),
                                    IconButton(
                                      icon: const Icon(Icons.add,
                                          color: Color(0x88FFFFFF)),
                                      onPressed: _showAddDialog,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Spacer(),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 40),
                                  child: Text(
                                    current.title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Serif',
                                      fontSize: 22,
                                      height: 1.4,
                                      color: Color(0xCCFFFFFF),
                                    ),
                                  ),
                                ),
                              ),
                              if (current.dueDate != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    DateFormat('M月d日').format(current.dueDate!),
                                    style: const TextStyle(
                                      color: Color(0x88FFFFFF),
                                      fontSize: 14,
                                      fontFamily: 'Serif',
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 40),
                              GestureDetector(
                                onTap: () => _completeTask(current),
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0x44FFFFFF),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(Icons.check,
                                      size: 28, color: Color(0x88FFFFFF)),
                                ),
                              ),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 30),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.list_alt,
                                          color: Color(0x88FFFFFF)),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => TaskListPage(
                                              goalId: widget.goal.id,
                                              taskBox: _taskBox,
                                              onChanged: () => setState(() {}),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add,
                                          color: Color(0x88FFFFFF)),
                                      onPressed: _showAddDialog,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
              // 完成祝福语
              if (_showingCelebration)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showingCelebration = false;
                      _justCompletedTask = null;
                    });
                  },
                  child: Container(
                    color: const Color(0x08000000),
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.only(top: 80),
                    child: const Text(
                      '恭喜你，又完成一项任务。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Serif',
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: Color(0xAAFFFFFF),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------ TaskListPage ------------
class TaskListPage extends StatefulWidget {
  final String goalId;
  final Box<Task> taskBox;
  final VoidCallback onChanged;
  const TaskListPage({
    super.key,
    required this.goalId,
    required this.taskBox,
    required this.onChanged,
  });

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  bool _showCompleted = false;

  List<Task> get _filteredTasks {
    final tasks = widget.taskBox.values
        .where((t) => t.goalId == widget.goalId)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    if (!_showCompleted) {
      return tasks.where((t) => !t.completed).toList();
    }
    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/waterball_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // 自定义导航栏（返回 + 日历 + 已完成开关）
            Padding(
              padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Color(0x88FFFFFF), size: 22),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GoalCalendarPage(goalId: widget.goalId),
                        ),
                      );
                    },
                    child: const Icon(Icons.description,
                        color: Color(0x88FFFFFF), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      const Text('已完成', style: TextStyle(fontSize: 12, color: Color(0x88FFFFFF))),
                      Switch(
                        value: _showCompleted,
                        onChanged: (val) => setState(() => _showCompleted = val),
                        activeColor: Colors.white38,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ReorderableListView(
                onReorder: (oldIndex, newIndex) {
                  final tasks = _filteredTasks;
                  if (newIndex > oldIndex) newIndex--;
                  final task = tasks.removeAt(oldIndex);
                  tasks.insert(newIndex, task);
                  for (int i = 0; i < tasks.length; i++) {
                    tasks[i].order = i;
                    tasks[i].save();
                  }
                  setState(() {});
                  widget.onChanged();
                },
                children: _filteredTasks.map((task) {
                  return Container(
                    key: ValueKey(task.id),
                    margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0x55E8DED1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: task.completed
                          ? const Icon(Icons.check_circle_outline, color: Color(0x44000000))
                          : const Icon(Icons.circle_outlined, color: Color(0x44000000)),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.completed ? TextDecoration.lineThrough : null,
                          color: task.completed ? const Color(0x44000000) : const Color(0xDD000000),
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Color(0x44000000)),
                        onPressed: () {
                          task.delete();
                          setState(() {});
                          widget.onChanged();
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}