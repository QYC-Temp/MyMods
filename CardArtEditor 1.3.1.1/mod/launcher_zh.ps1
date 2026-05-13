Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

function Get-Text {
    param([string]$Base64)
    return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Base64))
}

function Get-DefaultConfig {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    try {
        return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$exportScript = Join-Path $scriptRoot "export_anmouren_artifact.ps1"
$defaultConfigPath = Join-Path $scriptRoot "export_tool_defaults.json"
$defaultConfig = Get-DefaultConfig -Path $defaultConfigPath

$titleText = Get-Text "5p2A5oiu5bCW5aGUMiBNb2Qg5Lit5paH5a+85Ye65bel5YW3"
$headerText = Get-Text "6K+35aGr5YaZ5a+85Ye65L+h5oGv77yM54S25ZCO54K55Ye74oCc5byA5aeL5a+85Ye64oCd"
$labelModNameText = Get-Text "TW9kIOWQjeensA=="
$labelConfigText = Get-Text "5p6E5bu65qih5byP"
$labelGodotText = Get-Text "R29kb3Qg6Lev5b6E"
$browseText = Get-Text "5rWP6KeI"
$godotDialogTitleText = Get-Text "6K+36YCJ5oupIEdvZG90IOWPr+aJp+ihjOaWh+S7tg=="
$godotDialogFilterText = Get-Text "5Y+v5omn6KGM5paH5Lu2ICgqLmV4ZSl8Ki5leGV85omA5pyJ5paH5Lu2ICgqLiopfCouKg=="
$hintText = Get-Text "R29kb3Qg6Lev5b6E5Y+v55WZ56m644CC55WZ56m65pe25bCG55u05o6l5L2/55So57O757uf546v5aKD5Y+Y6YeP5Lit55qEIGdvZG9044CC"
$exportButtonText = Get-Text "5byA5aeL5a+85Ye6"
$cancelButtonText = Get-Text "5Y+W5raI"
$missingScriptText = Get-Text "5pyq5om+5Yiw5a+85Ye66ISa5pys77ya"
$startupFailedText = Get-Text "5ZCv5Yqo5aSx6LSl"
$missingModNameText = Get-Text "6K+36L6T5YWlIE1vZCDlkI3np7DjgII="
$missingInfoText = Get-Text "57y65bCR5L+h5oGv"
$successText = Get-Text "5a+85Ye65oiQ5Yqf44CC"
$doneText = Get-Text "5a6M5oiQ"
$outputFolderText = Get-Text "6L6T5Ye655uu5b2V77ya"
$exportFailedText = Get-Text "5a+85Ye65aSx6LSl77yM6ZSZ6K+v56CB77ya"
$checkConsoleText = Get-Text "6K+35p+l55yL5by55Ye655qEIFBvd2VyU2hlbGwg56qX5Y+j6L6T5Ye644CC"
$launchExceptionText = Get-Text "5ZCv5Yqo5a+85Ye65pe25Y+R55Sf5byC5bi477ya"
$logFolderText = Get-Text "6K+35ZCM5pe25p+l55yLIGxvZ3Mg5paH5Lu25aS544CC"

if (-not (Test-Path -LiteralPath $exportScript)) {
    [System.Windows.Forms.MessageBox]::Show(
        "$missingScriptText`n$exportScript",
        $startupFailedText,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit 1
}

$form = New-Object System.Windows.Forms.Form
$form.Text = $titleText
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(520, 290)
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

$labelTitle = New-Object System.Windows.Forms.Label
$labelTitle.Location = New-Object System.Drawing.Point(20, 15)
$labelTitle.Size = New-Object System.Drawing.Size(460, 25)
$labelTitle.Text = $headerText
$labelTitle.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 11, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($labelTitle)

$labelModName = New-Object System.Windows.Forms.Label
$labelModName.Location = New-Object System.Drawing.Point(20, 55)
$labelModName.Size = New-Object System.Drawing.Size(100, 23)
$labelModName.Text = $labelModNameText
$form.Controls.Add($labelModName)

$textModName = New-Object System.Windows.Forms.TextBox
$textModName.Location = New-Object System.Drawing.Point(130, 52)
$textModName.Size = New-Object System.Drawing.Size(330, 23)
$form.Controls.Add($textModName)

$labelConfig = New-Object System.Windows.Forms.Label
$labelConfig.Location = New-Object System.Drawing.Point(20, 92)
$labelConfig.Size = New-Object System.Drawing.Size(100, 23)
$labelConfig.Text = $labelConfigText
$form.Controls.Add($labelConfig)

$comboConfig = New-Object System.Windows.Forms.ComboBox
$comboConfig.Location = New-Object System.Drawing.Point(130, 89)
$comboConfig.Size = New-Object System.Drawing.Size(150, 23)
$comboConfig.DropDownStyle = "DropDownList"
[void]$comboConfig.Items.Add("Debug")
[void]$comboConfig.Items.Add("Release")
$comboConfig.SelectedIndex = 0
$form.Controls.Add($comboConfig)

$labelGodot = New-Object System.Windows.Forms.Label
$labelGodot.Location = New-Object System.Drawing.Point(20, 129)
$labelGodot.Size = New-Object System.Drawing.Size(100, 23)
$labelGodot.Text = $labelGodotText
$form.Controls.Add($labelGodot)

$textGodot = New-Object System.Windows.Forms.TextBox
$textGodot.Location = New-Object System.Drawing.Point(130, 126)
$textGodot.Size = New-Object System.Drawing.Size(250, 23)
$form.Controls.Add($textGodot)

$buttonBrowse = New-Object System.Windows.Forms.Button
$buttonBrowse.Location = New-Object System.Drawing.Point(390, 124)
$buttonBrowse.Size = New-Object System.Drawing.Size(70, 27)
$buttonBrowse.Text = $browseText
$buttonBrowse.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = $godotDialogTitleText
    $dialog.Filter = $godotDialogFilterText
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textGodot.Text = $dialog.FileName
    }
})
$form.Controls.Add($buttonBrowse)

