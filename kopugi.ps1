# 커푸기: 커밋 + 푸시 + 기록
Set-Location $PSScriptRoot
$env:Path = "C:\Program Files\Git\cmd;" + $env:Path
function Fail($m){ Write-Host "[중단] $m" -ForegroundColor Red; exit 1 }
if(-not (Get-Command git -ErrorAction SilentlyContinue)){ Fail "git이 설치되어 있지 않습니다. 설치: winget install Git.Git" }
git rev-parse --is-inside-work-tree *> $null
if($LASTEXITCODE -ne 0){ Fail "git 저장소가 아닙니다. 먼저 git init 이 필요합니다." }
if(-not (git remote)){ Fail "remote가 없습니다. 설정: git remote add origin <저장소URL>" }
if(-not (git status --porcelain)){ Write-Host "커밋할 변경 없음"; exit 0 }

git add -A
git reset -q -- .env '*.env' '*.key' '*.pem' 2>$null
$hit = git diff --cached -U0 | Select-String -Pattern '(api[_-]?key|secret|token|password|passwd)\s*[:=]\s*\S{8,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}' -CaseSensitive:$false
if($hit){ git reset -q; Fail "시크릿으로 의심되는 내용이 있어 중단했습니다:`n$($hit | Select-Object -First 3 | Out-String)" }

$n = (git diff --cached --name-only | Measure-Object).Count
$now = Get-Date -Format 'yyyy-MM-dd HH:mm'
git commit -q -m "커푸기: ${n}개 파일 변경 ($now)"
if($LASTEXITCODE -ne 0){ Fail "commit 실패" }
$hash = git rev-parse --short HEAD
$summary = (git show --stat --oneline --no-color HEAD | Select-Object -Skip 1 | Select-Object -Last 1).Trim()

$log = Join-Path $PSScriptRoot 'CHANGELOG.md'
$old = if(Test-Path $log){ Get-Content $log -Raw -Encoding UTF8 } else { "# CHANGELOG`n`n" }
$head = "# CHANGELOG`n`n"; $body = if($old.StartsWith($head)){ $old.Substring($head.Length) } else { $old }
[IO.File]::WriteAllText($log, $head + "- $now / $hash / ${n}개 파일, $summary`n" + $body, (New-Object Text.UTF8Encoding $false))
git add CHANGELOG.md
git commit -q -m "기록: CHANGELOG ($hash)"

$out = git push 2>&1
if($LASTEXITCODE -ne 0){ $out = git push -u origin HEAD 2>&1 }
if($LASTEXITCODE -ne 0){ Fail "push 실패: $out" }
Write-Host "완료  커밋 $hash / push 성공 / CHANGELOG 기록됨" -ForegroundColor Green