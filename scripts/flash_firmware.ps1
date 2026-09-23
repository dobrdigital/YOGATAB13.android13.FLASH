# Flash an unzipped YT-K606F firmware package over firehose (QFIL "Flat build" + UFS equivalent).
# Firehose must already be loaded (edl_enter_and_sahara.ps1). REQUIRES HUMAN APPROVAL. Wipes userdata.
param(
    [Parameter(Mandatory)] [string]$Port,           # e.g. COM4
    [Parameter(Mandatory)] [string]$FirmwareDir,
    [string]$Qpst = 'C:\Program Files (x86)\Qualcomm\QPST\bin',
    [string]$LogDir = '.'
)
$fh  = Join-Path $Qpst 'fh_loader.exe'
$xml = (@('rawprogram_unsparse0.xml') + (1..5 | ForEach-Object { "rawprogram$_.xml" }) + (0..5 | ForEach-Object { "patch$_.xml" })) -join ','
foreach ($f in $xml -split ',') { if (-not (Test-Path (Join-Path $FirmwareDir $f))) { throw "missing $f" } }
# provision_*.xml is deliberately NOT sent (UFS provisioning).
$log = Join-Path (Resolve-Path $LogDir) ('flash_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.log')
Push-Location $FirmwareDir
& $fh --port="\\.\$Port" --sendxml=$xml --search_path=$FirmwareDir --memoryname=ufs --noprompt --zlpawarehost=1 --setactivepartition=1 --reset 2>&1 |
    Tee-Object -FilePath $log | Select-String 'ERROR|NAK|All Finished|Overall to target  \d{2,}|setbootable' | Select-Object -Last 6
Pop-Location
$err = (Select-String -Path $log -Pattern 'ERROR|NAK').Count
Write-Host "ERROR/NAK lines: $err   log: $log"
if ($err) { exit 1 }
