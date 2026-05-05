import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'data.dart';
import 'task_flow_page.dart';
import 'sleep_settings_page.dart';
import 'sleep_guard_page.dart';
import 'achievement_page.dart';
import 'goal_timeline_page.dart';
import 'global_calendar_page.dart';

// ---------- 顶层睡眠判断函数 ----------
bool isInSleepWindow(SleepSettings settings) {
  if (!settings.enabled) return false;
  final now = DateTime.now();
  final sleepTime = DateTime(
      now.year, now.month, now.day, settings.sleepHour, settings.sleepMinute);
  final wakeTime = DateTime(
      now.year, now.month, now.day, settings.wakeHour, settings.wakeMinute);

  if (sleepTime.isAfter(wakeTime)) {
    return now.isAfter(sleepTime) || now.isBefore(wakeTime);
  } else {
    return now.isAfter(sleepTime) && now.isBefore(wakeTime);
  }
}

// ---------- Overlay 管理器 ----------
class SleepOverlayManager {
  static OverlayEntry? _entry;

  static void show2(OverlayState overlay) {
    if (_entry != null) return;
    _entry = OverlayEntry(
      builder: (_) => const SleepGuardPage(),
    );
    overlay.insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}

// ---------- 主函数 ----------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(GoalAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(GoalEventAdapter());
  Hive.registerAdapter(SleepSettingsAdapter());
  Hive.registerAdapter(AchievementRecordAdapter());

  await Hive.openBox<Goal>('goals');
  await Hive.openBox<Task>('tasks');
  await Hive.openBox<GoalEvent>('events');
  await Hive.openBox<SleepSettings>('sleep_settings');
  await Hive.openBox<AchievementRecord>('achievements');

  final sleepBox = Hive.box<SleepSettings>('sleep_settings');
  if (sleepBox.isEmpty) {
    sleepBox.add(SleepSettings());
  }

  runApp(const WhiteTowerApp());
}

// ---------- App 根组件 ----------
class WhiteTowerApp extends StatefulWidget {
  const WhiteTowerApp({super.key});
  @override
  State<WhiteTowerApp> createState() => _WhiteTowerAppState();
}

class _WhiteTowerAppState extends State<WhiteTowerApp> {
  Timer? _sleepTimer;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSleep());
    _sleepTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkSleep();
    });
  }

  void _checkSleep() {
    final box = Hive.box<SleepSettings>('sleep_settings');
    if (box.isEmpty) return;
    final settings = box.getAt(0)!;
    final inWindow = isInSleepWindow(settings);
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    if (inWindow) {
      SleepOverlayManager.show2(overlay);
    } else {
      SleepOverlayManager.hide();
    }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '白塔',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: const TowerEntryPage(),
    );
  }
}

