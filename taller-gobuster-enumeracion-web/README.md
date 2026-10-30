# Taller Gobuster — enumeración de recursos web (Corte 2)

Tarea de Classroom **"Go-Boster"** (50 pts, fecha límite 28-sep-2026). Resuelto el 29-oct-2026.

## Entregable

- [`informe/Informe_Gobuster.pdf`](informe/Informe_Gobuster.pdf): informe en formato IEEE de 5 páginas. El HTML fuente está junto al PDF.
- [`evidencias/`](evidencias/): transcripción de cada paso, tal como salió de la terminal de Kali (`01`–`13`), `resultados.txt` (la salida de `-o`) y `lab_gobuster.sh`, el script que ejecutó los pasos.

Laboratorio: Kali Linux en Docker (`kalilinux/kali-rolling`) contra Metasploitable 2 en VMware, en la red solo-anfitrión VMnet1 (`192.168.18.128`). Con el modo `dir` y `common.txt` aparecieron 13 recursos, entre ellos `/phpMyAdmin`, `/phpinfo.php` (PHP 5.2.4), `/dav`, `/twiki` y `/test`. El modo `dns` se probó contra `vulnweb.com`.

## Enunciado (resumen de `dia2_charlaCiberseguridad.pptx`, MSc. Iván Darío Méndez Aguilera)

Laboratorio con dos VMs en la misma red aislada (host-only / red interna): **Kali Linux** (atacante) y **Metasploitable 2** (objetivo). Alternativa permitida: OWASP Juice Shop en Docker dentro de Kali.

1. **IP del objetivo**: `ifconfig` en Metasploitable y `ping` desde Kali.
2. **Verificar Gobuster**: `gobuster -h` (si falta: `sudo apt update && sudo apt install gobuster`).
3. **Wordlists (SecLists)**: `git clone https://github.com/danielmiessler/SecLists.git` y comprobar `Discovery/Web-Content/common.txt`.
4. **Modo DIR**: `gobuster dir -u http://<IP> -w ~/SecLists/Discovery/Web-Content/common.txt`, explicando cada parte del comando.
5. **Análisis de resultados**: interpretar códigos 200 / 301 / 403 / 404 (p. ej. `/phpmyadmin`, `/dvwa` en Metasploitable) y guardar con `-o resultados.txt`.
6. **Modos avanzados**: `dns`, `vhost` y `fuzz`.
7. **Buenas prácticas y mitigación** desde el lado defensor.

Material de apoyo publicado: <https://hackertarget.com/gobuster-tutorial/> y la presentación del día 2.

