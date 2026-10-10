$env:Path = "C:\Program Files\nodejs;" + $env:Path
$env:TYPE_SPEED = '0.4'
Set-Location D:\naverblog-auto
node src/login-post.js D:\aiproject\blog\songdo-haneulchae-ivy1-v3.json 2>&1 | Tee-Object D:\aiproject\blog\post-v3.log