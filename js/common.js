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
        const adjustedHtml = html.replace(/(href="|src=")(?!http|#|\/)([^"]+)/g, (match, p1, p2) => {
            return p1 + pathPrefix + p2;
        });

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