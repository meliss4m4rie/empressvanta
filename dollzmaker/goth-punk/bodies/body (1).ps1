#requires -Version 5.1

# Folder containing the Dollz Maker body GIFs
\$Folder = 'E:\DOCUMENTS\MELISSA\.DOLLZ STUFF\dollz assets\goth - punk\female\bodies'

# Safety switch:
# \$true  = only show what would happen
# \$false = actually rename files
\$PreviewOnly = \$false

# Prefix for the new filenames
\$NewNamePrefix = 'Body'

# Include files in subfolders?
\$IncludeSubfolders = \$false

# Create a CSV report in the same folder
\$ReportPath = Join-Path \$Folder 'body-color-groups-report.csv'


# ------------------------------------------------------------
# Convert a number to spreadsheet-style letters:
# 0  -> A
# 1  -> B
# 25 -> Z
# 26 -> AA
# 27 -> AB
# ------------------------------------------------------------
function ConvertTo-GroupLetters {
    param (
        [int]\$Number
    )

    \$Result = ''

    do {
        \$Remainder = \$Number % 26
        \$Result = [char](65 + \$Remainder) + \$Result
        \$Number = [math]::Floor(\$Number / 26) - 1
    }
    while (\$Number -ge 0)

    return \$Result
}


# ------------------------------------------------------------
# Get the most common exact opaque pixel color from a GIF
# ------------------------------------------------------------
function Get-DominantOpaqueColor {
    param (
        [string]\$FilePath
    )

    \$Bitmap = \$null

    try {
        \$Bitmap = New-Object System.Drawing.Bitmap(\$FilePath)

        \$ColorCounts = @{}

        for (\$Y = 0; \$Y -lt \$Bitmap.Height; \$Y++) {
            for (\$X = 0; \$X -lt \$Bitmap.Width; \$X++) {
                \$Pixel = \$Bitmap.GetPixel(\$X, \$Y)

                # Ignore transparent pixels
                if (\$Pixel.A -eq 0) {
                    continue
                }

                # Exact RGB color; alpha is intentionally excluded
                \$ColorKey = '{0:X2}{1:X2}{2:X2}' -f `
                    \$Pixel.R, \$Pixel.G, \$Pixel.B

                if (\$ColorCounts.ContainsKey(\$ColorKey)) {
                    \$ColorCounts[\$ColorKey]++
                }
                else {
                    \$ColorCounts[\$ColorKey] = 1
                }
            }
        }

        if (\$ColorCounts.Count -eq 0) {
            throw "No opaque pixels were found."
        }

        # Select the most common exact color
        \$Dominant = \$ColorCounts.GetEnumerator() |
            Sort-Object Value -Descending |
            Select-Object -First 1

        return [PSCustomObject]@{
            RGB        = \$Dominant.Key
            PixelCount = \$Dominant.Value
            Width      = \$Bitmap.Width
            Height     = \$Bitmap.Height
        }
    }
    finally {
        if (\$Bitmap) {
            \$Bitmap.Dispose()
        }
    }
}


# ------------------------------------------------------------
# Confirm the folder exists
# ------------------------------------------------------------
if (-not (Test-Path -LiteralPath \$Folder -PathType Container)) {
    throw "Folder not found: \$Folder"
}


# Load System.Drawing
Add-Type -AssemblyName System.Drawing


# Find GIF files
if (\$IncludeSubfolders) {
    \$Files = Get-ChildItem -LiteralPath \$Folder -Filter '*.gif' -File -Recurse
}
else {
    \$Files = Get-ChildItem -LiteralPath \$Folder -Filter '*.gif' -File
}

if (\$Files.Count -eq 0) {
    throw "No GIF files were found in: \$Folder"
}

Write-Host "Found \$(\$Files.Count) GIF file(s)." -ForegroundColor Cyan
Write-Host "Reading exact pixel colors..." -ForegroundColor Cyan


# Analyze each image
\$AnalyzedFiles = foreach (\$File in \$Files) {
    try {
        \$ColorInfo = Get-DominantOpaqueColor -FilePath \$File.FullName

        [PSCustomObject]@{
            OriginalPath       = \$File.FullName
            OriginalName       = \$File.Name
            Extension          = \$File.Extension
            ColorRGB            = \$ColorInfo.RGB
            DominantPixelCount  = \$ColorInfo.PixelCount
            Width               = \$ColorInfo.Width
            Height              = \$ColorInfo.Height
        }
    }
    catch {
        Write-Warning "Could not analyze '\$(\$File.Name)': \$(\$_.Exception.Message)"
    }
}


# Group images by exact dominant RGB color.
# Sorting by RGB makes letter assignment repeatable.
\$Groups = \$AnalyzedFiles |
    Group-Object -Property ColorRGB |
    Sort-Object Name


if (\$Groups.Count -gt 702) {
    throw "There are more than 702 color groups. Increase the letter-conversion scheme if needed."
}


# Build the rename plan
\$RenamePlan = @()
\$GroupNumber = 0

foreach (\$Group in \$Groups) {
    \$GroupLetter = ConvertTo-GroupLetters -Number \$GroupNumber

    # Sort files inside each color group by original filename
    \$GroupFiles = \$Group.Group | Sort-Object OriginalName
    \$FileNumber = 1

    foreach (\$Item in \$GroupFiles) {
        \$NewName = '{0}_{1}_{2:D3}{3}' -f `
            \$NewNamePrefix,
            \$GroupLetter,
            \$FileNumber,
            \$Item.Extension.ToLower()

        \$NewPath = Join-Path \$Folder \$NewName

        \$RenamePlan += [PSCustomObject]@{
            GroupLetter         = \$GroupLetter
            ColorRGB             = \$Item.ColorRGB
            OriginalName        = \$Item.OriginalName
            OriginalPath        = \$Item.OriginalPath
            NewName              = \$NewName
            NewPath              = \$NewPath
            DominantPixelCount   = \$Item.DominantPixelCount
            Width                = \$Item.Width
            Height               = \$Item.Height
        }

        \$FileNumber++
    }

    \$GroupNumber++
}


# Display summary
Write-Host ''
Write-Host "Found \$(\$Groups.Count) exact-color group(s)." -ForegroundColor Green
Write-Host ''

\$RenamePlan |
    Group-Object GroupLetter |
    Sort-Object Name |
    ForEach-Object {
        \$Example = \$_.Group | Select-Object -First 1

        Write-Host ('Group {0}: {1} file(s), RGB #{2}' -f `
            \$_.Name,
            \$_.Count,
            \$Example.ColorRGB)
    }

Write-Host ''
Write-Host 'Rename preview:' -ForegroundColor Cyan

\$RenamePlan |
    Sort-Object GroupLetter, OriginalName |
    ForEach-Object {
        Write-Host ('  {0}  ->  {1}' -f \$_.OriginalName, \$_.NewName)
    }


# Export report even during preview
\$RenamePlan |
    Select-Object GroupLetter, ColorRGB, OriginalName, NewName,
        DominantPixelCount, Width, Height |
    Export-Csv -LiteralPath \$ReportPath -NoTypeInformation -Encoding UTF8

Write-Host ''
Write-Host "Report saved to: \$ReportPath" -ForegroundColor DarkCyan


# Stop after preview
if (\$PreviewOnly) {
    Write-Host ''
    Write-Host 'PREVIEW ONLY: no files were renamed.' -ForegroundColor Yellow
    Write-Host 'Review the output and CSV report.' -ForegroundColor Yellow
    Write-Host 'Then change `\$PreviewOnly = \$false` and run the script again.' -ForegroundColor Yellow
    return
}


# ------------------------------------------------------------
# Two-step rename:
# First rename everything to temporary names to prevent collisions.
# Then rename to the final names.
# ------------------------------------------------------------
Write-Host ''
Write-Host 'Starting actual rename...' -ForegroundColor Yellow

\$TemporaryPlan = @()

foreach (\$Item in \$RenamePlan) {
    \$TempName = '__TEMP_BODY_RENAME_' + [guid]::NewGuid().ToString('N') + \$Item.Extension
    \$TempPath = Join-Path \$Folder \$TempName

    Rename-Item `
        -LiteralPath \$Item.OriginalPath `
        -NewName \$TempName `
        -ErrorAction Stop

    \$TemporaryPlan += [PSCustomObject]@{
        TempPath = \$TempPath
        NewName  = \$Item.NewName
        NewPath  = \$Item.NewPath
    }
}


# Rename temporary files to final names
foreach (\$Item in \$TemporaryPlan) {
    Rename-Item `
        -LiteralPath \$Item.TempPath `
        -NewName \$Item.NewName `
        -ErrorAction Stop
}

Write-Host ''
Write-Host "Finished. Renamed \$(\$RenamePlan.Count) file(s)." -ForegroundColor Green
Write-Host "CSV report: \$ReportPath" -ForegroundColor Green