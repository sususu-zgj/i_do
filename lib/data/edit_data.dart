import 'package:flutter/foundation.dart';
import 'package:i_do/data/note.dart';

class EditData extends ChangeNotifier {
  EditData({this.note})
    : tags = List<String>.from(note?.tags ?? []),
      allTags = Noter().tags;

  final Note? note;

  final List<String> tags;

  final List<String> allTags ;

  void update() {
    notifyListeners();
  }
}