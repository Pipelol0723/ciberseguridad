#!/bin/bash
# Taller Gobuster: ejecuta cada paso en Kali y guarda la transcripción (prompt + comando + salida).
T=192.168.18.128
WL=/usr/share/seclists/Discovery/Web-Content/common.txt
DNSWL=/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt
E=/root/evidencias
mkdir -p $E
cd /root

run() {  # run <archivo> <comando>
  local f=$E/$1.txt; shift
  { printf '┌──(root㉿kali)-[~]\n└─# %s\n' "$*"; bash -c "$*" 2>&1; } > "$f"
  echo "listo: $f"
}

run 01_red_kali        "ip -4 -br addr; ip route"
run 02_ping            "ping -c 4 $T"
run 03_banner_web      "curl -s http://$T/ | head -16"
run 04_gobuster_help   "gobuster -h"
run 05_seclists        "ls -lh $WL && wc -l $WL"
run 06_gobuster_dir    "gobuster dir -u http://$T -w $WL -o resultados.txt --np"
run 07_resultados      "cat resultados.txt"
run 08_validacion      "for r in phpMyAdmin/ dvwa/ mutillidae/ twiki/ phpinfo.php dav/ server-status; do printf '%-14s ' \$r; curl -s -o /dev/null -w '%{http_code}  %{size_download} bytes\n' http://$T/\$r; done; curl -s http://$T/phpinfo.php | grep -o 'PHP Version [0-9.a-z-]*' | head -1"
run 09_dir_extensiones "gobuster dir -u http://$T -w $WL -x php,txt,html -t 20 --np"
run 10_dns_vulnweb     "gobuster dns --domain vulnweb.com -w $DNSWL -t 30 --np"
run 11_vhost           "gobuster vhost -u http://$T -w $DNSWL --append-domain --domain metasploitable.local --exclude-length 891 -t 30 --np"
run 12_fuzz            "gobuster fuzz -u http://$T/FUZZ -w $WL -b 404 -t 20 --np"
run 13_nmap            "nmap -Pn -sT -sV --version-light -n -p 21,22,23,25,53,80,111,139,445,512,513,514,1099,1524,2049,2121,3306,3632,5432,5900,6000,6667,8009,8180 $T"
echo FIN
