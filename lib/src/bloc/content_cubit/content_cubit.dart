import 'dart:async';

import 'package:commons/commons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/data/models/content/dvr_item_model.dart';
import 'package:fndtv/src/data/repositories/content/content_repository.dart';

part 'content_state.dart';
part 'content_cubit.freezed.dart';

const List<Duration> _kDefaultRetryBackoff = <Duration>[
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 3),
  Duration(seconds: 4),
];

class ContentCubit extends Cubit<ContentState> {
  ContentCubit({
    required ContentRepository contentDataSource,
    Duration initialLoadBudget = const Duration(seconds: 10),
    List<Duration> retryBackoff = _kDefaultRetryBackoff,
  })  : _contentDataSource = contentDataSource,
        _initialLoadBudget = initialLoadBudget,
        _retryBackoff = retryBackoff,
        super(const ContentState());

  final ContentRepository _contentDataSource;

  /// How long the first load keeps trying before it admits defeat.
  ///
  /// A cold-booted box runs this before the network stack is ready: the app is
  /// the launcher, so it starts well ahead of association and DHCP. The old
  /// behaviour gave up after a single attempt and parked on a Retry button that
  /// only a person could clear — a box left alone stayed on that screen. The
  /// splash's 2.5s head start was not enough on a new box, and a fixed delay
  /// would only be a longer guess, so this waits on the outcome instead of the
  /// clock: stay in [Status.loading] (spinner) and keep trying.
  ///
  /// Injectable so the behaviour can be tested without a ten-second wait.
  final Duration _initialLoadBudget;
  final List<Duration> _retryBackoff;

  Timer? _retryTimer;
  DateTime? _retryDeadline;
  List<int>? _retryTypeIds;
  int _retryAttempt = 0;

  ContentModelList? handleLiveList(
      ResponseModel<ContentModelList> responseModel) {
    return (switch (responseModel) {
      PaginatedModel<ContentModelList>() => responseModel.data,
      SuccessModel<ContentModelList>() => responseModel.data,
      _ => null,
    });
  }

  void getContentForType(int contentTypeId) async {
    if (isClosed) return;
    emit(state.copyWith(status: Status.loading));
    try {
      final result =
          await _contentDataSource.getContent(contentType: contentTypeId);
      final contentList = handleLiveList(result);

      final updatedContentMap =
          Map<String, ContentModelList?>.from(state.contentList ?? {});
      updatedContentMap['$contentTypeId'] = contentList;

      emit(
        state.copyWith(
          status: Status.success,
          contentList: updatedContentMap,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: Status.failure));
    }
  }

  /// Loads the content lists, retrying while the box comes online.
  ///
  /// Stays in [Status.loading] across retries so the viewer sees a spinner that
  /// resolves itself, not an error screen that needs a keypress.
  void getContentForMultipleTypes(List<int> contentTypeIds) {
    if (isClosed) return;
    _retryTimer?.cancel();
    _retryAttempt = 0;
    _retryTypeIds = contentTypeIds;
    _retryDeadline = DateTime.now().add(_initialLoadBudget);
    _attemptContentLoad();
  }

  /// Retries immediately instead of waiting for the next backoff tick.
  ///
  /// Called when connectivity returns, so the spinner ends as soon as the
  /// network is genuinely up. Also restarts a load that already gave up — a box
  /// that was offline at boot and reconnects later recovers on its own rather
  /// than sitting on the error until someone presses Retry.
  void retryNow() {
    if (isClosed) return;
    final ids = _retryTypeIds;
    if (ids == null) return;
    _retryTimer?.cancel();
    if (_retryDeadline == null) {
      _retryAttempt = 0;
      _retryDeadline = DateTime.now().add(_initialLoadBudget);
    }
    _attemptContentLoad();
  }

  Future<void> _attemptContentLoad() async {
    final ids = _retryTypeIds;
    if (isClosed || ids == null) return;
    emit(state.copyWith(status: Status.loading));

    final ok = await _fetchContentForTypes(ids);
    if (isClosed) return;
    if (ok) {
      _retryTimer?.cancel();
      _retryDeadline = null;
      return;
    }

    final deadline = _retryDeadline;
    if (deadline == null || !DateTime.now().isBefore(deadline)) {
      // Budget spent — now the error is honest rather than premature.
      _retryDeadline = null;
      emit(state.copyWith(status: Status.failure));
      return;
    }
    final delay =
        _retryBackoff[_retryAttempt.clamp(0, _retryBackoff.length - 1)];
    _retryAttempt++;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, _attemptContentLoad);
  }

  /// One attempt. Emits success itself; returns false so the caller can decide
  /// whether to retry or surface the failure.
  Future<bool> _fetchContentForTypes(List<int> contentTypeIds) async {
    Map<String, ContentModelList?> contentList = {};
    try {
      await Future.wait(
        contentTypeIds.map((typeId) async {
          // Special handling for VOD (typeId: 1) - fetch multiple pages to get diverse taglines
          if (typeId == 1) {
            final allVodItems = <LiveModel>[];
            final uniqueTaglines = <String>{};
            int currentPage = 1;
            const maxPages =
                5; // Limit to 5 pages max to avoid too many requests

            // Keep fetching pages until we have at least 3 unique taglines or reach max pages
            while (uniqueTaglines.length < 3 && currentPage <= maxPages) {
              final result = await _contentDataSource.getContent(
                  contentType: typeId, page: currentPage);
              final pageContent = handleLiveList(result);
              print('result $result');

              if (pageContent != null && pageContent.data.isNotEmpty) {
                allVodItems.addAll(pageContent.data);

                // Track unique taglines
                for (final item in pageContent.data) {
                  if (item.details?.tagline != null &&
                      item.details!.tagline!.isNotEmpty) {
                    uniqueTaglines.add(item.details!.tagline!);
                  }
                }

                currentPage++;
              } else {
                break; // No more data
              }
            }

            // Create a combined content list with all fetched VOD items
            contentList['$typeId'] = ContentModelList(
              statusCode: 200,
              message: 'success',
              data: allVodItems,
            );
          } else {
            // For other content types, fetch normally (page 1 only)
            final result =
                await _contentDataSource.getContent(contentType: typeId);
            contentList['$typeId'] = handleLiveList(result);
          }
        }),
      );

      emit(
        state.copyWith(
          status: Status.success,
          contentList: contentList,
        ),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> close() {
    _retryTimer?.cancel();
    return super.close();
  }

  void getDvrDataFromUrl({required String dvrUrl}) async {
    if (isClosed) return;
    emit(state.copyWith(dvrStatus: Status.loading));
    try {
      final result = await _contentDataSource.getDvrData(url: dvrUrl);

      if (result is SuccessModel<DvrDataModel>) {
        emit(
          state.copyWith(
            dvrStatus: Status.success,
            dvrData: result.data,
          ),
        );
      } else {
        emit(state.copyWith(dvrStatus: Status.failure));
      }
    } catch (e) {
      emit(state.copyWith(dvrStatus: Status.failure));
    }
  }
}
