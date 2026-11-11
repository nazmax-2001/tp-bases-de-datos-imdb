# TP Final Bases de Datos — Parte 2 (Base IMDb)

Base de datos relacional del catálogo cinematográfico de IMDb, con un tablero
interactivo generado desde PostgreSQL con Python.

Estudiantes: Máximo Nazarena y Pastori Ana. Cátedra: Bases de Datos (FIUNER).

## Archivos

| Archivo | Contenido |
|---|---|
| `01_ddl.sql` | Estructura de la base (DDL de la Parte 1, sin cambios) |
| `02_poblado.sql` | Poblado: 50 películas, 106 personas, 12 géneros, 5 roles, 207 participaciones |
| `03_consultas.sql` | 9 consultas complejas (reunión, EXISTS, NOT EXISTS, IN, NOT IN, consulta "para todos", HAVING, EXCEPT, > ALL) |
| `04_optimizacion.sql` | Consulta de 3 tablas: original, álgebra relacional y versión optimizada |
| `generar_tablero.py` | Interfaz de acceso a datos: se conecta a la base y genera el tablero |
| `plantilla_tablero.html` | Diseño del tablero (HTML, CSS y JavaScript); el script le agrega los datos |
| `docs/index.html` | Tablero generado, listo para publicar en GitHub Pages |
| `requirements.txt` | Módulos de Python necesarios |
| `figuras/` | Árboles de álgebra relacional y capturas del tablero |

## Requisitos

- PostgreSQL 13 o superior (probado en la versión 16).
- Python 3.10 o superior.
- Módulo: `pip install -r requirements.txt` (psycopg2-binary).

## Cómo generar el tablero

1. Crear la base y cargarla (en pgAdmin, abrir cada archivo en el Query Tool y
   ejecutarlo en orden, o desde una terminal):

   ```bash
   psql -U postgres -d imdb -f 01_ddl.sql
   psql -U postgres -d imdb -f 02_poblado.sql
   ```

2. Definir las credenciales como variables de entorno (no se escriben en el código):

   ```bash
   # Windows (PowerShell)
   $env:PGUSER="postgres"; $env:PGPASSWORD="tu_contraseña"; $env:PGDATABASE="imdb"
   # Linux / macOS
   export PGUSER=postgres PGPASSWORD=tu_contraseña PGDATABASE=imdb
   ```

   Por defecto se conecta a `localhost:5432`; se cambia con `PGHOST` y `PGPORT`.

3. Generar el tablero:

   ```bash
   python generar_tablero.py
   ```

   Se crea `docs/index.html`. Se puede abrir con doble clic para verlo en el navegador.
   Cada vez que cambian los datos de la base, se vuelve a correr el script.

## Cómo publicarlo en GitHub Pages

1. Crear un repositorio nuevo en GitHub (público).
2. Subir todos los archivos de esta carpeta, incluida la carpeta `docs/`
   (con "Add file" → "Upload files", o con `git push`).
3. En el repositorio: Settings → Pages → en "Build and deployment" elegir
   "Deploy from a branch", rama `main` y carpeta `/docs`. Guardar.
4. A los uno o dos minutos el tablero queda publicado en
   `https://<tu-usuario>.github.io/<nombre-del-repo>/`.

El tablero publicado lleva los datos adentro y no se conecta a la base:
la contraseña de PostgreSQL nunca se sube a GitHub.
