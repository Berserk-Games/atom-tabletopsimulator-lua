#!/usr/bin/python

import HTMLParser
import urllib2
import os, time, re, sys
import bs4

FORCE = False
MAX_SNIPPET_LENGTH = 500
SCRAPE_DELAY       = 0
LOCAL_PATH         = None
OUTPUT_FILENAME    = 'api-description.coffee'
PROVIDER_FILENAME  = 'provider.coffee'

args = sys.argv
args.pop(0)
while args:
	arg = args.pop(0).lower()[1:]
	if arg == 'f':
		FORCE = True
	elif arg == 's':
		MAX_SNIPPET_LENGTH = int(args.pop(0))
	elif arg == 'd':
		SCRAPE_DELAY = int(args.pop(0))
	elif arg == 'o':
		OUTPUT_FILENAME = args.pop(0)
	elif arg == 'l':
		if args and args[0][0] not in ('/', '-'):
			LOCAL_PATH = args.pop(0)
		else:
			LOCAL_PATH = '../../Tabletop-Simulator-API/site'
	elif arg.startswith('l='):
		LOCAL_PATH = arg[2:]
	else:
		print """
Options:
 -f             = Force (no confirmation prompt)
 -s #           = Set max snippet length to #
 -d #           = Set scrape delay to #
 -o <filename>  = Set output filename
 -l [<path>]    = Use local folder instead of api website.
                  If <path> unspecified uses '../../Tabletop-Simulator-API/site'
"""
		sys.exit(0)

URL_MATCH = re.compile("\s*descriptionMoreURL:\s*'(https://api[^']*)'")
FIX_SPACES = re.compile("(\s{2,})")

URL_HEADERS = {"User-Agent": "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.2.8) Gecko/20100722 Firefox/3.6.8 GTB7.1 (.NET CLR 3.5.30729)",
#"Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
#"Accept-Language": "en-us,en;q=0.5",
#"Accept-Charset": "ISO-8859-1,utf-8;q=0.7,*;q=0.7",
#"Accept-Encoding": "gzip,deflate",
}

DESCRIPTIONS = {}
SITES = {}


def make_char_index_lookup(html):
	lengths = [0, 0]
	total = 0
	length = len(html)
	while total < length:
		if html[total] == '\n':
			lengths.append(total + 1)
		total += 1
	def lookup((row, col)):
		return lengths[row] + col
	return lookup


def html_tags_and_ids(html):
	tags = []
	index_lookup = make_char_index_lookup(html)

	def id_from_attrs(attrs):
		for k, v in attrs:
			if k == 'id':
				return v
		return None

	class Parser(HTMLParser.HTMLParser):
		current_tag = []
		def handle_starttag(self, tag, attrs):
			id = id_from_attrs(attrs)
			self.current_tag.append((index_lookup(self.getpos()), id))
		def handle_endtag(self, tag):
			start_index, id = self.current_tag.pop()
			end_index = index_lookup(self.getpos()) + len(tag) + 3 # </{tag}>
			tags.append((start_index, end_index, tag, id))
		def handle_startendtag(self, tag, attrs):
			start_index = index_lookup(self.getpos())
			end_index = index_lookup(self.getpos()) + len(self.get_starttag_text())
			id = id_from_attrs(attrs)
			tags.append((start_index, end_index, tag, id))
	parser = Parser()
	parser.feed(html)
	tags.sort()
	ids = {}
	for i, tag in enumerate(tags):
		if tag[3]:
			ids[tag[3]] = i
	return tags, ids


def find_parent(tags, index):
	start_index, end_index, tag, id = tags[index]
	index -= 1
	while index >=0 and tags[index][1] < end_index:
		index -= 1
	if index == -1:
		return None
	else:
		return index


def find_prev_tag(tags, index, tag):
	index -= 1
	while index >= 0 and tags[index][2] != tag:
		index -= 1
	if index == -1:
		return None
	else:
		return index


def find_next_tag(tags, index, tag):
	index += 1
	while index < len(tags) and tags[index][2] != tag:
		index += 1
	if index >= len(tags):
		return None
	else:
		return index


def next_sibling(tags, index):
	start_index, end_index, tag, id = tags[index]
	parent_index = find_parent(tags, index)
	index += 1
	while index < len(tags) and tags[index][1] < end_index and tags[index][1] < tags[parent_index][1]:
		index += 1
	if index >= len(tags) or tags[index][1] > tags[parent_index][1]:
		return None
	else:
		return index


def get_description(url):
	if '#' not in url:
		return None
	if url not in DESCRIPTIONS:
		site, id = url.split('#')
		page = ""
		if site not in SITES:
			if LOCAL_PATH:
				path = site.replace('https://api.tabletopsimulator.com', LOCAL_PATH) + 'index.html'
				html = unicode(bs4.BeautifulSoup(''.join([x for x in open(path)]), 'html.parser'))
			else:
				if SCRAPE_DELAY:
					time.sleep(SCRAPE_DELAY)
				getreq = urllib2.Request(site, None, URL_HEADERS)
				html = unicode(bs4.BeautifulSoup(''.join([x for x in urllib2.urlopen(getreq)]), 'html.parser'))
			tags, ids = html_tags_and_ids(html)
			SITES[site] = html, tags, ids
		html, tags, ids = SITES[site]
		description = ""
		if id in ids:
			index = ids[id]
			start_index, end_index, tag, id = tags[index]
			if tag == 'a':
				index = find_parent(tags, index)
				start_index, end_index, tag, id = tags[index]
			if tag == 'td':
				parent_index = find_parent(tags, index)
				first_td = find_next_tag(tags, parent_index, 'td')
				last_td = first_td
				sibling = next_sibling(tags, first_td)
				while sibling != None:
					last_td = sibling
					sibling = next_sibling(tags, sibling)
				description = html[tags[first_td][0]:tags[last_td][1]].encode('utf-8').replace('\n',' ')
			else:
				while len(description) < MAX_SNIPPET_LENGTH:
					index = next_sibling(tags, index)
					if index == None or tags[index][3]:
						break
					end_index = tags[index][1]
					description = FIX_SPACES.sub(" ", html[start_index:end_index].encode('utf-8').replace('\n',' '))
		DESCRIPTIONS[url] = description
	return DESCRIPTIONS[url]


if not FORCE:
	print """
This will scrape the Tabletop Simulator API website to overwrite:
	\033[1;33mapi-description.coffee\033[0;0m

Press <Enter> to continue, or <ctrl-break> to exit."""
	raw_input()


print "Compiling URLs..."
urls =  URL_MATCH.findall(''.join((x for x in open(PROVIDER_FILENAME))))
total = float(len(urls))
print "Fetching URLs..."
for i, url in enumerate(urls):
	s = "%3d%% | %s" % (int(100 * (i+1) / total), url)
	sys.stdout.write("%-80s\r" % s)
	sys.stdout.flush()
	get_description(url)


print
print "Writing %s..." % OUTPUT_FILENAME
output = open(OUTPUT_FILENAME, 'w')
output.write("""\
module.exports =
  getDescription: (key) ->
    if key in descriptions
      return descriptions[key]
    else
      return null

descriptions = {
""")


for url in DESCRIPTIONS:
	if DESCRIPTIONS[url]:
		output.write("\t'%s':\\\n\t\t'''%s''',\n" % (url, DESCRIPTIONS[url]))

output.write('}')
output.close()
print "Done."
