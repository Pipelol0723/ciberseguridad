# Laboratorio Metasploitable — Kali + Metasploitable2 + Metasploitable3

Laboratorio de pentesting sobre VirtualBox: Kali Linux como atacante contra Metasploitable2 y Metasploitable3
(dos sub-VMs: Ubuntu 14.04 y Windows Server 2008), en una red host-only aislada de internet.

## Máquinas virtuales

| VM | Rol | Credenciales | IP |
|---|---|---|---|
| Kali Linux ("kali pipe") | Atacante | — | eth0 `172.28.128.101` (host-only) · eth1 NAT (internet) |
| Metasploitable2 | Víctima | `msfadmin` / `msfadmin` | Host-only únicamente, sin NAT (sin salida a internet, a propósito) |
| Metasploitable3 – ub1404 (Ubuntu) | Víctima | `vagrant` / `vagrant` | `172.28.128.3` (fija) |
| Metasploitable3 – win2k8 (Windows Server 2008) | Víctima | `vagrant` / `vagrant` | `172.28.128.100` (DHCP) |

Red host-only de VirtualBox: `172.28.128.0/24`, DHCP habilitado en el rango `172.28.128.100–254`.

## Cómo levantar cada VM

- **Metasploitable2**: no es un `.ova`, es un `.vmdk` — crear la VM en VirtualBox manualmente y apuntarla al disco existente (no crear uno nuevo). Descarga oficial: zip desde SourceForge (`metasploitable-linux-2.0.0.zip`), verificando el checksum.
- **Metasploitable3**: ver [`GUIA_INSTALACION.md`](./Metasploitable3/GUIA_INSTALACION.md) en esta carpeta — se levanta con `vagrant up ub1404` / `vagrant up win2k8` a partir del `Vagrantfile` incluido.

## Problemas encontrados y solución

- **Metasploitable2 no bootaba** (`kernel panic: IO-APIC + timer doesn't work`) — kernel viejo incompatible con la emulación moderna de VirtualBox. Con la VM apagada: `VBoxManage modifyvm "Metasploitable2" --ioapic off --acpi off --cpus 1`.
- **`vagrant up win2k8` falló por espacio en disco** (`VERR_DISK_FULL`) — dejar al menos 20-30 GB libres antes de levantar esa VM.
- **`VBoxManage` no estaba en el PATH de Windows** — está en `C:\Program Files\Oracle\VirtualBox\VBoxManage.exe`. Cuidado al agregarlo con `setx PATH`: puede truncar el PATH existente a 1024 caracteres y dañar otras entradas — mejor editarlo desde el panel de variables de entorno de Windows.
- **A la VM win2k8 le faltaba el adaptador de red del lab** (Vagrant no lo configuró) — agregar manualmente Adaptador 2 = red host-only del lab, con la VM apagada.
- Si el diálogo de Red de VirtualBox abre en blanco, doble clic en la barra de título para maximizarlo (bug de renderizado conocido).

## Carpeta compartida con Kali

Esta carpeta del curso está compartida hacia la VM de Kali (VirtualBox Shared Folders) y se monta automáticamente en
`/media/sf_ciberseguridad` dentro de la VM — útil para mover archivos entre Windows y Kali sin necesidad de red.
