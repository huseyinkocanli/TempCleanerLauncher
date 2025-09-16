<#
.SYNOPSIS
    Temp Cleaner - A user-friendly tool for cleaning temporary and cache files from your system.
.DESCRIPTION
    it is a tool for cleaning up system temporary files, including browser caches, application caches, and the Recycle Bin.
.AUTHOR
    Thekocanl
.VERSION
    1.2
#>

# --- Required .NET Assemblies ---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Cleanup Options Definition ---
$cleanupOptions = @(
    [pscustomobject]@{Name="User Temporary Files"; Path="$env:TEMP"; Enabled=$true; Info="Temporary files used by applications. Inaccessible files will be skipped."}
    [pscustomobject]@{Name="FiveM Cache"; Path=(Join-Path $env:LOCALAPPDATA "FiveM\FiveM.app\data\server-cache-priv"); Enabled=$false; Info="Cache for FiveM server data. The 'db' and 'unconfirmed' folders are preserved."}
    [pscustomobject]@{Name="Recycle Bin"; Path="RecycleBin"; Enabled=$true; Info="Permanently deletes all items in the Recycle Bin."}
    [pscustomobject]@{Name="Discord Cache"; Path="DiscordCache"; Enabled=$true; Info="Deletes Discord's cache files. This can help resolve issues with the app."}
	[pscustomobject]@{Name="Google Chrome Cache"; Path="ChromeCache"; Enabled=$true; Info="Deletes Google Chrome's cache files. May log you out from some websites."}
    [pscustomobject]@{Name="Microsoft Edge Cache"; Path="EdgeCache"; Enabled=$true; Info="Deletes Microsoft Edge's cache files. May log you out from some websites."}
    [pscustomobject]@{Name="Opera Cache"; Path="OperaCache"; Enabled=$true; Info="Deletes Opera's cache files. May log you out from some websites."}
	[pscustomobject]@{Name="Spotify Cache (Microsoft Store)"; Path=(Join-Path $env:LOCALAPPDATA "Packages\SpotifyAB.SpotifyMusic_zpdnekdrzrea0\LocalCache\Spotify\Data"); Enabled=$true; Info="Deletes Spotify's (Microsoft Store version) cached song data. You may need to re-download songs for offline listening."}
	[pscustomobject]@{Name="YouTube Music Cache"; Path="$env:APPDATA\YouTube Music\Cache\Cache_Data"; Enabled=$true; Info="Clears the cache for the YouTube Music desktop app. You may need to re-download offline songs."}
	[pscustomobject]@{Name="GameLoop Shader Cache"; Path="C:\TxGameAssistant\ui\ShaderCache"; Enabled=$true; Info="Clears the shader cache of the Tencent Gaming Buddy/GameLoop emulator. It may help resolve graphical glitches."}
)

# ===================================================================
# ==                       UI DESIGN                               ==
# ===================================================================

# --- Main Form ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "TempCleaner Pro - v1.2"
$form.Size = New-Object System.Drawing.Size(700, 785)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2c3e50")

# --- Set Form Icon ---
try {
    $iconFileName = "TempCleaner.ico" 
    $iconPath = Join-Path $PSScriptRoot $iconFileName

    if (Test-Path $iconPath) {
        $form.Icon = New-Object System.Drawing.Icon($iconPath)
    }
    else {
        $iconPath = Join-Path (Get-Location) $iconFileName
        if (Test-Path $iconPath) {
             $form.Icon = New-Object System.Drawing.Icon($iconPath)
        } else {
            Write-Warning "Icon file '$iconFileName' could not be found. Make sure it is in the same folder as the script."
        }
    }
}
catch {
    Write-Warning "An error occurred while loading the icon file. Continuing without the icon."
}

# --- GroupBox for Cleanup Options ---
$groupBox = New-Object System.Windows.Forms.GroupBox
$groupBox.Text = "Select Items to Clean"
$groupBox.Location = New-Object System.Drawing.Point(20, 20)
$groupBox.Size = New-Object System.Drawing.Size(645, 330)
$groupBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$groupBox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ecf0f1")
$form.Controls.Add($groupBox)

