param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,

    [string]$ProjectName = (Split-Path $ProjectPath -Leaf),
    [int]$Port1 = 3000,
    [int]$Port2 = 8080,
    [int]$Port3 = 5000,
    [switch]$Fresh,
    [switch]$SelectConversation
)

# Convert Windows path to WSL/Docker format
$ProjectPath = $ProjectPath -replace '\\', '/' -replace '^([A-Z]):', '/c'

# Smart auto-build logic: Check if image needs rebuilding
$needsRebuild = $false
$imageExists = docker image inspect claude-sandbox-claude 2>$null

if (-not $imageExists) {
    Write-Host "Docker image not found. Building claude-sandbox-claude..."
    $needsRebuild = $true
} else {
    # Check if Dockerfile is newer than the existing image
    $dockerfilePath = "Dockerfile"
    if (Test-Path $dockerfilePath) {
        $dockerfileModified = (Get-Item $dockerfilePath).LastWriteTime

        # Get image creation time
        $imageCreated = docker image inspect claude-sandbox-claude --format='{{.Created}}' 2>$null
        if ($imageCreated) {
            try {
                $imageCreatedTime = [DateTime]::Parse($imageCreated)
                if ($dockerfileModified -gt $imageCreatedTime) {
                    Write-Host "Dockerfile modified since last build. Rebuilding claude-sandbox-claude..."
                    $needsRebuild = $true
                }
            } catch {
                Write-Host "Could not parse image creation time. Rebuilding to be safe..."
                $needsRebuild = $true
            }
        }
    }
}

if ($needsRebuild) {
    # Change to script directory for Docker build context
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    Push-Location $scriptDir

    docker build -t claude-sandbox-claude .
    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        Write-Error "Docker build failed!"
        exit 1
    }
    Pop-Location
}

Write-Host "Starting Claude sandbox for: $ProjectName"
Write-Host "Project path: $ProjectPath"
Write-Host "Ports: $Port1, $Port2, $Port3"

# Check if .claude directory exists for session resumption
$claudeArgs = "claude"
if ($Fresh) {
    Write-Host "Starting fresh Claude session..."
} elseif ($SelectConversation -and (Test-Path "$($ProjectPath -replace '/c', 'C:' -replace '/', '\')\.claude")) {
    $claudeArgs = "claude --resume"
    Write-Host "Opening conversation selection menu..."
} elseif (Test-Path "$($ProjectPath -replace '/c', 'C:' -replace '/', '\')\.claude") {
    $claudeArgs = "claude --continue || claude"
    Write-Host "Attempting to resume previous Claude session (will start fresh if no conversation found)..."
} else {
    Write-Host "Starting fresh Claude session..."
}

# Startup command that includes global setup
$startupCmd = "source /home/developer/.claude-startup.sh 2>/dev/null || true; $claudeArgs"

# Generate unique container name with timestamp
$timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
$containerName = "claude-$ProjectName-$timestamp"

docker run -it --rm `
    --name $containerName `
    -v "${ProjectPath}:/workspace" `
    -v "claude-config:/home/developer/.config" `
    -v "claude-npm-global:/usr/local/lib/node_modules" `
    -p "${Port1}:3000" `
    -p "${Port2}:8080" `
    -p "${Port3}:5000" `
    claude-sandbox-claude `
    bash -c $startupCmd
