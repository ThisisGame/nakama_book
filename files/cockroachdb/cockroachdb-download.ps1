# 下载CockroachDB Windows版本
$version = "v22.2.19"
$url = "https://binaries.cockroachdb.com/cockroach-$version.windows-6.2-amd64.zip"
$output = "cockroach-$version.zip"

Write-Host "正在下载CockroachDB $version..." -ForegroundColor Green
Invoke-WebRequest -Uri $url -OutFile $output

Write-Host "正在解压..." -ForegroundColor Green
Expand-Archive -Path $output -DestinationPath ".\cockroach-$version" -Force

# 复制到工作目录
Copy-Item -Path ".\cockroach-$version\cockroach-$version.windows-6.2-amd64\cockroach.exe" -Destination ".\" -Force

Write-Host "安装完成！" -ForegroundColor Green