$yOffset = 30; $xOffset = 20
$cleanupOptions | ForEach-Object {
    $checkBox = New-Object System.Windows.Forms.CheckBox
    $checkBox.Text = $_.Name; $checkBox.Tag = $_; $checkBox.Checked = $_.Enabled
    $checkBox.Location = New-Object System.Drawing.Point($xOffset, $yOffset)
    $checkBox.AutoSize = $true; $checkBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $checkBox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#bdc3c7")
    $toolTip = New-Object System.Windows.Forms.ToolTip; $toolTip.SetToolTip($checkBox, $_.Info)
    $groupBox.Controls.Add($checkBox)
    $yOffset += 30
}

# --- Select/Deselect All Buttons ---
$selectAllButton = New-Object System.Windows.Forms.Button
$selectAllButton.Text = "Select All"
$selectAllButton.Location = New-Object System.Drawing.Point(420, 290)
$selectAllButton.Size = New-Object System.Drawing.Size(100, 25)
$selectAllButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$selectAllButton.FlatStyle = "Flat"; $selectAllButton.FlatAppearance.BorderSize = 1
$selectAllButton.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#bdc3c7")
$selectAllButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#34495e")
$selectAllButton.ForeColor = [System.Drawing.Color]::White
$groupBox.Controls.Add($selectAllButton)

$deselectAllButton = New-Object System.Windows.Forms.Button
$deselectAllButton.Text = "Deselect All"
$deselectAllButton.Location = New-Object System.Drawing.Point(525, 290)
$deselectAllButton.Size = New-Object System.Drawing.Size(100, 25)
$deselectAllButton.Font = $selectAllButton.Font
$deselectAllButton.FlatStyle = "Flat"; $deselectAllButton.FlatAppearance.BorderSize = 1
$deselectAllButton.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#bdc3c7")
$deselectAllButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#34495e")
$deselectAllButton.ForeColor = [System.Drawing.Color]::White
$groupBox.Controls.Add($deselectAllButton)

# --- Output Box (RichTextBox) ---
$outputBox = New-Object System.Windows.Forms.RichTextBox
$outputBox.Location = New-Object System.Drawing.Point(20, 370)
$outputBox.Size = New-Object System.Drawing.Size(645, 300)
$outputBox.ScrollBars = "Vertical"; $outputBox.ReadOnly = $true
$outputBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$outputBox.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e1e1e")
$outputBox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#2ecc71")
$outputBox.Text = "Select the items you want to clean and press 'Start Cleaning'."
$form.Controls.Add($outputBox)

# --- Other UI Elements ---
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(285, 695)
$progressBar.Size = New-Object System.Drawing.Size(120, 25)
$form.Controls.Add($progressBar)

# --- BUTTONS (Exit) ---
$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Location = New-Object System.Drawing.Point(20, 690)
$exitButton.Size = New-Object System.Drawing.Size(120, 35)
$exitButton.Text = "Exit"
$exitButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$exitButton.FlatStyle = "Flat"; $exitButton.FlatAppearance.BorderSize = 0
$exitButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#c0392b")
$exitButton.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($exitButton)

# --- BUTTONS (About) ---
$aboutButton = New-Object System.Windows.Forms.Button
$aboutButton.Location = New-Object System.Drawing.Point(150, 690)
$aboutButton.Size = New-Object System.Drawing.Size(120, 35)
$aboutButton.Text = "About"
$aboutButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$aboutButton.FlatStyle = "Flat"; $aboutButton.FlatAppearance.BorderSize = 0
$aboutButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#95a5a6")
$aboutButton.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($aboutButton)

# --- BUTTONS (Analyze) ---
$analyzeButton = New-Object System.Windows.Forms.Button
$analyzeButton.Location = New-Object System.Drawing.Point(415, 690)
$analyzeButton.Size = New-Object System.Drawing.Size(120, 35)
$analyzeButton.Text = "Analyze"
$analyzeButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$analyzeButton.FlatStyle = "Flat"; $analyzeButton.FlatAppearance.BorderSize = 0
$analyzeButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1abc9c")
$analyzeButton.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($analyzeButton)

