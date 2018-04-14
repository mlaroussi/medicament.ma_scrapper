#!/bin/bash
# This script retrieves medications database from medicament.ma

main='http://medicament.ma'
lists='listing-des-medicaments'
alpha=(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)

log(){
echo -e "$(date) : $1" >> log_file
}
log_display(){
echo -e "$(date) : $1" >> log_file ; echo -e $1
}

curl_rand(){
#User agents for most used browsers
UA=('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.99 Safari/537.36' 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_1) AppleWebKit/602.2.14 (KHTML, like Gecko) Version/10.0.1 Safari/602.2.14' 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.98 Safari/537.36' 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36' 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:50.0) Gecko/20100101 Firefox/50.0')
Proxies=('') #IP addreses
random_ua=${UA[$RANDOM % ${#UA[@]}]}
random_proxy=${Proxies[$RANDOM % ${#Proxies[@]}]}
echo $random_ua &>1
echo "Using $random_proxy" &>1
curl -sL -A "$random_ua" $1 -x "http://$random_proxy:1235"
}

get_count_by_letter() {
	curl_rand "$main/$lists/?lettre=$1" | grep 'résultats trouvés' | tr -dc '0-9'
}

get_medicines_from_page() {
	if [ "$2" -eq 1 ]; then
		curl_rand "$main/$lists/?lettre=$1" | tr "\n" "|" | grep -o '<tbody>.*</tbody>' | sed 's/\(<tbody>\|<\/tbody>\)//g' | sed 's/|/\n/g' | egrep -v 'tr>|td>|details' | sed ':a;N;$!ba;s/<br>\n/\t/g' | sed ':a;N;$!ba;s/\/">\n/\t/g' | sed ':a;N;$!ba;s/<a href="//g'  | sed 's/<[^>]*>//g' | sed '/^$/d' | tr -s " " | sed '/^[[:space:]]*$/d'
	else
		curl_rand "$main/$lists/page/$2/?lettre=$1" | tr "\n" "|" | grep -o '<tbody>.*</tbody>' | sed 's/\(<tbody>\|<\/tbody>\)//g' | sed 's/|/\n/g' | egrep -v 'tr>|td>|details' | sed ':a;N;$!ba;s/<br>\n/\t/g' | sed ':a;N;$!ba;s/\/">\n/\t/g' | sed ':a;N;$!ba;s/<a href="//g'  | sed 's/<[^>]*>//g' | sed '/^$/d' | tr -s " " | sed '/^[[:space:]]*$/d'
	fi
}

get_info_from_medicine(){
	product_page=$(curl_rand $1)
	product_title=$(echo $product_page | sed 's/>/>\n/g' | grep h3 | sed 's/<[^>]*>//g' | sed '/^$/d' | tr -s " " | sed '/^[[:space:]]*$/d' | sed ':a;N;$!ba;s/:\n/: /g')
	bar_code=$(echo $product_page | grep -n Code | head -1 | grep -Eo '[0-9]{13}' | awk '{print $1}'| head -1)
	product_info=$(echo $product_page | tr "\n" "|" | grep -o '<tbody>.*</tbody>' | sed 's/>/>\n/g' | sed 's/\(<tbody>\|<\/tbody>\)//g' | egrep -v 'field|class' | sed 's/<[^>]*>//g' | sed '/^$/d' | tr -s " " | sed '/^[[:space:]]*$/d' | sed ':a;N;$!ba;s/:\n/: /g' | sed ':a;N;$!ba;s/\n/\t/g')
	echo -e "$product_title => Code à barre : $bar_code\t$product_info" >> medicines.txt
}

mkdir -p lists medicines
log_display "Starting the process"

for i in "${alpha[@]}"
do
	num=$(get_count_by_letter $i)
	num_pages=$((num/40+1))
	log_display "Letter $i : $num medicine(s) ($num_pages pages)"
	for j in $(seq 1 $num_pages)
	do
		get_medicines_from_page $i $j >> lists/$i
		log_display "Page $j\t\t\t| PASS |"
	done
done

cat lists/* > lists_ALL

cat lists_ALL | awk '{ print $1 }' | while read line
do
   get_info_from_medicine $line
done
