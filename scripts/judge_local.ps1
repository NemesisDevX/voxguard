# PauseSignal — one-command local/judging run (PowerShell).
#
# Assembles --dart-define args from environment variables WITHOUT
# echoing their values, then runs the app. Any variable left unset
# simply isn't passed — the app resolves its truthful fallback.
#
# Usage:
#   $env:REVENUECAT_TEST_STORE_KEY = "..."
#   $env:VOXGUARD_RELAY_TOKEN = "..."
#   $env:VOXGUARD_ALERT_RELAY_URL = "https://<worker>.workers.dev/alert"
#   $env:VOXGUARD_RECORDING_TRANSCRIPTION_URL = "https://<worker>.workers.dev"
#   $env:ASSEMBLYAI_TOKEN_BROKER_URL = "https://<worker>.workers.dev/aai-token"
#   $env:VOXGUARD_SEMANTIC_PROXY_URL = "https://<worker>.workers.dev"
#   $env:ONESIGNAL_APP_ID = "..."
#
#   .\scripts\judge_local.ps1 run -d emulator-5554   # run on a device
#   .\scripts\judge_local.ps1 apk                     # build judging APK
#   .\scripts\judge_local.ps1 relay                   # wrangler dev relay
param(
  [Parameter(Position = 0)][string]$Mode = "run",
  [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest
)
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

$defines = @()
foreach ($name in @(
  "REVENUECAT_TEST_STORE_KEY",
  "REVENUECAT_ANDROID_KEY",
  "VOXGUARD_RELAY_TOKEN",
  "VOXGUARD_ALERT_RELAY_URL",
  "VOXGUARD_RECORDING_TRANSCRIPTION_URL",
  "ASSEMBLYAI_TOKEN_BROKER_URL",
  "VOXGUARD_SEMANTIC_PROXY_URL",
  "ONESIGNAL_APP_ID"
)) {
  $value = [Environment]::GetEnvironmentVariable($name)
  if (-not [string]::IsNullOrEmpty($value)) {
    $defines += "--dart-define=$name=$value"
  }
}

switch ($Mode) {
  "relay" {
    Write-Host "Starting local relay (wrangler dev) — secrets come from server/.dev.vars"
    Push-Location server
    try { npx wrangler dev } finally { Pop-Location }
  }
  "run" {
    Write-Host "Launching PauseSignal ($($defines.Count) integration define(s) set)"
    & flutter run --debug @defines @Rest
  }
  "apk" {
    Write-Host "Building judging APK ($($defines.Count) integration define(s) set)"
    & flutter build apk --debug @defines
    Write-Host "APK: build/app/outputs/flutter-apk/app-debug.apk"
  }
  default {
    Write-Error "usage: judge_local.ps1 [run <flutter-run-args> | apk | relay]"
    exit 2
  }
}
