# Guion del video: sesión de Junta Directiva de EPM (simulación)

**Parcial 2 – Ciberseguridad 2026 G01 · Universidad Sergio Arboleda**
Presenta: Andrés Felipe Céspedes Rondón, en el papel de **CISO (Director de Ciberseguridad) de EPM** [S].
Duración objetivo: **7 min 30 s** (rango 6–8 min).
Base: informe `informe/Informe_Parcial2_EPM.pdf`. Todo lo marcado con [S] es supuesto académico.

> Sugerencia de formato: grabar con cámara y pantalla compartida. Cada bloque indica qué mostrar en pantalla.
> Si se graba con compañeros, pueden hacer de presidente de la junta y de miembro del Comité de Auditoría y Riesgos (las preguntas van en cursiva).

---

## Bloque 1 · Apertura (0:00 – 0:40)

**Pantalla:** portada del informe o diapositiva «Informe de riesgo de ciberseguridad – Junta Directiva EPM».

> «Buenos días, señor presidente y miembros de la Junta. Soy el director de ciberseguridad. Desde octubre de 2025 la supervisión del riesgo de ciberseguridad está en el Comité de Auditoría y Riesgos, y hoy vengo a presentar el análisis de riesgos de seguridad de la información hecho con ISO 27001 e ISO 31000.
> En siete minutos les voy a mostrar tres cosas: cuáles son nuestros riesgos más graves, qué vulnerabilidades reales los pueden activar y qué plan y presupuesto propongo. Al final les pido cuatro decisiones.»

## Bloque 2 · Contexto (0:40 – 1:40)

**Pantalla:** cifras clave (sección 1 del informe) y una línea de tiempo del 12 de diciembre de 2022.

> «Recordemos quiénes somos: 3,05 millones de clientes en EPM y más de 10 millones en el Grupo, 8.558 colaboradores, y somos el primer generador de energía del país. Eso nos hace infraestructura crítica.
> Y ya nos pasó: el 12 de diciembre de 2022 sufrimos un ransomware atribuido a BlackCat. Se cayeron el portal y la app, unos 4.000 empleados tuvieron que trabajar desde casa y más de 300.000 familias con prepago no podían recargar. Además, los atacantes se llevaron información antes de cifrar.
> Desde entonces avanzamos: tenemos estrategia de ciberseguridad 2024–2027, SOC y un DRP en construcción. Pero nuestras políticas públicas son muy generales. Revisé ocho documentos publicados y ninguno exige, por ejemplo, MFA, respaldos inmutables ni reglas de acceso remoto a las redes de operación. Por eso propongo seis reglas internas nuevas.»

## Bloque 3 · Los tres riesgos prioritarios (1:40 – 3:40)

**Pantalla:** mapa de calor inherente (Figura 1a), luego resaltar R01, R05 y R02.

> «Evaluamos 12 riesgos con probabilidad por impacto en una escala de 1 a 25. Hoy tenemos 2 críticos, 9 altos y 1 medio. Los tres que les pido mirar son estos:»

1. **R01 – Ransomware en TI (nivel 20, crítico).**
   > «Es repetir 2022: se detiene la facturación, el prepago y los canales digitales. La probabilidad es alta porque ya ocurrió y porque los grupos de ransomware explotan justo las tecnologías que usa una empresa como la nuestra.»
2. **R05 – Filtración masiva de datos de clientes (nivel 20, crítico).**
   > «Hoy el ransomware primero roba y después cifra. Hablamos de datos de 3 millones de titulares, con sanciones de la SIC de hasta 2.000 salarios mínimos y un daño de confianza difícil de medir.»
3. **R02 – Compromiso del acceso remoto y del perímetro (nivel 16, alto).**
   > «Es la puerta de entrada de los otros dos. Las VPN y firewalls son los equipos más atacados del mundo y varias de sus fallas no requieren contraseña.»

> «Hay un cuarto riesgo que quiero dejar en el radar: el sabotaje del SCADA de energía (R03). Es menos probable, pero sus efectos son físicos, y es el único que seguirá en alto después del plan.»

*Pregunta del comité (opcional): «¿Por qué no está el SCADA entre los tres primeros?»*
> «Porque su nivel inherente es 15 y los otros tres están entre 16 y 20. Pero su residual sigue alto, por eso pido que la Junta lo acepte de forma explícita y lo revise cada trimestre.»

## Bloque 4 · Vulnerabilidades clave (3:40 – 4:50)

