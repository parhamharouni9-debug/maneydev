import '../models/month.dart';
import 'api_client.dart';

class GoalsService {
  GoalsService._();
  static final GoalsService instance = GoalsService._();
  final _api = ApiClient.instance;

  Future<Goal?> getGoal(String monthKey) async {
    final res = await _api.get('/api/goals', query: {'month_key': monthKey});
    if (res.data == null) return null;
    return Goal.fromJson(apiJsonObject(res.data));
  }

  Future<List<Goal>> listGoals() async {
    final res = await _api.get('/api/goals');
    final list = apiJsonObjectList(res.data);
    return list.map(Goal.fromJson).toList();
  }

  Future<Goal> saveGoal({
    required String monthKey,
    required num targetAmount,
    String? label,
  }) async {
    final res = await _api.post('/api/goals', data: {
      'month_key': monthKey,
      'target_amount': targetAmount,
      'label': label,
    });
    return Goal.fromJson(apiJsonObject(res.data));
  }

  Future<void> deleteGoal(String monthKey) async {
    await _api.delete('/api/goals/$monthKey');
  }
}
