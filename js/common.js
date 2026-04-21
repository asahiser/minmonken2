// -----------------------------------------------------------------------------
// common.js
// -----------------------------------------------------------------------------
// このファイルは同一オリジンに置かれた信頼できる静的HTMLパーツ
// （parts/header.html, parts/sidebar.html, parts/footer.html）を読み込んで
// 指定した要素に差し込むためのユーティリティです。
//
// 【セキュリティ上の注意】
// loadPart() は取得したHTMLを innerHTML に代入します。
// このため、以下の原則を必ず守ってください：
//   1) filePath は必ず自サイト（同一オリジン）の信頼できる静的ファイルに限る
//   2) ユーザー入力や外部APIからのHTMLをこの関数に渡さない
//   3) 新しいパーツを追加する場合は、そのパーツの内容がリポジトリ管理下
//      （＝コードレビュー可能な状態）であることを確認する
// 上記に該当しない動的HTMLを挿入したい場合は、DOMParser + replaceChildren()
// など、スクリプトが実行されない方法で差し込んでください。
// -----------------------------------------------------------------------------

// 指定したIDの要素に、外部HTMLファイルを読み込む関数
async function loadPart(elementId, filePath) {
    try {
        const response = await fetch(filePath);
        if (!response.ok) {
            throw new Error('HTTP error! status: ' + response.status);
        }
        const html = await response.text();

        // 読み込んだパーツ内のリンク（a href, src）を階層に合わせて補正する
        // "index.html" -> "../index.html" のように
        const pathPrefix = getPathPrefix();
        const adjustedHtml = html.replace(/(href="|src=")(?!http|#|\/|data:|javascript:)([^"]+)/g, (match, p1, p2) => {
            return p1 + pathPrefix + p2;
        });

        // 信頼済みパーツのみが渡される前提での innerHTML 利用
        // （上部コメント参照）
        document.getElementById(elementId).innerHTML = adjustedHtml;
    } catch (e) {
        console.error('パーツ読み込みエラー: ' + filePath, e);
    }
}

// 現在のファイル位置からルートへの相対パス（../）を計算する
function getPathPrefix() {
    // URLに '/post/' が含まれていたら1階層下とみなす
    return location.pathname.includes('/post/') ? '../' : '';
}

// ページの読み込みが終わったら実行
document.addEventListener("DOMContentLoaded", function() {
    const prefix = getPathPrefix();
    loadPart("header-part", prefix + "parts/header.html");
    loadPart("sidebar-part", prefix + "parts/sidebar.html");
    loadPart("footer-part", prefix + "parts/footer.html");
});
