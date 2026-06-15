import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class DvrDownloadService {
  final Dio _dio = Dio();

  /// Get list of available external storage locations (USB drives, SD cards)
  Future<List<({String path, String name})>> getAvailableStorageLocations() async {
    final List<({String path, String name})> locations = [];

    try {
      // Add app's external storage directory (always available)
      final appDir = await getExternalStorageDirectory();
      if (appDir != null) {
        locations.add((path: '${appDir.path}/Downloads', name: 'Device Storage'));
      }

      // Common USB/external storage mount points on Android
      final commonPaths = [
        '/storage/emulated/0/Movies',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Downloads',
        '/storage/usbdisk',
        '/storage/usb',
        '/mnt/usbdisk',
        '/mnt/usb',
        '/storage/sda1',
        '/storage/sdb1',
        '/mnt/media_rw/USB_DISK',
        '/mnt/media_rw/usbdisk',
      ];

      // Check which paths actually exist and are writable
      for (final path in commonPaths) {
        final dir = Directory(path);
        if (await dir.exists()) {
          try {
            // Try to check if we can write to this location
            final testFile = File('$path/.test_write_${DateTime.now().millisecondsSinceEpoch}');
            await testFile.writeAsString('test');
            await testFile.delete();

            // Extract a friendly name from the path
            String name;
            if (path.contains('/storage/emulated/0/')) {
              final folder = path.split('/').last;
              name = 'Internal Storage ($folder)';
            } else {
              final pathPart = path.split('/').last.toUpperCase();
              name = 'USB Drive ($pathPart)';
            }
            locations.add((path: path, name: name));
          } catch (e) {
            // Can't write to this location, skip it
            print('Cannot write to $path: $e');
          }
        }
      }

      // Try to list /storage directory to find mounted drives
      final storageDir = Directory('/storage');
      if (await storageDir.exists()) {
        await for (final entity in storageDir.list()) {
          if (entity is Directory) {
            final dirName = entity.path.split('/').last;
            // Skip emulated and self directories
            if (dirName != 'emulated' && dirName != 'self' && !dirName.startsWith('.')) {
              // Check if this directory has actual files/folders and is writable
              try {
                final testFile = File('${entity.path}/.test_write_${DateTime.now().millisecondsSinceEpoch}');
                await testFile.writeAsString('test');
                await testFile.delete();

                // Only add if not already in our list
                if (!locations.any((loc) => loc.path == entity.path)) {
                  locations.add((path: entity.path, name: 'External Storage ($dirName)'));
                }
              } catch (e) {
                // Can't write, skip
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error getting storage locations: $e');
    }

    return locations;
  }

  /// Downloads a DVR video file to a custom location (USB drive) selected by user
  /// Returns success status, file path, and error message if any
  Future<({bool success, String? filePath, String? error})> downloadDvrVideoToCustomLocation({
    required String videoUrl,
    required String fileName,
    required String selectedPath,
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      // Check if running on Android
      if (!Platform.isAndroid) {
        return (success: false, filePath: null, error: 'Downloads are only supported on Android TV');
      }

      // Ensure the selected path exists (create if necessary)
      final directory = Directory(selectedPath);
      if (!await directory.exists()) {
        try {
          await directory.create(recursive: true);
        } catch (e) {
          return (success: false, filePath: null, error: 'Failed to create directory: $e');
        }
      }

      // Sanitize filename
      final sanitizedFileName = _sanitizeFileName(fileName);
      final filePath = '$selectedPath/$sanitizedFileName';

      // Check if file already exists
      final file = File(filePath);
      if (await file.exists()) {
        return (success: false, filePath: null, error: 'File already exists in selected location');
      }

      // Download the file
      await _dio.download(
        videoUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (onProgress != null) {
            // Always call the progress callback, let the UI handle -1 total
            onProgress(received, total);
          }
        },
        options: Options(
          headers: {
            'Accept': '*/*',
          },
          receiveTimeout: const Duration(minutes: 30),
          sendTimeout: const Duration(minutes: 30),
        ),
      );

      return (success: true, filePath: filePath, error: null);
    } on DioException catch (e) {
      print(e.message);
      return (success: false, filePath: null, error: 'Download failed: ${e.message}');
    } catch (e) {
      print(e);
      return (success: false, filePath: null, error: 'Download failed: $e');
    }
  }

  /// Downloads a DVR video file to the default app directory
  /// Returns true if download was successful, false otherwise
  Future<({bool success, String? filePath, String? error})> downloadDvrVideo({
    required String videoUrl,
    required String fileName,
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      // Check if running on Android
      if (!Platform.isAndroid) {
        return (success: false, filePath: null, error: 'Downloads are only supported on Android TV');
      }

      // Get the downloads directory (no permissions needed for app-specific directories)
      final Directory? directory = await _getDownloadDirectory();
      if (directory == null) {
        return (success: false, filePath: null, error: 'Could not access downloads directory');
      }

      // Ensure the directory exists
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Sanitize filename
      final sanitizedFileName = _sanitizeFileName(fileName);
      final filePath = '${directory.path}/$sanitizedFileName';

      // Check if file already exists
      final file = File(filePath);
      if (await file.exists()) {
        return (success: false, filePath: null, error: 'File already exists');
      }

      // Download the file
      await _dio.download(
        videoUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (onProgress != null && total != -1) {
            onProgress(received, total);
          }
        },
        options: Options(
          headers: {
            'Accept': '*/*',
          },
          receiveTimeout: const Duration(minutes: 30),
          sendTimeout: const Duration(minutes: 30),
        ),
      );

      return (success: true, filePath: filePath, error: null);
    } on DioException catch (e) {
      print(e.message);
      return (success: false, filePath: null, error: 'Download failed: ${e.message}');
    } catch (e) {
      print(e);
      return (success: false, filePath: null, error: 'Download failed: $e');
    }
  }

  /// Get the appropriate download directory for Android
  Future<Directory?> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // For Android, use the app's external storage directory
      // This doesn't require storage permissions on Android 10+
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        // Create a Downloads subfolder in the app's directory
        return Directory('${directory.path}/Downloads');
      }
    }
    return null;
  }

  /// Sanitize the filename to remove invalid characters
  String _sanitizeFileName(String fileName) {
    // Remove invalid characters for file names
    String sanitized = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

    // Ensure the file has .mp4 extension if it doesn't have one
    if (!sanitized.toLowerCase().endsWith('.mp4') &&
        !sanitized.toLowerCase().endsWith('.m3u8') &&
        !sanitized.toLowerCase().endsWith('.ts')) {
      sanitized = '$sanitized.mp4';
    }

    return sanitized;
  }

  /// Cancel ongoing downloads (if needed in the future)
  void cancelDownload() {
    _dio.close(force: true);
  }

  /// Get the size of a file before downloading (optional)
  Future<int?> getFileSize(String url) async {
    try {
      final response = await _dio.head(url);
      final contentLength = response.headers.value('content-length');
      return contentLength != null ? int.tryParse(contentLength) : null;
    } catch (e) {
      return null;
    }
  }
}
