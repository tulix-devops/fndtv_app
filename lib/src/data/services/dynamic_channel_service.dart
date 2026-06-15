import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/data/models/content/images_model.dart';
import 'package:fndtv/src/data/models/content/source_model.dart';

class DynamicChannelService {
  DynamicChannelService._();
  
  static const String _primaryApiUrl = 'https://tulix.com/xml/watctv57/watctv57droid-v2.php';
  static const String _fallbackApiUrl = 'https://tulix.com/xml/watctv57/watctv57droid.php';
  
  static Future<List<LiveModel>> getChannels() async {
    // Try primary URL first
    try {
      print('Trying primary API: $_primaryApiUrl');
      final response = await http.get(Uri.parse(_primaryApiUrl));
      
      if (response.statusCode == 200) {
        print('Primary API success: ${response.body.length} characters');
        return _parseChannelData(response.body);
      } else {
        print('Primary API failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Primary API error: $e');
    }
    
    // Try fallback URL
    try {
      print('Trying fallback API: $_fallbackApiUrl');
      final response = await http.get(Uri.parse(_fallbackApiUrl));
      
      if (response.statusCode == 200) {
        print('Fallback API success: ${response.body.length} characters');
        return _parseChannelData(response.body);
      } else {
        print('Fallback API failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Fallback API error: $e');
    }
    
    print('Both APIs failed, using static fallback data');
    return _getFallbackChannels();
  }
  
  static List<LiveModel> _parseChannelData(String responseBody) {
    final List<LiveModel> channels = [];
    
    print('Raw API response: ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}...');
    
    // Check if response is XML format
    if (responseBody.trim().startsWith('<?xml')) {
      print('Detected XML format, parsing as XML');
      return _parseXmlChannelData(responseBody);
    } else {
      print('Detected plain text format, parsing as text');
      return _parseTextChannelData(responseBody);
    }
  }
  
  static List<LiveModel> _parseXmlChannelData(String xmlResponse) {
    final List<LiveModel> channels = [];
    
    try {
      // First, extract the content inside the <array> tag
      final arrayPattern = RegExp(r'<array>(.*?)</array>', dotAll: true);
      final arrayMatch = arrayPattern.firstMatch(xmlResponse);
      
      if (arrayMatch == null) {
        print('No <array> tag found in XML');
        return channels;
      }
      
      final arrayContent = arrayMatch.group(1)!;
      print('Array content length: ${arrayContent.length}');
      
      // Now extract all <dict> blocks within the array (these are the channels)
      final dictPattern = RegExp(r'<dict>(.*?)</dict>', dotAll: true);
      final dictMatches = dictPattern.allMatches(arrayContent).toList();
      
      print('Found ${dictMatches.length} channel dict blocks in array');
      
      for (int i = 0; i < dictMatches.length; i++) {
        final dictContent = dictMatches[i].group(1)!; // Get content inside <dict>...</dict>
        
        print('Processing channel dict $i');
        
        try {
          final id = _extractXmlValue(dictContent, 'id');
          final name = _extractXmlValue(dictContent, 'name');
          final logoUrlHD = _extractXmlValue(dictContent, 'logoUrlHD');
          final logoUrlSD = _extractXmlValue(dictContent, 'logoUrlSD');
          final hlsUrl = _extractXmlValue(dictContent, 'HlsStreamURL');
          
          print('XML Extracted - ID: $id, Name: $name, Logo: ${logoUrlHD?.substring(0, 50)}..., HLS: ${hlsUrl?.substring(0, 50)}...');
          
          if (id != null && name != null && logoUrlHD != null && hlsUrl != null) {
            // Decode URL-encoded characters and ensure HTTPS
            final decodedLogoHD = Uri.decodeFull(logoUrlHD).replaceFirst('http://', 'https://');
            final decodedLogoSD = logoUrlSD != null ? Uri.decodeFull(logoUrlSD).replaceFirst('http://', 'https://') : decodedLogoHD;
            final decodedHlsUrl = Uri.decodeFull(hlsUrl);
            
            print('Decoded URLs - Logo: $decodedLogoHD, HLS: $decodedHlsUrl');
            
            channels.add(LiveModel(
              id: int.tryParse(id) ?? i,
              statusId: 1,
              productId: 0,
              type: 'live',
              typeId: 1,
              title: name,
              description: '$name Channel',
              live: true,
              images: ImagesModel(
                thumbnail: decodedLogoHD,
                poster: decodedLogoHD,
                banner: decodedLogoHD,
              ),
              sources: SourceModel(
                id: int.tryParse(id) ?? i,
                primary: null,
                secondary: null,
                trailer: null,
                hls: decodedHlsUrl,
                dash: null,
                file: null,
              ),
            ));
            print('Successfully added XML channel: $name (ID: $id)');
            print('  - Thumbnail URL: $decodedLogoHD');
            print('  - HLS URL: $decodedHlsUrl');
          } else {
            print('Missing required fields - ID: $id, Name: $name, Logo: ${logoUrlHD != null}, HLS: ${hlsUrl != null}');
          }
        } catch (e) {
          print('Error parsing XML channel $i: $e');
          continue;
        }
      }
    } catch (e) {
      print('Error parsing XML response: $e');
    }
    
    print('Total XML channels parsed: ${channels.length}');
    return channels;
  }
  
  static String? _extractXmlValue(String xmlContent, String key) {
    final pattern = RegExp('<key>$key</key>\\s*<string>(.*?)</string>', dotAll: true);
    final match = pattern.firstMatch(xmlContent);
    return match?.group(1)?.trim();
  }
  
  static List<LiveModel> _parseTextChannelData(String responseBody) {
    final List<LiveModel> channels = [];
    
    // Remove "Channels" prefix if it exists
    String cleanedResponse = responseBody.replaceFirst(RegExp(r'^Channels\s*'), '');
    
    // Split by 'id ' to get individual channel blocks
    final parts = cleanedResponse.split(RegExp(r'\s+id\s+')).where((part) => part.trim().isNotEmpty).toList();
    
    print('Found ${parts.length} text channel parts');
    
    for (int i = 0; i < parts.length; i++) {
      final part = 'id ' + parts[i];
      
      try {
        final id = _extractValue(part, r'id\s+(\d+)');
        final name = _extractValue(part, r'name\s+([^l]+?)(?=\s+logoUrlHD)');
        final logoUrlHD = _extractValue(part, r'logoUrlHD\s+(http[^\s]+)');
        final hlsUrl = _extractValue(part, r'HlsStreamURL\s+(https?://[^\s]+)');
        
        if (id != null && name != null && logoUrlHD != null && hlsUrl != null) {
          // Decode URL-encoded characters and ensure HTTPS
          final decodedLogoHD = Uri.decodeFull(logoUrlHD).replaceFirst('http://', 'https://');
          final decodedHlsUrl = Uri.decodeFull(hlsUrl);
          
          channels.add(LiveModel(
            id: int.tryParse(id) ?? i,
            statusId: 1,
            productId: 0,
            type: 'live',
            typeId: 1,
            title: name.trim(),
            description: '${name.trim()} Channel',
            live: true,
            images: ImagesModel(
              thumbnail: decodedLogoHD,
              poster: decodedLogoHD,
              banner: decodedLogoHD,
            ),
            sources: SourceModel(
              id: int.tryParse(id) ?? i,
              primary: null,
              secondary: null,
              trailer: null,
              hls: decodedHlsUrl,
              dash: null,
              file: null,
            ),
          ));
        }
      } catch (e) {
        print('Error parsing text channel $i: $e');
        continue;
      }
    }
    
    return channels;
  }
  
  static String? _extractValue(String text, String pattern) {
    final regex = RegExp(pattern);
    final match = regex.firstMatch(text);
    return match?.group(1)?.trim();
  }
  
  // Fallback to static data if API fails
  static List<LiveModel> _getFallbackChannels() {
    return [
      LiveModel(
        id: 0,
        statusId: 1,
        productId: 0,
        type: 'live',
        typeId: 1,
        title: 'WATC TV',
        description: 'WATC TV Channel',
        live: true,
        images: ImagesModel(
          thumbnail: 'https://tulix.com/xml/watctv57/content/WATC%20TV/Watch%20WATC%20TV/watctv47-fire2.png',
          poster: 'https://tulix.com/xml/watctv57/content/WATC%20TV/Watch%20WATC%20TV/watctv47-fire2.png',
          banner: 'https://tulix.com/xml/watctv57/content/WATC%20TV/Watch%20WATC%20TV/watctv47-fire2.png',
        ),
        sources: SourceModel(
          id: 0,
          primary: null,
          secondary: null,
          trailer: null,
          hls: 'https://tgn.bozztv.com/watc57/watc57-1/watc57-1/index.m3u8',
          dash: null,
          file: null,
        ),
      ),
      LiveModel(
        id: 1,
        statusId: 1,
        productId: 0,
        type: 'live',
        typeId: 1,
        title: 'The Point Television Network',
        description: 'The Point Television Network Channel',
        live: true,
        images: ImagesModel(
          thumbnail: 'https://tulix.com/xml/watctv57/content/The%20Point%20Television%20Network/Watch%20The%20Point%20Television%20Network/thepoint-fire2.png',
          poster: 'https://tulix.com/xml/watctv57/content/The%20Point%20Television%20Network/Watch%20The%20Point%20Television%20Network/thepoint-fire2.png',
          banner: 'https://tulix.com/xml/watctv57/content/The%20Point%20Television%20Network/Watch%20The%20Point%20Television%20Network/thepoint-fire2.png',
        ),
        sources: SourceModel(
          id: 1,
          primary: null,
          secondary: null,
          trailer: null,
          hls: 'https://tgn.bozztv.com/watc57/watc57-2/watc57-2/index.m3u8',
          dash: null,
          file: null,
        ),
      ),
      LiveModel(
        id: 2,
        statusId: 1,
        productId: 0,
        type: 'live',
        typeId: 1,
        title: 'Lovers Of Old Programs',
        description: 'Lovers Of Old Programs Channel',
        live: true,
        images: ImagesModel(
          thumbnail: 'https://tulix.com/xml/watctv57/content/Lovers%20Of%20Old%20Programs/Watch%20Lovers%20Of%20Old%20Programs/theloop-fire.png',
          poster: 'https://tulix.com/xml/watctv57/content/Lovers%20Of%20Old%20Programs/Watch%20Lovers%20Of%20Old%20Programs/theloop-fire.png',
          banner: 'https://tulix.com/xml/watctv57/content/Lovers%20Of%20Old%20Programs/Watch%20Lovers%20Of%20Old%20Programs/theloop-fire.png',
        ),
        sources: SourceModel(
          id: 2,
          primary: null,
          secondary: null,
          trailer: null,
          hls: 'https://tgn.bozztv.com/watc57/watc57-theloop/watc57-theloop/index.m3u8',
          dash: null,
          file: null,
        ),
      ),
      LiveModel(
        id: 3,
        statusId: 1,
        productId: 0,
        type: 'live',
        typeId: 1,
        title: 'Harmony Gospel Music TV',
        description: 'Harmony Gospel Music TV Channel',
        live: true,
        images: ImagesModel(
          thumbnail: 'https://tulix.com/xml/watctv57/content/Harmony%20Gospel%20Music%20TV/Watch%20Harmony%20Gospel%20Music%20TV/harmony-fire.png',
          poster: 'https://tulix.com/xml/watctv57/content/Harmony%20Gospel%20Music%20TV/Watch%20Harmony%20Gospel%20Music%20TV/harmony-fire.png',
          banner: 'https://tulix.com/xml/watctv57/content/Harmony%20Gospel%20Music%20TV/Watch%20Harmony%20Gospel%20Music%20TV/harmony-fire.png',
        ),
        sources: SourceModel(
          id: 3,
          primary: null,
          secondary: null,
          trailer: null,
          hls: 'https://tgn.bozztv.com/watc57/watc57-harmony/watc57-harmony/index.m3u8',
          dash: null,
          file: null,
        ),
      ),
    ];
  }
}
