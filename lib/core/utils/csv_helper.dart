// import 'dart:io';
// import 'package:csv/csv.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:intl/intl.dart';
// import '../../features/expenses/domain/expense_model.dart';
//
// class CsvHelper {
//   static Future<void> exportExpenses(List<ExpenseModel> expenses) async {
//     try {
//       // 1. Create the Header Row
//       List<List<dynamic>> rows = [
//         ["Date", "Item", "Category", "Amount (BDT)"]
//       ];
//
//       // 2. Add Data Rows
//       for (var expense in expenses) {
//         rows.add([
//           DateFormat('yyyy-MM-dd').format(expense.date),
//           expense.title,
//           expense.category,
//           expense.amount,
//         ]);
//       }
//
//       // 3. Convert to CSV String
//       String csvData = const ListToCsvConverter().convert(rows);
//
//       // 4. Write to a temporary file
//       final directory = await getApplicationDocumentsDirectory();
//       final path = "${directory.path}/expenses_export.csv";
//       final file = File(path);
//       await file.writeAsString(csvData);
//
//       // 5. Share the file
//       // Note: subject is optional, used by email apps
//       await Share.shareXFiles([XFile(path)], text: 'Here is my Monthly Expense Report', subject: 'Expense Report');
//
//     } catch (e) {
//       // Throw error so UI can show it
//       throw Exception("Failed to export CSV: $e");
//     }
//   }
// }