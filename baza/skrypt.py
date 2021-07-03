#!/usr/bin/python3

# Skrypt do wyciągnięcia numerów fabrycznych liczników

import re

f = open("liczniki.tsv")

for linia in f:
    linia=linia.strip()
    l=linia.split("#")
    adres=l[0]
    opis=l[1]
    p=re.compile(r'\(\d{8}[^\)]*\)' , re.IGNORECASE)
    dopasowanie = re.search(p,opis)
    if dopasowanie:
        nr_fabr=dopasowanie.group()
        nr_fabr=nr_fabr[1:-1]
    else:
        nr_fabr="BRAK"

    print("INSERT INTO liczniki(adres,opis,nr_fabryczny) VALUES(\'" + adres + "\' , \'" + opis + "\' , \'" + nr_fabr + "\');")




