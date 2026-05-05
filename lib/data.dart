import 'package:hive/hive.dart';

// ==================== Goal ====================
@HiveType(typeId: 0)
class Goal extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double importanceSize;

  @HiveField(3)
  int colorValue;

  Goal({
    required this.id,
    required this.name,
    this.importanceSize = 1.0,
    required this.colorValue,
  });
}

class GoalAdapter extends TypeAdapter<Goal> {
  @override
  final int typeId = 0;

  @override
  Goal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Goal(
      id: fields[0] as String,
      name: fields[1] as String,
      importanceSize: fields[2] as double,
      colorValue: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Goal obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.importanceSize)
      ..writeByte(3)..write(obj.colorValue);
  }

  @override
  int get hashCode => typeId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ==================== Task ====================
@HiveType(typeId: 1)
class Task extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String goalId;

  @HiveField(2)
  String title;

  @HiveField(3)
  bool completed;

  @HiveField(4)
  DateTime? completedDate;

  @HiveField(5)
  int order;

  @HiveField(6)
  DateTime? dueDate;   // 新增：可选截止日期

  Task({
    required this.id,
    required this.goalId,
    required this.title,
    this.completed = false,
    this.completedDate,
    required this.order,
    this.dueDate,
  });
}

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 1;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      goalId: fields[1] as String,
      title: fields[2] as String,
      completed: fields[3] as bool,
      completedDate: fields[4] as DateTime?,
      order: fields[5] as int,
      dueDate: fields[6] as DateTime?,    // 新增
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(7)   // 从 6 改为 7
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.goalId)
      ..writeByte(2)..write(obj.title)
      ..writeByte(3)..write(obj.completed)
      ..writeByte(4)..write(obj.completedDate)
      ..writeByte(5)..write(obj.order)
      ..writeByte(6)..write(obj.dueDate);   // 新增
  }

  @override
  int get hashCode => typeId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ==================== GoalEvent ====================
@HiveType(typeId: 2)
class GoalEvent extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String goalId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String title;

  GoalEvent({
    required this.id,
    required this.goalId,
    required this.date,
    required this.title,
  });
}

class GoalEventAdapter extends TypeAdapter<GoalEvent> {
  @override
  final int typeId = 2;

  @override
  GoalEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GoalEvent(
      id: fields[0] as String,
      goalId: fields[1] as String,
      date: fields[2] as DateTime,
      title: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, GoalEvent obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.goalId)
      ..writeByte(2)..write(obj.date)
      ..writeByte(3)..write(obj.title);
  }

  @override
  int get hashCode => typeId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ==================== SleepSettings ====================
@HiveType(typeId: 3)
class SleepSettings extends HiveObject {
  @HiveField(0)
  bool enabled;

  @HiveField(1)
  int sleepHour;

  @HiveField(2)
  int sleepMinute;

  @HiveField(3)
  int wakeHour;

  @HiveField(4)
  int wakeMinute;

  SleepSettings({
    this.enabled = false,
    this.sleepHour = 23,
    this.sleepMinute = 0,
    this.wakeHour = 7,
    this.wakeMinute = 0,
  });
}

class SleepSettingsAdapter extends TypeAdapter<SleepSettings> {
  @override
  final int typeId = 3;

  @override
  SleepSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SleepSettings(
      enabled: fields[0] as bool,
      sleepHour: fields[1] as int,
      sleepMinute: fields[2] as int,
      wakeHour: fields[3] as int,
      wakeMinute: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SleepSettings obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)..write(obj.enabled)
      ..writeByte(1)..write(obj.sleepHour)
      ..writeByte(2)..write(obj.sleepMinute)
      ..writeByte(3)..write(obj.wakeHour)
      ..writeByte(4)..write(obj.wakeMinute);
  }

  @override
  int get hashCode => typeId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ==================== AchievementRecord ====================
@HiveType(typeId: 4)
class AchievementRecord extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String taskTitle;

  @HiveField(2)
  String goalName;

  @HiveField(3)
  int goalColor;

  @HiveField(4)
  DateTime completedAt;

  AchievementRecord({
    required this.id,
    required this.taskTitle,
    required this.goalName,
    required this.goalColor,
    required this.completedAt,
  });
}

class AchievementRecordAdapter extends TypeAdapter<AchievementRecord> {
  @override
  final int typeId = 4;

  @override
  AchievementRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AchievementRecord(
      id: fields[0] as String,
      taskTitle: fields[1] as String,
      goalName: fields[2] as String,
      goalColor: fields[3] as int,
      completedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AchievementRecord obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.taskTitle)
      ..writeByte(2)..write(obj.goalName)
      ..writeByte(3)..write(obj.goalColor)
      ..writeByte(4)..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}