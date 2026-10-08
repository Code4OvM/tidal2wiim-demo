param([Parameter(Mandatory=$true)][string]$PlantUmlJar)
$ErrorActionPreference = "Stop"
$jar = (Resolve-Path $PlantUmlJar).Path
$sources = Get-ChildItem (Join-Path $PSScriptRoot "PlantUML") -Filter "*.puml" | Sort-Object Name | ForEach-Object { $_.FullName }
foreach ($format in @("svg", "png")) {
    $folder = $format.ToUpper()
    New-Item -ItemType Directory -Force -Path (Join-Path $PSScriptRoot $folder) | Out-Null
    & java -Djava.awt.headless=true -jar $jar -charset UTF-8 "-t$format" -o "../$folder" @sources
    if ($LASTEXITCODE -ne 0) { throw "PlantUML-Export fehlgeschlagen: $format" }
}
Write-Host "Alle Diagramme wurden in SVG/ und PNG/ erzeugt."
