import re, requests

results = {}
output = open('badurls.txt', 'w')

for line_number, line in enumerate((x for x in open('api.yaml'))):
    url = re.search("((https?:)?/[^ ]+)\]", line)
    if not url: continue

    url = url.group(1)
    if url.startswith('/'): url = 'https://api.tabletopsimulator.com' + url
    if url in results:
        result = results[url]
    else:
        req = requests.get(url)
        result = results[url] = (req.status_code == 200)

    if result:
        print(url, "OK")
    else:
        print(url, "ERROR", req)
        output.write(f'{url} {req} line {line_number + 1}\n')

output.close()
