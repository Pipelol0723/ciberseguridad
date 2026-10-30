# Taller OSINT — Censys, Wayback Machine y WHOIS (Corte 2)

Tarea de Classroom **"Taller whois, Archive"** (50 pts, fecha límite 1-oct-2026). Resuelto el 29-oct-2026 sobre el dominio **vulnweb.com**, que Acunetix/Invicti publica con sitios vulnerables a propósito.

## Entregable

- [`informe/Informe_OSINT_vulnweb.pdf`](informe/Informe_OSINT_vulnweb.pdf): informe en formato IEEE de 7 páginas. El HTML fuente está junto al PDF.
- [`evidencias/censys/`](evidencias/censys/): capturas de las 6 búsquedas (certificados, puertos, servicios, versiones, geolocalización y proveedor).
- [`evidencias/wayback/`](evidencias/wayback/): las 4 versiones históricas (2012, 2016, 2020 y 2026).
- [`evidencias/whois/`](evidencias/whois/): salida completa de las 5 variantes de `whois`, más el `whois` de la IP y `dig`.

## Enunciado (publicación del profesor, 28-sep-2026)

> La actividad consiste en identificar un dominio que presente posibles vulnerabilidades.

1. **Censys** (<https://platform.censys.io>): seis búsquedas sobre el dominio, enfocadas en certificados digitales, puertos abiertos, servicios expuestos, versiones de software, geolocalización de la IP y proveedor de red. Cada hallazgo se documenta con capturas, descripción técnica y observaciones.
2. **Wayback Machine** (<https://web.archive.org>): recuperar al menos cuatro versiones anteriores del sitio y describir los cambios en estructura, contenido y elementos técnicos a lo largo del tiempo.
3. **WHOIS en terminal**: cinco variaciones distintas del comando, por ejemplo `whois dominio.com`, `whois -H dominio.com`, `whois -h whois.verisign-grs.com dominio.com`, `whois -p 43 dominio.com` y `whois --verbose dominio.com`. Registrar fechas de registro, entidad registrante, servidores DNS y estado actual.

Material de apoyo: <https://www.geeksforgeeks.org/linux-unix/how-to-use-the-whois-command-on-ubuntu-linux/>

