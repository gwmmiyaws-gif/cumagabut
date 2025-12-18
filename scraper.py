#!/usr/bin/env python3
"""
Domain Scraper Module
Upload file ini ke GitHub
"""

import sys
import os
import time
from playwright.sync_api import sync_playwright
from colorama import Fore, Style
from datetime import datetime

# Colors
RED = Fore.RED
GREEN = Fore.GREEN
YELLOW = Fore.YELLOW
CYAN = Fore.CYAN
MAGENTA = Fore.MAGENTA
BOLD = Style.BRIGHT
RESET = Style.RESET_ALL

def scrape_zonexsec(page, archive_type, max_page, save_ip):
    """Scrape Zone-Xsec"""
    domains = []
    ips = []
    base_url = 'https://zone-xsec.com/archive' if archive_type == 'archive' else 'https://zone-xsec.com/special'
    file_name = f'zonexsec_{archive_type}'
    
    print(f"\n{CYAN}[*] Mulai scraping Zone-Xsec {archive_type}...{RESET}\n")
    
    for page_num in range(1, max_page + 1):
        url = base_url if page_num == 1 else f"{base_url}/page={page_num}"
        
        print(f"{YELLOW}[*] Halaman {page_num}/{max_page}{RESET}")
        
        try:
            print(f"{CYAN}[*] Mengakses: {url}{RESET}")
            page.goto(url, wait_until='domcontentloaded', timeout=60000)
            
            # Check for Blazingfast protection
            bypassed = False
            for i in range(60):
                try:
                    still_checking = page.evaluate("""() => {
                        const bodyText = document.body.innerText;
                        const title = document.title;
                        return bodyText.includes('Verifying your browser') ||
                               bodyText.includes('Checking your browser') ||
                               bodyText.includes('Just a moment') ||
                               title.includes('Just a moment');
                    }""")
                    
                    if still_checking:
                        if i == 0:
                            print(f'{YELLOW}[*] Blazingfast terdeteksi! Menunggu bypass...{RESET}')
                        sys.stdout.write(f'\r{CYAN}[*] Menunggu... {i + 1} detik{RESET}')
                        sys.stdout.flush()
                        time.sleep(1)
                    else:
                        bypassed = True
                        print(f'\n{GREEN}[+] Bypass berhasil!{RESET}')
                        break
                except Exception:
                    time.sleep(1)
            
            if not bypassed:
                print(f'\n{YELLOW}[*] Timeout 60 detik, melanjutkan...{RESET}')
            
            time.sleep(3)
            page.wait_for_selector('tbody tr', timeout=15000)
            
            data = page.evaluate("""() => {
                const rows = document.querySelectorAll('tbody tr');
                const results = [];
                
                rows.forEach(row => {
                    const cells = row.querySelectorAll('td');
                    if (cells.length >= 9) {
                        const ipCell = cells[4];
                        const domainCell = cells[8];
                        
                        let ip = '';
                        const ipLink = ipCell.querySelector('a[href^="/ip/"]');
                        if (ipLink) {
                            ip = ipLink.getAttribute('href').replace('/ip/', '');
                        }
                        
                        let domain = domainCell.textContent.trim();
                        domain = domain.split('/')[0];
                        
                        if (domain) {
                            results.push({ domain: domain, ip: ip });
                        }
                    }
                });
                
                return results;
            }""")
            
            print(f"{GREEN}[+] Ditemukan {len(data)} entry{RESET}")
            
            for item in data:
                if item['domain'] not in domains:
                    domains.append(item['domain'])
                if item['ip'] and item['ip'] not in ips:
                    ips.append(item['ip'])
            
        except Exception as error:
            print(f"{RED}[!] Error di halaman {page_num}: {str(error)}{RESET}")
        
        time.sleep(2)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    domain_file = f'{file_name}_{timestamp}.txt'
    
    with open(domain_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(domains))
    
    print(f"\n{GREEN}[+] Selesai!{RESET}")
    print(f"{GREEN}[+] Total domains: {len(domains)} - Disimpan ke {domain_file}{RESET}")
    
    if save_ip:
        ip_file = f'{file_name}_ip_{timestamp}.txt'
        with open(ip_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(ips))
        print(f"{GREEN}[+] Total IPs: {len(ips)} - Disimpan ke {ip_file}{RESET}")

