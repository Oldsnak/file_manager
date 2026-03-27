// lib/features/downloader/pages/downloads_library_page.dart

import 'package:file_manager/core/services/device_video_save_service.dart';
import 'package:file_manager/core/services/download_jobs_registry.dart';
import 'package:file_manager/core/services/downloader_service.dart';
import 'package:file_manager/foundation/constants/api_config.dart';
import 'package:file_manager/foundation/constants/assets.dart';
import 'package:file_manager/foundation/constants/colors.dart';
import 'package:file_manager/foundation/constants/sizes.dart';
import 'package:file_manager/foundation/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';

/// Lists in-progress and completed video downloads (backed by [DownloadJobsRegistry]).
class DownloadsLibraryPage extends StatefulWidget {
  const DownloadsLibraryPage({super.key});

  @override
  State<DownloadsLibraryPage> createState() => _DownloadsLibraryPageState();
}

class _DownloadsLibraryPageState extends State<DownloadsLibraryPage> {
  DownloaderService? _service;
  DownloaderService? _ownedService;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    try {
      _service = Get.find<DownloaderService>();
    } catch (_) {
      _ownedService = DownloaderService(
        baseUrl: ApiConfig.effectiveBaseUrl,
        apiKey: ApiConfig.effectiveApiKey,
      );
      _service = _ownedService;
    }
    DownloadJobsRegistry.instance.load();
  }

  @override
  void dispose() {
    _ownedService?.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final svc = _service;
    if (svc == null) return;
    setState(() => _refreshing = true);
    DownloadJobsRegistry.instance.load();
    try {
      for (final j in List<DownloadJobRecord>.from(DownloadJobsRegistry.instance.jobs)) {
        if (j.phase != DownloadPhase.downloading && j.phase != DownloadPhase.saving) {
          continue;
        }
        if (j.localPath != null && j.localPath!.isNotEmpty) continue;
        try {
          final st = await svc.getStatus(j.jobId);
          if (st.status == 'finished') {
            DownloadJobsRegistry.instance.updateJob(j.jobId, phase: DownloadPhase.saving);
            final r = await DeviceVideoSaveService.saveJobToDevice(jobId: j.jobId, service: svc);
            if (r.path != null) {
              DownloadJobsRegistry.instance.applyCompletion(jobId: j.jobId, localPath: r.path, error: null);
            } else {
              DownloadJobsRegistry.instance.applyCompletion(
                jobId: j.jobId,
                localPath: null,
                error: r.error ?? 'Save failed',
              );
            }
          } else if (st.status == 'failed') {
            DownloadJobsRegistry.instance.applyCompletion(
              jobId: j.jobId,
              localPath: null,
              error: st.error ?? 'Failed',
            );
          } else {
            DownloadJobsRegistry.instance.updateJob(
              j.jobId,
              phase: DownloadPhase.downloading,
              percent: st.percent,
            );
          }
        } catch (_) {}
      }
    } finally {
      DownloadJobsRegistry.instance.load();
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('My downloads'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListenableBuilder(
        listenable: DownloadJobsRegistry.instance,
        builder: (context, _) {
          final jobs = DownloadJobsRegistry.instance.jobs;
          if (jobs.isEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.download_outlined, size: 56, color: TColors.grey),
                  SizedBox(height: 16),
                  Center(child: Text('No downloads yet')),
                  SizedBox(height: 8),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Videos you download appear here. Pull to refresh status.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: TColors.darkGrey),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final active = jobs.where((j) => j.phase == DownloadPhase.downloading || j.phase == DownloadPhase.saving).toList();
          final done = jobs.where((j) => j.phase == DownloadPhase.completed || j.phase == DownloadPhase.failed).toList();

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (_refreshing)
                  const LinearProgressIndicator(minHeight: 2),
                if (active.isNotEmpty) ...[
                  Text(
                    'In progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: dark ? TColors.textWhite : TColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: TSizes.sm),
                  ...active.map((j) => _JobTile(job: j, dark: dark)),
                  const SizedBox(height: TSizes.lg),
                ],
                Text(
                  'Library',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: dark ? TColors.textWhite : TColors.textPrimary,
                      ),
                ),
                const SizedBox(height: TSizes.sm),
                ...done.map((j) => _JobTile(job: j, dark: dark)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _JobTile extends StatelessWidget {
  const _JobTile({required this.job, required this.dark});

  final DownloadJobRecord job;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (job.phase) {
      DownloadPhase.downloading => job.percent != null
          ? '${job.percent!.clamp(0, 100).toStringAsFixed(0)}% · Downloading'
          : 'Downloading…',
      DownloadPhase.saving => 'Saving to storage…',
      DownloadPhase.completed => job.localPath ?? 'Saved',
      DownloadPhase.failed => job.error ?? 'Failed',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.xs),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 56,
            height: 56,
            child: _Thumb(url: job.thumbnailUrl),
          ),
        ),
        title: Text(
          job.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: dark ? TColors.textWhite : TColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: dark ? TColors.darkGrey : TColors.textSecondary, fontSize: 12)),
            if (job.phase == DownloadPhase.downloading && job.percent != null) ...[
              const SizedBox(height: 6),
              LinearProgressIndicator(value: (job.percent!.clamp(0, 100)) / 100.0),
            ],
          ],
        ),
        trailing: job.phase == DownloadPhase.completed && job.localPath != null
            ? IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () => OpenFilex.open(job.localPath!),
              )
            : null,
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final u = url?.trim();
    if (u != null && u.isNotEmpty) {
      return Image.network(
        u,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(thumbnail, fit: BoxFit.cover),
      );
    }
    return Image.asset(thumbnail, fit: BoxFit.cover);
  }
}
