param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,

    [string]$ProjectName = (Split-Path $ProjectPath -Leaf),
    [int]$Port1 = 3000,
    [int]$Port2 = 8080,
    [int]$Port3 = 5000,
    [switch]$Fresh
)# Convert Windows path to WSL/Docker format
$ProjectPath = $ProjectPath -replace '\\', '/' -replace '^([A-Z]):', '/c'

# Check if Docker image exists, build if not
$imageExists = docker image inspect claude-sandbox-claude 2>$null
if (-not $imageExists) {
    Write-Host "Docker image not found. Building claude-sandbox-claude..."
    docker build -t claude-sandbox-claude .
}

Write-Host "Starting Claude sandbox for: $ProjectName"
Write-Host "Project path: $ProjectPath"
Write-Host "Ports: $Port1, $Port2, $Port3"

# Check if .claude directory exists for session resumption
$claudeArgs = "claude"
if (-not $Fresh -and (Test-Path "$($ProjectPath -replace '/c', 'C:' -replace '/', '\')\.claude")) {
    $claudeArgs = "claude --resume"
    Write-Host "Resuming previous Claude session..."
} else {
    Write-Host "Starting fresh Claude session..."
}

docker run -it --rm `
    --name "claude-$ProjectName" `
    -v "${ProjectPath}:/workspace" `
    -v "claude-config:/home/developer/.config" `
    -p "${Port1}:3000" `
    -p "${Port2}:8080" `
    -p "${Port3}:5000" `
    claude-sandbox-claude `
    bash -c $claudeArgs
