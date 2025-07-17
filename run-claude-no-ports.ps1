param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,

    [string]$ProjectName = (Split-Path $ProjectPath -Leaf),
    [switch]$Resume
)

# Convert Windows path to WSL/Docker format
$ProjectPath = $ProjectPath -replace '\\', '/' -replace '^([A-Z]):', '/c'

# Check if Docker image exists, build if not
$imageExists = docker image inspect claude-sandbox-claude 2>$null
if (-not $imageExists) {
    Write-Host "Docker image not found. Building claude-sandbox-claude..."
    docker build -t claude-sandbox-claude .
}

Write-Host "Starting Claude sandbox for: $ProjectName (no ports)"
Write-Host "Project path: $ProjectPath"

# Check if .claude directory exists for session resumption
$claudeArgs = "claude"
if ($Resume -or (Test-Path "$($ProjectPath -replace '/c', 'C:' -replace '/', '\')\.claude")) {
    $claudeArgs = "claude --resume"
    Write-Host "Resuming previous Claude session..."
}

docker run -it --rm `
    --name "claude-$ProjectName-noports" `
    -v "${ProjectPath}:/workspace" `
    -v "claude-config:/home/developer/.config" `
    claude-sandbox-claude `
    bash -c $claudeArgs
