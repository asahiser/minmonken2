# minmonken2 セキュリティレビュー報告書

レビュー対象：`C:\Users\hugog\minmonken2`（民族問題研究部 公式サイトのソースコード）
レビュー日：2026年4月21日

---

## 総評

本サイトは静的HTML＋少量のJavaScript＋ローカル実行のPowerShell記事生成スクリプトで構成されており、サーバーサイド処理やユーザー入力フォームは存在しません。そのため、一般的なWebアプリで懸念されるSQLインジェクションやCSRF等のリスクはありません。ただし、**記事生成スクリプトのHTMLインジェクション**、**クライアントサイドJSの `innerHTML` 使用**、**運用管理（.gitignoreなし等）**に関しては改善が望まれます。重大度「高」の問題は1件、「中」は3件、「低」は5件を検出しました。

---

## 【重大度：高】

### H-1. `publish.ps1` のHTMLインジェクション脆弱性

`publish.ps1` では `draft.txt` から取得した `$title`、`$author`、`$bodyText` をエスケープ処理せずにそのままHTMLテンプレートへ埋め込んでいます。

```powershell
$bodyHtml += "<p>" + $para.Replace("`n", "<br>") + "</p>`n"
<title>$title | 民族問題研究部</title>
<h2 class="document-title">$title</h2>
$dateStr / 文責：$author
<div class="document-body">$bodyHtml</div>
```

draft.txtの投稿者欄や本文に `<script>`、`<iframe>`、`onerror=` 等のHTMLタグが含まれていれば、そのまま生成されるHTMLへ注入されます。個人運用でdraftの中身が完全に信頼できる場合は実害は小さいものの、他の部員がdraftを書く運用になった場合、あるいは外部テキストをコピペした際に危険です。

**対策例**：PowerShell側でHTMLエンコードを挟む。

```powershell
Add-Type -AssemblyName System.Web
$titleEsc  = [System.Web.HttpUtility]::HtmlEncode($title)
$authorEsc = [System.Web.HttpUtility]::HtmlEncode($author)
# 本文も段落ごとにエンコードしてから <br> を付与する
```

---

## 【重大度：中】

### M-1. `common.js` が `innerHTML` で取得HTMLを注入している

`js/common.js:17`：

```javascript
document.getElementById(elementId).innerHTML = adjustedHtml;
```

現時点では同一オリジンの静的ファイル（`parts/header.html` 等）を読み込むだけなのでリスクは限定的ですが、以下のリスクが残ります。

- GitHubアカウントやホスティング（eth.limo）が乗っ取られて `parts/sidebar.html` 等が差し替えられた場合、スクリプトがそのままDOMへ流し込まれる。
- 将来、記事本文や外部APIの応答を同じ関数で取り込むコードを追加した際に脆弱性が顕在化しやすい。
- `href`/`src` 書き換えの正規表現は、属性値内のクォート扱いや `data:` などのスキームを考慮しておらず、パーツ側の書式次第で誤置換される可能性があります。

**対策**：信頼できるパーツのみに限定することをコメントで明示化し、将来的には `DOMParser` でパースして `element.replaceChildren(...)` で差し替える、あるいは `<template>` 要素 や `<iframe srcdoc>` 等で分離することを検討。

### M-2. `.gitignore` が存在しない

リポジトリ直下に `.gitignore` がありません。今後 `.env`、Illustratorバックアップ、APIキー、個人メモ等を不用意にコミットするリスクがあります。

**対策**：最低限、以下のような `.gitignore` を追加してください。

```
# OS/エディタ生成ファイル
.DS_Store
Thumbs.db
*.swp
*.bak

# 秘密情報
.env
.env.*
*.pem
*.key
credentials*.json

# Illustrator一時ファイル
~*.ai
```

### M-3. リモート先が公開GitHub（`asahiser/minmonken2`）で、`draft.txt` 等もコミット対象

`draft.txt` には投稿者名や下書き本文が入っており、これがそのまま公開リポジトリへ push される可能性があります。公開前提の内容なら問題ありませんが、「公開したくない下書き」もうっかりコミットする可能性があります。

**対策**：`draft.txt` は `.gitignore` に追加してローカル専用にする。または `drafts/` フォルダを切ってまとめて除外する。

---

## 【重大度：低】

### L-1. `run_publish.bat`、`run_publish.bat.txt`、`run_publish.txt` が3つ存在する

内容がまったく同じ3ファイルが直下にあります。`.txt` 拡張子付きを誤って実行しようとすると、メモ帳が開くだけで混乱のもとです。1つに整理するか、`.txt` の方を削除することを推奨します。

### L-2. PowerShell 実行時に `-ExecutionPolicy Bypass` を常用

`run_publish.bat` で `-ExecutionPolicy Bypass` を指定しています。ローカル自分専用ツールとしては一般的ですが、配布する場合や他者に渡す場合は `-ExecutionPolicy RemoteSigned` の方が安全です。`Bypass` では `publish.ps1` が書き換えられても警告なしに任意コードが動作するため、スクリプトの完全性を運用で守る必要があります。

### L-3. Content Security Policy (CSP) の欠如

全HTMLに `<meta http-equiv="Content-Security-Policy" ...>` が設定されていません。XSSが入り込んだ場合の緩和策として、最低限以下のようなCSPをヘッダに追加することを推奨します。

```html
<meta http-equiv="Content-Security-Policy"
      content="default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'">
```

※ インラインstyle属性を多用しているため、`style-src` には当面 `'unsafe-inline'` が必要です。将来的にはスタイルをCSSファイル側へ移して `'unsafe-inline'` を外すのが理想。

### L-4. HTML構造の不整合

`about_us.html` と `syuisyo.html` には `<body>` 開始タグがありません（`</head>` の直後にいきなり `<div class="academic-wrapper">` が来ている）。ブラウザは寛容に解釈しますが、一部のセキュリティスキャナやアクセシビリティツールが誤判定する可能性があります。

### L-5. プライバシーポリシー記載の連絡先が個人のXアカウントのみ

`privacy.html` で連絡窓口がXのDM（`@asti0422`）のみになっています。個人情報保護法上の「開示・訂正等の請求窓口」として、団体名義のメールや問い合わせフォーム窓口を別途用意するとより堅牢な体制を示せます（運用面の推奨）。

---

## 確認したがリスク無し

- 外部CDN呼び出し：なし
- パスワード／APIキーのハードコード：`grep` で一切検出されず
- `eval`、`document.write`、`onerror=`、`onload=`、`javascript:` スキームの使用：なし（`common.js` の `innerHTML` のみ）
- ユーザー入力フォーム：なし（サイト内に `<form>`、`<input>` が存在しない）
- 外部スクリプトの読み込み：なし（同一オリジンの `js/common.js` のみ）

---

## 優先対応リスト（推奨順）

1. `publish.ps1` にHTMLエスケープを追加する（H-1）
2. `.gitignore` を作成して、`draft.txt`・機密ファイル・OSゴミファイルを除外する（M-2, M-3）
3. 冗長な `run_publish.*.txt` ファイルを削除する（L-1）
4. 全HTMLにCSPメタタグを追加する（L-3）
5. `common.js` の注入経路を将来の変更から守るためコメント付きガードを追加（M-1）

以上です。
