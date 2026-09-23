# Install the WHQL Qualcomm HS-USB QDLoader 9008 driver (v2.1.1.0) from the Microsoft Update Catalog
# and remove old Qualcomm 2014 driver packages that Windows 11 Code Integrity refuses to load (event 3004).
# Self-elevates (UAC).
param([string]$WorkDir = "$env:TEMP\qdloader_whql")

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $exe = (Get-Process -Id $PID).Path
    Start-Process $exe -Verb RunAs -Wait -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"",'-WorkDir',"`"$WorkDir`""
    exit
}

$url  = 'https://catalog.s.download.windowsupdate.com/c/msdownload/update/driver/drvs/2016/04/20855130_dae427ffe0a2d6268aa209d782d05ea874aad0dc.cab'
$sha256 = '47B5301DCE3E1639C10B8071B381227CE5237FA87973FF0282893D4E03E52FE5'
New-Item -ItemType Directory -Force $WorkDir | Out-Null
$cab = Join-Path $WorkDir 'qdloader9008_whql_2.1.1.0.cab'
if (-not (Test-Path $cab)) { curl.exe -L -o $cab $url }
if ((Get-FileHash $cab -Algorithm SHA256).Hash -ne $sha256) { throw "SHA-256 mismatch for $cab" }
& "$env:windir\System32\expand.exe" $cab -F:* $WorkDir | Out-Null

$sig = Get-AuthenticodeSignature (Join-Path $WorkDir 'qcser.cat')
if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notmatch 'Microsoft Windows Hardware Compatibility Publisher') {
    throw "qcser.cat signature not valid WHQL: $($sig.Status) $($sig.SignerCertificate.Subject)"
}

# Remove old (non-WHQL) Qualcomm packages: qcser / qcfilter / qcmdm / qcwwan from the 2014 installer.
$blocks = (pnputil /enum-drivers | Out-String) -split "(\r?\n){2,}"
foreach ($b in $blocks) {
    if ($b -match 'Provider Name:\s+Qualcomm' -and $b -match 'Original Name:\s+(qcser|qcfilter|qcmdm|qcwwan)\.inf' -and $b -notmatch '2\.1\.1\.0') {
        $oem = [regex]::Match($b, 'Published Name:\s+(oem\d+\.inf)').Groups[1].Value
        if ($oem) { Write-Host "Removing old Qualcomm package $oem"; pnputil /delete-driver $oem /uninstall /force }
    }
}

pnputil /add-driver (Join-Path $WorkDir 'qcser.inf') /install
Write-Host 'Done. Plug the tablet in EDL mode: Device Manager should show "Qualcomm HS-USB QDLoader 9008 (COMx)" with status Started.'
