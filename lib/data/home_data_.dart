import 'package:flutter/material.dart';
import 'package:i_do/data/db.dart';

class HomeData extends ChangeNotifier {
  // 单例
  HomeData._internal();
  static final HomeData _instance = HomeData._internal();
  factory HomeData() => _instance;
  final String id = 'home_data';

  // 排序模式
  /// 默认排序
  static const int SORT_DEFAULT = 0; 

  /// 标题排序
  static const int SORT_TITLE = 1;

  /// 日期排序
  static const int SORT_DATE = 2;

  /// 排序模式（不保存）
  int get sortMode => _sortMode;
  set sortMode(int value) {
    if (value < SORT_DEFAULT || value > SORT_DATE) {
      return;
    }
    _sortMode = value;
    notifyListeners();
  }

  // 逆向排序（不保存）
  bool get isSortReverse => _isSortReverse;
  set isSortReverse(bool value) {
    _isSortReverse = value;
    notifyListeners();
  }

  // Note 显示的列数
  int get columnsCount => _columnsCount;
  set columnsCount(int value) {
    if (value < 1) {
      value = 1;
    }
    _columnsCount = value;
    notifyListeners();
  }


  /// 控制创建Note按钮的位置
  /// true - 浮动在右下角
  /// false - 固定在AppBar 
  bool get isEditButtonFloating => _isEditButtonFloating;
  set isEditButtonFloating(bool value) {
    _isEditButtonFloating = value;
    update();
  }

  /// 是否显示完成的Note
  bool get isFinishShown => _isFinishShown;
  set isFinishShown(bool value) {
    _isFinishShown = value;
    if (!_isFinishShown && !_isUnfinishShown) {
      // 保证至少有一个被显示
      _isUnfinishShown = true;
    }
    update();
  }
  
  /// 是否显示未完成的Note
  bool get isUnfinishShown => _isUnfinishShown;
  set isUnfinishShown(bool value) {
    _isUnfinishShown = value;
    if (!_isUnfinishShown && !_isFinishShown) {
      // 保证至少有一个被显示
      _isFinishShown = true;
    }
    update();
  }
  
  // 显示完成日期
  bool get isDateShown => _isDateShown;
  set isDateShown(bool value) {
    _isDateShown = value;
    update();
  } 

  // 显示标签
  bool get isTagShown => _isTagShown;
  set isTagShown(bool value) {
    _isTagShown = value;
    update();
  }

  // 通过点击修改完成情况
  bool get isToggleFinish => _isToggleFinish;
  set isToggleFinish(bool value) {
    _isToggleFinish = value;
    update();
  }

  Map<String, Object> toMap() {
    return {
      'isEditButtonFloating': _isEditButtonFloating ? 1 : 0,
      'isFinishShown': _isFinishShown ? 1 : 0,
      'isUnfinishShown': _isUnfinishShown ? 1 : 0,
      'isDateShown': _isDateShown ? 1 : 0,
      'isTagShown': _isTagShown ? 1 : 0,
      'isToggleFinish': _isToggleFinish ? 1 : 0,
    };
  }

  /// 从Map中加载数据
  void fromMap(Map<String, Object> map) {
    _isEditButtonFloating = map['isEditButtonFloating'] == 1;
    _isFinishShown = map['isFinishShown'] == 1;
    _isUnfinishShown = map['isUnfinishShown'] == 1;
    _isDateShown = map['isDateShown'] == 1;
    _isTagShown = map['isTagShown'] == 1;
    _isToggleFinish = map['isToggleFinish'] == 1;
    notifyListeners();
  }

  /// 初始化
  Future<void> load() async {
    final data = await DB().getHomeData(id);
    if (data != null) {
      fromMap(data);
    }
    else {
      await DB().insertHomeData(id, toMap());
    }
  }

  /// 更新
  Future<void> update() async {
    try {
      await DB().updateHomeData(id, toMap());
      notifyListeners();
      debugPrint('HomeData updated');
    } catch(_) {}
  }

  int _sortMode = SORT_DEFAULT;
  bool _isSortReverse = false;
  bool _isEditButtonFloating = true;
  bool _isFinishShown = false;  
  bool _isUnfinishShown = true;  
  bool _isDateShown = false;
  bool _isTagShown = false;
  bool _isToggleFinish = false;
  int _columnsCount = 1;
}
