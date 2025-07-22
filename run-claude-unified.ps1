param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,

    [string]$ProjectName = (Split-Path $ProjectPath -Leaf),

    # Port configuration (only used if ForwardPorts is enabled)
    [int]$Port1 = 3001,
    [int]$Port2 = 8081,
    [int]$Port3 = 5001,

    # Session mode flags
    [switch]$Fresh,
    [switch]$Resume,
    [switch]$SelectConversation,

    # Instance and port forwarding
    [string]$Instance = "default",
    [switch]$ForwardPorts
)

# Convert Windows path to WSL/Docker format
$ProjectPath = $ProjectPath -replace '\\', '/' -replace '^([A-Z]):', '/c'

# Display version and instance information
if (Test-Path "VERSION") {
    $versionContent = Get-Content "VERSION" | ForEach-Object {
        if ($_ -match "CLAUDE_SANDBOX_VERSION=(.+)") {
            $version = $matches[1]
            $portInfo = if ($ForwardPorts) { " (ports: $Port1,$Port2,$Port3)" } else { "" }

            if ($Instance -eq "default") {
                Write-Host "🚀 Claude Sandbox $version$portInfo - Starting..." -ForegroundColor Green
            } else {
                Write-Host "🚀 Claude Sandbox $version [$Instance]$portInfo - Starting..." -ForegroundColor Green
            }
        }
    }
}

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
                Write-Host "Could not compare timestamps. Rebuilding to be safe..."
                $needsRebuild = $true
            }
        } else {
            Write-Host "Could not get image creation time. Rebuilding to be safe..."
            $needsRebuild = $true
        }
    }
}

if ($needsRebuild) {
    docker build -t claude-sandbox-claude .
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker build failed!"
        exit 1
    }
}

Write-Host "Starting Claude sandbox for: $ProjectName"
Write-Host "Project path: $ProjectPath"
if ($Instance -ne "default") {
    Write-Host "Instance: $Instance"
}

# Determine Claude command based on session flags
$claudeCmd = "claude"
if ($Fresh) {
    $claudeCmd = "claude"
    Write-Host "Starting fresh Claude session..."
} elseif ($Resume) {
    $claudeCmd = "claude --resume"
    Write-Host "Resuming previous Claude session..."
} elseif ($SelectConversation) {
    $claudeCmd = "claude --select-conversation"
    Write-Host "Starting Claude with conversation selection..."
} else {
    # Auto mode: resume if .claude exists, otherwise fresh
    $claudePath = Join-Path ($ProjectPath -replace '^/c', 'C:' -replace '/', '\') ".claude"
    if (Test-Path $claudePath) {
        $claudeCmd = "claude --continue || claude"
        Write-Host "Attempting to resume previous Claude session (will start fresh if no conversation found)..."
    } else {
        Write-Host "Starting fresh Claude session..."
    }
}

# Generate instance-specific container and volume names
if ($Instance -eq "default") {
    if ($ForwardPorts) {
        $containerName = "claude-$ProjectName"
    } else {
        $containerName = "claude-$ProjectName-noports"
    }
    $configVolume = "claude-config"
} else {
    if ($ForwardPorts) {
        $containerName = "claude-$ProjectName-$Instance"
    } else {
        $containerName = "claude-$ProjectName-noports-$Instance"
    }
    $configVolume = "claude-config-$Instance"
}

Write-Host "Container: $containerName"
Write-Host "Config volume: $configVolume"

# Build Docker run command
$dockerArgs = @(
    "run", "-it", "--rm",
    "--name", $containerName,
    "-v", "$ProjectPath" + ":/workspace",
    "-v", "$configVolume" + ":/home/developer/.config",
    "-v", "claude-npm-global:/usr/local/lib/node_modules"
)

# Add port forwarding if requested
if ($ForwardPorts) {
    $dockerArgs += @(
        "-p", "$Port1" + ":3000",
        "-p", "$Port2" + ":8080",
        "-p", "$Port3" + ":5000"
    )
    Write-Host "Port forwarding: $Port1→3000, $Port2→8080, $Port3→5000"
} else {
    Write-Host "No ports exposed (secure mode)"
}

# Complete the command
$startupCmd = "source /home/developer/.claude-startup.sh 2>/dev/null || true; $claudeCmd"
$dockerArgs += @("claude-sandbox-claude", "bash", "-c", $startupCmd)

# Execute the Docker command
& docker @dockerArgs
