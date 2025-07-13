param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,
    
    [string]$ProjectName = (Split-Path $ProjectPath -Leaf),
    [int]$Port1 = 3000,
    [int]$Port2 = 8080,
    [int]$Port3 = 5000
)

# Convert Windows path to WSL/Docker format
$ProjectPath = $ProjectPath -replace '\\', '/' -replace '^([A-Z]):', '/c'

Write-Host "Starting Claude sandbox for: $ProjectName"
Write-Host "Project path: $ProjectPath"
Write-Host "Ports: $Port1, $Port2, $Port3"

docker run -it --rm `
    --name "claude-$ProjectName" `
    -v "${ProjectPath}:/workspace" `
    -v "claude-config:/home/developer/.config" `
    -p "${Port1}:3000" `
    -p "${Port2}:8080" `
    -p "${Port3}:5000" `
    claude-sandbox-claude `
    claude
