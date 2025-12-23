import '../data/thinkspace_repository.dart';
import '../models/think_node.dart';

class ThinkSpaceAI {
  final ThinkSpaceRepository repo;
  ThinkSpaceAI(this.repo);

  // 🔥 VERY EARLY placeholder logic — AI version will replace this.
  Future<String> inferLifecycle(ThinkNode node) async {
    final text = node.content.toLowerCase();

    if (text.length < 40) return "concept";
    if (text.contains("why") || text.contains("how")) return "thought";
    if (text.contains("project") || text.contains("goal")) return "brainstorm";

    return "idea"; // fallback
  }

  Future<String> inferFunction(ThinkNode node) async {
    final text = node.content.toLowerCase();

    if (text.contains("todo") ||
        text.contains("task") ||
        text.contains("list")) {
      return "todo";
    }

    if (text.contains("journal") || text.contains("diary")) {
      return "journal";
    }

    if (text.contains("plan") || text.contains("organize")) {
      return "planner";
    }

    return "general";
  }
}
