# Kader Website - HTTP Server
# Run: powershell -ExecutionPolicy Bypass -File start-server.ps1

$port = 8000
$root = $PSScriptRoot
$ip   = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1).IPAddress

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  Kader Website is running!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Local:   http://localhost:$port" -ForegroundColor White
Write-Host "  Network: http://${ip}:$port" -ForegroundColor Yellow
Write-Host ""
Write-Host "  QR icin: qr.html dosyasini tarayicide ac" -ForegroundColor Green
Write-Host ""
Write-Host "  Durdurmak icin: Ctrl+C" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Prefixes.Add("http://127.0.0.1:$port/")
$listener.Start()

$mimeTypes = @{
  '.html' = 'text/html; charset=utf-8'
  '.css'  = 'text/css'
  '.js'   = 'application/javascript'
  '.json' = 'application/json'
  '.png'  = 'image/png'
  '.jpg'  = 'image/jpeg'
  '.jpeg' = 'image/jpeg'
  '.gif'  = 'image/gif'
  '.svg'  = 'image/svg+xml'
  '.ico'  = 'image/x-icon'
  '.webp' = 'image/webp'
}

while ($listener.IsListening) {
  try {
    $ctx  = $listener.GetContext()
    $req  = $ctx.Request
    $resp = $ctx.Response

    $urlPath = $req.Url.LocalPath
    if ($urlPath -eq '/') { $urlPath = '/index.html' }

    $filePath = Join-Path $root ($urlPath.TrimStart('/').Replace('/', '\'))

    if (Test-Path $filePath -PathType Leaf) {
      $ext  = [System.IO.Path]::GetExtension($filePath).ToLower()
      $mime = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { 'application/octet-stream' }
      $bytes = [System.IO.File]::ReadAllBytes($filePath)
      $resp.ContentType   = $mime
      $resp.ContentLength64 = $bytes.Length
      $resp.StatusCode    = 200
      $resp.OutputStream.Write($bytes, 0, $bytes.Length)
      Write-Host "  200  $urlPath" -ForegroundColor Green
    } else {
      $resp.StatusCode = 404
      $body = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
      $resp.OutputStream.Write($body, 0, $body.Length)
      Write-Host "  404  $urlPath" -ForegroundColor Red
    }

    $resp.OutputStream.Close()
  } catch {
    # silently continue on connection errors
  }
}
