param(
    [string]$ProjectName,
    [string]$ConfigFile = "config.json"
)

# Load configuration
if (-not (Test-Path $ConfigFile)) {
    Write-Error "Config file '$ConfigFile' not found. Copy config.example.json to config.json first."
    exit 1
}

$config = Get-Content $ConfigFile | ConvertFrom-Json

# Determine project
if (-not $ProjectName) {
    $ProjectName = $config.default_project
    Write-Host "Using default project: $ProjectName"
}

if (-not $config.projects.$ProjectName) {
    Write-Error "Project '$ProjectName' not found in config file."
    Write-Host "Available projects:" $config.projects.PSObject.Properties.Name
    exit 1
}

$project = $config.projects.$ProjectName
$projectPath = $project.path -replace '\\', '/' -replace '^([A-Z]):', '/c'

Write-Host "Starting Claude sandbox for: $ProjectName"
Write-Host "Project path: $($project.path)"

docker run -it --rm `
    --name "claude-$ProjectName" `
    -v "${projectPath}:/workspace" `
    -v "claude-config:/home/developer/.config" `
    -p "$($project.ports.web):3000" `
    -p "$($project.ports.api):8080" `
    -p "$($project.ports.dev):5000" `
    claude-sandbox-claude `
    claude
