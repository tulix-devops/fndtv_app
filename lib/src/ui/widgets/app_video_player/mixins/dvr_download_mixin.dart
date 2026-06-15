import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fndtv/src/core/services/dvr_download_service.dart';
import 'package:fndtv/src/data/models/content/dvr_item_model.dart';
import 'package:ui_kit/ui_kit.dart';

/// Mixin that provides DVR download functionality to any widget
mixin DvrDownloadMixin<T extends StatefulWidget> on State<T> {
  // Track multiple downloads with their progress
  final Map<int, double> _downloadProgresses = {};
  final Map<int, int> _downloadedBytesMap = {};
  final Set<int> _activeDownloads = {};
  final DvrDownloadService _downloadService = DvrDownloadService();

  /// Check if a specific item is downloading
  bool isItemDownloading(int itemId) => _activeDownloads.contains(itemId);

  /// Get download progress for a specific item
  double getItemDownloadProgress(int itemId) => _downloadProgresses[itemId] ?? 0.0;

  /// Get downloaded bytes for a specific item
  int getItemDownloadedBytes(int itemId) => _downloadedBytesMap[itemId] ?? 0;

  /// Check if any downloads are active
  bool get hasActiveDownloads => _activeDownloads.isNotEmpty;

  /// Start downloading a DVR video
  Future<void> downloadDvrVideo({
    required DvrItemModel dvrItem,
    VoidCallback? onDownloadStart,
    VoidCallback? onDownloadComplete,
    Function(String)? onDownloadError,
  }) async {
    if (!Platform.isAndroid) {
      _showSnackbar('Downloads are only supported on Android TV');
      return;
    }

    final itemId = dvrItem.id;

    // Check if this item is already being downloaded
    if (_activeDownloads.contains(itemId)) {
      _showSnackbar('This video is already being downloaded');
      return;
    }

    final downloadUrl = dvrItem.downloadurl;
    if (downloadUrl == null || downloadUrl.isEmpty) {
      _showSnackbar('Download URL not available for this video');
      return;
    }

    final selectedLocation = await _showDownloadLocationDialog();

    if (selectedLocation == null) {
      return;
    }

    final title = dvrItem.displayTitle;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${title}_$timestamp.mp4';

    setState(() {
      _activeDownloads.add(itemId);
      _downloadProgresses[itemId] = 0.0;
      _downloadedBytesMap[itemId] = 0;
    });

    onDownloadStart?.call();

    _showSnackbar(
      'Download started for ${dvrItem.displayTitle}',
      duration: const Duration(seconds: 2),
    );

    try {
      final result = await _downloadService.downloadDvrVideoToCustomLocation(
        videoUrl: downloadUrl,
        fileName: fileName,
        selectedPath: selectedLocation,
        onProgress: (received, total) {
          if (mounted) {
            setState(() {
              _downloadedBytesMap[itemId] = received;
              if (total != -1) {
                _downloadProgresses[itemId] = received / total;
              } else {
                _downloadProgresses[itemId] = -1;
              }
            });
          }
        },
      );

      if (result.success) {
        _showSnackbar(
          '${dvrItem.displayTitle} downloaded successfully!',
          duration: const Duration(seconds: 3),
        );
        onDownloadComplete?.call();
      } else {
        _showSnackbar(
          'Download failed: ${result.error ?? "Unknown error"}',
          duration: const Duration(seconds: 3),
        );
        onDownloadError?.call(result.error ?? "Unknown error");
      }
    } catch (e) {
      _showSnackbar(
        'Download failed: $e',
        duration: const Duration(seconds: 3),
      );
      onDownloadError?.call(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _activeDownloads.remove(itemId);
          _downloadProgresses.remove(itemId);
          _downloadedBytesMap.remove(itemId);
        });
      }
    }
  }

  /// Show dialog to select download location
  Future<String?> _showDownloadLocationDialog() async {
    final locations = await _downloadService.getAvailableStorageLocations();

    if (locations.isEmpty) {
      _showSnackbar('No storage locations available');
      return null;
    }

    if (!mounted) return null;

    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        Future.delayed(const Duration(seconds: 9), () {
          if (context.mounted) {
            Navigator.of(context).pop(null);
          }
        });

        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: context.uiColors.primary, width: 2),
          ),
          title: Row(
            children: [
              Icon(Icons.folder_open, color: context.uiColors.primary, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Choose Download Location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      final location = locations[index];
                      final isUsb = location.name.contains('USB') || location.name.contains('External');

                      return Card(
                        color: Colors.grey[850],
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(location.path),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isUsb ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isUsb ? Icons.usb : Icons.tv,
                                    color: isUsb ? Colors.green : Colors.blue,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        location.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        location.path,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white54,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(null),
              icon: const Icon(Icons.close, color: Colors.white70),
              label: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show a snackbar message
  void _showSnackbar(String message, {Duration duration = const Duration(seconds: 2)}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Build a download progress indicator widget for a specific item
  Widget buildDownloadProgressIndicator(BuildContext context, int itemId) {
    if (!_activeDownloads.contains(itemId)) {
      return const SizedBox.shrink();
    }

    final progress = _downloadProgresses[itemId] ?? 0.0;
    final bytes = _downloadedBytesMap[itemId] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.uiColors.primary, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress != -1 ? progress : null,
              valueColor: AlwaysStoppedAnimation<Color>(context.uiColors.primary),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            progress != -1
                ? '${(progress * 100).toStringAsFixed(0)}%'
                : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB',
            style: TextStyles.bodySmall.copyWith(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