// ---------- 白塔入口页 ----------
class TowerEntryPage extends StatelessWidget {
  const TowerEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WaterBallsHomePage()),
        );
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/tower_entry.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Color(0x20FFFFFF), // 极淡的白色遮罩，值越大越白
                BlendMode.lighten,
              ),
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 20),
                Text(
                  '白塔',
                  style: TextStyle(
                    fontFamily: 'Serif',
                    fontSize: 30,
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- 水球主页 ----------
class WaterBallsHomePage extends StatelessWidget {
  const WaterBallsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final goalBox = Hive.box<Goal>('goals');

    if (goalBox.isEmpty) {
      goalBox.add(Goal(
        id: const Uuid().v4(),
        name: '示例：数学建模',
        importanceSize: 1.2,
        colorValue: Colors.blueGrey.value,
      ));
    }

    return Scaffold(
      body: Stack(
        children: [
          // ========== 背景层：插画 + 光照 ==========
          Stack(
            children: [
              // 底层插画保持不变
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/waterball_bg.png'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Color(0x10FFFFFF),
                      BlendMode.lighten,
                    ),
                  ),
                ),
              ),
            ],
          ),

              // 白光 — 提亮并抵消橘色
              Positioned(
                bottom: -120,
                left: -120,
                child: Container(
                  width: 450,
                  height: 450,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment.bottomLeft,
                      radius: 0.9,
                      colors: [
                        Color(0x30FFFFFF),
                        Color(0x08FFFFFF),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

          // ========== 水球列表 ==========
          ValueListenableBuilder(
            valueListenable: goalBox.listenable(),
            builder: (context, box, _) {
              final goals = box.values.toList();
              if (goals.isEmpty) {
                return const Center(
                  child: Text('还没有目标，点击右下角 + 创建',
                      style: TextStyle(color: Color(0x88000000))),
                );
              }
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 24,
                    runSpacing: 24,
                    children: goals
                        .map((goal) => WaterBubbleWidget(goal: goal))
                        .toList(),
                  ),
                ),
              );
            },
          ),

          // ========== 界面按钮 ==========
          // 左上角返回白塔
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const TowerEntryPage()),
                );
              },
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0x88000000), size: 24),
            ),
          ),

          // 全局日历入口
          Positioned(
            top: 50,
            left: 60,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GlobalCalendarPage()),
                );
              },
              child: const Icon(Icons.library_books, 
                  color: Color(0x88000000), size: 22),
            ),
          ),

          // 右上角隐士的安眠
          Positioned(
            top: 50,
            right: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SleepSettingsPage()),
                );
              },
              child: const Icon(Icons.nightlight_round,
                  color: Color(0x88000000), size: 24),
            ),
          ),

          // 右下角添加水球
          Positioned(
            bottom: 40,
            right: 20,
            child: GestureDetector(
              onTap: () => _showAddGoalDialog(context),
              child: const Icon(Icons.add_circle_outline,
                  color: Color(0x88000000), size: 28),
            ),
          ),

          // 成就入口
          Positioned(
            bottom: 90,
            right: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AchievementPage()),
                );
              },
              child: const Icon(Icons.door_front_door,
                  color: Color(0x88000000), size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- 水球气泡组件 ----------
class WaterBubbleWidget extends StatelessWidget {
  final Goal goal;
  const WaterBubbleWidget({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    final size = 80.0 * goal.importanceSize;
    final glassColor = Color(goal.colorValue);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskFlowPage(goal: goal)),
        );
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8DED1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.timeline, color: Color(0xFF2B2B2B)),
                    title: const Text('查看时间线', style: TextStyle(color: Color(0xFF2B2B2B))),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => GoalTimelinePage(goal: goal)),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Color(0xFF2B2B2B)),
                    title: const Text('删除水球', style: TextStyle(color: Color(0xFF2B2B2B))),
                    onTap: () {
                      Navigator.pop(ctx);
                      _deleteGoal(goal);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 0.8,
            colors: [
              Colors.white.withOpacity(0.25),
              Colors.white.withOpacity(0.05),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: glassColor.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: glassColor.withOpacity(0.25),
            width: 1.0,
          ),
        ),
        child: Stack(
          children: [
            // 高光点（横向椭圆）
            Positioned(
              top: size * 0.18,
              left: size * 0.22,
              child: Container(
                width: size * 0.25,
                height: size * 0.15,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(size * 0.125, size * 0.075),
                  ),
                  gradient: RadialGradient(
                    center: const Alignment(-0.2, -0.2),
                    radius: 0.8,
                    colors: [
                      Colors.white.withOpacity(0.6),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // 文字
            Center(
              child: Padding(
                padding: EdgeInsets.all(size * 0.15),
                child: Text(
                  goal.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Serif',
                    fontSize: size * 0.16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- 新建水球对话框 ----------
void _showAddGoalDialog(BuildContext context) {
  final nameController = TextEditingController();
  double sizeValue = 1.0;
  Color selectedColor = Colors.blueGrey;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: const Color(0xFF2B2B2B),   // 羊皮纸实色
        title: const Text('新建水球', style: TextStyle(color: Color(0xFFDDDDDD))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: Color(0xFFDDDDDD)),
              decoration: const InputDecoration(
                hintText: '目标名称',
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
                const Text('大小', style: TextStyle(color: Color(0xFFDDDDDD))),
                Expanded(
                  child: Slider(
                    value: sizeValue,
                    min: 0.5,
                    max: 1.5,
                    activeColor: Color(0xCCD4A74A),
                    onChanged: (val) {
                      setDialogState(() => sizeValue = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('颜色', style: TextStyle(color: Color(0xFFDDDDDD))),
                const SizedBox(width: 8),
                ...[Colors.blueGrey, Colors.teal, Colors.deepOrange, Colors.indigo]
                    .map((c) => GestureDetector(
                          onTap: () {
                            setDialogState(() => selectedColor = c);
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c,
                              border: selectedColor == c
                                  ? Border.all(
                                      color: const Color(0xFFD4A74A), width: 2)
                                  : null,
                            ),
                          ),
                        ))
                    .toList(),
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
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final goalBox = Hive.box<Goal>('goals');
                goalBox.add(Goal(
                  id: const Uuid().v4(),
                  name: name,
                  importanceSize: sizeValue,
                  colorValue: selectedColor.value,
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('创建', style: TextStyle(color: Color(0xFFDDDDDD))),
          ),
        ],
      ),
    ),
  );
}

void _deleteGoal(Goal goal) {
  final goalBox = Hive.box<Goal>('goals');
  final taskBox = Hive.box<Task>('tasks');
  final eventBox = Hive.box<GoalEvent>('events');

  // 删除关联任务
  final tasksToDelete = taskBox.values.where((t) => t.goalId == goal.id).toList();
  for (var t in tasksToDelete) {
    t.delete();
  }
  // 删除关联事件
  final eventsToDelete = eventBox.values.where((e) => e.goalId == goal.id).toList();
  for (var e in eventsToDelete) {
    e.delete();
  }
  // 删除目标本身
  goal.delete();
}