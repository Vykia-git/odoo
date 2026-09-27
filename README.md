# Odoo base de Vykia

Plantilla limpia de **Odoo 19 Community + módulos de la OCA** en Docker, para empezar cada proyecto nuevo de Odoo. No lleva desarrollos propios de ningún cliente.

- **Odoo 19.0** (imagen oficial) + **PostgreSQL 17**.
- **21 repositorios de la OCA** como submódulos git en su rama `19.0`: contabilidad española, SEPA, informes, proyectos, RRHH, documentos, utilidades web, etc. (ver tabla más abajo).
- **`vykia_base`**: se instala sola en cada base de datos nueva y trae el **menú de inicio a pantalla completa** (cuadrícula de aplicaciones con buscador, módulo OCA `web_responsive`).
- Script para crear bases de datos en español, opcionalmente con la contabilidad española.

## Estructura

| Ruta | Contenido |
|---|---|
| `addons/` | Módulos propios. Hoy solo `vykia_base`; aquí van los desarrollos de cada proyecto |
| `addons_oca/` | Repositorios de la OCA (submódulos, rama `19.0`). **No se editan** |
| `config/odoo.conf.example` | Plantilla de configuración. El `config/odoo.conf` real no se sube a git |
| `tools/new_db.sh` | Crea una base de datos nueva |
| `Dockerfile` | Imagen de Odoo con las dependencias Python de los módulos OCA |

## Requisitos

- Docker con Docker Compose.
- Git.

## Puesta en marcha

```bash
git clone --recurse-submodules https://github.com/Vykia-git/odoo.git
cd odoo
cp config/odoo.conf.example config/odoo.conf   # y cambia admin_passwd
docker compose up -d --build
./tools/new_db.sh prueba --spain
```

Abre **http://localhost:8069** y entra con `admin` / `admin`. Cámbialo después del primer acceso.

> **Importante:** clona con `--recurse-submodules`. Si ya lo clonaste sin esa opción, `addons_oca/` estará vacío: ejecuta `git submodule update --init --depth 1`.

## Crear bases de datos

```bash
./tools/new_db.sh mi_cliente                          # Odoo vacío en español
./tools/new_db.sh mi_cliente --spain                  # + compañía española y plan contable (l10n_es)
./tools/new_db.sh mi_cliente --spain -i sale_management,crm   # + los módulos que quieras
```

También se puede crear desde el gestor de bases de datos de Odoo (http://localhost:8069/web/database/manager). En cualquier caso, `vykia_base` y el menú a pantalla completa se instalan solos.

Con `--spain`, el país de la compañía se fija **antes** de instalar la contabilidad, para que Odoo cargue el plan contable español (`es_pymes`).

## Empezar un proyecto nuevo a partir de esta plantilla

1. Crea el repositorio vacío del proyecto en GitHub (p. ej. `Vykia-git/odoo-cliente`).
2. Clona la plantilla y apúntala al repositorio nuevo:
   ```bash
   git clone --recurse-submodules https://github.com/Vykia-git/odoo.git odoo-cliente
   cd odoo-cliente
   git remote rename origin plantilla
   git remote add origin git@github.com:Vykia-git/odoo-cliente.git
   git push -u origin master
   ```
3. Crea los módulos del proyecto en `addons/<proyecto>_<modulo>/`.
4. Para traer al proyecto las mejoras de la plantilla más adelante:
   ```bash
   git fetch plantilla && git merge plantilla/master
   ```

## Módulos de la OCA

Todos en la rama `19.0`, montados en `/mnt/oca-addons/<repo>` y ya incluidos en el `addons_path`.

| Repositorio | Para qué |
|---|---|
| `l10n-spain` | Localización española: modelos AEAT, SII, Facturae, N43, provincias… |
| `account-financial-tools`, `account-financial-reporting`, `account-reconcile`, `account-closing`, `account-budgeting`, `mis-builder` | Contabilidad avanzada, informes financieros, conciliación, cierres, presupuestos |
| `account-payment`, `bank-payment` | Modos de pago, órdenes de pago, SEPA (transferencias y adeudos), mandatos, devoluciones |
| `contract` | Contratos y facturación recurrente, suscripciones |
| `project`, `hr`, `calendar`, `helpdesk`, `knowledge`, `dms` | Proyectos, RRHH, reservas, soporte, base de conocimiento, gestión documental |
| `reporting-engine` | Informes Excel, CSV, py3o… |
| `server-tools`, `server-ux`, `queue` | Auditoría, limpieza de BD, colas de trabajos, utilidades de administración |
| `web` | Mejoras de interfaz: `web_responsive`, `web_dark_mode`, `web_environment_ribbon`… |

Algunos módulos de esos repositorios aún no están migrados a 19.0 por la OCA y no se pueden instalar (p. ej. varios extras de `dms` y de `queue`).

### Actualizar los módulos de la OCA

```bash
git submodule update --remote --depth 1
git add addons_oca && git commit -m "chore: bump OCA submodules"
docker compose run --rm web odoo -d <bd> -u all --stop-after-init   # en cada base de datos
```

### Añadir otro repositorio de la OCA

```bash
REPO=sale-workflow
git clone --depth 1 -b 19.0 https://github.com/OCA/$REPO.git addons_oca/$REPO
git submodule add -b 19.0 https://github.com/OCA/$REPO.git addons_oca/$REPO
git submodule absorbgitdirs addons_oca/$REPO
git config -f .gitmodules submodule.addons_oca/$REPO.shallow true
```

Después añade `/mnt/oca-addons/<repo>` al `addons_path` de `config/odoo.conf` **y** de `config/odoo.conf.example`, y reinicia (`docker compose restart web`). Si los módulos piden librerías Python nuevas, añádelas al `Dockerfile` y reconstruye (`docker compose up -d --build`).

> Clonar primero con `--depth 1 -b 19.0` es necesario: con `git submodule add --depth 1` git solo descarga la rama por defecto del repositorio, que en muchos repos de la OCA no es la `19.0`.

## Operación habitual

| Tarea | Comando |
|---|---|
| Arrancar / parar | `docker compose up -d` / `docker compose stop` |
| Ver el log | `docker compose logs -f web` |
| Actualizar un módulo | `docker compose run --rm web odoo -d <bd> -u <modulo> --stop-after-init && docker compose restart web` |
| Tests de un módulo | `docker compose run --rm web odoo -d test_<modulo> -i <modulo> --test-tags /<modulo> --stop-after-init` |
| Consola de Odoo | `docker compose run --rm web odoo shell -d <bd>` |
| Cargar un idioma | `docker compose run --rm web odoo i18n loadlang -d <bd> -l es` |

## Licencias

Odoo Community es LGPL-3. Los módulos de la OCA son AGPL-3 o LGPL-3: consulta el campo `license` de cada `__manifest__.py` antes de hacer depender de ellos un módulo propietario. `vykia_base` es LGPL-3.
