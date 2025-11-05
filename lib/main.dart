import 'domain/services/room_management_service.dart';
import 'data/json_repository.dart';
import 'data/history_repository.dart';
import 'ui/main_menu.dart';

Future<void> main() async {
  final repo = JsonRepository('data_roomManagement.json');
  final historyRepo = HistoryRepository('data_history.json');
  final service = RoomManagementService(repo, historyRepo);

  await service.load();
  await MainMenu(service, historyRepo).start();
  await service.save();
}
