/// Editing a wallet's balance is stored as an ordinary income/expense
/// transaction in one of these two categories. They change balances (and show
/// up in History) but are not real income or spending, so income/expense
/// totals, reports and budgets skip them.
const adjustmentIncomeCategoryId = 'income-adjustment';
const adjustmentExpenseCategoryId = 'expense-adjustment';
const adjustmentCategoryName = 'Penyesuaian saldo';
const adjustmentCategoryIcon = 'tune';

bool isAdjustmentCategory(String? categoryId) =>
    categoryId == adjustmentIncomeCategoryId ||
    categoryId == adjustmentExpenseCategoryId;
