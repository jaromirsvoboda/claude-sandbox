param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,

    [string]$ProjectName = (Split-Path $ProjectPath -Leaf)
)

$env:PROJECT_PATH = $ProjectPath
$env:PROJECT_NAME = $ProjectName

Write-Host "Starting Claude sandbox for: $ProjectName"
Write-Host "Project path: $ProjectPath"

docker-compose up -d
docker-compose exec claude claude