def scrape_haxorid(page, archive_type, max_page, save_ip):
    """Scrape Haxor.id"""
    domains = []
    ips = []
    base_url = 'https://haxor.id/archive' if archive_type == 'archive' else 'https://haxor.id/archive/special'
    file_name = f'haxorid_{archive_type}'
    
    print(f"\n{CYAN}[*] Mulai scraping Haxor.id {archive_type}...{RESET}\n")
    
    for page_num in range(1, max_page + 1):
        url = base_url if page_num == 1 else f"{base_url}?page={page_num}"
        
        print(f"{YELLOW}[*] Halaman {page_num}/{max_page}{RESET}")
        
        try:
            print(f"{CYAN}[*] Mengakses: {url}{RESET}")
            page.goto(url, wait_until='domcontentloaded', timeout=60000)
            time.sleep(2)
            
            page.wait_for_selector('tbody tr', timeout=15000)
            
            data = page.evaluate("""() => {
                const rows = document.querySelectorAll('tbody tr');
                const results = [];
                
                rows.forEach(row => {
                    const cells = row.querySelectorAll('td');
                    if (cells.length >= 10) {
                        const ipCell = cells[4];
                        const domainCell = cells[8];
                        
                        let ip = '';
                        const ipLink = ipCell.querySelector('a[href^="/archive/ip/"]');
                        if (ipLink) {
                            ip = ipLink.getAttribute('href').replace('/archive/ip/', '');
                        }
                        
                        const domainLink = domainCell.querySelector('a');
                        let domain = '';
                        if (domainLink) {
                            domain = domainLink.getAttribute('title') || domainLink.textContent.trim();
                            domain = domain.split('/')[0];
                        }
                        
                        if (domain) {
                            results.push({ domain: domain, ip: ip });
                        }
                    }
                });
                
                return results;
            }""")
            
            print(f"{GREEN}[+] Ditemukan {len(data)} entry{RESET}")
            
            for item in data:
                if item['domain'] not in domains:
                    domains.append(item['domain'])
                if item['ip'] and item['ip'] not in ips:
                    ips.append(item['ip'])
            
        except Exception as error:
            print(f"{RED}[!] Error di halaman {page_num}: {str(error)}{RESET}")
        
        time.sleep(1.5)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    domain_file = f'{file_name}_{timestamp}.txt'
    
    with open(domain_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(domains))
    
    print(f"\n{GREEN}[+] Selesai!{RESET}")
    print(f"{GREEN}[+] Total domains: {len(domains)} - Disimpan ke {domain_file}{RESET}")
    
    if save_ip:
        ip_file = f'{file_name}_ip_{timestamp}.txt'
        with open(ip_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(ips))
        print(f"{GREEN}[+] Total IPs: {len(ips)} - Disimpan ke {ip_file}{RESET}")

def main():
    """Main function untuk scraper"""
    print(f"{CYAN}[*] Domain Scraper Module{RESET}\n")
    
    # Get parameters from command line
    if len(sys.argv) < 5:
        print(f"{RED}[!] Invalid arguments{RESET}")
        return
    
    source = sys.argv[1]
    archive_type = sys.argv[2]
    max_page = int(sys.argv[3])
    save_ip = sys.argv[4] == 'True'
    
    print(f"{CYAN}[*] Membuka browser...{RESET}")
    
    # Set PLAYWRIGHT_BROWSERS_PATH sebelum import
    import os
    playwright_browsers = os.path.join(os.path.expanduser('~'), 'AppData', 'Local', 'ms-playwright')
    os.environ['PLAYWRIGHT_BROWSERS_PATH'] = playwright_browsers
    
    print(f"{CYAN}[*] Browser path: {playwright_browsers}{RESET}\n")
    
    try:
        from playwright.sync_api import sync_playwright
        
        with sync_playwright() as p:
            # Coba launch dengan berbagai cara
            try:
                browser = p.chromium.launch(
                    headless=False,
                    args=['--no-sandbox', '--disable-setuid-sandbox']
                )
            except Exception as e:
                print(f"{RED}[!] Failed to launch browser: {str(e)}{RESET}")
                print(f"{YELLOW}[*] Trying alternative browser path...{RESET}")
                
                # Coba run playwright install dulu
                import subprocess
                subprocess.run(['playwright', 'install', 'chromium'], capture_output=True)
                
                # Retry
                browser = p.chromium.launch(
                    headless=False,
                    args=['--no-sandbox', '--disable-setuid-sandbox']
                )
            
            page = browser.new_page()
            page.set_viewport_size({"width": 1920, "height": 1080})
            
            try:
                if source == '1':
                    scrape_zonexsec(page, archive_type, max_page, save_ip)
                elif source == '2':
                    scrape_haxorid(page, archive_type, max_page, save_ip)
                elif source == '3':
                    # Grab ALL
                    print(f'\n{BOLD}{MAGENTA}[*] GRAB ALL MODE{RESET}\n')
                    
                    print(f'{CYAN}{"="*50}{RESET}')
                    print(f'{YELLOW}[*] 1/2 Zone-Xsec{RESET}')
                    print(f'{CYAN}{"="*50}{RESET}')
                    scrape_zonexsec(page, archive_type, max_page, save_ip)
                    
                    print(f'\n{CYAN}{"="*50}{RESET}')
                    print(f'{YELLOW}[*] 2/2 Haxor.id{RESET}')
                    print(f'{CYAN}{"="*50}{RESET}')
                    scrape_haxorid(page, archive_type, max_page, save_ip)
                    
                    print(f'\n{GREEN}[+] Semua scraping selesai!{RESET}')
                    
            except Exception as error:
                print(f'{RED}[!] Error: {str(error)}{RESET}')
            
            browser.close()
            print(f'\n{CYAN}[*] Browser ditutup!{RESET}')
            
    except Exception as e:
        print(f"{RED}[!] Error: {str(e)}{RESET}")
        print(f"\n{YELLOW}[*] Solusi:{RESET}")
        print(f"{MAGENTA}   playwright install chromium{RESET}")

if __name__ == '__main__':
    main()
