import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for ExpensesApi
void main() {
  final instance = Openapi().getExpensesApi();

  group(ExpensesApi, () {
    // Create Expense
    //
    // Parse lexical money and create one complete source expense.
    //
    //Future<ExpenseResponse> createExpenseApiV1GroupsGroupIdExpensesPost(String groupId, String xCSRFToken, ExpenseWriteRequest expenseWriteRequest) async
    test('test createExpenseApiV1GroupsGroupIdExpensesPost', () async {
      // TODO
    });

    // Delete Expense
    //
    // Delete a source expense and all of its derived effect.
    //
    //Future deleteExpenseApiV1GroupsGroupIdExpensesExpenseIdDelete(String groupId, String expenseId, String xCSRFToken) async
    test('test deleteExpenseApiV1GroupsGroupIdExpensesExpenseIdDelete', () async {
      // TODO
    });

    // Edit Expense
    //
    // Validate a full replacement before changing the source expense.
    //
    //Future<ExpenseResponse> editExpenseApiV1GroupsGroupIdExpensesExpenseIdPatch(String groupId, String expenseId, String xCSRFToken, ExpenseWriteRequest expenseWriteRequest) async
    test('test editExpenseApiV1GroupsGroupIdExpensesExpenseIdPatch', () async {
      // TODO
    });

    // Get Expense
    //
    // Read one group-owned source expense.
    //
    //Future<ExpenseResponse> getExpenseApiV1GroupsGroupIdExpensesExpenseIdGet(String groupId, String expenseId) async
    test('test getExpenseApiV1GroupsGroupIdExpensesExpenseIdGet', () async {
      // TODO
    });

    // List Expenses
    //
    // List source expenses in stable creation order with current names.
    //
    //Future<List<ExpenseResponse>> listExpensesApiV1GroupsGroupIdExpensesGet(String groupId) async
    test('test listExpensesApiV1GroupsGroupIdExpensesGet', () async {
      // TODO
    });

  });
}
