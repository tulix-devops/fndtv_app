import 'package:commons/commons.dart';

/// Helper extension to map content type IDs from API to ContentType enum
extension ContentTypeMapper on int {
  /// Maps a content type ID to its corresponding ContentType enum value
  /// Returns null if the mapping is not found
  ContentType? toContentType() {
    // Based on the API response:
    // id: 3 -> "channel" -> ContentType.television
    // id: 10 -> "radio" -> ContentType.radio
    switch (this) {
      case 3: // channel
        return ContentType.television;
      case 10: // radio
        return ContentType.radio;
      case 8: // television (if used)
        return ContentType.television;
      case 9: // television languages (if used)
        return ContentType.televisionLan;
      case 12: // dvr (if used)
        return ContentType.dvr;
      default:
        // Fallback to television for unknown types
        return ContentType.television;
    }
  }
}

/// Helper extension to get content type ID from ContentType enum
extension ContentTypeIdMapper on ContentType {
  /// Returns the API content type ID for this ContentType
  int get apiId {
    switch (this) {
      case ContentType.television:
        return 3; // or 8, depending on your API
      case ContentType.televisionLan:
        return 9;
      case ContentType.radio:
        return 10;
      case ContentType.dvr:
        return 12;
    }
  }
}
