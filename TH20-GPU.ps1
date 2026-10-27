[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [ValidateSet('Apply','Restore','Status')][string]$Action = 'Status',
    [string]$GameExe
)
$ErrorActionPreference = 'Stop'
try {
    if (-not $GameExe) {
        Add-Type -AssemblyName System.Windows.Forms
        $picker = New-Object System.Windows.Forms.OpenFileDialog
        $picker.Title = 'Select TH20 game executable (th20.exe)'
        $picker.Filter = 'TH20 executable (th20.exe)|th20.exe'
        if ($picker.ShowDialog() -ne 'OK') { exit 0 }
        $GameExe = $picker.FileName
        $picker.Dispose()
    }
    $GameExe = [IO.Path]::GetFullPath($GameExe)
    if ([IO.Path]::GetFileName($GameExe) -ine 'th20.exe') { throw 'Select th20.exe, not a launcher or another game.' }
    $key = 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'
    $current = $null
    if (Test-Path -LiteralPath $key) {
        $property = (Get-ItemProperty -LiteralPath $key).PSObject.Properties[$GameExe]
        if ($null -ne $property) {
            if ((Get-Item -LiteralPath $key).GetValueKind($GameExe) -ne 'String') { throw 'Unexpected registry value type; no changes made.' }
            $current = [string]$property.Value
        }
    }
    $sha = [Security.Cryptography.SHA256]::Create()
    $id = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($GameExe.ToLowerInvariant()))).Replace('-','')
    $sha.Dispose()
    $backupDir = Join-Path $PSScriptRoot 'backups'
    $backupPath = Join-Path $backupDir ($id + '.json')
    Write-Host ('Game: ' + $GameExe)
    Write-Host ('Current preference: ' + $(if ($null -eq $current) {'Windows default (no entry)'} else {$current}))
    if ($Action -eq 'Status') { exit 0 }
    if ($Action -eq 'Apply') {
        if (-not (Test-Path -LiteralPath $GameExe -PathType Leaf)) { throw 'Game executable not found.' }
        if ($WhatIfPreference) {
            [void]$PSCmdlet.ShouldProcess($GameExe, 'Back up per-app GPU preference and set GpuPreference=2; hardware checks run on actual apply')
            exit 0
        }
        $gpus = @(Get-CimInstance Win32_VideoController)
        $intel = @($gpus | Where-Object { $_.Name -match 'Intel' -and $_.Status -eq 'OK' })
        $other = @($gpus | Where-Object { $_.Name -match 'NVIDIA|AMD|Radeon' -and $_.Status -eq 'OK' })
        if (-not $intel.Count -or -not $other.Count) { throw 'This workaround requires enabled Intel graphics plus an NVIDIA/AMD adapter. No changes made.' }
        Write-Host ('Adapters: ' + (($gpus | ForEach-Object {$_.Name}) -join ', '))
        # Preserve unrelated fields such as AppStatus in this application's value.
        $applied = 'GpuPreference=2;' + ([regex]::Replace([string]$current, '(?i)GpuPreference=[^;]*;?', ''))
        if (Test-Path -LiteralPath $backupPath) {
            $backup = Get-Content -LiteralPath $backupPath -Raw | ConvertFrom-Json
            if ($backup.GameExe -ine $GameExe) { throw 'Backup path mismatch.' }
            if ($current -ceq $backup.Applied) { Write-Host 'Already applied. Original backup retained.'; exit 0 }
            if ($current -cne $backup.Previous) { throw 'Preference changed since backup. Review the backup before applying again.' }
            $applied = [string]$backup.Applied
        } else {
            if ($current -match '(?i)(^|;)GpuPreference=2(;|$)') { Write-Host 'High-performance GPU preference already set. Nothing changed.'; exit 0 }
            if (-not $PSCmdlet.ShouldProcess($GameExe, 'Back up and set high-performance GPU preference')) { exit 0 }
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            [ordered]@{GameExe=$GameExe;Previous=$current;Applied=$applied;Created=(Get-Date).ToString('o')} |
                ConvertTo-Json | Set-Content -LiteralPath $backupPath -Encoding UTF8
        }
        if (-not $PSCmdlet.ShouldProcess($GameExe, 'Write per-app high-performance GPU preference')) { exit 0 }
        if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key -Force | Out-Null }
        New-ItemProperty -LiteralPath $key -Name $GameExe -PropertyType String -Value $applied -Force | Out-Null
        if ((Get-ItemPropertyValue -LiteralPath $key -Name $GameExe) -cne $applied) { throw 'Preference verification failed.' }
        Write-Host 'Applied. Fully exit and restart TH20. Windows chooses the high-performance GPU.'
        Write-Host ('Backup: ' + $backupPath)
    } else {
        if (-not (Test-Path -LiteralPath $backupPath)) { throw 'No backup from this tool exists for the selected executable.' }
        $backup = Get-Content -LiteralPath $backupPath -Raw | ConvertFrom-Json
        if ($backup.GameExe -ine $GameExe) { throw 'Backup path mismatch.' }
        if ($current -ceq $backup.Previous) { Write-Host 'Original preference already restored.'; exit 0 }
        if ($current -cne $backup.Applied) { throw 'Preference changed after applying. Restore stopped to preserve the newer setting.' }
        if (-not $PSCmdlet.ShouldProcess($GameExe, 'Restore original per-app GPU preference')) { exit 0 }
        if ($null -eq $backup.Previous) {
            Remove-ItemProperty -LiteralPath $key -Name $GameExe
        } else {
            New-ItemProperty -LiteralPath $key -Name $GameExe -PropertyType String -Value ([string]$backup.Previous) -Force | Out-Null
        }
        Write-Host 'Restored. Fully exit and restart TH20. Backup retained.'
    }
} catch {
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
