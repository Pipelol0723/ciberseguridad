# Laboratorio reducido — 3 zonas con Kali / Ubuntu / Windows10

Versión simplificada del diseño completo (8 zonas → 2 zonas + 1 punto de control), sin narrativa de ataque — es una demostración de **segmentación de red con firewall**, tal como la define el material del curso ("Seguridad de la información — Semana 2"): zonas que se comunican entre sí, pero solo a través de un cortafuegos que filtra el tráfico.

**Mapeo de zonas (confirmado):**

| VM | Zona que representa | Rol |
|---|---|---|
| Kali | **DMZ Externa** | Host Linux con un servicio expuesto (servidor web en el puerto 80) — pág. 7 del PDF: "sistemas expuestos a Internet, como servidores web o de correo" |
| Ubuntu | **Firewall / enrutador de filtrado**, y también **Zona de Gestión** | Segmenta el tráfico entre las otras dos zonas (pág. 3: "enrutadores de filtrado... funcionan como barreras de control") y hace de administración/monitoreo (pág. 8) |
| Windows10 | **Zona Empresarial** | Equipo de usuario final (pág. 7: "dispositivos de los usuarios finales, como computadoras, impresoras y teléfonos") que consulta el servicio autorizado en la DMZ Externa |

```
   Kali — DMZ Externa              Ubuntu — Firewall / Zona de Gestión         Windows10 — Zona Empresarial
   192.168.50.10           <—>    NIC1: 192.168.50.1                              192.168.60.10
   servidor web :80               NIC2: 192.168.60.1          <—>                equipo de usuario final
                                   NIC3: NAT (solo para
                                   actualizar paquetes)
```

Todo lo que pase entre Kali y Windows10 atraviesa Ubuntu obligatoriamente, porque están en subredes distintas — Ubuntu decide, con `iptables`, qué se deja pasar entre las dos zonas.

Esto lo ejecutas tú en tu PC (VirtualBox corre en tu Windows, yo no tengo acceso directo a él) — te dejo cada comando listo para copiar y pegar.

---

## 1. Crear las 2 redes host-only nuevas

Ya tienes la red `VirtualBox Host-Only Ethernet Adapter #3` (172.28.128.0/24) del laboratorio de Metasploitable — no la toques, vamos a crear **dos nuevas** para este ejercicio.

**Opción GUI:** VirtualBox → *Archivo* → *Host Network Manager* → *Crear* (dos veces) → a cada una asígnale IP:

- Nueva #1 (zona **DMZ Externa**): IPv4 `192.168.50.1` / máscara `255.255.255.0`, DHCP **desactivado**
- Nueva #2 (zona **Zona Empresarial**): IPv4 `192.168.60.1` / máscara `255.255.255.0`, DHCP **desactivado**

**Opción PowerShell (como Administrador), equivalente:**
```powershell
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" hostonlyif create
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" list hostonlyifs
# identifica el nombre que te dio (ej. "VirtualBox Host-Only Ethernet Adapter #4") y usa ESE nombre abajo:
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" hostonlyif ipconfig "VirtualBox Host-Only Ethernet Adapter #4" --ip 192.168.50.1 --netmask 255.255.255.0
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" dhcpserver remove --ifname "VirtualBox Host-Only Ethernet Adapter #4"

& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" hostonlyif create
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" hostonlyif ipconfig "VirtualBox Host-Only Ethernet Adapter #5" --ip 192.168.60.1 --netmask 255.255.255.0
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" dhcpserver remove --ifname "VirtualBox Host-Only Ethernet Adapter #5"
```
Ajusta los números `#4`/`#5` a lo que realmente te asigne `list hostonlyifs` (puede que ya tengas otras).

---

## 2. Adaptadores de red por VM

Con cada VM **apagada**, en Configuración → Red:

| VM | Adaptador 1 | Adaptador 2 | Adaptador 3 |
|---|---|---|---|
| **Kali** (DMZ Externa) | Solo-anfitrión → *#4* | NAT (para actualizar herramientas) | — |
| **Ubuntu** (Firewall / Zona de Gestión) | Solo-anfitrión → *#4* | Solo-anfitrión → *#5* | NAT (para `apt update`) |
| **Windows10** (Zona Empresarial) | Solo-anfitrión → *#5* | Deshabilitado | — |

