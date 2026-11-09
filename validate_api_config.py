#!/usr/bin/env python3
import sys
import json
import time
import urllib.request
import urllib.error

def validate_endpoint(url, headers=None, token=None):
    req_headers = {
        'User-Agent': 'RecPlay/1.0',
        'Accept': 'application/json',
    }
    if headers:
        req_headers.update(headers)
    if token:
        req_headers['Authorization'] = f'Bearer {token}'

    req = urllib.request.Request(url, headers=req_headers)
    start = time.time()
    try:
        with urllib.request.urlopen(req, timeout=8) as response:
            latency = int((time.time() - start) * 1000)
            return {
                'url': url,
                'reachable': True,
                'status_code': response.status,
                'latency_ms': latency,
                'content_type': response.headers.get('Content-Type', 'N/A'),
            }
    except urllib.error.HTTPError as e:
        latency = int((time.time() - start) * 1000)
        return {
            'url': url,
            'reachable': e.code < 500,
            'status_code': e.code,
            'latency_ms': latency,
            'error': str(e),
        }
    except Exception as e:
        latency = int((time.time() - start) * 1000)
        return {
            'url': url,
            'reachable': False,
            'status_code': None,
            'latency_ms': latency,
            'error': str(e),
        }

def main():
    if len(sys.argv) < 2:
        print("Uso: python3 validate_api_config.py <caminho_do_arquivo_config.json>")
        sys.exit(1)

    path = sys.argv[1]
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    base_url = data.get('base_url') or data.get('baseUrl', '')
    token = data.get('auth_token') or data.get('authToken')
    headers = data.get('custom_headers') or data.get('customHeaders')

    print("=" * 60)
    print(f"VALIDAÇÃO EM TEMPO REAL: {data.get('name', 'Media Provider')}")
    print(f"Base URL: {base_url}")
    print("=" * 60)

    endpoints_to_test = {}
    if base_url:
        endpoints_to_test['Base URL'] = base_url

    for key in ['auth_endpoint', 'categories_endpoint', 'content_endpoint', 'live_endpoint']:
        val = data.get(key)
        if val:
            if val.startswith('http'):
                full_url = val
            else:
                clean_base = base_url.rstrip('/')
                clean_end = val.lstrip('/')
                full_url = f"{clean_base}/{clean_end}"
            endpoints_to_test[key] = full_url

    for label, url in endpoints_to_test.items():
        print(f"\n[Testando] {label}: {url}")
        res = validate_endpoint(url, headers=headers, token=token)
        if res['reachable']:
            status_text = f"ONLINE (HTTP {res['status_code']})"
            icon = "🟢"
        else:
            status_text = f"OFFLINE ({res.get('error', 'Inacessível')})"
            icon = "🔴"
        print(f"  {icon} Status: {status_text} | Latência: {res['latency_ms']}ms")

    print("\n" + "=" * 60)
    print("Diagnóstico Concluído.")

if __name__ == '__main__':
    main()
