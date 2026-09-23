# Pre-flash checks on an unzipped YT-K606F firmware folder (read-only, no device needed).
param([Parameter(Mandatory)] [string]$FirmwareDir)
$ok = $true
Push-Location $FirmwareDir

Write-Host '== 1. build properties (from super_*.img)'
$props = foreach ($f in Get-ChildItem super_*.img) {
    Select-String -Path $f.FullName -Pattern 'ro\.build\.display\.id=[\w\-\.]+|ro\.build\.version\.release=\d+|ro\.odm\.lenovo\.sku=\w+' -AllMatches -Encoding ascii |
        ForEach-Object { $_.Matches.Value }
}
$props = $props | Sort-Object -Unique; $props
if (-not ($props -match 'YT-K606F')) { Write-Host 'FAIL: not a YT-K606F build'; $ok = $false }

Write-Host '== 2. .x -> .xml (S510488 packaging quirk)'
$x = Get-ChildItem *.x
if ($x) { Write-Host "FAIL: rename these to .xml first: $($x.Name -join ', ')"; $ok = $false } else { 'none' }

Write-Host '== 3. files referenced by rawprogram*.xml exist'
foreach ($rp in Get-ChildItem rawprogram*.xml) {
    foreach ($fn in ([xml](Get-Content $rp)).data.program.filename | Where-Object { $_ } | Sort-Object -Unique) {
        if (-not (Test-Path $fn)) { Write-Host "FAIL: $($rp.Name) references missing $fn"; $ok = $false }
    }
}

Write-Host '== 4. sector size'
Select-String -Path rawprogram*.xml, patch*.xml -Pattern 'SECTOR_SIZE_IN_BYTES="(\d+)"' -AllMatches |
    ForEach-Object { $_.Matches.Groups[1].Value } | Group-Object | ForEach-Object { "$($_.Count) x $($_.Name)"; if ($_.Name -ne '4096') { $ok = $false } }

Write-Host '== 5. labels written vs preserved'
foreach ($rp in Get-ChildItem rawprogram*.xml) {
    $p = ([xml](Get-Content $rp)).data.program
    "{0}: WRITES {1}" -f $rp.Name, (($p | Where-Object { $_.filename } | ForEach-Object label | Sort-Object -Unique) -join ' ')
    $skip = $p | Where-Object { -not $_.filename } | ForEach-Object label | Sort-Object -Unique
    if ($skip) { "{0}: keeps  {1}" -f $rp.Name, ($skip -join ' ') }
}

Write-Host '== 6. userdata end patch'
Select-String -Path patch0.xml -Pattern "userdata" | Select-Object -First 1 | ForEach-Object { ([regex]::Match($_.Line, 'value="[^"]+"')).Value }

Pop-Location
if ($ok) { Write-Host 'RESULT: OK' } else { Write-Host 'RESULT: STOP'; exit 1 }