# --- BUTTONS (Start and Restart) ---
$startButton = New-Object System.Windows.Forms.Button
$startButton.Location = New-Object System.Drawing.Point(545, 690)
$startButton.Size = New-Object System.Drawing.Size(120, 35)
$startButton.Text = "Start Cleaning"
$startButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$startButton.FlatStyle = "Flat"; $startButton.FlatAppearance.BorderSize = 0
$startButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#3498db")
$startButton.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($startButton)

$restartButton = New-Object System.Windows.Forms.Button
$restartButton.Location = $startButton.Location
$restartButton.Size = $startButton.Size
$restartButton.Text = "Restart"
$restartButton.Font = $startButton.Font
$restartButton.FlatStyle = "Flat"; $restartButton.FlatAppearance.BorderSize = 0
$restartButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#f39c12")
$restartButton.ForeColor = [System.Drawing.Color]::White
$restartButton.Visible = $false
$form.Controls.Add($restartButton)

# --- Helper Functions ---
function Write-Log ($message) { $outputBox.AppendText("$(Get-Date -Format 'HH:mm:ss') - $message`r`n"); $form.Refresh() }
function Format-Bytes ($bytes) { $units="B","KB","MB","GB","TB";$i=0;while($bytes-ge 1024-and$i-lt($units.Length-1)){$bytes/=1024;$i++};return "$([math]::Round($bytes,2)) $($units[$i])" }

# --- About Functions ---
function Show-AboutForm {
    $aboutForm = New-Object System.Windows.Forms.Form
    $aboutForm.Text = "About TempCleaner"
    $aboutForm.Size = New-Object System.Drawing.Size(400, 250)
    $aboutForm.StartPosition = "CenterParent"
    $aboutForm.FormBorderStyle = 'FixedDialog'
    $aboutForm.MaximizeBox = $false
    $aboutForm.MinimizeBox = $false
    $aboutForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#34495e")

    $appNameLabel = New-Object System.Windows.Forms.Label
    $appNameLabel.Text = "TempCleaner"
    $appNameLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $appNameLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ecf0f1")
    $appNameLabel.AutoSize = $true
    $appNameLabel.Location = New-Object System.Drawing.Point(130, 20)
    $aboutForm.Controls.Add($appNameLabel)

    $versionLabel = New-Object System.Windows.Forms.Label
    $versionLabel.Text = "Version 1.2"
    $versionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $versionLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#bdc3c7")
    $versionLabel.AutoSize = $true
    $versionLabel.Location = New-Object System.Drawing.Point(130, 55)
    $aboutForm.Controls.Add($versionLabel)

    $authorLabel = New-Object System.Windows.Forms.Label
    $authorLabel.Text = "by Thekocanl"
    $authorLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $authorLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#bdc3c7")
    $authorLabel.AutoSize = $true
    $authorLabel.Location = New-Object System.Drawing.Point(130, 80)
    $aboutForm.Controls.Add($authorLabel)

    $linkLabel = New-Object System.Windows.Forms.LinkLabel
    $linkLabel.Text = "GitHub Profile"
    $linkLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $linkLabel.LinkColor = [System.Drawing.ColorTranslator]::FromHtml("#3498db")
    $linkLabel.AutoSize = $true
    $linkLabel.Location = New-Object System.Drawing.Point(130, 105)
    $linkLabel.Links.Add(0, $linkLabel.Text.Length, "https://github.com/huseyinkocanli") | Out-Null
    $linkLabel.Add_LinkClicked({
        param($sender, $e)
        [System.Diagnostics.Process]::Start($e.Link.LinkData)
    })
    $aboutForm.Controls.Add($linkLabel)

    try {
        $iconPath = Join-Path $PSScriptRoot "TempCleaner.ico"
        if (Test-Path $iconPath) {
            $aboutForm.Icon = New-Object System.Drawing.Icon($iconPath)
            $pictureBox = New-Object System.Windows.Forms.PictureBox
            $pictureBox.Image = [System.Drawing.Image]::FromFile($iconPath)
            $pictureBox.Location = New-Object System.Drawing.Point(30, 30)
            $pictureBox.Size = New-Object System.Drawing.Size(64, 64)
            $pictureBox.SizeMode = 'StretchImage'
            $aboutForm.Controls.Add($pictureBox)
        }
    } catch {}

    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Text = "OK"
    $closeButton.Location = New-Object System.Drawing.Point(150, 160)
    $closeButton.Size = New-Object System.Drawing.Size(100, 30)
    $closeButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $closeButton.FlatStyle = "Flat"; $closeButton.FlatAppearance.BorderSize = 0
    $closeButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#3498db")
    $closeButton.ForeColor = [System.Drawing.Color]::White
    $closeButton.Add_Click({ $aboutForm.Close() })
    $aboutForm.Controls.Add($closeButton)

    $aboutForm.ShowDialog() | Out-Null
}

