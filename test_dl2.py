import subprocess, time, os
os.chdir(r'D:\OpenCode\Aplikasi DTMS')
server = subprocess.Popen(['python', '-m', 'http.server', '9999'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
time.sleep(2)
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    b = p.chromium.launch(headless=True)
    page = b.new_page()
    errors = []
    page.on('console', lambda msg: errors.append(msg.text) if msg.type == 'error' else None)

    page.goto('http://localhost:9999', wait_until='networkidle', timeout=15000)
    page.fill('#username', 'admin')
    page.fill('#password', 'admin')
    page.click('button[type="submit"]')
    page.wait_for_timeout(1000)

    # T-2023-002
    page.goto('http://localhost:9999/#tooling/T-2023-002', wait_until='networkidle', timeout=15000)
    page.locator('button:has-text("Riwayat Pengiriman")').click()
    page.wait_for_timeout(800)
    summary = page.locator('#delivery-log-modal .modal-body > div:first-child').first.inner_text()
    print('=== T-2023-002 HEADER ===')
    print(summary[:400])
    rows = page.locator('#delivery-log-modal .table tbody tr')
    print(f'Rows: {rows.count()}')
    for i in range(rows.count()):
        cells = rows.nth(i).locator('td')
        vals = [cells.nth(j).inner_text() for j in range(cells.count())]
        print(f'  {vals}')

    print(f'\nConsole errors: {errors}')
    b.close()
server.terminate()
