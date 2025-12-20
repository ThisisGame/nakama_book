# Windows原生多节点启动脚本（修正版）
param(
    [switch]$ShowWindows = $true
)

$ErrorActionPreference = "Stop"

# 配置节点
$nodes = @(
    @{Name="node1"; Port=26257; HttpPort=7070; Store="cockroach-data-1"},
    @{Name="node2"; Port=26258; HttpPort=7071; Store="cockroach-data-2"},
    @{Name="node3"; Port=26259; HttpPort=7072; Store="cockroach-data-3"}
)

# 清理旧进程
Write-Host "停止现有CockroachDB进程..." -ForegroundColor Yellow
Get-Process -Name "cockroach" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 3

# 清理数据目录
foreach ($node in $nodes) {
    $storePath = $node.Store
    if (Test-Path $storePath) {
        Remove-Item -Recurse -Force $storePath
    }
    New-Item -ItemType Directory -Path $storePath -Force | Out-Null
}

# 启动节点
$processes = @()
Write-Host "正在启动节点..." -ForegroundColor Green

foreach ($node in $nodes) {
    $joinList = ($nodes | ForEach-Object { "localhost:$($_.Port)" }) -join ","
    
    $arguments = @(
        "start",
        "--insecure",
        "--store=$($node.Store)",
        "--listen-addr=localhost:$($node.Port)",
        "--http-addr=localhost:$($node.HttpPort)",
        "--join=$joinList"
    )
    
    Write-Host "启动 $($node.Name) (端口: $($node.Port))..." -ForegroundColor Cyan
    
    if ($ShowWindows) {
        # 方式1：显示窗口（开发调试用）
        $process = Start-Process -FilePath ".\cockroach.exe" `
            -ArgumentList $arguments `
            -WindowStyle Normal `
            -PassThru
    } else {
        # 方式2：隐藏窗口运行（生产推荐）
        $process = Start-Process -FilePath ".\cockroach.exe" `
            -ArgumentList $arguments `
            -WindowStyle Hidden `
            -PassThru `
            -RedirectStandardOutput "$($node.Store)\stdout.log" `
            -RedirectStandardError "$($node.Store)\stderr.log"
    }
    
    $processes += $process
    Start-Sleep -Seconds 2
}

# 保存进程ID以便后续管理
$processes | ForEach-Object { 
    [PSCustomObject]@{
        Node = $nodes[$processes.IndexOf($_)]
        ProcessId = $_.Id
    } | ConvertTo-Json | Set-Content ".\processes.json"
}

# 等待节点启动
Write-Host "等待节点启动..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# 初始化集群
Write-Host "初始化集群..." -ForegroundColor Green
try {
    $initArgs = @(
        "init",
        "--insecure",
        "--host=localhost:$($nodes[0].Port)"
    )
    
    $initProcess = Start-Process -FilePath ".\cockroach.exe" `
        -ArgumentList $initArgs `
        -NoNewWindow `
        -Wait `
        -RedirectStandardOutput ".\init-output.log" `
        -RedirectStandardError ".\init-error.log"
    
    if (Test-Path ".\init-error.log") {
        $initError = Get-Content ".\init-error.log"
        if ($initError -and $initError -notlike "*cluster has already been initialized*") {
            Write-Host "初始化可能失败: $initError" -ForegroundColor Red
        }
    }
    
    Write-Host "集群初始化完成" -ForegroundColor Green
} catch {
    Write-Host "初始化出错: $_" -ForegroundColor Red
}

# 检查状态
Write-Host "`n=== 集群状态 ===" -ForegroundColor Cyan
try {
    $statusArgs = @(
        "node",
        "status",
        "--insecure",
        "--host=localhost:$($nodes[0].Port)"
    )
    
    Start-Process -FilePath ".\cockroach.exe" `
        -ArgumentList $statusArgs `
        -NoNewWindow `
        -Wait
} catch {
    Write-Host "无法获取状态: $_" -ForegroundColor Red
}

# 显示访问信息
Write-Host "`n=== 访问信息 ===" -ForegroundColor Green
foreach ($node in $nodes) {
    Write-Host "$($node.Name):" -ForegroundColor Yellow
    Write-Host "  SQL: localhost:$($node.Port)" -ForegroundColor White
    Write-Host "  Web UI: http://localhost:$($node.HttpPort)" -ForegroundColor White
    Write-Host "  日志文件: $($node.Store)\*.log" -ForegroundColor Gray
}

Write-Host "`n使用示例:" -ForegroundColor Cyan
Write-Host "  .\cockroach sql --insecure --host=localhost:26257" -ForegroundColor White
Write-Host "`n管理命令:" -ForegroundColor Cyan
Write-Host "  .\stop-cluster.ps1     # 停止集群" -ForegroundColor White
Write-Host "  .\check-status.ps1     # 检查状态" -ForegroundColor White