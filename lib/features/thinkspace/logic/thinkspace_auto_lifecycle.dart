import '../data/thinkspace_repository.dart';
import '../models/think_node.dart';

class ThinkSpaceAI {
  final ThinkSpaceRepository repo;

  ThinkSpaceAI(this.repo);

  /// Returns the lifecycle: idea, concept, thought, brainstorm, perspective.
  Future<String> inferLifecycle(ThinkNode node) async {
    final children = await repo.getChildren(node.id);
    final childCount = children.length;

    // Count grandchildren (depth > 1)
    int grandChildren = 0;
    for (final c in children) {
      final gc = await repo.getChildren(c.id);
      grandChildren += gc.length;
    }

    // Count siblings
    int siblingCount = 0;
    if (node.parentId != null) {
      final siblings =
          (await repo.getChildren(node.parentId!)).where((n) => n.id != node.id);
      siblingCount = siblings.length;
    }

    final content = node.content.trim();
    final length = content.length;

    // RULE 1: No structure + short = idea
    if (childCount == 0 && siblingCount == 0 && length < 200) {
      return "idea";
    }

    // RULE 2: 1–2 children = concept
    if (childCount >= 1 && childCount <= 2) {
      return "concept";
    }

    // RULE 3: 3+ children OR rich content
    if (childCount >= 3 || length > 1000) {
      return "thought";
    }

    // RULE 4: 2+ siblings or grandchildren
    if (siblingCount >= 2 || grandChildren >= 2) {
      return "brainstorm";
    }

    // RULE 5: deep network = perspective
    if ((childCount + grandChildren) >= 5) {
      return "perspective";
    }

    // Fallback
    return node.lifecycleState;
  }
}
