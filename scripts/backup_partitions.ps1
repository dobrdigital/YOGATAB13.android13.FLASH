# READ-ONLY backup over firehose (programmer must already be loaded via Sahara):
#  1) primary GPT of all 6 UFS LUNs -> <OutDir>\gpt\dev_gpt_main<N>.bin (+ device_layout.json via gpt_compare.py)
#  2) device-unique partitions      -> <OutDir>\partitions\*.bin + SHA256SUMS.txt
param(
    [Parameter(Mandatory)] [string]$Port,       # e.g. COM4
    [Parameter(Mandatory)] [string]$OutDir,
    [string]$Qpst = 'C:\Program Files (x86)\Qualcomm\QPST\bin',
    [string[]]$Partitions = @('persist','fpinfo','frp','keystore','misc','ssd','lenovocust','lenovoraw','cdt','ddr','devinfo','secdata','modemst1','modemst2','fsg','fsc')
)
$fh = Join-Path $Qpst 'fh_loader.exe'
$gptDir  = Join-Path $OutDir 'gpt';        New-Item -ItemType Directory -Force $gptDir  | Out-Null
$partDir = Join-Path $OutDir 'partitions'; New-Item -ItemType Directory -Force $partDir | Out-Null

function Invoke-FhRead([string]$Dir, [string]$Xml) {
    Set-Content -Path (Join-Path $Dir 'read.xml') -Value $Xml -Encoding ascii
    Push-Location $Dir
    & $fh --port="\\.\$Port" --sendxml=read.xml --search_path=$Dir --mainoutputdir=$Dir --memoryname=ufs --noprompt --zlpawarehost=1 2>&1 |
        Tee-Object -FilePath (Join-Path $Dir 'fh_read.log') | Select-String 'ERROR|All Finished' | Select-Object -Last 3
    Pop-Location
}

# 1) GPT: 6 sectors (4096 B) from LBA 0 of each LUN
$items = (0..5 | ForEach-Object { "<read SECTOR_SIZE_IN_BYTES=`"4096`" filename=`"dev_gpt_main$_.bin`" physical_partition_number=`"$_`" label=`"PrimaryGPT`" start_sector=`"0`" num_partition_sectors=`"6`"/>" }) -join "`n"
Invoke-FhRead $gptDir "<?xml version=`"1.0`" ?>`n<data>`n$items`n</data>`n"

# 2) parse layout
$py = Join-Path $PSScriptRoot 'gpt_compare.py'
python $py --device $gptDir --dump-layout (Join-Path $gptDir 'device_layout.json') | Out-Null
$layout = Get-Content (Join-Path $gptDir 'device_layout.json') | ConvertFrom-Json

$reads = @()
foreach ($lun in 0..5) {
    foreach ($p in $layout."$lun") {
        if ($Partitions -contains $p[0]) {
            $cnt = [int64]$p[2] - [int64]$p[1] + 1
            $reads += "<read SECTOR_SIZE_IN_BYTES=`"4096`" filename=`"$($p[0]).bin`" physical_partition_number=`"$lun`" label=`"$($p[0])`" start_sector=`"$($p[1])`" num_partition_sectors=`"$cnt`"/>"
        }
    }
}
Invoke-FhRead $partDir ("<?xml version=`"1.0`" ?>`n<data>`n" + ($reads -join "`n") + "`n</data>`n")

Get-ChildItem $partDir -Filter *.bin | ForEach-Object { "{0}  {1}" -f (Get-FileHash $_.FullName).Hash.ToLower(), $_.Name } |
    Set-Content (Join-Path $partDir 'SHA256SUMS.txt')
Get-ChildItem $partDir -Filter *.bin | Select-Object Name, Length | Format-Table -AutoSize
Write-Host "Backups in $OutDir — keep them private (serial number, MACs, calibration)."
