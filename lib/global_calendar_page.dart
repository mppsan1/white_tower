import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import 'data.dart';
import 'task_flow_page.dart';

class GlobalCalendarPage extends StatefulWidget {
  const GlobalCalendarPage({super.key});

  @override
  State<GlobalCalendarPage> createState() => _GlobalCalendarPageState();
}

class _GlobalCalendarPageState extends State<GlobalCalendarPage> {
  late final Box<GoalEvent> _eventsBox;
  late final Box<Task> _tasksBox;
  late final Box<Goal> _goalsBox;
  Map<DateTime, List<dynamic>> _itemsByDay = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _eventsBox = Hive.box<GoalEvent>('events');
    _tasksBox = Hive.box<Task>('tasks');
    _goalsBox = Hive.box<Goal>('goals');
    _buildItemsMap();
  }

  void _buildItemsMap() {
    _itemsByDay = {};
    for (var event in _eventsBox.values) {
      final day = DateTime(event.date.year, event.date.month, event.date.day);
      _itemsByDay[day] = [...? _itemsByDay[day], event];
    }
    for (var task in _tasksBox.values) {
      if (!task.completed && task.dueDate != null) {
        final day = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        _itemsByDay[day] = [...? _itemsByDay[day], task];
      }
    }
  }

  List<dynamic> _getItemsForDay(DateTime day) {
    return _itemsByDay[day] ?? [];
  }

  Color _getGoalColor(String goalId) {
    final goal = _goalsBox.values.firstWhere(
      (g) => g.id == goalId,
      orElse: () => Goal(id: '', name: '', colorValue: Colors.grey.value, importanceSize: 1.0),
    );
    return Color(goal.colorValue);
  }

  String _getGoalName(String goalId) {
    final goal = _goalsBox.values.firstWhere(
      (g) => g.id == goalId,
      orElse: () => Goal(id: '', name: '', colorValue: 0, importanceSize: 1),
    );
    return goal.name;
  }

  void _onItemTap(dynamic item) {
    if (item is Task) {
      final goal = _goalsBox.values.firstWhere(
        (g) => g.id == item.goalId,
        orElse: () => Goal(id: '', name: '', colorValue: 0, importanceSize: 1),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TaskFlowPage(goal: goal)),
      );
    } else if (item is GoalEvent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('事件：${item.title}')),
      );
    }
  }

  Future<void> _addTaskForDay(DateTime day) async {
    final goals = _goalsBox.values.toList();
    if (goals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先创建目标')),
      );
      return;
    }

    Goal? chosenGoal;
    await showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: const Color(0xFFE8DED1),
        title: const Text('选择目标', style: TextStyle(color: Color(0xFFDDDDDD))),
        children: goals.map((g) => SimpleDialogOption(
          onPressed: () {
            chosenGoal = g;
            Navigator.pop(ctx);
          },
          child: Text(g.name, style: const TextStyle(color: Color(0xFFDDDDDD))),
        )).toList(),
      ),
    );
    if (chosenGoal == null) return;

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

    final tasks = _tasksBox.values.where((t) => t.goalId == chosenGoal!.id).toList();
    final maxOrder = tasks.isEmpty ? 0 : tasks.map((t) => t.order).reduce((a, b) => a > b ? a : b);
    final newTask = Task(
      id: Uuid().v4(),
      goalId: chosenGoal!.id,
      title: title,
      completed: false,
      order: maxOrder + 1,
      dueDate: day,
    );
    _tasksBox.add(newTask);
    _buildItemsMap();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final selectedItems = _selectedDay != null ? _getItemsForDay(_selectedDay!) : [];

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
            // 返回按钮
            Padding(
              padding: const EdgeInsets.only(top: 40, left: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Color(0x88FFFFFF), size: 22),
                ),
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
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _focusedDay,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _focusedDay = picked);
                    }
                  },
                  child: Text(
                    '${_focusedDay.year}年',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xCCFFFFFF)),
                  ),
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
              eventLoader: (day) => _getItemsForDay(day),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, items) {
                  if (items.isEmpty) return const SizedBox.shrink();
                  final seenGoalIds = <String>{};
                  final List<String> goalIds = [];
                  for (final item in items) {
                    final String gid;
                    if (item is Task) {
                      gid = item.goalId;
                    } else if (item is GoalEvent) {
                      gid = item.goalId;
                    } else {
                      continue;
                    }
                    if (!seenGoalIds.contains(gid)) {
                      seenGoalIds.add(gid);
                      goalIds.add(gid);
                    }
                  }
                  String? firstTitle;
                  for (final item in items) {
                    if (item is Task) {
                      firstTitle = item.title;
                      break;
                    } else if (item is GoalEvent) {
                      firstTitle = item.title;
                      break;
                    }
                  }
                  String? label;
                  if (firstTitle != null && firstTitle.isNotEmpty) {
                    if (firstTitle.length <= 2) {
                      label = firstTitle;
                    } else {
                      label = '${firstTitle.substring(0, 2)}…';
                    }
                  }
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: goalIds.map((gid) => Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 1),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getGoalColor(gid),
                            ),
                          )).toList(),
                        ),
                      ),
                      if (label != null)
                        Positioned(
                          bottom: -2,
                          left: 0,
                          right: 0,
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 9, height: 1.2, color: Color(0xCCEEEEEE)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const Divider(color: Color(0x44FFFFFF)),
            Expanded(
              child: _selectedDay == null
                  ? const Center(child: Text('选择一个日期查看事件/任务', style: TextStyle(color: Color(0x88FFFFFF))))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: selectedItems.map((item) {
                        final String goalId;
                        final String title;
                        final bool isTask;
                        if (item is GoalEvent) {
                          goalId = item.goalId;
                          title = item.title;
                          isTask = false;
                        } else if (item is Task) {
                          goalId = item.goalId;
                          title = item.title;
                          isTask = true;
                        } else {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0x55E8DED1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getGoalColor(goalId).withOpacity(0.7),
                              ),
                            ),
                            title: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${_getGoalName(goalId)} · ',
                                    style: const TextStyle(fontSize: 12, color: Color(0x88000000)),
                                  ),
                                  TextSpan(
                                    text: title,
                                    style: const TextStyle(color: Color(0xDD000000), fontSize: 14),
                                  ),
                                  if (isTask)
                                    const TextSpan(
                                      text: '  (任务)',
                                      style: TextStyle(fontSize: 11, color: Color(0x88000000)),
                                    ),
                                ],
                              ),
                            ),
                            onTap: () => _onItemTap(item),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedDay != null
          ? FloatingActionButton.small(
              heroTag: 'add_task_cal',
              onPressed: () => _addTaskForDay(_selectedDay!),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}