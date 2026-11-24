/// Last-Write-Wins (LWW) deterministic conflict resolver helper.
/// Returns true if incoming remote record is newer than local record based on updated_at.
bool isRemoteNewer(Map<String, dynamic> local, Map<String, dynamic> remote) {
  final localUpdatedAt = local['updated_at'] as String?;
  final remoteUpdatedAt = remote['updated_at'] as String?;

  if (remoteUpdatedAt == null) return false;
  if (localUpdatedAt == null) return true;

  try {
    final localTime = DateTime.parse(localUpdatedAt);
    final remoteTime = DateTime.parse(remoteUpdatedAt);
    return remoteTime.isAfter(localTime);
  } catch (_) {
    return false;
  }
}
