# deploy-github.ps1
# GitHub Pages'e deploy scripti
# Gereksinimler: git (https://git-scm.com) + GitHub CLI (https://cli.github.com)
#
# Kullanim: PowerShell'de bu klasorde calistir:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\deploy-github.ps1

param(
    [string]$RepoName = "kader-website"
)

$ErrorActionPreference = "Stop"

Write-Host "`n[1/5] Gereksinimler kontrol ediliyor..." -ForegroundColor Magenta

# git kontrolu
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "HATA: git yuklu degil!" -ForegroundColor Red
    Write-Host "Lutfen https://git-scm.com adresinden yukleyin, sonra bu scripti tekrar calistirin." -ForegroundColor Yellow
    exit 1
}

# gh kontrolu
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "HATA: GitHub CLI (gh) yuklu degil!" -ForegroundColor Red
    Write-Host "Lutfen https://cli.github.com adresinden yukleyin, sonra bu scripti tekrar calistirin." -ForegroundColor Yellow
    exit 1
}

# gh login kontrolu
$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "HATA: GitHub CLI'ya giris yapilmamis!" -ForegroundColor Red
    Write-Host "Su komutu calistir: gh auth login" -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] git ve gh hazir" -ForegroundColor Green

# GitHub kullanici adini al
$ghUser = gh api user --jq ".login" 2>&1
Write-Host "[2/5] GitHub kullanicisi: $ghUser" -ForegroundColor Magenta

# Git init (eger yoksa)
Write-Host "[3/5] Git deposu baslatiliyor..." -ForegroundColor Magenta
if (-not (Test-Path ".git")) {
    git init
    git branch -M main
}

# .gitignore olustur
@"
# OS
.DS_Store
Thumbs.db
desktop.ini

# Editor
.vscode/
*.suo
*.user

# Scripts (deploy scripti publish edilmesin)
deploy-github.ps1
generate_qr.py
"@ | Set-Content .gitignore

# Commit
git add .
git commit -m "Ilk yuklemede: romantik website - 07 Mart 2025" 2>&1 | Out-Null
Write-Host "[OK] Commit tamamlandi" -ForegroundColor Green

# GitHub repo olustur
Write-Host "[4/5] GitHub reposu olusturuluyor: $RepoName ..." -ForegroundColor Magenta
$repoCheck = gh repo view "$ghUser/$RepoName" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "[BILGI] Repo zaten var, push yapiliyor..." -ForegroundColor Yellow
    git remote remove origin 2>&1 | Out-Null
    git remote add origin "https://github.com/$ghUser/$RepoName.git"
    git push -u origin main --force
} else {
    gh repo create $RepoName --public --source=. --push
}
Write-Host "[OK] Repo ve push tamamlandi" -ForegroundColor Green

# GitHub Pages aktifle
Write-Host "[5/5] GitHub Pages aktiflestirilliyor..." -ForegroundColor Magenta
$pagesPayload = '{"source":{"branch":"main","path":"/"}}'
$pagesResult = gh api "repos/$ghUser/$RepoName/pages" -X POST -H "Accept: application/vnd.github+json" --input - <<< $pagesPayload 2>&1

if ($LASTEXITCODE -ne 0) {
    # Belki zaten aktif, PUT ile guncelle
    gh api "repos/$ghUser/$RepoName/pages" -X PUT -H "Accept: application/vnd.github+json" -f "source[branch]=main" -f "source[path]=/" 2>&1 | Out-Null
}

$pageUrl = "https://$ghUser.github.io/$RepoName/"
Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host " BASARILI! Site yayinda (1-2 dakika bekle):" -ForegroundColor Green
Write-Host " $pageUrl" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

Write-Host "QR kodunu guncellemek icin qr.html'yi tarayicida ac," -ForegroundColor Yellow
Write-Host "'GitHub Pages' sekmesine gec ve su URL'yi gir:" -ForegroundColor Yellow
Write-Host "  $pageUrl" -ForegroundColor Cyan

# qr.html'yi varsayilan tarayicida ac
Start-Process "qr.html"