**Importante — Kali:** hoy su Adaptador 1 probablemente apunta a `#3` (172.28.128.0/24, el lab de Metasploitable). Cámbialo a `#4` para este ejercicio. Cuando quieras volver al otro laboratorio, devuélvelo a `#3`.

**Windows10 sin Adaptador 2:** en la arquitectura real, la Zona Empresarial sí tendría salida a Internet controlada (vía proxy); aquí la dejamos sin NAT a propósito, solo para que toda su comunicación pase forzosamente por Ubuntu y el efecto del firewall se vea limpio en la prueba.

---

## 3. IPs estáticas dentro de cada VM

| Máquina | Interfaz | IP | Gateway |
|---|---|---|---|
| Ubuntu | NIC1 (hacia DMZ Externa) | `192.168.50.1/24` | — (es el gateway) |
| Ubuntu | NIC2 (hacia Zona Empresarial) | `192.168.60.1/24` | — (es el gateway) |
| Kali | NIC1 | `192.168.50.10/24` | `192.168.50.1` |
| Windows10 | NIC1 | `192.168.60.10/24` | `192.168.60.1` |

**En Ubuntu**, revisa primero los nombres reales de las interfaces:
```bash
ip a
```
Edita `/etc/netplan/*.yaml` (ajusta `enp0s3`/`enp0s8`/`enp0s9` a los nombres reales que viste con `ip a`):
```yaml
network:
  version: 2
  ethernets:
    enp0s3:        # NIC1 - hacia DMZ Externa
      addresses: [192.168.50.1/24]
    enp0s8:        # NIC2 - hacia Zona Empresarial
      addresses: [192.168.60.1/24]
    enp0s9:        # NIC3 - NAT
      dhcp4: true
```
```bash
sudo netplan apply
```

**En Kali** (revisa el nombre de la conexión con `nmcli con show` primero, suele ser `Wired connection 1`):
```bash
sudo nmcli con mod "Wired connection 1" ipv4.method manual
sudo nmcli con mod "Wired connection 1" ipv4.addresses 192.168.50.10/24
sudo nmcli con mod "Wired connection 1" ipv4.gateway 192.168.50.1
sudo nmcli con up "Wired connection 1"
```

**En Windows10** (GUI): *Panel de control → Centro de redes y recursos compartidos → Cambiar configuración del adaptador* → clic derecho en la NIC → *Propiedades* → *Protocolo de Internet versión 4 (TCP/IPv4)* → *Usar la siguiente dirección IP*:
- IP: `192.168.60.10`
- Máscara: `255.255.255.0`
- Puerta de enlace: `192.168.60.1`
- DNS: déjalo vacío (no tiene salida a Internet)

**Checkpoint:** antes de seguir, verifica que Ubuntu hace ping a ambos lados:
```bash
ping -c 3 192.168.50.10   # Kali
ping -c 3 192.168.60.10   # Windows10 (puede fallar si el Firewall de Windows bloquea ICMP por defecto — normal)
```

---

## 4. Habilitar reenvío + reglas de firewall en Ubuntu

```bash
# habilitar IP forwarding (para que Ubuntu enrute entre sus dos redes)
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf

# limpiar reglas previas de la cadena FORWARD
sudo iptables -F FORWARD

# política por defecto: bloquear todo el reenvío (default-deny)
sudo iptables -P FORWARD DROP

# permitir el tráfico de respuesta de conexiones ya establecidas
sudo iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# LA EXCEPCIÓN: solo Zona Empresarial (Windows10) -> DMZ Externa (Kali) puerto 80 queda permitido
sudo iptables -A FORWARD -p tcp -s 192.168.60.10 -d 192.168.50.10 --dport 80 -j ACCEPT
```

Para que las reglas sobrevivan un reinicio:
```bash
sudo apt install iptables-persistent -y
sudo netfilter-persistent save
```

---

## 5. Exponer el servicio en Kali (el "puerto puntual permitido" de la DMZ Externa)

En Kali, un servidor web mínimo (ya trae Python instalado):
```bash
sudo python3 -m http.server 80
```
Déjalo corriendo en esa terminal mientras haces la prueba (o ejecútalo con `&` al final para que quede en segundo plano).

