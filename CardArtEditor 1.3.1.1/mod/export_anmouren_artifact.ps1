param(
    [string]$ModName = "",
    [string]$GodotPath = "godot",
    [string]$ExportPreset = "Windows Desktop",
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Debug",
    [string]$Author = "a2329",
    [string]$Version = "v1.0.0",
    [string]$Description = ""
)

$ErrorActionPreference = "Stop"

function Write-LogLine {
    param(
        [string]$Message
    )

    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[{0}] {1}" -f $time, $Message
    Add-Content -LiteralPath $script:logPath -Value $line -Encoding UTF8
}

function Wait-ForFile {
    param(
        [string]$Path,
        [int]$TimeoutSeconds = 30
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        if (Test-Path -LiteralPath $Path) {
            return $true
        }

        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $deadline)

    return $false
}

function Ensure-ExpectedSolutionFile {
    param(
        [string]$ProjectRoot,
        [string]$AssemblyName
    )

    $expectedSolutionPath = Join-Path $ProjectRoot ($AssemblyName + ".sln")
    if (Test-Path -LiteralPath $expectedSolutionPath) {
        return $expectedSolutionPath
    }

    $existingSolution = Get-ChildItem -LiteralPath $ProjectRoot -File -Filter *.sln | Select-Object -First 1
    if ($existingSolution) {
        Copy-Item -LiteralPath $existingSolution.FullName -Destination $expectedSolutionPath -Force
        return $expectedSolutionPath
    }

    return $null
}

function Get-TemplateJsonFile {
    param(
        [string]$SearchRoot,
        [string]$ExcludedRoot
    )

    $jsonFiles = Get-ChildItem -LiteralPath $SearchRoot -Recurse -File -Filter *.json |
        Where-Object {
            $_.FullName -notlike (Join-Path $ExcludedRoot "*") -and
            $_.Name -ne "mod_manifest.json" -and
            $_.DirectoryName -notlike (Join-Path $SearchRoot "generated*")
        }

    foreach ($file in $jsonFiles) {
        try {
            $json = Get-Content -Raw -LiteralPath $file.FullName | ConvertFrom-Json
            if ($null -ne $json.id -or $null -ne $json.name) {
                return $file
            }
        }
        catch {
        }
    }

    return $null
}

