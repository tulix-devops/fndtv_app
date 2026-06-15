part of 'content_cubit.dart';

@freezed
class ContentState with _$ContentState {
  const ContentState._();
  const factory ContentState({
    @Default(Status.initial) Status status,
    Map<String, ContentModelList?>? contentList,
    @Default(Status.initial) Status dvrStatus,
    DvrDataModel? dvrData,
  }) = _ContentState;
}
