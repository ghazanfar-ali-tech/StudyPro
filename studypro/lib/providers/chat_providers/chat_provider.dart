
import 'package:flutter/foundation.dart';

class ChatProvider with ChangeNotifier {
  String? _editingMessageKey;
  String _editingMessageText = '';
  bool _isEditing = false;

  String? get editingMessageKey => _editingMessageKey;
  String get editingMessageText => _editingMessageText;
  bool get isEditing => _isEditing;

  void startEditing(String messageKey, String messageText) {
    _editingMessageKey = messageKey;
    _editingMessageText = messageText;
    _isEditing = true;
    notifyListeners();
  }

  void stopEditing() {
    _editingMessageKey = null;
    _editingMessageText = '';
    _isEditing = false;
    notifyListeners();
  }
}