import 'package:commons/http/data/models/api_response_model.dart';
import 'package:fndtv/src/data/data_sources/content/content_data_source.dart';
import 'package:fndtv/src/data/models/content/content_type_model.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/data/models/content/dvr_item_model.dart';

abstract class ContentRepository {
  Future<ResponseModel<ContentTypeListModel>> getContentTypeList();
  Future<ResponseModel<ContentModelList>> getContent({required int contentType, int? page});
  Future<ResponseModel<LiveModel>> getContentDetail({required int contentType, required int id, String? date});
  Future<ResponseModel<DvrDataModel>> getDvrData({required String url});
}

final class ContentRepositoryImpl implements ContentRepository {
  ContentRepositoryImpl({required ContentDataSource dataSource}) : _contentDataSource = dataSource;

  final ContentDataSource _contentDataSource;

  @override
  Future<ResponseModel<ContentTypeListModel>> getContentTypeList() {
    return _contentDataSource.getContentTypeList();
  }

  @override
  Future<ResponseModel<ContentModelList>> getContent({required int contentType, int? page}) {
    return _contentDataSource.getContents(contentType: contentType, page: page);
  }

  @override
  Future<ResponseModel<LiveModel>> getContentDetail({required int contentType, required int id, String? date}) {
    return _contentDataSource.getContentDetail(contentType: contentType, id: id, date: date);
  }

  @override
  Future<ResponseModel<DvrDataModel>> getDvrData({required String url}) {
    return _contentDataSource.getDvrData(url: url);
  }
}
