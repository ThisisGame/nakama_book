# 停止Windows上的CockroachDB集群
Write-Host "正在停止CockroachDB集群..." -ForegroundColor Yellow

# 方法1：通过进程名停止
$cockroachProcesses = Get-Process -Name "cockroach" -ErrorAction SilentlyContinue
if ($cockroachProcesses) {
    Write-Host "发现 $($cockroachProcesses.Count) 个CockroachDB进程" -ForegroundColor Cyan
    $cockroachProcesses | Stop-Process -Force
    Write-Host "已停止所有进程" -ForegroundColor Green
} else {
    Write-Host "未找到运行的CockroachDB进程" -ForegroundColor Yellow
}

# 方法2：通过保存的进程ID停止
# if (Test-Path ".\processes.json") {
    # $savedProcesses = Get-Content ".\processes.json" | ConvertFrom-Json
    # foreach ($proc in $savedProcesses) {
        # try {
            # Get-Process -Id $proc.ProcessId -ErrorAction SilentlyContinue | Stop-Process -Force
            # Write-Host "已停止进程 $($proc.Node.Name) (PID: $($proc.ProcessId))" -ForegroundColor Green
        # } catch {
            # Write-Host "进程 $($proc.ProcessId) 已停止" -ForegroundColor Gray
        # }
    # }
    # Remove-Item ".\processes.json" -Force
# }

# 检查是否还有残留进程
Start-Sleep -Seconds 2
$remaining = Get-Process -Name "cockroach" -ErrorAction SilentlyContinue
if ($remaining) {
    Write-Host "警告: 仍有 $($remaining.Count) 个进程在运行" -ForegroundColor Red
    $remaining | Format-Table Id, Name, StartTime
} else {
    Write-Host "所有CockroachDB进程已成功停止" -ForegroundColor Green
}