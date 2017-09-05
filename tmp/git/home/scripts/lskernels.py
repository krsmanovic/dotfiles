#!/usr/bin/env python

from bs4 import BeautifulSoup as BS
from tabulate import tabulate as T
import requests as R
import sys

def die(msg):
    print(msg, file=sys.stderr)
    sys.exit(1)

OUT = []

try:
    r = R.get("https://kernel.org").text
except:
    die("Couldn't reach kernel.org.")

s = BS(r, 'html.parser')
t = s.find("table", { "id": "releases" })

if not t:
    die("Couldn't find table#releases in HTML source.")

for row in t.find_all("tr"):
    cells = row.find_all("td")
    OUT.append([ cells[1].text, cells[2].text, cells[0].text[:-1] ])

print(T(OUT, headers=["Version", "Release date", "Type"]))
