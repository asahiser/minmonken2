# 設定
$draftFile = "draft.txt"
$postDir = "post"

# postフォルダがなければ作る
if (!(Test-Path $postDir)) { New-Item -ItemType Directory -Force -Path $postDir | Out-Null }

# draft.txt の読み込み
$content = Get-Content $draftFile -Encoding UTF8 -Raw
if (-not $content) { Write-Error "ドラフトファイル ($draftFile) が空か、見つかりません。"; exit }

# HTMLエスケープ用のユーティリティを読み込む
Add-Type -AssemblyName System.Web

# 文字列をHTMLセーフに変換する関数（< > & " ' を実体参照へ）
function ConvertTo-HtmlSafe {
    param([string]$s)
    if ($null -eq $s) { return "" }
    return [System.Web.HttpUtility]::HtmlEncode($s)
}

# データの抽出（正規表現）
$title = if ($content -match "タイトル：(.+)") { $matches[1].Trim() } else { "無題" }
$author = if ($content -match "投稿者：(.+)") { $matches[1].Trim() } else { "匿名" }
$dateStr = if ($content -match "投稿日時：(.+)") { $matches[1].Trim() } else { Get-Date -Format "yyyy-MM-dd" }

# 日付文字列のバリデーション（ファイル名として安全な形式のみ許可）
if ($dateStr -notmatch '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') {
    Write-Warning "投稿日時の形式が想定外のため、本日の日付を使用します。: $dateStr"
    $dateStr = Get-Date -Format "yyyy-MM-dd"
}

# 本文の抽出（4行目以降を本文とみなす）
$lines = $content -split "`r`n|`n"
$bodyText = $lines[3..($lines.Length-1)] -join "`n"

# 本文をHTML形式に整形
# 1. 段落ごとに区切る（空行で分割）
# 2. 各段落をHTMLエスケープ
# 3. 改行を <br> に置換（エスケープ後に行うことでタグ注入を防ぐ）
$bodyHtml = ""
foreach ($para in ($bodyText -split "`n`n")) {
    if ($para.Trim() -ne "") {
        $paraEscaped = ConvertTo-HtmlSafe $para
        $paraWithBr = $paraEscaped -replace "`n", "<br>"
        $bodyHtml += "<p>" + $paraWithBr + "</p>`n"
    }
}

# タイトル・投稿者もエスケープ
$titleSafe  = ConvertTo-HtmlSafe $title
$authorSafe = ConvertTo-HtmlSafe $author
$dateSafe   = ConvertTo-HtmlSafe $dateStr

# ファイル名の決定（日付.html）
$fileName = "$postDir\$dateStr.html"

# HTMLテンプレートへの流し込み
$htmlContent = @"
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="Content-Security-Policy" content="default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'">
    <title>$titleSafe | 民族問題研究部</title>
    <link rel="stylesheet" href="../style.css">
</head>
<body>

<div class="academic-wrapper">
    <link rel="icon" href="../minmonken_simplified_logo.png" type="image/png">
<header class="academic-header">
    <img src="../logo_minmonken.svg" alt="民族問題研究部ロゴ" width="200">
</header>

    <div class="academic-container">
        <nav class="academic-sidebar">
    <ul>
        <li><a href="../index.html">トップページ</a></li>
        <li>資料
            <ul>
                <li><a href="../syuisyo.html">設立趣意書</a></li>
                <li><a href="../about_us.html">私たちについて</a></li>
                <li>勉強会
                    <ul>
                        <li><a href="../gasshuku01.html">第一回民問研合宿</a></li>
                        <li><a href="../post/2026-02-20.html">リバタリアン・ナショナリズム批判</a></li>
                    </ul>
                </li>
                <li>講演会
                    <ul>
                        <li><a href="../koenkai01.html">第一回特別講演会</a></li>
                        <li><a href="../koenkai02.html">第二回特別講演会</a></li>
                    </ul>
                </li>
                <li><a href="../statements.html">その他声明文など</a></li>
                <li><a href="../junbi.html">ニュース翻訳</a></li>
            </ul>
        </li>
        <li>組織
            <ul><li><a href="../activities.html">研究活動</a></li>
                <li><a href="../junbi.html">規則類</a></li>
                <li>組織構成
                    <ul>
                        <li>部会
                            <ul>
                                <li><span class="pending">ナショナリズム部会</span></li>
                                <li><span class="pending">人権問題部会</span></li>
                                <li><span class="pending">政治学部会</span></li>
                            </ul>
                        </li>
                        <li>研究会
                            <ul>
                                <li><a href="../myanmar.html">ミャンマー問題研究会</a></li>
                                <li><a href="../junbi.html">クルド問題研究会</a></li>
                            </ul>
                        </li>
                    </ul>
                </li>
            </ul>
        </li>
        <li>入部案内
            <ul>
                <li><span class="pending">準備中</span></li>
            </ul>
        </li>
        <li>その他
            <ul>
                <li><a href="../privacy.html">プライバシーポリシー</a></li>
                <li><a href="../junbi.html">リンク集</a></li>
                <li><a href="../junbi.html">サイトマップ</a></li>
            </ul>
        </li>
    </ul>
</nav>

        <main class="academic-main">
            <article>
                <h2 class="document-title">$titleSafe</h2>
                <div class="post-meta">
                    $dateSafe / 文責：$authorSafe
                </div>

                <div class="document-body">
                    $bodyHtml
                </div>

                <div class="back-link">
                    <a href="../index.html">← トップページに戻る</a>
                </div>
            </article>
        </main>
    </div>

    <footer class="academic-footer">
    &copy; 2026 民族問題研究部 All Rights Reserved.
</footer>

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
