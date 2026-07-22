/// The current "now playing" info for a radio stream, parsed from an ICY
/// `StreamTitle` (e.g. `"Artist - Title"`). [artist] is null when the stream
/// only sends a bare title.
class RadioMetadata {
  final String title;
  final String? artist;

  const RadioMetadata({required this.title, this.artist});

  /// Parses a raw ICY `StreamTitle` value. Returns null when there's nothing
  /// meaningful to show (empty, whitespace, or a lone separator), so callers can
  /// simply hide the now-playing line.
  ///
  /// Splits on the FIRST ` - ` so `"A - B - C"` → artist `A`, title `B - C`.
  static RadioMetadata? parse(String? streamTitle) {
    final raw = streamTitle ?? '';
    if (raw.trim().isEmpty) return null;

    // Locate the separator on the raw string (not a pre-trimmed copy) so a
    // leading `" - Title"` is still recognised as an empty-artist entry.
    final sep = raw.indexOf(' - ');
    if (sep < 0) {
      final title = raw.trim();
      return title.isEmpty ? null : RadioMetadata(title: title);
    }

    final artist = raw.substring(0, sep).trim();
    final title = raw.substring(sep + 3).trim();
    if (artist.isEmpty && title.isEmpty) return null;
    if (artist.isEmpty) return RadioMetadata(title: title);
    if (title.isEmpty) return RadioMetadata(title: artist);
    return RadioMetadata(title: title, artist: artist);
  }

  /// One-line form for compact displays: `"Artist — Title"` or just `"Title"`.
  String get display => artist == null ? title : '$artist — $title';

  @override
  bool operator ==(Object other) =>
      other is RadioMetadata && other.title == title && other.artist == artist;

  @override
  int get hashCode => Object.hash(title, artist);
}
