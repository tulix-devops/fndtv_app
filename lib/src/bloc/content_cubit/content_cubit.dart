import 'package:commons/commons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/data/models/content/dvr_item_model.dart';
import 'package:fndtv/src/data/repositories/content/content_repository.dart';

part 'content_state.dart';
part 'content_cubit.freezed.dart';

class ContentCubit extends Cubit<ContentState> {
  ContentCubit({
    required ContentRepository contentDataSource,
  })  : _contentDataSource = contentDataSource,
        super(const ContentState());

  final ContentRepository _contentDataSource;

  ContentModelList? handleLiveList(ResponseModel<ContentModelList> responseModel) {
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
      final result = await _contentDataSource.getContent(contentType: contentTypeId);
      final contentList = handleLiveList(result);

      final updatedContentMap = Map<String, ContentModelList?>.from(state.contentList ?? {});
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

  void getContentForMultipleTypes(List<int> contentTypeIds) async {
    if (isClosed) return;
    emit(state.copyWith(status: Status.loading));
    Map<String, ContentModelList?> contentList = {};
    try {
      await Future.wait(
        contentTypeIds.map((typeId) async {
          // Special handling for VOD (typeId: 1) - fetch multiple pages to get diverse taglines
          if (typeId == 1) {
            final allVodItems = <LiveModel>[];
            final uniqueTaglines = <String>{};
            int currentPage = 1;
            const maxPages = 5; // Limit to 5 pages max to avoid too many requests
            
            // Keep fetching pages until we have at least 3 unique taglines or reach max pages
            while (uniqueTaglines.length < 3 && currentPage <= maxPages) {
              final result = await _contentDataSource.getContent(contentType: typeId, page: currentPage);
              final pageContent = handleLiveList(result);
              
              if (pageContent != null && pageContent.data.isNotEmpty) {
                allVodItems.addAll(pageContent.data);
                
                // Track unique taglines
                for (final item in pageContent.data) {
                  if (item.details?.tagline != null && item.details!.tagline!.isNotEmpty) {
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
            final result = await _contentDataSource.getContent(contentType: typeId);
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
    } catch (e) {
      emit(state.copyWith(status: Status.failure));
    }
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
