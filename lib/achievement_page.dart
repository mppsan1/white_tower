import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'data.dart';
import 'dart:math';

class AchievementPage extends StatefulWidget {
  const AchievementPage({super.key});

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
  String _filterMode = 'all';
  DateTime? _selectedMonth;
  DateTime? _selectedYear;

  List<AchievementRecord> _getFilteredRecords() {
    final box = Hive.box<AchievementRecord>('achievements');
    var records = box.values.toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    if (_filterMode == 'month' && _selectedMonth != null) {
      records = records.where((r) {
        return r.completedAt.year == _selectedMonth!.year &&
            r.completedAt.month == _selectedMonth!.month;
      }).toList();
    } else if (_filterMode == 'year' && _selectedYear != null) {
      records = records.where((r) {
        return r.completedAt.year == _selectedYear!.year;
      }).toList();
    }
    return records;
  }

  String _generateCsv() {
    final records = _getFilteredRecords();
    final buffer = StringBuffer('目标,任务\n');
    for (final r in records) {
      buffer.writeln('"${r.goalName}","${r.taskTitle}"');
    }
    return buffer.toString();
  }

  Future<void> _exportCsv() async {
    final csv = _generateCsv();
    await Share.share(csv, subject: '白塔成就记录');
  }

  @override
  Widget build(BuildContext context) {
    final records = _getFilteredRecords();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C1E4A),
              Color(0xFFB1443C),
              Color(0xFFE58C46),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 背景上的透光感
              // 你的云图（透明，叠加在背景色上）
              Positioned.fill(
                child: Image.asset(
                  'assets/images/achievement_clouds.png',
                  fit: BoxFit.cover,
                ),
              ),
              // 星星：上部随机淡金光点，越往下越少
              Positioned.fill(
                child: CustomPaint(
                  painter: _StarsPainter(),
                ),
              ),
              Column(
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    '但是人不能栖居于窗上',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'NotoSerifSC', // 替换为你最终的字体名
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: Color(0xCCFFE7CC),
                      shadows: [
                        Shadow(
                          blurRadius: 6,
                          color: Color(0x33000000),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFilterChip('全部', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('按月', 'month'),
                      const SizedBox(width: 8),
                      _buildFilterChip('按年', 'year'),
                    ],
                  ),
                  if (_filterMode == 'month')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _buildMonthPicker(),
                    ),
                  if (_filterMode == 'year')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _buildYearPicker(),
                    ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _exportCsv,
                    child: const Text(
                      '导出 CSV',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0x88FFE7CC),
                        decoration: TextDecoration.underline,
                        fontFamily: 'NotoSerifSC',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 成就列表（无背景板）
                  Expanded(
                    child: records.isEmpty
                        ? const Center(
                            child: Text(
                              '暂无记录',
                              style: TextStyle(
                                color: Color(0x88FFE7CC),
                                fontFamily: 'NotoSerifSC',
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 8),
                            itemCount: records.length,
                            itemBuilder: (context, index) {
                              final record = records[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // 目标名小标题
                                    Text(
                                      record.goalName,
                                      style: const TextStyle(
                                        color: Color(0xCCFFE7CC),
                                        fontSize: 14,
                                        fontFamily: 'NotoSerifSC',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // 成就项：圆点 + 任务名
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          margin: const EdgeInsets.only(
                                              right: 12),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0x44FFE7CC),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            record.taskTitle,
                                            style: const TextStyle(
                                              color: Color(0xAAFFE7CC),
                                              fontSize: 14,
                                              fontFamily: 'NotoSerifSC',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
              // 返回按钮
              Positioned(
                top: 16,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xAAFFE7CC),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String mode) {
    final isActive = _filterMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterMode = mode;
          if (mode == 'month') _selectedMonth ??= DateTime.now();
          if (mode == 'year') _selectedYear ??= DateTime.now();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0x33FFE7CC) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? const Color(0x88FFE7CC)
                : const Color(0x22FFE7CC),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'NotoSerifSC',
            color: isActive
                ? const Color(0xEEFFE7CC)
                : const Color(0x66FFE7CC),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0x88FFE7CC)),
          onPressed: () {
            setState(() {
              _selectedMonth = DateTime(
                  _selectedMonth!.year, _selectedMonth!.month - 1);
            });
          },
        ),
        Text(
          DateFormat('yyyy年M月').format(_selectedMonth!),
          style: const TextStyle(
            color: Color(0xCCFFE7CC),
            fontSize: 14,
            fontFamily: 'NotoSerifSC',
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Color(0x88FFE7CC)),
          onPressed: () {
            setState(() {
              _selectedMonth = DateTime(
                  _selectedMonth!.year, _selectedMonth!.month + 1);
            });
          },
        ),
      ],
    );
  }

  Widget _buildYearPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0x88FFE7CC)),
          onPressed: () {
            setState(() {
              _selectedYear = DateTime(_selectedYear!.year - 1);
            });
          },
        ),
        Text(
          '${_selectedYear!.year}年',
          style: const TextStyle(
            color: Color(0xCCFFE7CC),
            fontSize: 14,
            fontFamily: 'NotoSerifSC',
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Color(0x88FFE7CC)),
          onPressed: () {
            setState(() {
              _selectedYear = DateTime(_selectedYear!.year + 1);
            });
          },
        ),
      ],
    );
  }
}

class _StarsPainter extends CustomPainter {
  final int count = 30;
  late final List<_Star> stars;

  _StarsPainter() {
    final rng = Random(42); // 固定种子，每次打开相同
    stars = List.generate(count, (i) {
      final x = rng.nextDouble();
      // y 集中在 0.0 ~ 0.6 区域，越靠近顶部越容易
      final y = rng.nextDouble() * 0.6;
      // 越靠下的星星越少（按概率筛掉一部分）
      if (y > 0.4 && rng.nextDouble() > 0.6) {
        return _Star(x: x, y: y, radius: 0, opacity: 0);
      }
      // 大小随 y 减小，顶部最大约 2.5，靠近 0.6 处约 0.8
      final maxRadius = 2.5 - y * 2.8;
      final radius = 0.5 + rng.nextDouble() * maxRadius;
      // 透明度同样随 y 越往下越低
      final opacity = (1.0 - y * 1.5).clamp(0.0, 1.0) * (0.3 + rng.nextDouble() * 0.4);
      return _Star(x: x, y: y, radius: radius, opacity: opacity);
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFF5E1); // 淡暖金黄
    for (final star in stars) {
      if (star.radius <= 0 || star.opacity <= 0) continue;
      paint.color = const Color(0xFFFFF5E1).withOpacity(star.opacity);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Star {
  final double x;
  final double y;
  final double radius;
  final double opacity;
  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
  });
}