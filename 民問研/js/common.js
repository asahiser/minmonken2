// 指定したIDの要素に、外部HTMLファイルを読み込む関数
async function loadPart(elementId, filePath) {
    try {
        const response = await fetch(filePath);
        if (!response.ok) {
            throw new Error('HTTP error! status: ' + response.status);
        }
        const html = await response.text();
        document.getElementById(elementId).innerHTML = html;
    } catch (e) {
        console.error('パーツ読み込みエラー: ' + filePath, e);
    }
}

// ページの読み込みが終わったら実行
document.addEventListener("DOMContentLoaded", function() {
    loadPart("header-part", "parts/header.html");
    loadPart("sidebar-part", "parts/sidebar.html");
    loadPart("footer-part", "parts/footer.html");
});
