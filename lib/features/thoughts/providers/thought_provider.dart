import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/thought_bubble.dart';

enum DeleteMode {
  moveChildrenToParent,
  detachChildrenToRoot,
  deleteSubtree,
}

class ThoughtProvider extends ChangeNotifier {
  final Map<String, ThoughtBubble> _bubbles = {};

  Map<String, ThoughtBubble> get bubbles => _bubbles;

  List<ThoughtBubble> get rootBubbles =>
      _bubbles.values.where((b) => b.parentId == null).toList();

  ThoughtBubble? getBubble(String id) => _bubbles[id];

  // --------------------------------------------------
  // CREATE ROOT
  // --------------------------------------------------
  ThoughtBubble addRootBubble(String title, String body,
      {String color = "#888888"}) {
    final id = const Uuid().v4();

    final bubble = ThoughtBubble(
      id: id,
      title: title,
      body: body,
      parentId: null,
      children: [],
      color: color,
    );

    _bubbles[id] = bubble;
    notifyListeners();
    return bubble;
  }

  // --------------------------------------------------
  // CREATE CHILD
  // --------------------------------------------------
  ThoughtBubble addChildBubble(
      String parentId, String title, String body,
      {String color = "#888888"}) {
    final parent = _bubbles[parentId];
    if (parent == null) throw Exception("Parent bubble not found");

    final id = const Uuid().v4();

    final child = ThoughtBubble(
      id: id,
      title: title,
      body: body,
      parentId: parentId,
      children: [],
      color: color,
    );

    _bubbles[id] = child;
    parent.children.add(id);

    notifyListeners();
    return child;
  }

  // --------------------------------------------------
  // UPDATE
  // --------------------------------------------------
  void updateBubble(String id, String title, String body) {
    final bubble = _bubbles[id];
    if (bubble == null) return;

    bubble.title = title;
    bubble.body = body;
    notifyListeners();
  }

  // --------------------------------------------------
  // COLOR
  // --------------------------------------------------
  void setBubbleColor(String id, String color) {
    final b = _bubbles[id];
    if (b == null) return;
    b.color = color;
    notifyListeners();
  }

  // --------------------------------------------------
  // REORDER CHILDREN
  // --------------------------------------------------
  void reorderChildren(String parentId, List<String> newOrder) {
    final parent = _bubbles[parentId];
    if (parent == null) return;

    parent.children = List<String>.from(newOrder);
    notifyListeners();
  }

  // --------------------------------------------------
  // DELETE HANDLING
  // --------------------------------------------------
  void deleteBubble(String id, {required DeleteMode mode}) {
    final bubble = _bubbles[id];
    if (bubble == null) return;

    final parentId = bubble.parentId;

    // Move children to parent
    if (mode == DeleteMode.moveChildrenToParent) {
      for (final childId in bubble.children) {
        final child = _bubbles[childId];
        if (child != null) child.parentId = parentId;
      }
      if (parentId != null) {
        final parent = _bubbles[parentId];
        parent?.children.remove(id);
        parent?.children.addAll(bubble.children);
      }
    }

    // Detach children to root
    if (mode == DeleteMode.detachChildrenToRoot) {
      for (final childId in bubble.children) {
        final child = _bubbles[childId];
        if (child != null) child.parentId = null;
      }
    }

    // Delete subtree
    if (mode == DeleteMode.deleteSubtree) {
      for (final childId in bubble.children) {
        deleteBubble(childId, mode: DeleteMode.deleteSubtree);
      }
    }

    _bubbles.remove(id);
    notifyListeners();
  }
}