function New-ManifestObject {
    param(
        [string]$TargetModName,
        [string]$TemplateJsonPath,
        [string]$DefaultAuthor,
        [string]$DefaultVersion,
        [string]$DefaultDescription
    )

    if ($TemplateJsonPath) {
        $manifest = Get-Content -Raw -LiteralPath $TemplateJsonPath | ConvertFrom-Json
    }
    else {
        $manifest = [ordered]@{
            id = $TargetModName
            name = $TargetModName
            author = $DefaultAuthor
            description = $DefaultDescription
            version = $DefaultVersion
            has_pck = $true
            has_dll = $true
            dependencies = @()
            affects_gameplay = $false
        }

        return [pscustomobject]$manifest
    }

    $manifest.id = $TargetModName
    $manifest.name = $TargetModName

    if ([string]::IsNullOrWhiteSpace([string]$manifest.author)) {
        $manifest | Add-Member -NotePropertyName author -NotePropertyValue $DefaultAuthor -Force
    }
    if ([string]::IsNullOrWhiteSpace([string]$manifest.description)) {
        $manifest | Add-Member -NotePropertyName description -NotePropertyValue $DefaultDescription -Force
    }
    if ([string]::IsNullOrWhiteSpace([string]$manifest.version)) {
        $manifest | Add-Member -NotePropertyName version -NotePropertyValue $DefaultVersion -Force
    }

    $manifest | Add-Member -NotePropertyName has_pck -NotePropertyValue $true -Force
    $manifest | Add-Member -NotePropertyName has_dll -NotePropertyValue $true -Force

    if ($null -eq $manifest.dependencies) {
        $manifest | Add-Member -NotePropertyName dependencies -NotePropertyValue @() -Force
    }
    if ($null -eq $manifest.affects_gameplay) {
        $manifest | Add-Member -NotePropertyName affects_gameplay -NotePropertyValue $false -Force
    }

    return $manifest
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
$defaultConfigPath = Join-Path $scriptRoot "export_tool_defaults.json"
$defaultConfig = Get-DefaultConfig -Path $defaultConfigPath

if ([string]::IsNullOrWhiteSpace($ModName) -and $defaultConfig -and -not [string]::IsNullOrWhiteSpace([string]$defaultConfig.ModName)) {
    $ModName = [string]$defaultConfig.ModName
}

if (([string]::IsNullOrWhiteSpace($GodotPath) -or $GodotPath -eq "godot") -and $defaultConfig -and -not [string]::IsNullOrWhiteSpace([string]$defaultConfig.GodotPath)) {
    $GodotPath = [string]$defaultConfig.GodotPath
}

if ([string]::IsNullOrWhiteSpace($Author) -and $defaultConfig -and -not [string]::IsNullOrWhiteSpace([string]$defaultConfig.Author)) {
    $Author = [string]$defaultConfig.Author
}

if ([string]::IsNullOrWhiteSpace($Version) -and $defaultConfig -and -not [string]::IsNullOrWhiteSpace([string]$defaultConfig.Version)) {
    $Version = [string]$defaultConfig.Version
}

if ([string]::IsNullOrWhiteSpace($Description) -and $defaultConfig -and -not [string]::IsNullOrWhiteSpace([string]$defaultConfig.Description)) {
    $Description = [string]$defaultConfig.Description
}

if ([string]::IsNullOrWhiteSpace($ModName)) {
    $ModName = Read-Host "Enter mod name"
}

$ModName = $ModName.Trim()
if ([string]::IsNullOrWhiteSpace($ModName)) {
    throw "Mod name cannot be empty."
}

$projectRoot = Split-Path -Parent $scriptRoot
$logRoot = Join-Path $scriptRoot "logs"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logPath = Join-Path $logRoot ("export_{0}_{1}.log" -f $ModName, $timestamp)
$outputRoot = Join-Path $scriptRoot $ModName
$tempExportRoot = Join-Path $scriptRoot ".export_tmp"
$tempPckPath = Join-Path $tempExportRoot ($ModName + ".pck")
$finalDllPath = Join-Path $outputRoot ($ModName + ".dll")
$finalJsonPath = Join-Path $outputRoot ($ModName + ".json")
$finalPckPath = Join-Path $outputRoot ($ModName + ".pck")
$declarationFileName = "卡牌管理器导出使用声明.md"
$finalDeclarationPath = Join-Path $outputRoot $declarationFileName
$declarationCandidates = @(
    (Join-Path $scriptRoot $declarationFileName),
    (Join-Path $projectRoot $declarationFileName)
)

if ([string]::IsNullOrWhiteSpace($Description)) {
    $Description = "$ModName card pack"
}

New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
New-Item -ItemType File -Force -Path $logPath | Out-Null

try {
    Write-LogLine "Export started."
    Write-LogLine "Project root: $projectRoot"
    Write-LogLine "Output root: $outputRoot"
    if ($defaultConfig) {
        Write-LogLine "Resolved defaults: $defaultConfigPath"
    }
    else {
        Write-LogLine "Resolved defaults: <missing>"
    }
    Write-Host "Log file: $logPath"
    Write-Host "Project root: $projectRoot"
    Write-Host "Output root: $outputRoot"

    $projectFile = Get-ChildItem -LiteralPath $projectRoot -File -Filter *.csproj | Select-Object -First 1
    if (-not $projectFile) {
        throw "No .csproj file found under: $projectRoot"
    }

    [xml]$projectXml = Get-Content -Raw -LiteralPath $projectFile.FullName
    $assemblyName = $projectXml.Project.PropertyGroup.AssemblyName | Select-Object -First 1
    $targetFramework = $projectXml.Project.PropertyGroup.TargetFramework | Select-Object -First 1

    if ([string]::IsNullOrWhiteSpace($assemblyName)) {
        $assemblyName = [System.IO.Path]::GetFileNameWithoutExtension($projectFile.Name)
    }
    if ([string]::IsNullOrWhiteSpace($targetFramework)) {
        throw "TargetFramework not found in $($projectFile.FullName)"
    }

    $solutionPath = Ensure-ExpectedSolutionFile -ProjectRoot $projectRoot -AssemblyName $assemblyName
    if ($solutionPath) {
        Write-Host "Resolved solution: $solutionPath"
        Write-LogLine "Resolved solution: $solutionPath"
    }
    else {
        Write-Host "Resolved solution: <missing>"
        Write-LogLine "Resolved solution: <missing>"
    }

    $templateJsonFile = Get-TemplateJsonFile -SearchRoot $projectRoot -ExcludedRoot $scriptRoot
    $templateJsonPath = $null
    if ($templateJsonFile) {
        $templateJsonPath = $templateJsonFile.FullName
        Write-Host "Template json: $templateJsonPath"
        Write-LogLine "Template json: $templateJsonPath"
    }
    else {
        Write-Host "Template json: <auto-generate>"
        Write-LogLine "Template json: <auto-generate>"
    }

    $manifest = New-ManifestObject -TargetModName $ModName -TemplateJsonPath $templateJsonPath -DefaultAuthor $Author -DefaultVersion $Version -DefaultDescription $Description

    New-Item -ItemType Directory -Force -Path $tempExportRoot | Out-Null
    New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null

    Write-Host "[1/4] Building C# project"
    Write-LogLine "Running dotnet build for $($projectFile.FullName) with configuration $Configuration"
    dotnet build $projectFile.FullName -c $Configuration
    if ($LASTEXITCODE -ne 0) {
        Write-LogLine "dotnet build failed with exit code $LASTEXITCODE"
        throw "dotnet build failed."
    }

    $dllCandidates = @(
        (Join-Path $projectRoot ".godot\\mono\\temp\\bin\\Debug\\$assemblyName.dll"),
        (Join-Path $projectRoot ".godot\\mono\\temp\\bin\\ExportDebug\\$assemblyName.dll"),
        (Join-Path $projectRoot ".godot\\mono\\temp\\bin\\ExportRelease\\$assemblyName.dll"),
        (Join-Path $projectRoot "bin\\$Configuration\\$targetFramework\\$assemblyName.dll"),
        (Join-Path $projectRoot "bin\\Debug\\$targetFramework\\$assemblyName.dll"),
        (Join-Path $projectRoot "bin\\Release\\$targetFramework\\$assemblyName.dll")
    )

    $dllPath = $dllCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $dllPath) {
        Write-LogLine "DLL resolution failed for assembly $assemblyName"
        throw "Could not find built DLL for assembly: $assemblyName"
    }
    Write-Host "Resolved DLL: $dllPath"
    Write-LogLine "Resolved DLL: $dllPath"

    Write-Host "[2/4] Exporting Godot PCK"
    Write-LogLine "Running Godot export with executable $GodotPath"
    & $GodotPath --headless --path $projectRoot --export-pack $ExportPreset $tempPckPath
    if ($LASTEXITCODE -ne 0) {
        Write-LogLine "Godot export failed with exit code $LASTEXITCODE"
        throw "Godot export-pack failed."
    }
    if (-not (Wait-ForFile -Path $tempPckPath -TimeoutSeconds 60)) {
        Write-LogLine "Timed out waiting for exported PCK: $tempPckPath"
        throw "Exported PCK was not created in time: $tempPckPath"
    }
    Write-LogLine "Resolved PCK: $tempPckPath"

    Write-Host "[3/4] Writing DLL and JSON"
    Write-LogLine "Copying DLL to $finalDllPath"
    Copy-Item -LiteralPath $dllPath -Destination $finalDllPath -Force
    Write-LogLine "Writing manifest JSON to $finalJsonPath"
    $manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $finalJsonPath -Encoding UTF8

    Write-Host "[4/4] Writing PCK"
    Write-LogLine "Copying PCK to $finalPckPath"
    Copy-Item -LiteralPath $tempPckPath -Destination $finalPckPath -Force

    $declarationPath = $declarationCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if ($declarationPath) {
        Write-LogLine "Copying declaration to $finalDeclarationPath"
        Copy-Item -LiteralPath $declarationPath -Destination $finalDeclarationPath -Force
    }
    else {
        Write-LogLine "Declaration file was not found. Skipping declaration copy."
    }

    Write-LogLine "Export completed successfully."
    Write-Host ""
    Write-Host "Export complete:"
    Write-Host "  DLL : $finalDllPath"
    Write-Host "  JSON: $finalJsonPath"
    Write-Host "  PCK : $finalPckPath"
    if (Test-Path -LiteralPath $finalDeclarationPath) {
        Write-Host "  DECL: $finalDeclarationPath"
    }
    Write-Host "  LOG : $logPath"
}
catch {
    Write-LogLine ("ERROR: " + $_.Exception.Message)
    Write-Error $_
    Write-Host "Export failed. Log file: $logPath"
    exit 1
}
