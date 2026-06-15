import 'package:freezed_annotation/freezed_annotation.dart';

part 'dvr_item_model.freezed.dart';
part 'dvr_item_model.g.dart';

@freezed
class DvrItemModel with _$DvrItemModel {
  const DvrItemModel._();

  const factory DvrItemModel({
    required int id,
    @JsonKey(name: 'name') required String title,
    required String descr,
    @JsonKey(name: 'length') String? duration,
    @JsonKey(name: 'hdposterurl') String? thumb,
    @JsonKey(name: 'hls') required String stream,
    String? downloadurl,
    @JsonKey(name: 'islive') int? isLive,
  }) = _DvrItemModel;

  factory DvrItemModel.fromJson(Map<String, dynamic> json) => _$DvrItemModelFromJson(json);

  // Helper getters for easier access
  DateTime get startDateTime => DateTime.fromMillisecondsSinceEpoch(id * 1000);
  
  DateTime get endDateTime {
    int durationMinutes = 0;
    if (duration != null && duration!.isNotEmpty) {
      final match = RegExp(r'(\d+)').firstMatch(duration!);
      if (match != null) {
        durationMinutes = int.tryParse(match.group(1) ?? '0') ?? 0;
      }
    }
    return startDateTime.add(Duration(minutes: durationMinutes));
  }

  String get formattedStartTime {
    final dt = startDateTime;
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String get formattedEndTime {
    final dt = endDateTime;
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String get dayName {
    const dayNames = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    return dayNames[startDateTime.weekday % 7];
  }

  /// Returns a stable date key in `yyyy-MM-dd` format for grouping items by
  /// exact date (so same weekday on different weeks won't be merged).
  String get dateKey => startDateTime.toIso8601String().split('T').first;

  /// Returns a short, human friendly label combining day name and date
  /// e.g. "MON 08/09/2024" which is useful to display in the UI list.
  String get dateLabel {
    final dt = startDateTime;
    final dayAbbr = dayName.substring(0, 3).toUpperCase();
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$dayAbbr $month/$day';
  }

  bool get isFuture => startDateTime.isAfter(DateTime.now());
  
  bool get isLiveStream => (isLive ?? 0) == 1;

  String get displayTitle => title.isNotEmpty ? title : 'Program';
  String get displayDescription => descr.isNotEmpty ? descr : '';
  
  String get displayThumb => thumb ?? '';
}

@freezed
class DvrDataModel with _$DvrDataModel {
  const DvrDataModel._();

  const factory DvrDataModel({
    required List<DvrItemModel> items,
  }) = _DvrDataModel;

  factory DvrDataModel.fromJson(Map<String, dynamic> json) => _$DvrDataModelFromJson(json);

  factory DvrDataModel.fromList(List<dynamic> jsonList) {
    final items = jsonList.map((item) => DvrItemModel.fromJson(item as Map<String, dynamic>)).toList();
    return DvrDataModel(items: items);
  }

  // Organize items by day of week
  Map<String, List<DvrItemModel>> get itemsByDay {
    // Use a LinkedHashMap to preserve chronological insertion order.
    final Map<String, List<DvrItemModel>> schedulesByDay = <String, List<DvrItemModel>>{};

    // Filter out future items and sort globally by start time so groups are
    // created in chronological order.

    for (final item in items) {
      final label = item.dateLabel; // human friendly label used as map key

      if (!schedulesByDay.containsKey(label)) {
        schedulesByDay[label] = [];
      }

      schedulesByDay[label]!.add(item);
    }

    // Ensure items in each date group are sorted by start time
    for (final daySchedules in schedulesByDay.values) {
      daySchedules.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    }

    // Sort the map by keys (dates) in reverse chronological order
    final sortedKeys = schedulesByDay.keys.toList()
      ..sort((a, b) {
        // Get the first item from each day to compare dates
        final dateA = schedulesByDay[a]!.first.startDateTime;
        final dateB = schedulesByDay[b]!.first.startDateTime;
        return dateB.compareTo(dateA); // Reversed for most recent first
      });

    // Create a new LinkedHashMap with sorted keys
    final sortedMap = <String, List<DvrItemModel>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = schedulesByDay[key]!;
    }

    return sortedMap;
  }
}
