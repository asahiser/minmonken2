# 設定
$draftFile = "draft.txt"
$postDir = "post"

# postフォルダがなければ作る
if (!(Test-Path $postDir)) { New-Item -ItemType Directory -Force -Path $postDir | Out-Null }

# draft.txt の読み込み
$content = Get-Content $draftFile -Encoding UTF8 -Raw
if (-not $content) { Write-Error "ドラフトファイル ($draftFile) が空か、見つかりません。"; exit }

# データの抽出（正規表現）
$title = if ($content -match "タイトル：(.+)") { $matches[1].Trim() } else { "無題" }
$author = if ($content -match "投稿者：(.+)") { $matches[1].Trim() } else { "匿名" }
$dateStr = if ($content -match "投稿日時：(.+)") { $matches[1].Trim() } else { Get-Date -Format "yyyy-MM-dd" }

# 本文の抽出（4行目以降を本文とみなす）
$lines = $content -split "`r`n|`n"
$bodyText = $lines[3..($lines.Length-1)] -join "`n"

# 本文をHTML形式に整形（段落タグをつける）
$bodyHtml = ""
foreach ($para in ($bodyText -split "`n`n")) { # 空行で段落分け
    if ($para.Trim() -ne "") {
        $bodyHtml += "<p>" + $para.Replace("`n", "<br>") + "</p>`n"
    }
}

# ファイル名の決定（日付.html）
# すでに同名のファイルがある場合は連番をつける処理を入れるとより安全ですが、今回は上書き仕様にします
$fileName = "$postDir\$dateStr.html"

# HTMLテンプレートへの流し込み
$htmlContent = @"
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title | 民族問題研究部</title>
    <link rel="stylesheet" href="../style.css">
    <script src="../js/common.js"></script>
</head>
<body>

<div class="academic-wrapper">
    <div id="header-part"></div>

    <div class="academic-container">
        <div id="sidebar-part"></div>

        <main class="academic-main">
            <article>
                <h2 class="document-title" style="margin-bottom:10px;">$title</h2>
                <div style="text-align:right; font-size:12px; color:#666; margin-bottom:30px; border-bottom:1px solid #eee; padding-bottom:10px;">
                    $dateStr / 文責：$author
                </div>
                
                <div class="document-body">
                    $bodyHtml
                </div>

                <div style="margin-top:50px; text-align:center;">
                    <a href="../index.html" style="font-size:12px;">← トップページに戻る</a>
                </div>
            </article>
        </main>
    </div>

    <div id="footer-part"></div>
</div>

</body>
</html>
"@

# ファイル書き出し
Set-Content -Path $fileName -Value $htmlContent -Encoding UTF8

Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host "記事を作成しました！" -ForegroundColor Green
Write-Host "保存先: $fileName"
Write-Host "----------------------------------------"