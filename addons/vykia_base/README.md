# Vykia Base

Base común de todas las instancias Odoo de Vykia. Se instala **sola** en cada base de datos nueva (`auto_install`) y trae:

- **`web_responsive`** (OCA): el menú de inicio a pantalla completa, con la cuadrícula de aplicaciones y el buscador de menús.

Para añadir algo que deban tener todas las instancias (otro módulo OCA de interfaz, ajustes por defecto…), se añade como dependencia en `__manifest__.py` y se sube la versión.
