# Reboot the tablet into EDL (adb reboot edl), find the 9008 COM port and immediately upload the firehose programmer.
# Nothing is written to flash: the programmer runs from RAM.
param(
    [Parameter(Mandatory)] [string]$Programmer,             # ...\prog_firehose_ddr.elf from the firmware package
    [string]$Adb  = 'adb.exe',
    [string]$Qpst = 'C:\Program Files (x86)\Qualcomm\QPST\bin',
    [string]$LogDir = '.'
)

function Find-EdlPort {
    $out = pnputil /enum-devices /connected /class Ports 2>$null | Out-String
    $m = [regex]::Match($out, 'QDLoader 9008 \((COM\d+)\)')
    if ($m.Success) { $m.Groups[1].Value } else { $null }
}

$port = Find-EdlPort
if (-not $port) {
    Write-Host 'Waiting for adb device...'
    & $Adb wait-for-device
    $deadline = (Get-Date).AddSeconds(180)
    while ((& $Adb shell getprop sys.boot_completed 2>$null) -ne '1' -and (Get-Date) -lt $deadline) { Start-Sleep 2 }
    Write-Host 'adb reboot edl'
    & $Adb reboot edl
    $deadline = (Get-Date).AddSeconds(40)
    while (-not ($port = Find-EdlPort) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 300 }
}
if (-not $port) { Write-Host 'EDL port not found. Fallback: power off, hold Vol+, plug USB.'; exit 2 }

Write-Host "EDL port: $port"
$log = Join-Path $LogDir ('sahara_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.log')
& (Join-Path $Qpst 'QSaharaServer.exe') -p "\\.\$port" -s "13:$Programmer" 2>&1 | Tee-Object -FilePath $log | Select-Object -Last 6
Write-Host "PORT=$port"
