import 'package:flutter/foundation.dart';

class NotesProvider extends ChangeNotifier {
  List<String> notes = [];

  Future<void> loadFromStorage() async {
    // Temporary placeholder
    notes = [];
    notifyListeners();
  }

  void addNote(String note) {
    notes.add(note);
    notifyListeners();
  }
}
