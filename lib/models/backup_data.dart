class BackupAccount {
  const BackupAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String type;
  final int initialBalance;
  final String icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'initialBalance': initialBalance,
    'icon': icon,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class BackupCategory {
  const BackupCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String type;
  final String icon;
  final DateTime createdAt;

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'icon': icon,
    'createdAt': createdAt.toIso8601String(),
  };
}

class BackupTransaction {
  const BackupTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.accountId,
    required this.destinationAccountId,
    required this.categoryId,
    required this.note,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String type;
  final int amount;
  final String accountId;
  final String? destinationAccountId;
  final String? categoryId;
  final String? note;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type,
    'amount': amount,
    'accountId': accountId,
    'destinationAccountId': destinationAccountId,
    'categoryId': categoryId,
    'note': note,
    'transactionDate': transactionDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class BackupData {
  const BackupData({
    required this.exportedAt,
    required this.accounts,
    required this.categories,
    required this.transactions,
  });

  static const int currentVersion = 1;
  final DateTime exportedAt;
  final List<BackupAccount> accounts;
  final List<BackupCategory> categories;
  final List<BackupTransaction> transactions;

  Map<String, Object> toJson() => {
    'version': currentVersion,
    'app': 'FerikMoney',
    'exportedAt': exportedAt.toIso8601String(),
    'data': {
      'accounts': accounts.map((item) => item.toJson()).toList(),
      'categories': categories.map((item) => item.toJson()).toList(),
      'transactions': transactions.map((item) => item.toJson()).toList(),
    },
  };
}

class BackupValidationException implements Exception {
  const BackupValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
