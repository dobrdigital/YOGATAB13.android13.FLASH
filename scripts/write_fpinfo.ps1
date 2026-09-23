# WRITE the fpinfo partition (only needed when region byte 0xE9 is 02 and you want ROW). Requires human approval.
# Writes the image, reads it back and compares SHA-256. Firehose must already be loaded.
param(
    [Parameter(Mandatory)] [string]$Port,
    [Parameter(Mandatory)] [string]$Image,        # patched copy from: fpinfo_inspect.py fpinfo.bin --set-region 01 --out <Image>
    [Parameter(Mandatory)] [string]$Layout,       # device_layout.json from backup_partitions.ps1
    [string]$Qpst = 'C:\Program Files (x86)\Qualcomm\QPST\bin'
)
$fh = Join-Path $Qpst 'fh_loader.exe'
$entry = (Get-Content $Layout | ConvertFrom-Json)."0" | Where-Object { $_[0] -eq 'fpinfo' }
if (-not $entry) { throw 'fpinfo not found in LUN0 layout' }
$start = [int64]$entry[1]; $count = [int64]$entry[2] - $start + 1
if ((Get-Item $Image).Length -ne $count * 4096) { throw "image size does not match partition size ($($count*4096))" }

$dir = Split-Path -Parent (Resolve-Path $Image); $name = Split-Path -Leaf $Image
$common = @("--port=\\.\$Port", "--search_path=$dir", "--mainoutputdir=$dir", '--memoryname=ufs', '--noprompt', '--zlpawarehost=1')
Push-Location $dir
Set-Content prog_fpinfo.xml "<?xml version=`"1.0`" ?>`n<data>`n<program SECTOR_SIZE_IN_BYTES=`"4096`" filename=`"$name`" physical_partition_number=`"0`" label=`"fpinfo`" start_sector=`"$start`" num_partition_sectors=`"$count`"/>`n</data>`n" -Encoding ascii
& $fh @common --sendxml=prog_fpinfo.xml 2>&1 | Select-String 'ERROR|All Finished' | Select-Object -Last 3
Set-Content read_fpinfo.xml "<?xml version=`"1.0`" ?>`n<data>`n<read SECTOR_SIZE_IN_BYTES=`"4096`" filename=`"fpinfo_readback.bin`" physical_partition_number=`"0`" label=`"fpinfo`" start_sector=`"$start`" num_partition_sectors=`"$count`"/>`n</data>`n" -Encoding ascii
& $fh @common --sendxml=read_fpinfo.xml 2>&1 | Select-String 'ERROR|All Finished' | Select-Object -Last 3
Pop-Location
$a = (Get-FileHash $Image).Hash; $b = (Get-FileHash (Join-Path $dir 'fpinfo_readback.bin')).Hash
if ($a -eq $b) { Write-Host "fpinfo verified: $a" } else { throw "READBACK MISMATCH: wrote $a, read $b" }
