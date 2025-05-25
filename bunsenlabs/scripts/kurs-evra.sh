#!/bin/bash

wget -q -O - "http://www.google.com/finance/converter?a=1&from=EUR&to=RSD"|grep "<div id=currency_converter_result>"|sed 's/<[^>]*>//g'
echo $1
exit
