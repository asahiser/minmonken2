import { readFileSync, writeFileSync, readdirSync } from 'fs';
import { join } from 'path';

const headerRaw = readFileSync('parts/header.html', 'utf-8');
const sidebarRaw = readFileSync('parts/sidebar.html', 'utf-8');
const footerRaw = readFileSync('parts/footer.html', 'utf-8');

function adjustPaths(html, prefix) {
  return html.replace(/(href="|src=")(?!http|#|\/|data:|javascript:)([^"]+)/g,
    (_, p1, p2) => p1 + prefix + p2);
}

function processFile(filepath, prefix = '') {
  let content = readFileSync(filepath, 'utf-8');

  const h = adjustPaths(headerRaw, prefix);
  const s = adjustPaths(sidebarRaw, prefix);

  content = content.replace('<div id="header-part"></div>', h);
  content = content.replace('<div id="sidebar-part"></div>', s);
  content = content.replace('<div id="footer-part"></div>', footerRaw);
  content = content.replace(/ *<script src="(?:\.\.\/)?js\/common\.js"><\/script>\r?\n?/g, '');

  writeFileSync(filepath, content, 'utf-8');
  console.log('OK:', filepath);
}

// Root pages
for (const f of readdirSync('.').filter(f => f.endsWith('.html')).sort()) {
  processFile(f);
}

// post/ pages
for (const f of readdirSync('post').filter(f => f.endsWith('.html')).sort()) {
  processFile(join('post', f), '../');
}

console.log('完了');
