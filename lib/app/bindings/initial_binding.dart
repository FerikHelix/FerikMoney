import 'package:get/get.dart';

import '../../database/app_database.dart';
import '../../features/main/money_controller.dart';
import '../../repositories/money_repository.dart';
import '../../services/backup_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AppDatabase(), permanent: true);
    Get.put(MoneyRepository(Get.find()), permanent: true);
    Get.put(BackupService(Get.find()), permanent: true);
    Get.put(MoneyController(Get.find()), permanent: true);
  }
}
