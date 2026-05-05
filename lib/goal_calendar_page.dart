import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'data.dart';
import 'global_calendar_page.dart';

class GoalCalendarPage extends StatefulWidget {
  final String goalId;
  const GoalCalendarPage({super.key, required this.goalId});

  @override
  State<GoalCalendarPage> createState() => _GoalCalendarPageState();
}

class _GoalCalendarPageState extends State<GoalCalendarPage> {
  late final Box<Task> _tasksBox;
  late final Goal _goal;
  Map<DateTime, List<Task>> _tasksByDay = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _tasksBox = Hive.box<Task>('tasks');
    _goal = Hive.box<Goal>('goals').values.firstWhere((g) => g.id == widget.goalId);
    _buildTasksMap();
  }

  void _buildTasksMap() {
    _tasksByDay = {};
    final tasks = _tasksBox.values.where(
        (t) => t.goalId == widget.goalId && !t.completed && t.dueDate != null);
    for (var task in tasks) {
      final day = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      _tasksByDay[day] = [...? _tasksByDay[day], task];
    }
  }

  List<Task> _getTasksForDay(DateTime day) {
    return _tasksByDay[day] ?? [];
  }

  Future<void> _addTask(DateTime day) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2B2B2B),
        title: const Text('添加任务', style: TextStyle(color: Color(0xFFDDDDDD))),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Color(0xFFDDDDDD)),
          decoration: const InputDecoration(
            hintText: '任务描述...',
            hintStyle: TextStyle(color: Color(0x88DDDDDD)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0x44DDDDDD))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0x88DDDDDD))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Color(0x88DDDDDD))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('添加', style: TextStyle(color: Color(0xFFDDDDDD))),
          ),
        ],
      ),
    );
    if (title == null || title.isEmpty) return;

    final tasks = _tasksBox.values.where((t) => t.goalId == widget.goalId).toList();
    final maxOrder = tasks.isEmpty ? 0 : tasks.map((t) => t.order).reduce((a, b) => a > b ? a : b);
    final newTask = Task(
      id: const Uuid().v4(),
      goalId: widget.goalId,
      title: title,
      completed: false,
      order: maxOrder + 1,
      dueDate: day,
    );
    _tasksBox.add(newTask);
    _buildTasksMap();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final selectedTasks = _selectedDay != null ? _getTasksForDay(_selectedDay!) : [];

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
            // 返回按钮 + 跳转全局日历
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
                        MaterialPageRoute(builder: (_) => const GlobalCalendarPage()),
                      );
                    },
                    child: const Icon(Icons.public, color: Color(0x88FFFFFF), size: 22),
                  ),
                ],
              ),
            ),
            // 年份切换
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Color(0x88FFFFFF)),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year - 1, _focusedDay.month, _focusedDay.day);
                    });
                  },
                ),
                Text(
                  '${_focusedDay.year}年',
                  style: const TextStyle(fontSize: 16, color: Color(0xCCFFFFFF)),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Color(0x88FFFFFF)),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year + 1, _focusedDay.month, _focusedDay.day);
                    });
                  },
                ),
              ],
            ),
            TableCalendar(
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: Color(0x44FFFFFF),
                  shape: BoxShape.circle,
                ),
                todayDecoration: const BoxDecoration(
                  color: Color(0x22FFFFFF),
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: const TextStyle(color: Color(0xCCEEEEEE), fontSize: 14),
                weekendTextStyle: const TextStyle(color: Color(0x99EEEEEE), fontSize: 14),
                outsideTextStyle: const TextStyle(color: Color(0x44EEEEEE), fontSize: 14),
                todayTextStyle: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(color: Color(0xCCFFFFFF), fontSize: 18),
                leftChevronIcon: Icon(Icons.chevron_left, color: Color(0x88FFFFFF)),
                rightChevronIcon: Icon(Icons.chevron_right, color: Color(0x88FFFFFF)),
              ),
              eventLoader: (day) => _getTasksForDay(day),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return const SizedBox.shrink();
                  return Positioned(
                    bottom: 2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(_goal.colorValue),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Color(0x44FFFFFF)),
            Expanded(
              child: _selectedDay == null
                  ? const Center(child: Text('选择一个日期', style: TextStyle(color: Color(0x88FFFFFF))))
                  : selectedTasks.isEmpty
                      ? const Center(child: Text('当天没有任务', style: TextStyle(color: Color(0x88FFFFFF))))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: selectedTasks.length,
                          itemBuilder: (context, index) {
                            final task = selectedTasks[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0x55E8DED1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  task.completed ? Icons.check_circle_outline : Icons.circle_outlined,
                                  color: Color(_goal.colorValue),
                                ),
                                title: Text(task.title, style: const TextStyle(color: Color(0xDD000000))),
                                subtitle: Text(
                                  DateFormat('M月d日').format(task.dueDate!),
                                  style: const TextStyle(fontSize: 12, color: Color(0x88000000)),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedDay != null
          ? FloatingActionButton.small(
              heroTag: 'add_task_goal_cal',
              onPressed: () => _addTask(_selectedDay!),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}