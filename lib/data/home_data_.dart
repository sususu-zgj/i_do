import 'package:flutter/material.dart';
import 'package:i_do/data/db.dart';

class HomeData extends ChangeNotifier {
  HomeData._internal();
  static final HomeData _instance = HomeData._internal();
  factory HomeData() => _instance;

  static const int SORT_DEFAULT = 0; 
  static const int SORT_TITLE = 1;
  static const int SORT_DATE = 2;

  // 排序模式（不保存）
  int _sortMode = SORT_DEFAULT;
  int get sortMode => _sortMode;
  set sortMode(int value) {
    if (value < SORT_DEFAULT || value > SORT_DATE) {
      return;
    }
    _sortMode = value;
    notifyListeners();
  }

  bool _sortReverse = false;
  bool get sortReverse => _sortReverse;
  set sortReverse(bool value) {
    _sortReverse = value;
    notifyListeners();
  }

  final String id = 'home_data';

  /// 控制创建Note按钮的位置
  /// true - 浮动在右下角
  /// false - 固定在AppBar 
  bool _isEditButtonFloating = true;
  bool get isEditButtonFloating => _isEditButtonFloating;
  set isEditButtonFloating(bool value) {
    _isEditButtonFloating = value;
    update();
  }

  /// 是否显示完成的Note
  bool _isFinishShown = false;  
  set isFinishShown(bool value) {
    _isFinishShown = value;
    if (!_isFinishShown && !_isUnfinishShown) {
      // 保证至少有一个被显示
      _isUnfinishShown = true;
    }
    update();
  }
  bool get isFinishShown => _isFinishShown;

  bool _isUnfinishShown = true;  
  set isUnfinishShown(bool value) {
    _isUnfinishShown = value;
    if (!_isUnfinishShown && !_isFinishShown) {
      // 保证至少有一个被显示
      _isFinishShown = true;
    }
    update();
  }
  bool get isUnfinishShown => _isUnfinishShown;

  // 显示完成日期
  bool _isDateShown = false;
  set isDateShown(bool value) {
    _isDateShown = value;
    update();
  } 
  bool get isDateShown => _isDateShown;

  // 显示标签
  bool _isTagShown = false;
  set isTagShown(bool value) {
    _isTagShown = value;
    update();
  }
  bool get isTagShown => _isTagShown;

  // 通过点击修改完成情况
  bool _isToggleFinish = false;
  set isToggleFinish(bool value) {
    _isToggleFinish = value;
    update();
  }
  bool get isToggleFinish => _isToggleFinish;

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

  void fromMap(Map<String, Object> map) {
    _isEditButtonFloating = map['isEditButtonFloating'] == 1;
    _isFinishShown = map['isFinishShown'] == 1;
    _isUnfinishShown = map['isUnfinishShown'] == 1;
    _isDateShown = map['isDateShown'] == 1;
    _isTagShown = map['isTagShown'] == 1;
    _isToggleFinish = map['isToggleFinish'] == 1;
    notifyListeners();
  }

  Future<void> load() async {
    final data = await DB().getHomeData(id);
    if (data != null) {
      fromMap(data);
    }
    else {
      await DB().insertHomeData(id, toMap());
    }
  }

  Future<void> update() async {
    try {
      await DB().updateHomeData(id, toMap());
      notifyListeners();
      debugPrint('HomeData updated');
    } catch(_) {}
  }

}
