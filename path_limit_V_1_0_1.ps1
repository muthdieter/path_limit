Clear-Host

$ScriptName = "path_limit"
$scriptVersion = "V_1_0_1"
$scriptGitHub = "https://github.com/muthdieter"
$scriptDate = "7.2025"

mode 300

Write-Host ""
Write-Host "             ____  __  __"
Write-Host "            |  _ \|  \/  |"
Write-Host "            | | | | |\/| |"
Write-Host "            | |_| | |  | |"
Write-Host "            |____/|_|  |_|"
Write-Host ""
Write-Host "       $scriptGitHub " -ForegroundColor magenta
Write-Host "       $ScriptName   " -ForegroundColor Green
Write-Host "       $scriptVersion" -ForegroundColor Green
Write-Host "       $scriptDate   " -ForegroundColor Green
Write-Host ""
Pause

# ==== SELECT FOLDER ====
Add-Type -AssemblyName System.Windows.Forms
function Select-FolderDialog($description) {
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = $description
    if ($dialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true })) -eq 'OK') {
        return $dialog.SelectedPath
    } else {
        Write-Host "Cancelled by user." -ForegroundColor Yellow
        exit
    }
}

$BaseFolder = Select-FolderDialog "Select the base folder to check for long file paths:"
Write-Host "`nSelected path: $BaseFolder" -ForegroundColor Cyan

# ==== SCAN FILES AND FOLDERS ====
Write-Host "`nScanning for long paths..." -ForegroundColor Cyan

$PathLimit = 256
$Results = @()

# Files
Get-ChildItem -Path $BaseFolder -Recurse -Force -File -ErrorAction SilentlyContinue | ForEach-Object {
    $fullPath = $_.FullName
    if ($fullPath.Length -ge $PathLimit) {
        $Results += [PSCustomObject]@{
            Type        = "File"
            Path        = $fullPath
            Length      = $fullPath.Length
        }
    }
}

# Directories
Get-ChildItem -Path $BaseFolder -Recurse -Force -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $fullPath = $_.FullName
    if ($fullPath.Length -ge $PathLimit) {
        $Results += [PSCustomObject]@{
            Type        = "Folder"
            Path        = $fullPath
            Length      = $fullPath.Length
        }
    }
}

# ==== OUTPUT RESULTS ====
$OutputFolder = Split-Path -Parent $MyInvocation.MyCommand.Path
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$csvPath = Join-Path $OutputFolder "LongPaths_$timestamp.csv"
$htmlPath = Join-Path $OutputFolder "LongPaths_$timestamp.html"

if ($Results.Count -gt 0) {
    $Results | Sort-Object Length -Descending | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    $Results | Sort-Object Length -Descending | ConvertTo-Html -Property Type, Path, Length -Title "Paths longer than 256 characters" |
        Out-File -FilePath $htmlPath -Encoding UTF8

    Write-Host "`nFound $($Results.Count) long paths." -ForegroundColor Green
    Write-Host "CSV Output:  $csvPath" -ForegroundColor Cyan
    Write-Host "HTML Output: $htmlPath" -ForegroundColor Cyan
} else {
    Write-Host "`nNo paths longer than $PathLimit characters were found." -ForegroundColor Green
}

Pause
