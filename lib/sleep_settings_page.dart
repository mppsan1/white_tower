import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data.dart';

class SleepSettingsPage extends StatefulWidget {
  const SleepSettingsPage({super.key});

  @override
  State<SleepSettingsPage> createState() => _SleepSettingsPageState();
}

class _SleepSettingsPageState extends State<SleepSettingsPage> {
  SleepSettings get _settings =>
      Hive.box<SleepSettings>('sleep_settings').getAt(0)!;

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/waterball_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // 返回按钮（替代原 AppBar）
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
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  SwitchListTile(
                    title: const Text('开启隐士的安眠',
                        style: TextStyle(color: Color(0xFFDDDDDD))),
                    subtitle: const Text('到时间后白塔将无法进入',
                        style: TextStyle(color: Color(0x88DDDDDD))),
                    value: settings.enabled,
                    activeColor: Colors.white70,
                    onChanged: (val) {
                      setState(() {
                        settings.enabled = val;
                        settings.save();
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('安眠时间',
                      style: TextStyle(
                          fontSize: 16, color: Color(0xFFDDDDDD))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('入睡',
                              style: TextStyle(color: Color(0xFFDDDDDD))),
                          subtitle: Text(
                            '${settings.sleepHour.toString().padLeft(2, '0')}:${settings.sleepMinute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Color(0x88DDDDDD)),
                          ),
                          onTap: () => _pickTime(isSleep: true),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: const Text('醒来',
                              style: TextStyle(color: Color(0xFFDDDDDD))),
                          subtitle: Text(
                            '${settings.wakeHour.toString().padLeft(2, '0')}:${settings.wakeMinute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Color(0x88DDDDDD)),
                          ),
                          onTap: () => _pickTime(isSleep: false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime({required bool isSleep}) async {
    final settings = _settings;
    final initialHour = isSleep ? settings.sleepHour : settings.wakeHour;
    final initialMinute = isSleep ? settings.sleepMinute : settings.wakeMinute;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xCCD4A74A),
              onPrimary: Colors.black,
              surface: Color(0xFF2B2B2B),
              onSurface: Color(0xFFDDDDDD),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isSleep) {
          settings.sleepHour = picked.hour;
          settings.sleepMinute = picked.minute;
        } else {
          settings.wakeHour = picked.hour;
          settings.wakeMinute = picked.minute;
        }
        settings.save();
      });
    }
  }
}