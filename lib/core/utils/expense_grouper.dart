import 'package:intl/intl.dart';
import '../../features/expenses/domain/expense_model.dart';

class ExpenseGrouper {
  // 1. Group by Date (Existing)
  static Map<String, List<ExpenseModel>> groupExpensesByDate(List<ExpenseModel> expenses) {
    final Map<String, List<ExpenseModel>> grouped = {};
    for (var expense in expenses) {
      final String dateKey = DateFormat('yyyy-MM-dd').format(expense.date);
      if (grouped.containsKey(dateKey)) {
        grouped[dateKey]!.add(expense);
      } else {
        grouped[dateKey] = [expense];
      }
    }
    return grouped;
  }

  // 2. Group by Week (New) -> Key: "2025-W42"
  static Map<String, double> groupExpensesByWeek(List<ExpenseModel> expenses) {
    final Map<String, double> grouped = {};
    for (var expense in expenses) {
      // Get Week Number
      final date = expense.date;
      // Simple algorithm: Day of year / 7
      final dayOfYear = int.parse(DateFormat("D").format(date));
      final weekNum = ((dayOfYear - date.weekday + 10) / 7).floor();

      final String key = "${date.year}-W$weekNum";

      if (grouped.containsKey(key)) {
        grouped[key] = grouped[key]! + expense.amount;
      } else {
        grouped[key] = expense.amount;
      }
    }
    return grouped;
  }

  // 3. Group by Year (New) -> Key: "2025"
  static Map<String, double> groupExpensesByYear(List<ExpenseModel> expenses) {
    final Map<String, double> grouped = {};
    for (var expense in expenses) {
      final String year = expense.date.year.toString();

      if (grouped.containsKey(year)) {
        grouped[year] = grouped[year]! + expense.amount;
      } else {
        grouped[year] = expense.amount;
      }
    }
    return grouped;
  }

  // Helper for Headers
  static String getNiceHeader(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return "Today";
    } else if (dateToCheck == yesterday) {
      return "Yesterday";
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
}