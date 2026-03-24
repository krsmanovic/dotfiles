#!/bin/bash

echo "====================== Provera da li je JMBG u procurelim podacima  ======================"
echo "====================== Koristim API sajta https://kompromitovan.com ======================"
echo

WORKDIR="$(mktemp -d)"
HASH_PREFIXES_FILE="$WORKDIR/hash_prefixes"

read -sp "Unesi JMBG: " jmbg
echo

# lokalna validacija formata
if ! [[ $jmbg =~ ^[0-9]+$ ]]; then
    echo "JMBG mora sadrzati samo cifre."
    exit 1
fi
if [ ${#jmbg} -ne 13 ]; then
    echo "JMBG mora biti duzine 13 karaktera."
    exit 1
fi

# lokalna validacija datuma rodjenja
if [ ${jmbg:4:1}${jmbg:5:1}${jmbg:6:1} -gt 900 ]; then
    MILENIJUM="1"
elif [ ${jmbg:4:1}${jmbg:5:1}${jmbg:6:1} -lt $(date +%y) ]; then
    MILENIJUM="2"
else
    echo "Pogresno unesecna godina rodjenja."
    exit 1
fi
DATUM_RODJENJA="$MILENIJUM${jmbg:4:1}${jmbg:5:1}${jmbg:6:1}-${jmbg:2:1}${jmbg:3:1}-${jmbg:0:1}${jmbg:1:1}"
if ! [[ "$(date +%F -d $DATUM_RODJENJA)" == "$DATUM_RODJENJA" ]]; then
    echo "Pogresan datum rodnjenja."
    exit 1
fi

# lokalna validacija kontrolne cifre
SUMA=$((7 * ${jmbg:0:1} + 6 * ${jmbg:1:1} + 5 * ${jmbg:2:1} + 4 * ${jmbg:3:1} + 3 * ${jmbg:4:1} + 2 * ${jmbg:5:1} + 7 * ${jmbg:6:1} + 6 * ${jmbg:7:1} + 5 * ${jmbg:8:1} + 4 * ${jmbg:9:1} + 3 * ${jmbg:10:1} + 2 * ${jmbg:11:1}))
MODULO=$(( SUMA % 11 ))
if [ $MODULO -eq 0 ]; then
    KONTROLNA_CIFRA=$MODULO
elif [ $MODULO -eq 1 ]; then
    echo "Pogresan maticni broj."
    exit 1
elif [ $MODULO -gt 1 ]; then
    KONTROLNA_CIFRA=$(( 11 - MODULO ))
else
    echo "Pokvario ti se konjpjuktor."
    exit 1
fi
if [ ${jmbg:12:1} -ne $KONTROLNA_CIFRA ]; then
    echo "Kontrolna cifra se ne poklapa."
    exit 1
fi

# skini listu koja se poklapa sa pocetna 3 karaktera hash-a preko api-a
HASH=$(echo -n "$jmbg" | sha256sum | cut -d " " -f 1)
HASH_PREFIX=$(echo -n "$HASH" | cut -c 1-3)
curl -sS "https://api.kompromitovan.com/search?prefix=$HASH_PREFIX" > $HASH_PREFIXES_FILE

# proveri da li smo u rezultatima
if grep -q "$HASH" $HASH_PREFIXES_FILE; then
    echo "Pronadjen JMBG u bazi!"
else
    echo "JMBG nije pronadjen u bazi!"
fi
rm -rf $WORKDIR
echo
