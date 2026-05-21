import os, re

with open('parts/header.html', 'r', encoding='utf-8') as f:
    header_raw = f.read()
with open('parts/sidebar.html', 'r', encoding='utf-8') as f:
    sidebar_raw = f.read()
with open('parts/footer.html', 'r', encoding='utf-8') as f:
    footer_raw = f.read()

def adjust_paths(html, prefix):
    return re.sub(
        r'(href="|src=")(?!http|#|/|data:|javascript:)([^"]+)',
        lambda m: m.group(1) + prefix + m.group(2),
        html
    )

def process_file(filepath, prefix=''):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    h = adjust_paths(header_raw, prefix)
    s = adjust_paths(sidebar_raw, prefix)
    foot = footer_raw

    content = content.replace('<div id="header-part"></div>', h)
    content = content.replace('<div id="sidebar-part"></div>', s)
    content = content.replace('<div id="footer-part"></div>', foot)
    content = re.sub(r' *<script src="(?:\.\.\/)?js/common\.js"></script>\n?', '', content)

    with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
        f.write(content)
    print(f'OK: {filepath}')

for page in sorted(f for f in os.listdir('.') if f.endswith('.html')):
    process_file(page)

post_dir = 'post'
for page in sorted(f for f in os.listdir(post_dir) if f.endswith('.html')):
    process_file(os.path.join(post_dir, page), prefix='../')

print('完了')
