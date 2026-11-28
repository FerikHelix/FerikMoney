class DomainError implements Exception {
  const DomainError(this.code, [this.details]);

  final String code;
  final Object? details;

  @override
  String toString() => 'DomainError($code)';
}

abstract final class ErrorCodes {
  static const lastWallet = 'last_wallet';
  static const walletHasHistory = 'wallet_has_history';
  static const duplicateName = 'duplicate_name';
  static const sameWallet = 'same_wallet';
  static const futureDate = 'future_date';
  static const invalidAmount = 'invalid_amount';
  static const amountTooLarge = 'amount_too_large';
  static const overpayment = 'overpayment';
  static const alreadyCommitted = 'already_committed';
  static const invalidDueDay = 'invalid_due_day';
  static const noWallet = 'no_wallet';
}
