import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'data.dart';

class GoalTimelinePage extends StatefulWidget {
  final Goal goal;
  const GoalTimelinePage({super.key, required this.goal});

  @override
  State<GoalTimelinePage> createState() => _GoalTimelinePageState();
}

class _GoalTimelinePageState extends State<GoalTimelinePage> {
  late Box<GoalEvent> _eventsBox;
  List<GoalEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _eventsBox = Hive.box<GoalEvent>('events');
    _loadEvents();
  }

  void _loadEvents() {
    _events = _eventsBox.values
        .where((e) => e.goalId == widget.goal.id)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> _pickDateAndAdd() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2B2B2B),
        title: const Text('添加事件', style: TextStyle(color: Color(0xFFDDDDDD))),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Color(0xFFDDDDDD)),
          decoration: const InputDecoration(
            hintText: '事件描述...',
            hintStyle: TextStyle(color: Color(0x88DDDDDD)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0x44DDDDDD)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0x88DDDDDD)),
            ),
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
    if (title != null && title.isNotEmpty) {
      final newEvent = GoalEvent(
        id: const Uuid().v4(),
        goalId: widget.goal.id,
        date: pickedDate,
        title: title,
      );
      _eventsBox.add(newEvent);
      _loadEvents();
      setState(() {});
    }
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
            Padding(
              padding: const EdgeInsets.only(top: 50, left: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Color(0x88FFFFFF), size: 22),
                ),
              ),
            ),
            Expanded(
              child: _events.isEmpty
                  ? const Center(
                      child: Text('暂无日期事件',
                          style: TextStyle(color: Color(0x88FFFFFF))),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        final event = _events[index];
                        final color = Color(widget.goal.colorValue).withOpacity(0.7);
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0x55E8DED1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle, color: color),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                DateFormat('M月d日 EEEE').format(event.date),
                                style: const TextStyle(color: Color(0x88000000)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(event.title,
                                    style: const TextStyle(color: Color(0xDD000000))),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'add_event',
            onPressed: _pickDateAndAdd,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'ai_add',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI 导入功能开发中...')),
              );
            },
            child: const Icon(Icons.auto_awesome),
          ),
        ],
      ),
    );
  }
}