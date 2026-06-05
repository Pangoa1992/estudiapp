# Uso: .\deploy.ps1 -Version 1.7.4
# Opcional: .\deploy.ps1 -Version 1.7.4 -Track internal
param(
  [Parameter(Mandatory=$true)][string]$Version,
  [string]$Track = 'production'
)

Set-Location $PSScriptRoot

# --- 1. Calcular nuevo versionCode desde pubspec.yaml ---
$pubspec = Get-Content pubspec.yaml -Raw
if ($pubspec -notmatch 'version:\s+[\d.]+\+(\d+)') {
  Write-Error "No se pudo leer el versionCode de pubspec.yaml"; exit 1
}
$currentCode = [int]$Matches[1]
$newCode = $currentCode + 1

# --- 2. Actualizar pubspec.yaml ---
$newVersion = "${Version}+${newCode}"
$pubspec = $pubspec -replace 'version:\s+[\d.]+\+\d+', "version: $newVersion"
Set-Content pubspec.yaml $pubspec -Encoding utf8
Write-Host "Version: $newVersion"

# --- 3. Build App Bundle ---
Write-Host "`nBuilding AAB..."
flutter build appbundle --release
if ($LASTEXITCODE -ne 0) { Write-Error "flutter build falló"; exit 1 }

# --- 4. Subir a Play Store ---
Write-Host "`nSubiendo a Play Store (track: $Track)..."
node deploy/upload.js $Track
if ($LASTEXITCODE -ne 0) { Write-Error "Upload falló"; exit 1 }

Write-Host "`n✓ EstudiApp $newVersion publicada en Play Store"
