class SyncResult {
  const SyncResult({
    required this.syncedCount,
    required this.failedCount,
  });

  final int syncedCount;
  final int failedCount;
}
