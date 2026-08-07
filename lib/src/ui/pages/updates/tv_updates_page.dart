import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_localization/app_localization.dart';
import 'package:local_storage/local_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:fndtv/src/core/services/update_installer.dart';
import 'package:fndtv/src/data/models/device/device_update_model.dart';
import 'package:fndtv/src/data/repositories/device/device_repository.dart';
import 'package:fndtv/src/ui/widgets/tv/tv_widgets.dart' show kTvBg, kTvAccent;

enum UpdateScreenStatus { loading, upToDate, available, installFailed, error }

/// Version this box last handed to the system installer.
///
/// Needed because [UpdateInstaller.install] fires an ACTION_VIEW intent and
/// reports whether the *installer launched*, not whether the install landed.
/// Android silently refuses a lower versionCode (the `--split-per-abi` trap in
/// android/app/build.gradle.kts inflates it to 2005, after which every normal
/// build reads as a downgrade), and the viewer sees a success screen while the
/// old build keeps running. Persisting the attempt lets the next launch notice.
const String kStbPendingUpdateVersionKey = 'stb_pending_update_version';

/// Compares dotted version names ("0.0.11"), tolerating a "+build" suffix and
/// differing component counts. Returns <0 / 0 / >0 like [Comparable.compareTo].
///
/// Numeric per component on purpose: string equality would call 0.0.9 and
/// 0.0.10 "different" in the right direction only by luck, and "0.0.9" sorts
/// after "0.0.10" lexicographically.
int compareVersionNames(String a, String b) {
  List<int> parts(String v) => v
      .split('+')
      .first
      .trim()
      .split('.')
      .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();

  final pa = parts(a);
  final pb = parts(b);
  final n = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < n; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

/// Which screen the update page should show.
///
/// [local] is the running version (authoritative — read from the APK).
/// [latest] is what the backend advertises. [attempted] is the version last
/// handed to the system installer, or null/empty if there is no pending attempt.
///
/// Deliberately does not consult the server's `update_required`: that is
/// computed against the server's stored copy of our version, which freezes the
/// moment check-in stops being accepted.
UpdateScreenStatus resolveUpdateStatus({
  required String local,
  required String latest,
  String? attempted,
}) {
  final newerAvailable =
      latest.isNotEmpty && compareVersionNames(local, latest) < 0;

  // Checked first: a refused install leaves a newer version still advertised,
  // so without this it is indistinguishable from an update never started.
  final installDidNotLand = attempted != null &&
      attempted.isNotEmpty &&
      compareVersionNames(local, attempted) < 0;
  if (installDidNotLand && newerAvailable) return UpdateScreenStatus.installFailed;

  return newerAvailable
      ? UpdateScreenStatus.available
      : UpdateScreenStatus.upToDate;
}

/// Full-screen "Software update" page (TV). Checks the box's device id against
/// the backend update endpoint and shows whether a newer build is available.
class TvUpdatesPage extends StatefulWidget {
  const TvUpdatesPage({super.key});

  @override
  State<TvUpdatesPage> createState() => _TvUpdatesPageState();
}

class _TvUpdatesPageState extends State<TvUpdatesPage> {
  UpdateScreenStatus _status = UpdateScreenStatus.loading;
  DeviceUpdateModel? _model;

  /// The version actually running, read from the APK. The server's
  /// `installed_app_version` is only its own record of what a box last managed
  /// to report, so it goes stale the moment check-in stops working — which is
  /// exactly what stranded the fleet on "Mise à jour disponible" while every
  /// box was already on the latest build.
  String _localVersion = '';

  /// Set when the installer told us why it failed this session. Null when the
  /// failure was inferred on a later launch, where no reason is available.
  StbInstallResult? _installFailureReason;

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
          _status = UpdateScreenStatus.error;
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

    // Recorded BEFORE handing off: this process is usually killed mid-install,
    // so anything written afterwards may never run.
    final attempted = _model?.latestVersion ?? '';
    if (attempted.isNotEmpty) {
      await context
          .read<LocalStorage>()
          .store<String>(kStbPendingUpdateVersionKey, attempted);
    }

    final outcome = await _installer.install(path);
    if (!mounted) return;
    setState(() {
      _installing = false;
      // A silent install replaces this process, so reaching here at all usually
      // means something went wrong. Say which, rather than dropping back to a
      // screen that looks like the update was never started.
      if (outcome.didNotInstall) {
        _installFailureReason = outcome.kind;
        _status = UpdateScreenStatus.installFailed;
      }
    });
  }

  Future<void> _check() async {
    setState(() {
      _status = UpdateScreenStatus.loading;
      _downloadProgress = null;
      _downloaded = false;
      _installing = false;
      _apkPath = null;
    });
    final storage = context.read<LocalStorage>();
    final repo = context.read<DeviceRepository>();

    final deviceId = await storage.get<String>(kStbDeviceIdKey);
    if (deviceId == null || deviceId.isEmpty) {
      if (mounted) setState(() => _status = UpdateScreenStatus.error);
      return;
    }

    final deviceToken = await storage.get<String>(kStbDeviceTokenKey);
    final model = await repo.checkUpdate(deviceId, deviceToken: deviceToken);
    final local = (await PackageInfo.fromPlatform()).version;

    // Cleared once read, either way, so this only ever reports on the most
    // recent attempt.
    final attempted = await storage.get<String>(kStbPendingUpdateVersionKey);
    if (attempted != null && attempted.isNotEmpty) {
      await storage.store<String>(kStbPendingUpdateVersionKey, '');
    }

    if (!mounted) return;
    setState(() {
      _model = model;
      _localVersion = local;
      if (model == null) {
        _status = UpdateScreenStatus.error;
        return;
      }

      // Nothing is lost by ignoring the server's `update_required`: forcing an
      // update onto a box already running the latest build is a no-op, and a
      // genuine forced rollout goes out as an MDM UPDATE_APP command, which is
      // a separate path.
      _status = resolveUpdateStatus(
        local: local,
        latest: model.latestVersion,
        attempted: attempted,
      );
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
      case UpdateScreenStatus.loading:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: kTvAccent),
            const SizedBox(height: 22),
            Text(l.updatesChecking,
                style: GoogleFonts.sora(color: Colors.white70, fontSize: 16)),
          ],
        );

      case UpdateScreenStatus.upToDate:
        return _StatusBlock(
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF3BB273),
          title: l.updatesUpToDate,
          subtitle: 'v$_localVersion',
        );

      case UpdateScreenStatus.installFailed:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusBlock(
              icon: Icons.error_outline_rounded,
              iconColor: const Color(0xFFE0A33D),
              title: l.updatesNotInstalled,
              subtitle: 'v$_localVersion  →  v${_model?.latestVersion ?? ''}',
            ),
            const SizedBox(height: 14),
            Text(
              switch (_installFailureReason) {
                StbInstallResult.blockedDowngrade => l.updatesBlockedDowngrade,
                StbInstallResult.blockedSignature => l.updatesBlockedSignature,
                StbInstallResult.aborted => l.updatesInstallCancelled,
                _ => l.updatesNotInstalledHint,
              },
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 22),
            _UpdateButton(
              label: l.updatesDownload,
              icon: Icons.refresh_rounded,
              autofocus: true,
              onTap: () {
                setState(() => _status = UpdateScreenStatus.available);
                _startDownload();
              },
            ),
          ],
        );

      case UpdateScreenStatus.available:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusBlock(
              icon: _downloaded
                  ? Icons.check_circle_rounded
                  : Icons.system_update_rounded,
              iconColor: _downloaded ? const Color(0xFF3BB273) : kTvAccent,
              title: _downloaded ? l.updatesDownloaded : l.updatesAvailable,
              // Left side is the running version, not the server's record of it.
              subtitle: 'v$_localVersion  →  v${_model?.latestVersion ?? ''}',
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

      case UpdateScreenStatus.error:
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