---

## 6. Probar la segmentación desde Windows10

Sin instalar nada — con herramientas nativas de Windows (cmd/PowerShell):

```powershell
# esto NO debería funcionar (bloqueado por la política DROP del FORWARD):
ping 192.168.50.10

# esto SÍ debería funcionar (es la excepción que abrimos):
Test-NetConnection -ComputerName 192.168.50.10 -Port 80
```
También puedes abrir un navegador **dentro de la VM de Windows10** y entrar a `http://192.168.50.10` — debería listar el directorio que sirve `python3 -m http.server` en Kali.

Si el `ping` no responde pero `Test-NetConnection`/el navegador sí funcionan, la segmentación está haciendo exactamente lo que describe el PDF: el firewall filtra por origen/destino/puerto y solo deja pasar lo explícitamente autorizado entre las dos zonas.

---

## 7. Para volver al laboratorio de Metasploitable después

Recuerda devolver el Adaptador 1 de Kali de `#4` a `VirtualBox Host-Only Ethernet Adapter #3` (172.28.128.0/24) — los dos laboratorios usan la misma Kali pero redes distintas.

---

## 8. Componentes adicionales: IDS, IPS y VPN (mapeo conceptual)

Ampliación del laboratorio: se agregan estos tres componentes a la topología, pero **solo a nivel de documento/diagrama** — no se instala nada nuevo en las VMs. Es el mismo ejercicio que hicimos para mapear las 8 zonas a las 3 VMs: explicar dónde encajaría cada componente y por qué, sin montarlo físicamente.

| Componente | Dónde se ubicaría | Función | Por qué ahí |
|---|---|---|---|
| **IDS** (detección de intrusos) | En Ubuntu, junto al firewall | Analiza pasivamente el tráfico que cruza la cadena `FORWARD` entre Kali y Windows10, y genera alertas — no bloquea nada por sí mismo | Ubuntu ya es el único punto que ve el tráfico entre las dos zonas; un IDS ahí (ej. Suricata en modo IDS) no requiere tocar ninguna otra VM |
| **IPS** (prevención de intrusos) | También en Ubuntu, en línea con iptables | Igual que el IDS pero bloqueando activamente lo que detecta como malicioso — complementa las reglas fijas de iptables con detección por firmas/comportamiento | Mismo punto de control; iptables ya bloquea por IP/puerto/protocolo, un IPS extendería eso a patrones que las reglas fijas no cubren |
| **VPN** | En Ubuntu, sobre su interfaz NAT (salida a Internet) | Acceso remoto cifrado y autenticado para administrar el firewall/Zona de Gestión desde fuera, sin exponer ningún puerto de administración directamente | Ubuntu ya representa la Zona de Gestión — una VPN ahí es la forma de dar acceso remoto "fuera de banda" sin abrir accesos directos |

```
                                VPN (acceso remoto administrativo)
                                        |
   Kali -- DMZ Externa       [ IDS/IPS ]|Ubuntu -- Firewall/Zona de Gestión      Windows10 -- Zona Empresarial
   192.168.50.10        <-->  [ monitorea/filtra ]                  <-->        192.168.60.10
                                  el tráfico entre
                                  las dos zonas
```

---

## 9. Justificación general del taller

Todo el ejercicio —desde la topología reducida hasta la regla de Google— gira alrededor de una misma idea del curso: la segmentación por zonas solo funciona si existe un punto de control obligatorio entre ellas, y ese punto decide explícitamente qué tráfico pasa (pág. 3 del PDF: "enrutadores de filtrado... funcionan como barreras de control"). El diseño de 3 VMs no es una simplificación al azar: mapea 1 a 1 las 8 zonas del modelo completo del curso a los tres roles mínimos necesarios para demostrarlo — una zona expuesta (Kali), un punto de control (Ubuntu) y una zona interna (Windows10) — sin perder ninguna idea del material original, solo reduciendo cuántas VMs hacen falta para mostrarla.

