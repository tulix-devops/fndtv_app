import 'package:commons/commons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:fndtv/src/data/models/content/content_type_model.dart';
import 'package:fndtv/src/data/models/content/dvr_item_model.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/data/repositories/content/content_repository.dart';

/// Fails the first [failuresBeforeSuccess] calls, then succeeds — models a box
/// whose network comes up a moment after the app does.
class _FlakyRepo implements ContentRepository {
  _FlakyRepo({this.failuresBeforeSuccess = 0, this.alwaysFail = false});

  int failuresBeforeSuccess;
  final bool alwaysFail;
  int calls = 0;

  @override
  Future<ResponseModel<ContentModelList>> getContent({
    required int contentType,
    int? page,
  }) async {
    calls++;
    if (alwaysFail || failuresBeforeSuccess-- > 0) {
      throw Exception('network unreachable');
    }
    return SuccessModel<ContentModelList>(
      statusCode: 200,
      message: 'ok',
      data: ContentModelList(
        statusCode: 200,
        message: 'ok',
        data: const <LiveModel>[],
      ),
    );
  }

  @override
  Future<ResponseModel<ContentTypeListModel>> getContentTypeList() =>
      throw UnimplementedError();
  @override
  Future<ResponseModel<LiveModel>> getContentDetail({
    required int contentType,
    required int id,
    String? date,
  }) =>
      throw UnimplementedError();
  @override
  Future<ResponseModel<DvrDataModel>> getDvrData({required String url}) =>
      throw UnimplementedError();
}

ContentCubit _cubit(ContentRepository repo) => ContentCubit(
      contentDataSource: repo,
      initialLoadBudget: const Duration(milliseconds: 400),
      retryBackoff: const [Duration(milliseconds: 20)],
    );

void main() {
  group('ContentCubit initial load', () {
    test('a failure inside the budget keeps the spinner, never the error', () async {
      // The reported bug: a cold boot lost the race with DHCP, and one failed
      // attempt parked the box on a Retry screen until someone pressed OK.
      final repo = _FlakyRepo(failuresBeforeSuccess: 2);
      final cubit = _cubit(repo);
      final seen = <Status>[];
      final sub = cubit.stream.listen((s) => seen.add(s.status));

      cubit.getContentForMultipleTypes([8]);
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(cubit.state.status, Status.success);
      expect(repo.calls, greaterThan(1), reason: 'should have retried');
      expect(seen, isNot(contains(Status.failure)),
          reason: 'must never flash the error while still retrying');

      await sub.cancel();
      await cubit.close();
    });

    test('gives up once the budget is spent', () async {
      final repo = _FlakyRepo(alwaysFail: true);
      final cubit = _cubit(repo);

      cubit.getContentForMultipleTypes([8]);
      await Future<void>.delayed(const Duration(milliseconds: 700));

      expect(cubit.state.status, Status.failure);
      await cubit.close();
    });

    test('retryNow recovers a load that already gave up', () async {
      // A box offline at boot that reconnects later must heal itself rather
      // than wait for a person to press Retry.
      final repo = _FlakyRepo(alwaysFail: false, failuresBeforeSuccess: 999);
      final cubit = _cubit(repo);

      cubit.getContentForMultipleTypes([8]);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(cubit.state.status, Status.failure);

      // Network is back.
      repo.failuresBeforeSuccess = 0;
      cubit.retryNow();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(cubit.state.status, Status.success);
      await cubit.close();
    });

    test('a closed cubit stops retrying', () async {
      final repo = _FlakyRepo(alwaysFail: true);
      final cubit = _cubit(repo);

      cubit.getContentForMultipleTypes([8]);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await cubit.close();
      final callsAtClose = repo.calls;

      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(repo.calls, callsAtClose,
          reason: 'no timer should outlive the cubit');
    });
  });
}
