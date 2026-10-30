# Ciberseguridad — 8vo Semestre

Talleres y laboratorios de la materia de Seguridad de la Información / Ciberseguridad, 8vo semestre.
Profesor: MSc Iván Darío Méndez Aguilera. Estudiante: Andres Felipe Céspedes Rondón.

## Contenido

- **`material-curso/`** — material de referencia entregado por el profesor.
- **`laboratorio-metasploitable/`** — laboratorio base de pentesting: Kali Linux atacando Metasploitable2 y Metasploitable3 (Ubuntu 14.04 + Windows Server 2008), en una red host-only aislada (`172.28.128.0/24`). Las imágenes de disco de las VMs no están en este repo por su tamaño — ver más abajo cómo obtenerlas. Sí incluye la guía de instalación y el `Vagrantfile` oficial.
- **`taller-meterpreter-postexplotacion/`** — post-explotación con Meterpreter sobre el Windows Server 2008 del laboratorio anterior: acceso inicial vía `psexec`, consola remota, keylogger, stream de pantalla y capturas automáticas. Incluye la guía (`taller_meterpreter.docx`) y el informe con evidencias.
- **`taller-dmz-segmentacion/`** — diseño de una red segmentada en 8 zonas (DMZ, Extranet, zona restringida, zona de gestión, etc.) para una empresa ficticia ("NovaTech S.A.S."), más un laboratorio reducido de 3 VMs (Kali / Ubuntu-firewall / Windows10) que valida la segmentación con `iptables`, incluyendo la captura de tráfico (`.pcapng`) de las pruebas de las reglas.
- **`taller-metadata-forense/`** — extracción de metadata forense de un PDF (con Autopsy en Windows) y una foto (con `exiftool` en Kali), incluyendo cálculo de hash MD5/SHA-256. Incluye los archivos originales usados como evidencia.
- **`parcial-netinvm/`** — primer parcial sobre el laboratorio NETinVM: informe, evidencias por punto y guías.

### Corte 2

- **`taller-gobuster-enumeracion-web/`** — enumeración de recursos web con Gobuster (modos `dir`, `dns`, `vhost` y `fuzz`) desde Kali en Docker contra Metasploitable 2 en VMware. Incluye el informe IEEE y las transcripciones de la terminal.
- **`taller-osint-whois-wayback-censys/`** — reconocimiento pasivo de `vulnweb.com`: 6 búsquedas en Censys, 4 versiones históricas en Wayback Machine y 5 variantes de `whois`. Incluye el informe IEEE y las capturas.
- **`parcial2-gestion-riesgos-iso27001/`** — Parcial 2: análisis de riesgos de EPM con ISO/IEC 27001:2022 e ISO 31000. Incluye el informe y el guion del video de sustentación.

## Laboratorio Metasploitable — cómo obtener las VMs

Este repo no incluye las imágenes de disco de las VMs (superan el límite de 100 MB por archivo de GitHub):

- **Metasploitable2**: descarga el zip oficial desde SourceForge y verifica el checksum antes de importar el `.vmdk` a VirtualBox (crear la VM apuntando al disco existente, no crear uno nuevo). Credenciales: `msfadmin` / `msfadmin`.
- **Metasploitable3**: no requiere descarga manual — sigue `laboratorio-metasploitable/GUIA_INSTALACION.md` (usa Vagrant, que descarga las boxes oficiales de Rapid7 automáticamente).

## Notas

- El taller de Meterpreter (`taller_meterpreter.docx`, paso 2.1) referencia la ruta antigua `...\ciberseguridad\Metasploitable\Metasploitable3` para el `cd` inicial. Tras esta reorganización la carpeta se llama `laboratorio-metasploitable/Metasploitable3` — actualizar esa línea si se vuelve a correr el taller.
- Todos los laboratorios de red corren en entornos aislados (redes host-only de VirtualBox), sin salida a redes no autorizadas.