# ===================================================================
# ==                       BUTTON CLICK EVENTS                     ==
# ===================================================================

$aboutButton.Add_Click({
    Show-AboutForm
})

$selectAllButton.Add_Click({
    $groupBox.Controls | Where-Object { $_ -is [System.Windows.Forms.CheckBox] } | ForEach-Object {
        $_.Checked = $true
    }
})

$deselectAllButton.Add_Click({
    $groupBox.Controls | Where-Object { $_ -is [System.Windows.Forms.CheckBox] } | ForEach-Object {
        $_.Checked = $false
    }
})

$analyzeButton.Add_Click({
    $startButton.Enabled = $false
    $analyzeButton.Enabled = $false
    $groupBox.Enabled = $false
    $exitButton.Enabled = $false
    $outputBox.Text = ""
    $progressBar.Value = 0
    $totalPotentialSpace = 0
    $selectedOptions = $groupBox.Controls | Where-Object { $_.GetType().Name -eq 'CheckBox' -and $_.Checked }

    try {
        if ($selectedOptions.Count -eq 0) {
            Write-Log "No items selected for analysis. Operation cancelled."
        } else {
            $progressBar.Maximum = $selectedOptions.Count
            Write-Log "Analysis process started..."
            foreach ($checkBox in $selectedOptions) {
                $option = $checkBox.Tag
                Write-Log "-------------------------------------------------"
                Write-Log "Analyzing: $($option.Name)"
                $sizeForThisOption = 0
                
                if ($option.Path -eq "RecycleBin") {
                    try {
                        $shell = New-Object -ComObject Shell.Application
                        $recycleBin = $shell.Namespace(0xA)
                        $sizeForThisOption = ($recycleBin.Items() | Measure-Object -Property Size -Sum -ErrorAction SilentlyContinue).Sum
                        Write-Log "-> Potential space to be freed from Recycle Bin: $(Format-Bytes $sizeForThisOption)"
                    } catch {
                        Write-Log "-> ERROR: Could not analyze the Recycle Bin. Message: $($_.Exception.Message)"
                    }
                } elseif ($option.Path -in @("DiscordCache", "ChromeCache", "EdgeCache", "OperaCache")) {
                    $browserPaths = @()
                    switch ($option.Path) {
                        "DiscordCache" { $browserPaths = @("$env:APPDATA\discord\Cache", "$env:APPDATA\discord\Code Cache", "$env:APPDATA\discord\GPUCache") }
                        "ChromeCache" { $browserPaths = @("$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache", "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache", "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\GPUCache") }
                        "EdgeCache"   { $browserPaths = @("$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache", "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache", "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\GPUCache") }
                        "OperaCache"  { $browserPaths = @("$env:APPDATA\Opera Software\Opera Stable\Cache", "$env:APPDATA\Opera Software\Opera Stable\Code Cache", "$env:APPDATA\Opera Software\Opera Stable\GPUCache") }
                    }
                    
                    foreach ($path in $browserPaths) {
                        if (Test-Path $path) {
                            $sizeForThisOption += (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        }
                    }
                    Write-Log "-> Potential space to be freed from $($option.Name): $(Format-Bytes $sizeForThisOption)"
                } elseif (Test-Path $option.Path) {
                    $itemsToAnalyze = Get-ChildItem -Path $option.Path -Force -ErrorAction SilentlyContinue
                    if ($option.Name -like "*FiveM*") {
                        $itemsToAnalyze = $itemsToAnalyze | Where-Object { $_.Name -ne "db" -and $_.Name -ne "unconfirmed" }
                    }
                    $sizeForThisOption = ($itemsToAnalyze | ForEach-Object {
                        if ($_.PSIsContainer) {
                            (Get-ChildItem $_.FullName -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        } else {
                            $_.Length
                        }
                    } | Measure-Object -Sum).Sum
                    Write-Log "-> Potential space to be freed from this location: $(Format-Bytes $sizeForThisOption)"
                } else {
                    Write-Log "-> Location not found, skipping analysis: $($option.Path)"
                }
                
                $totalPotentialSpace += $sizeForThisOption
                $progressBar.PerformStep()
            }
            Write-Log "================================================="
            $outputBox.SelectionColor = [System.Drawing.ColorTranslator]::FromHtml("#1abc9c"); $outputBox.AppendText("ANALYSIS COMPLETED!`r`n")
            $outputBox.SelectionColor = [System.Drawing.ColorTranslator]::FromHtml("#f1c40f"); $outputBox.AppendText("Total potential space to be freed: $(Format-Bytes $totalPotentialSpace)`r`n")
        }
    } catch {
        $outputBox.SelectionColor = [System.Drawing.ColorTranslator]::fromhtml("#e74c3c"); Write-Log "CRITICAL ERROR: An unexpected error occurred during analysis: $($_.Exception.Message)"
    } finally {
        $startButton.Enabled = $true
        $analyzeButton.Enabled = $true
        $groupBox.Enabled = $true
        $exitButton.Enabled = $true
    }
})


$startButton.Add_Click({
    $startButton.Text = "Working..."
    $startButton.Enabled = $false
    $analyzeButton.Enabled = $false
    $startButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#7f8c8d")

    $groupBox.Enabled = $false
	$exitButton.Enabled = $false
    $outputBox.Text = ""
    $progressBar.Value = 0
    $totalFreedSpace = 0
    $selectedOptions = $groupBox.Controls | Where-Object { $_.GetType().Name -eq 'CheckBox' -and $_.Checked }

    try {
        if ($selectedOptions.Count -eq 0) {
            Write-Log "No cleaning options were selected. Operation cancelled."
        } else {
            $progressBar.Maximum = $selectedOptions.Count
            Write-Log "Cleaning process started..."
            foreach ($checkBox in $selectedOptions) {
                $option = $checkBox.Tag; Write-Log "-------------------------------------------------"; Write-Log "Processing: $($option.Name)"; $freedSpaceForThisOption = 0
                if ($option.Path -eq "RecycleBin") {
                    try {
                        $shell = New-Object -ComObject Shell.Application
                        $recycleBin = $shell.Namespace(0xA)
                        $sizeBefore = ($recycleBin.Items() | Measure-Object -Property Size -Sum -ErrorAction SilentlyContinue).Sum

                        if ($sizeBefore -gt 0) {
                            Clear-RecycleBin -Force -ErrorAction Stop
                            if ($shell.Namespace(0xA).Items().Count -eq 0) {
                                $freedSpaceForThisOption = $sizeBefore
                            }
                        }
                        $totalFreedSpace += $freedSpaceForThisOption
                        Write-Log "-> Recycle Bin cleaned. Space Freed: $(Format-Bytes $freedSpaceForThisOption)"
                    } catch {
                        Write-Log "-> ERROR: Could not empty the Recycle Bin. Message: $($_.Exception.Message)"
                    }
                } elseif ($option.Path -in @("DiscordCache", "ChromeCache", "EdgeCache", "OperaCache")) {
                    $browserPaths = @()
                    switch ($option.Path) {
                        "DiscordCache" { 
                            $browserPaths = @(
                                "$env:APPDATA\discord\Cache", 
                                "$env:APPDATA\discord\Code Cache", 
                                "$env:APPDATA\discord\GPUCache"
                            ) 
                        }
                        "ChromeCache" {
                            $browserPaths = @(
                                "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
                                "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
                                "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\GPUCache"
                            )
                        }
                        "EdgeCache" {
                            $browserPaths = @(
                                "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
                                "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache",
                                "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\GPUCache"
                            )
                        }
                        "OperaCache" {
                             $browserPaths = @(
                                "$env:APPDATA\Opera Software\Opera Stable\Cache",
                                "$env:APPDATA\Opera Software\Opera Stable\Code Cache",
                                "$env:APPDATA\Opera Software\Opera Stable\GPUCache"
                            )
                        }
                    }
                    
                    Write-Log "-> Cleaning $($option.Name)..."
                    foreach ($path in $browserPaths) {
                        if (Test-Path $path) {
                            $sizeBefore = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                            Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
                            if ($?) {
                                $freedSpaceForThisOption += $sizeBefore
                            }
                        }
                    }
                    $totalFreedSpace += $freedSpaceForThisOption
                    Write-Log "-> $($option.Name) cleaned. Space Freed: $(Format-Bytes $freedSpaceForThisOption)"
                } elseif (Test-Path $option.Path) {
                    $itemsToDelete = Get-ChildItem -Path $option.Path -Force -ErrorAction SilentlyContinue
                    if ($option.Name -like "*FiveM*") {
                        $itemsToDelete = $itemsToDelete | Where-Object { $_.Name -ne "db" -and $_.Name -ne "unconfirmed" }
                    }

                    foreach ($item in $itemsToDelete) {
                        $itemPath = $item.FullName
                        $itemSize = 0
                        
                        if ($item.PSIsContainer) {
                            $itemSize = (Get-ChildItem $itemPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                        } else {
                            $itemSize = $item.Length
                        }

                        Remove-Item -Path $itemPath -Recurse -Force -ErrorAction SilentlyContinue
                        
                        if (-not (Test-Path -Path $itemPath)) {
                            $freedSpaceForThisOption += $itemSize
                        }
                    }
                    
                    $totalFreedSpace += $freedSpaceForThisOption
                    Write-Log "-> Location cleaned. Space Freed: $(Format-Bytes $freedSpaceForThisOption)"
                } else {
                    Write-Log "-> Location not found, skipping: $($option.Path)"
                }
                $progressBar.PerformStep()
            }
            Write-Log "================================================="
            $outputBox.SelectionColor = [System.Drawing.ColorTranslator]::FromHtml("#27ae60"); $outputBox.AppendText("ALL OPERATIONS COMPLETED SUCCESSFULLY!`r`n")
            $outputBox.SelectionColor = [System.Drawing.ColorTranslator]::FromHtml("#f1c40f"); $outputBox.AppendText("Total space freed: $(Format-Bytes $totalFreedSpace)`r`n")
        }
    } catch {
        $outputBox.SelectionColor = [System.Drawing.ColorTranslator]::fromhtml("#e74c3c"); Write-Log "CRITICAL ERROR: An unexpected error occurred: $($_.Exception.Message)"
    } finally {
        $startButton.Visible = $false
        $restartButton.Visible = $true
		$exitButton.Enabled = $true
        $analyzeButton.Enabled = false
    }
})

$restartButton.Add_Click({
    $restartButton.Visible = $false
    $outputBox.Text = "Select the items you want to clean and press 'Start Cleaning'."
    $progressBar.Value = 0
    $groupBox.Enabled = $true
	$exitButton.Enabled = $true
    $analyzeButton.Enabled = $true
    
    $startButton.Text = "Start Cleaning"
    $startButton.Enabled = $true
    $startButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#3498db")
    $startButton.Visible = $true
})

$exitButton.Add_Click({
    $form.Close()
})

$form.ShowDialog() | Out-Null