$labelHint = New-Object System.Windows.Forms.Label
$labelHint.Location = New-Object System.Drawing.Point(130, 156)
$labelHint.Size = New-Object System.Drawing.Size(330, 34)
$labelHint.Text = $hintText
$labelHint.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($labelHint)

$buttonExport = New-Object System.Windows.Forms.Button
$buttonExport.Location = New-Object System.Drawing.Point(280, 205)
$buttonExport.Size = New-Object System.Drawing.Size(85, 32)
$buttonExport.Text = $exportButtonText
$form.Controls.Add($buttonExport)

$buttonCancel = New-Object System.Windows.Forms.Button
$buttonCancel.Location = New-Object System.Drawing.Point(375, 205)
$buttonCancel.Size = New-Object System.Drawing.Size(85, 32)
$buttonCancel.Text = $cancelButtonText
$buttonCancel.Add_Click({ $form.Close() })
$form.Controls.Add($buttonCancel)

if ($defaultConfig) {
    if (-not [string]::IsNullOrWhiteSpace([string]$defaultConfig.ModName)) {
        $textModName.Text = [string]$defaultConfig.ModName
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$defaultConfig.GodotPath)) {
        $textGodot.Text = [string]$defaultConfig.GodotPath
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$defaultConfig.DefaultConfiguration)) {
        $selectedIndex = $comboConfig.Items.IndexOf([string]$defaultConfig.DefaultConfiguration)
        if ($selectedIndex -ge 0) {
            $comboConfig.SelectedIndex = $selectedIndex
        }
    }
}

$buttonExport.Add_Click({
    $modName = $textModName.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($modName)) {
        [System.Windows.Forms.MessageBox]::Show(
            $missingModNameText,
            $missingInfoText,
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    $config = [string]$comboConfig.SelectedItem
    $godotPath = $textGodot.Text.Trim()
    $arguments = @(
        "-ExecutionPolicy", "Bypass",
        "-File", $exportScript,
        "-ModName", $modName,
        "-Configuration", $config
    )

    if (-not [string]::IsNullOrWhiteSpace($godotPath)) {
        $arguments += @("-GodotPath", $godotPath)
    }

    $form.Enabled = $false

    try {
        $process = Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Wait -PassThru
        if ($process.ExitCode -eq 0) {
            $outputDir = Join-Path $scriptRoot $modName
            [System.Windows.Forms.MessageBox]::Show(
                "$successText`n$outputFolderText`n$outputDir",
                $doneText,
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null
            $form.Close()
        }
        else {
            [System.Windows.Forms.MessageBox]::Show(
                "$exportFailedText $($process.ExitCode)`n$checkConsoleText`n$logFolderText",
                $exportFailedText,
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "$launchExceptionText`n$($_.Exception.Message)",
            $startupFailedText,
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
    finally {
        $form.Enabled = $true
    }
})

[void]$form.ShowDialog()
