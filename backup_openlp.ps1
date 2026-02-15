# ============================================================
# OpenLP Monthly Backup Script
# Backs up OpenLP data from user 'niedziela' to C:\backup
# Creates a timestamped ZIP archive
# ============================================================

param(
    [string]$SourcePath = 'C:\Users\niedziela\AppData\Roaming\openlp',
    [string]$BackupRoot = 'C:\backup'
)

$ErrorActionPreference = 'Stop'

# Generate timestamp
$timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$backupName = "OpenLP_backup_$timestamp"
$backupDir = Join-Path $BackupRoot $backupName
$zipPath = "$backupDir.zip"

# Validate source exists
if (-not (Test-Path $SourcePath)) {
    Write-Error "Source path not found: $SourcePath"
    exit 1
}

# Ensure backup root exists
if (-not (Test-Path $BackupRoot)) {
    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
}

# Create temporary staging directory
Write-Host "[$timestamp] Starting OpenLP backup..."
Write-Host "Source: $SourcePath"
Write-Host "Destination: $zipPath"

New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

# Copy all OpenLP data to staging directory
Write-Host "Copying files..."
Copy-Item -Path "$SourcePath\*" -Destination $backupDir -Recurse -Force

# Count copied files
$copiedFiles = Get-ChildItem $backupDir -Recurse -File
$totalSize = ($copiedFiles | Measure-Object -Property Length -Sum).Sum
$totalSizeMB = [math]::Round($totalSize / 1MB, 2)
Write-Host "Copied $($copiedFiles.Count) files ($totalSizeMB MB)"

# Compress to ZIP
Write-Host "Compressing to ZIP..."
Compress-Archive -Path "$backupDir\*" -DestinationPath $zipPath -CompressionLevel Optimal -Force

$zipSize = (Get-Item $zipPath).Length
$zipSizeMB = [math]::Round($zipSize / 1MB, 2)
Write-Host "ZIP created: $zipPath ($zipSizeMB MB)"

# Remove staging directory (keep only the ZIP)
Remove-Item -Path $backupDir -Recurse -Force
Write-Host "Staging directory cleaned up."

# Cleanup old backups (keep last 6 months)
$cutoffDate = (Get-Date).AddMonths(-6)
$oldBackups = Get-ChildItem $BackupRoot -Filter 'OpenLP_backup_*.zip' |
    Where-Object { $_.LastWriteTime -lt $cutoffDate }

if ($oldBackups) {
    Write-Host "Removing $($oldBackups.Count) backup(s) older than 6 months..."
    $oldBackups | Remove-Item -Force
}

Write-Host "[$((Get-Date).ToString('yyyy-MM-dd_HH-mm-ss'))] Backup complete!"
