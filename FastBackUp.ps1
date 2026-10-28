# FastBackUp
# Created by Bratislav Cvetkovic
# Copyright (c) 2026 Bratislav Cvetkovic
# Licensed under the MIT License.
# See the LICENSE file for details.

param(
    [ValidateSet("Backup", "Restore")]
    [string]$Mode = "Backup"
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic

$ErrorActionPreference = "Stop"

$PartSize = [int64](3.5 * 1024 * 1024 * 1024)
$LogFile = Join-Path $env:TEMP "FastBackUp.log"

function Write-Log {
    param([string]$Message)

    $line = "{0}  {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8
}

function Show-Info {
    param([string]$Message, [string]$Title = "FastBackUp")

    [System.Windows.Forms.MessageBox]::Show(
        $Message,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
}

function Show-Error {
    param([string]$Message)

    Write-Log "ERROR: $Message"

    [System.Windows.Forms.MessageBox]::Show(
        $Message,
        "FastBackUp - Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
}

function Select-Folder {
    param(
        [string]$Description,
        [string]$InitialPath = ""
    )

    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = $Description
    $dialog.ShowNewFolderButton = $true

    if ($InitialPath -and (Test-Path -LiteralPath $InitialPath)) {
        $dialog.SelectedPath = $InitialPath
    }

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.SelectedPath
    }

    return $null
}


function Get-TempFolder {

    Add-Type -AssemblyName Microsoft.VisualBasic -ErrorAction SilentlyContinue

    # 1. Enter the temporary folder name
    $folderName = [Microsoft.VisualBasic.Interaction]::InputBox(
        "Enter the name of the temporary folder for ZIP files:",
        "FastBackUp - Temporary Folder Name",
        "FastBackUpTemp"
    )

    if ([string]::IsNullOrWhiteSpace($folderName)) {
        Write-Log "Temporary folder selection was cancelled."
        return $null
    }

    # Validate the folder name
    if ($folderName.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0) {
        Show-Error "The folder name contains invalid characters."
        return $null
    }

    # 2. Choose the location in the Windows dialog
    $parentFolder = Select-Folder `
        "Choose the location where the temporary folder will be stored: $folderName"

    if (-not $parentFolder) {
        return $null
    }

    # If an existing folder with this name was selected,
    # use it instead of creating a duplicate nested folder.
    $selectedLeaf = Split-Path -Path $parentFolder -Leaf

    if ($selectedLeaf -ieq $folderName) {
        $tempPath = $parentFolder
    }
    else {
        $tempPath = Join-Path $parentFolder $folderName
    }

    # 3. Create the folder if it does not exist
    if (-not (Test-Path -LiteralPath $tempPath)) {
        New-Item -ItemType Directory -Path $tempPath -Force | Out-Null
        Write-Log "Created temporary folder: $tempPath"
    }
    else {
        Write-Log "Using existing temporary folder: $tempPath"
    }

    return $tempPath
}


function Get-ArchiveName {
    param([string]$SuggestedName)

    $name = [Microsoft.VisualBasic.Interaction]::InputBox(
        "Enter a backup name. You can edit the suggested name.",
        "FastBackUp - Backup Name",
        $SuggestedName
    )

    if ([string]::IsNullOrWhiteSpace($name)) {
        return $null
    }

    $name = $name.Trim()

    foreach ($ch in [System.IO.Path]::GetInvalidFileNameChars()) {
        $name = $name.Replace([string]$ch, "_")
    }

    $name = $name.Trim().TrimEnd(".")

    if ([string]::IsNullOrWhiteSpace($name)) {
        throw "The backup name is invalid."
    }

    return $name
}

function Invoke-Tar {
    param([string[]]$Arguments)

    $tar = Join-Path $env:WINDIR "System32\tar.exe"

    if (-not (Test-Path -LiteralPath $tar)) {
        throw "Windows tar.exe was not found."
    }

    & $tar @Arguments
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        throw "tar.exe reported an error. Exit code: $exitCode"
    }
}

function Get-ElapsedText {
    param([datetime]$Start, [datetime]$End)

    $duration = $End - $Start

    return "{0} h {1} min {2} sec" -f `
        [int][Math]::Floor($duration.TotalHours), `
        $duration.Minutes, `
        $duration.Seconds
}

function Test-ZipArchive {
    param([string]$ZipPath)

    $tar = Join-Path $env:WINDIR "System32\tar.exe"
    $null = & $tar -tf $ZipPath 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "ZIP archive validation failed. The archive may be damaged."
    }
}

function Split-Archive {
    param(
        [string]$ZipPath,
        [string]$OutputFolder,
        [string]$BaseName
    )

    $bufferSize = 1MB
    $buffer = New-Object byte[] $bufferSize
    $partNumber = 1
    $totalBytes = (Get-Item -LiteralPath $ZipPath).Length
    $copiedTotal = [int64]0

    $inputStream = [System.IO.File]::OpenRead($ZipPath)

    try {
        while ($copiedTotal -lt $totalBytes) {
            $partName = "{0}.zip.{1:D3}" -f $BaseName, $partNumber
            $partPath = Join-Path $OutputFolder $partName
            $outputStream = [System.IO.File]::Create($partPath)
            $partBytes = [int64]0

            try {
                while ($partBytes -lt $PartSize) {
                    $remaining = $PartSize - $partBytes
                    $readCount = [int][Math]::Min([int64]$buffer.Length, [int64]$remaining)
                    $read = $inputStream.Read($buffer, 0, $readCount)

                    if ($read -le 0) {
                        break
                    }

                    $outputStream.Write($buffer, 0, $read)
                    $partBytes += $read
                    $copiedTotal += $read
                }
            }
            finally {
                $outputStream.Dispose()
            }

            Write-Log "Created part: $partName, size: $partBytes bytes"
            $partNumber++
        }
    }
    finally {
        $inputStream.Dispose()
    }

    if ($copiedTotal -ne $totalBytes) {
        throw "Archive splitting did not complete."
    }
}

function Join-ArchiveParts {
    param(
        [string]$BackupFolder,
        [string]$ZipPath
    )

    $firstPart = Get-ChildItem -LiteralPath $BackupFolder -File |
        Where-Object { $_.Name -match '\.zip\.001$' } |
        Select-Object -First 1

    if (-not $firstPart) {
        throw "No archive part ending in .zip.001 was found."
    }

    $baseName = $firstPart.Name -replace '\.zip\.001$', ''
    $parts = @()
    $number = 1

    while ($true) {
        $partName = "{0}.zip.{1:D3}" -f $baseName, $number
        $partPath = Join-Path $BackupFolder $partName

        if (-not (Test-Path -LiteralPath $partPath -PathType Leaf)) {
            break
        }

        $parts += Get-Item -LiteralPath $partPath
        $number++
    }

    if ($parts.Count -eq 0) {
        throw "No backup parts were found."
    }

    $stream = [System.IO.File]::Create($ZipPath)

    try {
        foreach ($part in $parts) {
            Write-Log "Joining part: $($part.Name)"
            $inputStream = [System.IO.File]::OpenRead($part.FullName)

            try {
                $inputStream.CopyTo($stream)
            }
            finally {
                $inputStream.Dispose()
            }
        }
    }
    finally {
        $stream.Dispose()
    }

    return $baseName
}

try {
    Write-Log "----------------------------------------------"
    Write-Log "Operation started: $Mode"

    if ($Mode -eq "Backup") {

    

Clear-Host
Write-Host ""
Write-Host "                        FastBackUp"
Write-Host "                       SOURCE SELECTION"
Write-Host "Do you want to back up a folder or an individual file?"
Write-Host "================================================================"
Write-Host ""
Write-Host "  1 - Select an individual file"
Write-Host "  2 - Select a folder"
Write-Host "  3 - Cancel"
Write-Host ""
$izbor = Read-Host "Select an option (1-3)"

if ($izbor -eq "1") {
    $pick = [System.Windows.Forms.DialogResult]::Yes
}
elseif ($izbor -eq "2") {
    $pick = [System.Windows.Forms.DialogResult]::No
}
else {
    $pick = [System.Windows.Forms.DialogResult]::Cancel
}


        if ($pick -eq [System.Windows.Forms.DialogResult]::Cancel) {
            exit
        }

        if ($pick -eq [System.Windows.Forms.DialogResult]::Yes) {
            $dialog = New-Object System.Windows.Forms.OpenFileDialog
            $dialog.Title = "Select a file to back up"
            $dialog.CheckFileExists = $true
            $dialog.Multiselect = $false

            if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
                exit
            }

            $sourcePath = $dialog.FileName
        }
        else {
            $sourcePath = Select-Folder "Select a folder to back up"

            if (-not $sourcePath) {
                exit
            }
        }

        $sourceItem = Get-Item -LiteralPath $sourcePath
        $sourceParent = Split-Path -Parent $sourceItem.FullName
        $sourceName = $sourceItem.Name

        if ([string]::IsNullOrWhiteSpace($sourceParent) -or
            [string]::IsNullOrWhiteSpace($sourceName)) {
            throw "Select a specific file or folder, not the root of a drive."
        }

        $destination = Select-Folder "Select the destination folder for the backup"

        if (-not $destination) {
            exit
        }

        $tempFolder = Get-TempFolder

        if (-not $tempFolder) {
            exit
        }

        $stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $baseName = Get-ArchiveName ("{0}+{1}" -f $sourceName, $stamp)

        if (-not $baseName) {
            exit
        }

        $outputFolder = Join-Path $destination $baseName

        if (Test-Path -LiteralPath $outputFolder) {
            throw "The backup folder already exists: $outputFolder"
        }

        New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null

        $zipPath = Join-Path $tempFolder ($baseName + "_temp.zip")
        $infoPath = Join-Path $outputFolder "FastBackUp_info.txt"
        $successPath = Join-Path $outputFolder "SUCCESS.txt"

        Set-Content -LiteralPath $infoPath -Encoding UTF8 -Value @(
            "FastBackUp - Backup Information"
            "Name: $baseName"
            "Source: $sourcePath"
            "Destination: $outputFolder"
            "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        )

        if (Test-Path -LiteralPath $zipPath) {
            Remove-Item -LiteralPath $zipPath -Force
        }

        $start = Get-Date
        Write-Log "Backup creation started: $sourcePath"
        Write-Host "Creating ZIP archive. Please wait..." -ForegroundColor Cyan

        Invoke-Tar @("-a", "-c", "-f", $zipPath, "-C", $sourceParent, "--", $sourceName)

        Write-Host "Validating archive..." -ForegroundColor Cyan
        Test-ZipArchive $zipPath

        Write-Host "Splitting archive into parts..." -ForegroundColor Cyan
        Split-Archive -ZipPath $zipPath -OutputFolder $outputFolder -BaseName $baseName

        $end = Get-Date
        $elapsed = Get-ElapsedText $start $end

        Add-Content -LiteralPath $infoPath -Encoding UTF8 -Value @(
            "Finished: $($end.ToString('yyyy-MM-dd HH:mm:ss'))"
            "Duration: $elapsed"
            "Number of parts: $((Get-ChildItem -LiteralPath $outputFolder -Filter '*.zip.*' -File).Count)"
        )

        Set-Content -LiteralPath $successPath -Encoding UTF8 -Value @(
            "Backup created successfully."
            "Name: $baseName"
            "Duration: $elapsed"
            "Completion time: $($end.ToString('yyyy-MM-dd HH:mm:ss'))"
        )

        Remove-Item -LiteralPath $zipPath -Force

        Write-Log "Backup completed successfully: $outputFolder"
        Show-Info "Backup completed successfully!`r`n`r`nFolder:`r`n$outputFolder`r`n`r`nDuration: $elapsed"
    }

    elseif ($Mode -eq "Restore") {

        $backupFolder = Select-Folder "Select the folder containing the backup parts"

        if (-not $backupFolder) {
            exit
        }

        $tempFolder = Get-TempFolder

        if (-not $tempFolder) {
            exit
        }

        $firstPart = Get-ChildItem -LiteralPath $backupFolder -File |
            Where-Object { $_.Name -match '\.zip\.001$' } |
            Select-Object -First 1

        if (-not $firstPart) {
            throw "The selected folder does not contain an archive part ending in .zip.001."
        }

        $baseName = $firstPart.Name -replace '\.zip\.001$', ''
        $zipPath = Join-Path $tempFolder ($baseName + ".zip")

        $mergeStart = Get-Date
        Write-Log "Started joining archive parts from: $backupFolder"
        Write-Host "Joining backup parts..." -ForegroundColor Cyan

        if (Test-Path -LiteralPath $zipPath) {
            Remove-Item -LiteralPath $zipPath -Force
        }

        Join-ArchiveParts -BackupFolder $backupFolder -ZipPath $zipPath | Out-Null

        Write-Host "Validating the joined archive..." -ForegroundColor Cyan
        Test-ZipArchive $zipPath

        $mergeEnd = Get-Date
        $mergeElapsed = Get-ElapsedText $mergeStart $mergeEnd
        Write-Log "Joining completed. Duration: $mergeElapsed"

        $answer = [System.Windows.Forms.MessageBox]::Show(
            "The archive has been joined and validated.`r`n`r`nJoin started: $($mergeStart.ToString('HH:mm:ss'))`r`nJoin finished: $($mergeEnd.ToString('HH:mm:ss'))`r`nDuration: $mergeElapsed`r`n`r`nDo you want to extract all files now?`r`n`r`nYes = Extract now`r`nNo = Keep the ZIP for manual extraction.",
            "FastBackUp - Join Completed",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )

        if ($answer -eq [System.Windows.Forms.DialogResult]::No) {
            Show-Info "The ZIP archive has been saved to:`r`n$zipPath`r`n`r`nYou can extract it manually later."
            exit
        }

        $restoreDestination = Select-Folder "Select the destination folder for restoring data"

        if (-not $restoreDestination) {
            exit
        }

        $restoreFolder = Join-Path $restoreDestination $baseName

        if (Test-Path -LiteralPath $restoreFolder) {
            $confirm = [System.Windows.Forms.MessageBox]::Show(
                "The folder already exists:`r`n$restoreFolder`r`n`r`nDo you want to continue extraction?",
                "FastBackUp - Warning",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )

            if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) {
                exit
            }
        }
        else {
            New-Item -ItemType Directory -Path $restoreFolder -Force | Out-Null
        }

        $extractStart = Get-Date
        Write-Log "Extraction started in: $restoreFolder"
        Write-Host "Extracting files..." -ForegroundColor Cyan

        Invoke-Tar @("-xf", $zipPath, "-C", $restoreFolder)

        $extractEnd = Get-Date
        $extractElapsed = Get-ElapsedText $extractStart $extractEnd

        Write-Log "Extraction completed. Duration: $extractElapsed"

        Show-Info "Data restoration is complete.`r`n`r`nFolder:`r`n$restoreFolder`r`n`r`nExtraction started: $($extractStart.ToString('HH:mm:ss'))`r`nExtraction finished: $($extractEnd.ToString('HH:mm:ss'))`r`nDuration: $extractElapsed`r`n`r`nThe joined ZIP archive was left at:`r`n$zipPath"
    }
}
catch {
    $message = $_.Exception.Message
    Write-Log "ERROR: $message"
    Show-Error "$message`r`n`r`nDetails were written to:`r`n$LogFile"
}
