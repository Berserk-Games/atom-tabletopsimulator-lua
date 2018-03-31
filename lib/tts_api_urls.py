import urllib2, sys, re
from bs4 import BeautifulSoup

text = ''.join((x for x in open("provider.coffee")))
urls = set(re.findall("""['"](https://api.tabletopsimulator.com/[^'"]*)['"]""", text))

if False: #this used to transpose urls
    urls = set(re.findall("""['"](http://berserk-games.com/[^'"]*)['"]""", text))
    urls = [x[1] for x in reversed(sorted(((len(x), x) for x in urls)))]



    def new_url(url):
        s = url.lower()
        s = s.replace("http://berserk-games.com/knowledgebase/", "https://api.tabletopsimulator.com/")
        s = s.replace("/scripting-", "/")
        s = s.replace("/api/#on", "/event/#on")
        s = s.replace("/api/", "/base/")
        s = s.replace("/external-editor-api", "/externaleditorapi")
        return s

    replacements = {}
    for url in urls:
        replacements[url] = new_url(url)


#if len(sys.argv) > 1:
    if sys.argv[1].upper() == "/W":
        todo = {}
        for url in urls:
            text = text.replace(url, replacements[url])

        out=open("provider.coffee", 'w')
        out.write(text)
        out.close()
    else:
        print "Specify no parameters to check new urls, or specify /W to write them to provider.coffee"
        sys.exit(1)

else:
    sites = {}
    missing = []
    errors = 0
    ok = 0

    for url in sorted(urls):#sorted(replacements):
        #url = replacements[old_url]
        id_index = url.find("#")
        site = url[:id_index]
        id = url[id_index:]

        if site in missing:
            print '\r' + "404 : " + url + "                    "
            errors += 1
            continue

        if url not in sites:
            page = urllib2.urlopen(url)
            if not page:
                print '\r' + "404 : " + url + "                    "
                missing[site] = True
                errors += 1
                continue
            soup = BeautifulSoup(page, 'html.parser')
            sites[url] = soup
        else:
            soup = sites[url]

        if id_index >= 0 and not soup.select(id):
            print '\r' + "#ID : " + url + "                    "
            errors += 1
        else:
            ok += 1
            print '\r' + url + "                    ",

    print "\r                                                                  "
    print ok, "ok ", errors, "errors"
