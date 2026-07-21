import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../auth/presentation/controllers/app_auth_provider.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/models/expense_models.dart';

part 'pool_controller.g.dart';

@riverpod
class TripPoolController extends _$TripPoolController {
  @override
  Future<TripPoolModel?> build(String tripId) async {
    ref.watch(authSessionRevisionProvider);
    final repo = ref.watch(expenseRepositoryProvider);
    return repo.getPool(tripId);
  }
}
