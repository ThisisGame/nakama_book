# Windows部署测试脚本
Write-Host "=== CockroachDB Windows部署测试 ===" -ForegroundColor Cyan
Write-Host "时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White

# 测试1: 检查CockroachDB版本
Write-Host "`n[测试1] 检查CockroachDB版本..." -ForegroundColor Green
try {
    if (Test-Path ".\cockroach.exe") {
        $version = .\cockroach.exe version
        Write-Host "CockroachDB版本: $($version[0])" -ForegroundColor Green
    } else {
        Write-Host "未找到cockroach.exe" -ForegroundColor Red
    }
} catch {
    Write-Host "检查版本失败: $_" -ForegroundColor Red
}

# 测试2: 检查端口占用
Write-Host "`n[测试2] 检查端口占用..." -ForegroundColor Green
$ports = @(26257, 26258, 26259, 8080, 8081, 8082)
foreach ($port in $ports) {
    $process = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "端口 $port 被占用 (PID: $($process.OwningProcess))" -ForegroundColor Yellow
    } else {
        Write-Host "端口 $port 可用" -ForegroundColor Green
    }
}

# 测试3: 检查必需的文件
Write-Host "`n[测试3] 检查必需文件..." -ForegroundColor Green
$requiredFiles = @(
    "cockroach.exe",
    "start-windows-cluster.ps1",
    "stop-cluster.ps1"
)

foreach ($file in $requiredFiles) {
    if (Test-Path ".\$file") {
        Write-Host "找到: $file" -ForegroundColor Green
    } else {
        Write-Host "缺少: $file" -ForegroundColor Red
    }
}

Write-Host "`n=== 部署建议 ===" -ForegroundColor Cyan
Write-Host "1. Docker方式 (最简单):" -ForegroundColor Yellow
Write-Host "   运行: .\docker-simple.ps1" -ForegroundColor White
Write-Host "`n2. Windows服务方式 (最稳定):" -ForegroundColor Yellow
Write-Host "   需要管理员权限" -ForegroundColor White
Write-Host "   运行: .\install-all-services.ps1" -ForegroundColor White
Write-Host "`n3. 直接运行方式 (开发测试):" -ForegroundColor Yellow
Write-Host "   运行: .\start-windows-cluster.ps1" -ForegroundColor White
Write-Host "   停止: .\stop-cluster.ps1" -ForegroundColor White