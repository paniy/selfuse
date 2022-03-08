#!/bin/bash

sleep $((($RANDOM % 1800) + 1))

[[ ! -d "/panyi/shell/cloudflare" ]] && mkdir -p /panyi/shell/cloudflare
cd /panyi/shell/cloudflare

if [[ ! -f "CloudflareST" ]]; then
	wget -N https://github.com/XIU2/CloudflareSpeedTest/releases/download/v2.0.3/CloudflareST_linux_arm64.tar.gz
	tar -xvf CloudflareST_linux_arm64.tar.gz
	chmod +x CloudflareST
fi

##/etc/init.d/haproxy stop
/etc/init.d/passwall stop
wait

./CloudflareST -dn 10 -tll 30 -o cf_result.txt
wait
sleep 3

if [[ -f "cf_result.txt" ]]; then
	first=$(sed -n '2p' cf_result.txt | awk -F ',' '{print $1}') && echo $first >>ip-all.txt
	second=$(sed -n '3p' cf_result.txt | awk -F ',' '{print $1}') && echo $second >>ip-all.txt
	third=$(sed -n '4p' cf_result.txt | awk -F ',' '{print $1}') && echo $third >>ip-all.txt
	forth=$(sed -n '5p' cf_result.txt | awk -F ',' '{print $1}') && echo $forth >>ip-all.txt
	wait
	uci commit passwall
	wait
	sed -i "s/$(uci get passwall.573736ca855246c1a6344efbc6426cdf.address)/${first}/g" /etc/config/passwall
	sed -i "s/$(uci get passwall.f70e025e89c44701bc60e02dfccb64b3.address)/${second}/g" /etc/config/passwall
	sed -i "s/$(uci get passwall.9fbdbe9b0b204a098124aaf6a85bc53e.address)/${third}/g" /etc/config/passwall
	sed -i "s/$(uci get passwall.4a1d5fee605e479b9a3a5526338ebf90.address)/${forth}/g" /etc/config/passwall
	#uci set passwall.f70e025e89c44701bc60e02dfccb64b3.address="${second}"
	#uci set passwall.9fbdbe9b0b204a098124aaf6a85bc53e.address="${third}"
	wait
	uci commit passwall
	wait
	##[[ $(/etc/init.d/haproxy status) != "running" ]] && /etc/init.d/haproxy start
	##wait
	[[ $(/etc/init.d/passwall status) != "running" ]] && /etc/init.d/passwall start
	wait
	if [[ -f "ip-all.txt" ]]; then
		sort -t "." -k4 -n -r ip-all.txt >ip-all-serialize.txt
		uniq -c ip-all.txt ip-mediate.txt
		sort -r ip-mediate.txt >ip-statistics.txt
		rm -rf ip-mediate.txt
	fi
fi