**Pantalla:** Tabla 5 del informe (resaltar V01, V02, V05, V06 y V09).

> «Analizamos diez vulnerabilidades reales. Las diez están en el catálogo de CISA de vulnerabilidades explotadas activamente, y seis se han usado en campañas de ransomware. Aclaro algo importante: no estoy diciendo que EPM las tenga; son ejemplos del tipo de tecnología que tenemos y que hay que vigilar. Destaco cuatro:»

- **Citrix Bleed (CVE-2023-4966) y PAN-OS (CVE-2024-3400):** «en equipos de acceso remoto; la primera roba sesiones y se salta el MFA, la segunda tiene la puntuación máxima, 10.»
- **VMware ESXi (CVE-2024-37085) y Veeam (CVE-2024-40711):** «la combinación que usan los atacantes para cifrar todos los servidores virtuales y borrar los respaldos, que fue lo que se reportó en 2022.»
- **PLC Unitronics (CVE-2023-6448):** «contraseña por defecto en controladores de plantas de agua; en 2023 se explotó contra empresas de agua en Estados Unidos.»

> «La lección es simple: si un equipo de administración o de control industrial está expuesto a internet y sin parche, es cuestión de tiempo.»

## Bloque 5 · Plan y presupuesto (4:50 – 6:20)

**Pantalla:** Tabla 13 (plan) y luego mapa de calor residual (Figura 1b).

> «Propongo un plan de 11 acciones en 12 meses, por **COP 12.150 millones** [S]. Lo divido en tres fases:»

| Fase | Qué hacemos | Qué baja |
|---|---|---|
| 0–3 meses | MFA en todo acceso remoto y privilegiado; parcheo urgente y cierre de interfaces expuestas | R02 de 16 a 8; routers de 12 a 4 |
| 3–6 meses | Respaldos inmutables probados, antifraude y DMARC, seguridad SAP, PLC de agua fuera de internet | Agua de 15 a 5; phishing de 15 a 6 |
| 6–12 meses | Administración por niveles, segmentación TI/OT con bastión, SOC con registros de 12 meses, cifrado y enmascaramiento de datos | Ransomware y filtración de 20 a 8 |

> «La inversión más grande es la segmentación de las redes de operación, COP 3.500 millones [S], porque protege lo que la gente siente directamente: la luz y el agua.
> Como resultado esperado pasamos de 2 críticos y 9 altos a cero críticos y solo 1 alto. Para medirlo traeré cada trimestre un tablero con indicadores concretos: porcentaje de cuentas con MFA, vulnerabilidades críticas corregidas en 7 días, sistemas con copia inmutable y tiempo de recuperación probado del prepago.»

*Pregunta del comité (opcional): «¿Y si nos atacan mientras ejecutamos el plan?»*
> «Por eso la primera fase son medidas de bajo costo y rápido efecto, y desde el primer trimestre tendremos guías de respuesta y un simulacro. En el informe dejé un caso completo de ransomware con contención, investigación, recuperación y prevención.»

## Bloque 6 · Cierre y decisiones que se piden a la Junta (6:20 – 7:30)

**Pantalla:** lista de decisiones.

> «Para cerrar, les pido cuatro decisiones:»

1. **Aprobar el plan de tratamiento** y su presupuesto de COP 12.150 millones [S] para los próximos 12 meses.
2. **Adoptar las seis reglas internas** (acceso remoto a OT por bastión, administración por niveles, superficie expuesta controlada, registros de 12 meses, verificación de pagos y prohibición de datos reales en pruebas) como lineamiento obligatorio para EPM y sus contratistas.
3. **Aceptar formalmente el riesgo residual alto de R03** (SCADA de energía) con seguimiento trimestral del Comité de Auditoría y Riesgos.
4. **Autorizar la cotización de una póliza de ciberriesgo** para transferir parte del impacto económico de R01 y R05.

> «En 2022 aprendimos que un incidente digital en EPM es un problema de servicio público, no solo de tecnología. Con estas decisiones pasamos de reaccionar a prevenir. Muchas gracias; quedo atento a sus preguntas.»

---

### Checklist antes de grabar
- [ ] Tener abiertas en pantalla: portada, Tabla 5, Figura 1a, Tabla 13 y Figura 1b del PDF.
- [ ] Cronometrar un ensayo: si pasa de 8 min, recortar las preguntas opcionales del comité.
- [ ] Decir en voz alta al menos una vez que los montos y responsables son supuestos académicos [S].
- [ ] Subir el video junto con el PDF a Classroom.