Ubuntu se eligió como ese punto de control porque es la única VM con presencia en ambas subredes: cualquier otra distribución hubiera dejado un camino que evita el firewall, y la demostración perdería sentido. Por eso la política de la cadena `FORWARD` es default-deny (bloquear todo y abrir solo lo estrictamente necesario) en vez de ir bloqueando tráfico "malo" caso por caso — es el mismo principio de menor privilegio que sustenta cualquier firewall real, y es lo que se prueba con las 6 reglas: unas veces con `DROP` (silencio total), otras con `REJECT` (rechazo explícito) y otras con `ACCEPT`, capturando tráfico real con Wireshark para comprobar que el firewall efectivamente se comporta distinto en cada caso, no que "no pasa nada" por otra razón (como de hecho ocurrió durante las pruebas con `ip_forward` desactivado).

Los componentes de la sección 8 (IDS, IPS, VPN) no son un añadido desconectado del resto: se ubican todos en Ubuntu precisamente porque es el único punto de la topología por el que obligatoriamente pasa el tráfico entre zonas — el mismo argumento que ya justifica por qué el firewall vive ahí. Son la extensión natural de "¿qué más pondría un punto de control real, además de reglas fijas de iptables?".

La regla de Google (sección 10) se agrega para mostrar el mismo concepto —filtrado de tráfico con iptables— aplicado en un lugar y con un criterio distintos a propósito, ampliando el alcance del taller: en vez de filtrar tráfico que cruza entre zonas (cadena `FORWARD` de Ubuntu), filtra la salida propia de un host hacia Internet (cadena `OUTPUT` de Kali), y en vez de filtrar solo por IP/puerto/protocolo, agrega una condición horaria. Es la prueba de que la misma herramienta y la misma lógica de segmentación (decidir explícitamente qué tráfico se permite) sirve tanto en el punto central de la red como en un host individual.

---

## 10. Implementación: bloquear el tráfico de Kali hacia Google por horario

Esta regla vive en la propia Kali (cadena `OUTPUT`), no en Ubuntu, porque el tráfico de Internet de Kali sale por su propio adaptador NAT — no pasa por la cadena `FORWARD` de Ubuntu, así que Ubuntu nunca lo ve. Como Google no tiene una IP fija, se resuelve `google.com` a una IP real con `dig` y se bloquea esa IP puntual (una limitación conocida: cubre esa IP, no toda la infraestructura de Google) en los puertos de navegación (80/443), dentro de una ventana horaria diaria de 00:00 a 00:12 usando el módulo `-m time` de iptables con `--kerneltz` para que el rango se interprete en la zona horaria del sistema y no en UTC.

**Comandos, en Kali:**
```bash
# 1. Resolver una IP real de google.com
dig +short google.com | head -1
# ejemplo de salida: 142.250.xx.xx -- usa la que te devuelva a ti

# 2. Confirmar el huso horario de Kali (el módulo time de iptables usa UTC por defecto)
timedatectl status

# 3. Cargar la regla (reemplaza <IP_GOOGLE> por la IP del paso 1)
sudo iptables -A OUTPUT -d <IP_GOOGLE> -p tcp -m multiport --dports 80,443 \
  -m time --timestart 00:00 --timestop 00:12 --kerneltz -j DROP
```
`--kerneltz` hace que el rango de horas se interprete con el huso horario configurado en el sistema en vez de UTC por defecto — evita el mismo tipo de confusión de reloj que tuvimos con Ubuntu al principio del taller.

**Cómo probarla sin esperar hasta la madrugada:** cambia temporalmente el horario de la regla a un rango que incluya el minuto actual (ej., si son las 15:40, usa `--timestart 15:39 --timestop 15:41`) y prueba:
```bash
curl -I https://google.com
ping -c 2 <IP_GOOGLE>
```
Debe fallar (timeout/sin respuesta) dentro de esa ventana de prueba, y funcionar normal fuera de ella. Una vez confirmes que la regla funciona, bórrala y cárgala de nuevo con el horario real:
```bash
sudo iptables -D OUTPUT -d <IP_GOOGLE> -p tcp -m multiport --dports 80,443 \
  -m time --timestart 15:39 --timestop 15:41 --kerneltz -j DROP

sudo iptables -A OUTPUT -d <IP_GOOGLE> -p tcp -m multiport --dports 80,443 \
  -m time --timestart 00:00 --timestop 00:12 --kerneltz -j DROP
```
