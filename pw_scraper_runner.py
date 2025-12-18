import sys
from playwright.sync_api import sync_playwright

def main():
    if len(sys.argv) < 5:
        print("[!] Argumen tidak lengkap")
        sys.exit(1)

    source = sys.argv[1]          # 1 / 2 / 3
    archive_type = sys.argv[2]    # archive / special
    max_page = int(sys.argv[3])
    save_ip = sys.argv[4] == "1"

    with sync_playwright() as p:
        browser = p.chromium.launch(
            headless=False,
            args=["--no-sandbox", "--disable-setuid-sandbox"]
        )

        page = browser.new_page()
        page.set_viewport_size({"width": 1920, "height": 1080})

        if source == "1":
            from scraper_zonexsec import scrape_zonexsec
            scrape_zonexsec(page, archive_type, max_page, save_ip)

        elif source == "2":
            from scraper_haxorid import scrape_haxorid
            scrape_haxorid(page, archive_type, max_page, save_ip)

        elif source == "3":
            from scraper_zonexsec import scrape_zonexsec
            from scraper_haxorid import scrape_haxorid
            scrape_zonexsec(page, archive_type, max_page, save_ip)
            scrape_haxorid(page, archive_type, max_page, save_ip)

        browser.close()

if __name__ == "__main__":
    main()
