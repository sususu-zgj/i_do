import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:i_do/data/db.dart';

class Setting extends ChangeNotifier {
  Setting._internal();
  factory Setting() => _instance;
  static final Setting _instance = Setting._internal();

  static const int version = 1;
  static const String id = 'main';
  static const List<ThemeMode> _themeModes = [
    ThemeMode.light,
    ThemeMode.dark,
    ThemeMode.system,
  ];

  static List<ThemeMode> get themeModes => List.of(_themeModes);

  late SettingData _data;
  SettingData get data => _data;

  Future<void> load() async {
    _data = await DB().getSettingData(id);
    debugPrint('Setting loaded');
  }

  Future<void> update(SettingData setting) async {
    try {
      await DB().updateSettingData(setting);
      _data = setting;
      notifyListeners();
      debugPrint('Setting updated');
    } catch(_) {}
  }

  ThemeMode get themeMode {
    if (data.darkMode == null) {
      return ThemeMode.system;
    } else if (data.darkMode!) {
      return ThemeMode.dark;
    } else {
      return ThemeMode.light;
    }
  }

  int get themeModeIndex {
    if (data.darkMode == null) {
      return 2;
    } else if (data.darkMode!) {
      return 1;
    } else {
      return 0;
    }
  }

  set themeMode(ThemeMode themeMode) {
    bool? darkMode;
    switch (themeMode) {
      case ThemeMode.system:
        darkMode = null;
        break;
      case ThemeMode.light:
        darkMode = false;
        break;
      case ThemeMode.dark:
        darkMode = true;
        break;
    }
    update(data.copyWith(darkMode: darkMode));
  }

  FlexScheme get colorScheme => data.colorScheme;

  set colorScheme(FlexScheme scheme) {
    update(data.copyWith(flexColorScheme: scheme, darkMode: data.darkMode));
  }

  String get path => data.path;

  set path(String newPath) {
    update(data.copyWith(path: newPath, darkMode: data.darkMode));
  }

  bool get enableAnimations => data.enableAnimations;

  set enableAnimations(bool enable) {
    update(data.copyWith(enableAnimations: enable, darkMode: data.darkMode));
  }

  bool get savePop => data.savePop;

  set savePop(bool enable) {
    update(data.copyWith(savePop: enable, darkMode: data.darkMode));
  }

}

///
/// 与设置有关的数据
/// 修改字段需要创建新的实例
///
class SettingData {
  static final Map<String, FlexScheme> scheme = {
    for (var e in FlexScheme.values) e.name: e
  };

  SettingData({
    required this.version,
    this.darkMode,
    FlexScheme flexColorScheme = FlexScheme.flutterDash,
    required this.path,
    this.enableAnimations = true,
    this.savePop = true,
  }) : _flexColorScheme = flexColorScheme.name;

  SettingData copyWith({
    int? version,
    required bool? darkMode,
    FlexScheme? flexColorScheme,
    String? path,
    bool? enableAnimations,
    bool? savePop,
  }) {
    return SettingData(
      version: version ?? this.version,
      darkMode: darkMode,
      flexColorScheme: flexColorScheme ?? colorScheme,
      path: path ?? this.path,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      savePop: savePop ?? this.savePop,
    );
  }

  // 唯一id
  final String id = 'main';

  // 版本
  final int version;

  /// 应用主题
  /// null - 系统主题 - 2
  /// false - 浅色模式 - 0
  /// true - 深色模式 - 1
  final bool? darkMode;

  // 调色板名称
  final String _flexColorScheme;
  FlexScheme get colorScheme => scheme[_flexColorScheme] ?? FlexScheme.flutterDash;

  // 储存路径
  final String path;

  // 动画开关
  final bool enableAnimations;

  // 保存Note时回到主页
  final bool savePop;

  // 转为Map
  Map<String, Object> toMap() {
    return {
      'id': id,
      'version': version,
      'darkMode': darkMode == null
          ? 2
          : (darkMode!
              ? 1
              : 0), // null - 系统主题 - 2, false - 浅色模式 - 0, true - 深色模式 - 1
      'flexColorScheme': _flexColorScheme,
      'path': path,
      'enableAnimations': enableAnimations ? 1 : 0,
      'savePop': savePop ? 1 : 0,
    };
  }

  // 从Map创建
  factory SettingData.fromMap(Map<String, Object?> map) {
    return SettingData(
      version: map['version'] as int,
      darkMode: map['darkMode'] == null
          ? null
          : ( (map['darkMode'] as int) == 2
              ? null
              : (map['darkMode'] as int) == 1 ),
      flexColorScheme: scheme[map['flexColorScheme'] as String? ?? 'mandyRed'] ?? FlexScheme.flutterDash,
      path: map['path'] as String,
      enableAnimations: (map['enableAnimations'] as int?) == 1,
      savePop: (map['savePop'] as int?) == 1,
    );
  }
}