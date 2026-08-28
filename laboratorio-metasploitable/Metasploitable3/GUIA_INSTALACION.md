# Guía de instalación — Metasploitable 3

Metasploitable 3 no se distribuye como un archivo de VM único (Microsoft no permite redistribuir Windows como imagen). Se levanta con **Vagrant**, que descarga las "boxes" precompiladas oficiales de Rapid7 y las importa en VirtualBox. Como ya tienes VirtualBox instalado, solo falta Vagrant.

Fuente oficial: [rapid7/metasploitable3](https://github.com/rapid7/metasploitable3)

## Requisitos

- VirtualBox (ya lo tienes instalado)
- ~65 GB libres en disco
- 4.5 GB de RAM disponibles
- Conexión a internet estable (las boxes pesan varios GB cada una)

## Paso 1 — Instalar Vagrant

Descarga el instalador desde https://developer.hashicorp.com/vagrant/install (Windows, .msi) o, si tienes winget:

```powershell
winget install HashiCorp.Vagrant
```

Reinicia la terminal después de instalar y confirma con:

```powershell
vagrant --version
```

## Paso 2 — Instalar el plugin vagrant-reload

Necesario para el aprovisionamiento de la máquina Windows:

```powershell
vagrant plugin install vagrant-reload
```

## Paso 3 — Levantar las máquinas

En esta misma carpeta (`Metasploitable3/`) ya dejé el `Vagrantfile` oficial. Desde una terminal (PowerShell o CMD) dentro de esta carpeta:

```powershell
cd "Metasploitable\Metasploitable3"

# Levantar solo la máquina Linux (Ubuntu 14.04)
vagrant up ub1404

# Levantar solo la máquina Windows (Server 2008)
vagrant up win2k8

# O levantar ambas
vagrant up
```

La primera vez, Vagrant descarga las boxes desde Vagrant Cloud (`rapid7/metasploitable3-ub1404` y `rapid7/metasploitable3-win2k8`). Pesan varios GB cada una, así que puede tardar bastante según tu conexión. El aprovisionamiento de la máquina Windows además corre varios scripts de configuración — tarda unos 10 minutos adicionales.

## Credenciales por defecto

- Usuario: `vagrant`
- Contraseña: `vagrant`

## Comandos útiles

```powershell
vagrant status       # ver estado de las VMs
vagrant halt          # apagar
vagrant destroy       # eliminar la VM (libera espacio)
vagrant ssh ub1404    # conectarte por SSH a la máquina Linux
```

## Advertencia de seguridad

Estas máquinas son **intencionalmente vulnerables**. El Vagrantfile ya las configura en red privada/aislada (`private_network`), no en modo bridge. No las expongas a redes no confiables ni a internet directamente.

## Alternativa: build manual con Packer

Si en algún momento las boxes precompiladas dejan de estar disponibles en Vagrant Cloud, se puede construir todo desde cero clonando el repo y usando Packer (requiere descargar un ISO de evaluación de Windows Server 2008 R2, ~1-1.5 horas de build):

```powershell
git clone https://github.com/rapid7/metasploitable3.git
cd metasploitable3
.\build.ps1 windows2008   # o: .\build.ps1 ubuntu1404
```

Detalles completos en el [README del repo](https://github.com/rapid7/metasploitable3#building-metasploitable-3).
