import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_localization/app_localization.dart';
import 'package:local_storage/local_storage.dart';
import 'package:fndtv/src/core/services/update_installer.dart';
import 'package:fndtv/src/data/models/device/device_update_model.dart';
import 'package:fndtv/src/data/repositories/device/device_repository.dart';
import 'package:fndtv/src/ui/widgets/tv/tv_widgets.dart' show kTvBg, kTvAccent;

enum _UpdateStatus { loading, upToDate, available, error }

/// Full-screen "Software update" page (TV). Checks the box's device id against
/// the backend update endpoint and shows whether a newer build is available.
class TvUpdatesPage extends StatefulWidget {
  const TvUpdatesPage({super.key});

  @override
  State<TvUpdatesPage> createState() => _TvUpdatesPageState();
}

class _TvUpdatesPageState extends State<TvUpdatesPage> {
  _UpdateStatus _status = _UpdateStatus.loading;
  DeviceUpdateModel? _model;

  final UpdateInstaller _installer = UpdateInstaller();

  // Download / install state.
  double? _downloadProgress; // null = not started, 1.0 = done
  bool _downloaded = false;
  bool _installing = false;
  String? _apkPath;

  @override
  void initState() {
    super.initState();
    _check();
  }

  /// Downloads the update APK (real progress), verifies its SHA-256, then marks
  /// it ready to install.
  Future<void> _startDownload() async {
    final url = _model?.apkDownloadUrl;
    if (url == null || url.isEmpty) return;

    setState(() {
      _downloadProgress = 0;
      _downloaded = false;
    });

    final deviceToken =
        await context.read<LocalStorage>().get<String>(kStbDeviceTokenKey);
    try {
      final path = await _installer.download(url, deviceToken: deviceToken,
          onProgress: (p) {
        if (mounted) setState(() => _downloadProgress = p);
      });
      final ok = await _installer.verify(path, _model?.apkSha256);
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _downloadProgress = null;
          _status = _UpdateStatus.error;
        });
        return;
      }
      setState(() {
        _apkPath = path;
        _downloaded = true;
        _downloadProgress = 1.0;
      });
    } catch (e) {
      // Download failed — return to the Download button so it can be retried.
      if (mounted) setState(() => _downloadProgress = null);
    }
  }

  /// Hands the downloaded APK to the system installer.
  Future<void> _startInstall() async {
    final path = _apkPath;
    if (path == null) return;
    setState(() => _installing = true);
    await _installer.install(path);
    // On success the system installer UI takes over; either way, drop the
    // spinner so the button is usable if the user cancels and returns.
    if (mounted) setState(() => _installing = false);
  }

  Future<void> _check() async {
    setState(() {
      _status = _UpdateStatus.loading;
      _downloadProgress = null;
      _downloaded = false;
      _installing = false;
      _apkPath = null;
    });
    final storage = context.read<LocalStorage>();
    final repo = context.read<DeviceRepository>();

    final deviceId = await storage.get<String>(kStbDeviceIdKey);
    if (deviceId == null || deviceId.isEmpty) {
      if (mounted) setState(() => _status = _UpdateStatus.error);
      return;
    }

    final deviceToken = await storage.get<String>(kStbDeviceTokenKey);
    final model = await repo.checkUpdate(deviceId, deviceToken: deviceToken);
    if (!mounted) return;
    setState(() {
      _model = model;
      if (model == null) {
        _status = _UpdateStatus.error;
      } else {
        _status = model.updateRequired
            ? _UpdateStatus.available
            : _UpdateStatus.upToDate;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kTvBg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l = context.l;

    switch (_status) {
      case _UpdateStatus.loading:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: kTvAccent),
            const SizedBox(height: 22),
            Text(l.updatesChecking,
                style: GoogleFonts.sora(color: Colors.white70, fontSize: 16)),
          ],
        );

      case _UpdateStatus.upToDate:
        return _StatusBlock(
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF3BB273),
          title: l.updatesUpToDate,
          subtitle: 'v${_model?.latestVersion ?? ''}',
        );

      case _UpdateStatus.available:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusBlock(
              icon: _downloaded
                  ? Icons.check_circle_rounded
                  : Icons.system_update_rounded,
              iconColor: _downloaded ? const Color(0xFF3BB273) : kTvAccent,
              title: _downloaded ? l.updatesDownloaded : l.updatesAvailable,
              subtitle:
                  'v${_model?.installedVersion ?? ''}  →  v${_model?.latestVersion ?? ''}',
            ),
            const SizedBox(height: 26),
            if (_downloadProgress == null)
              _UpdateButton(
                label: l.updatesDownload,
                icon: Icons.download_rounded,
                autofocus: true,
                onTap: _startDownload,
              )
            else if (!_downloaded)
              _DownloadProgress(
                progress: _downloadProgress!,
                label: l.updatesDownloading,
              )
            else if (_installing)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: kTvAccent),
                  const SizedBox(height: 16),
                  Text(l.updatesInstalling,
                      style: GoogleFonts.sora(
                          color: Colors.white70, fontSize: 16)),
                ],
              )
            else
              _UpdateButton(
                label: l.updatesInstall,
                icon: Icons.install_mobile_rounded,
                autofocus: true,
                onTap: _startInstall,
              ),
          ],
        );

      case _UpdateStatus.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusBlock(
              icon: Icons.error_outline_rounded,
              iconColor: Colors.white38,
              title: l.updatesUnavailable,
            ),
            const SizedBox(height: 26),
            _UpdateButton(
              label: l.updatesRetry,
              icon: Icons.refresh_rounded,
              autofocus: true,
              onTap: _check,
            ),
          ],
        );
    }
  }
}

class _DownloadProgress extends StatelessWidget {
  final double progress;
  final String label;

  const _DownloadProgress({required this.progress, required this.label});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return SizedBox(
      width: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style:
                      GoogleFonts.sora(color: Colors.white70, fontSize: 14)),
              Text('$pct%',
                  style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(kTvAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBlock extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;

  const _StatusBlock({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 64),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.sora(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            style: GoogleFonts.sora(color: Colors.white54, fontSize: 16),
          ),
        ],
      ],
    );
  }
}

class _UpdateButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool autofocus;
  final VoidCallback onTap;

  const _UpdateButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.autofocus = false,
  });

  @override
  State<_UpdateButton> createState() => _UpdateButtonState();
}

class _UpdateButtonState extends State<_UpdateButton> {
  final FocusNode _node = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(() {
      if (mounted) setState(() => _focused = _node.hasFocus);
    });
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        focusNode: _node,
        autofocus: widget.autofocus,
        borderRadius: BorderRadius.circular(14),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
          decoration: BoxDecoration(
            color: _focused ? kTvAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kTvAccent, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon,
                  color: _focused ? Colors.white : kTvAccent, size: 20),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: GoogleFonts.sora(
                  color: _focused ? Colors.white : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
