"""
Interfaz de acceso a datos — Base IMDb (TP Final, Bases de Datos, Parte 2)

Se conecta a PostgreSQL con psycopg2 (DB-API 2.0), ejecuta las consultas
del catálogo y las consultas del TP, y genera un tablero interactivo (docs/index.html) que se publica en
GitHub Pages. El tablero lleva los datos adentro: no necesita la base para
verse, y las credenciales nunca se publican.

Uso:
    python generar_tablero.py
        -> genera docs/index.html (abrirlo con doble clic o subirlo a GitHub)

Credenciales: se leen de variables de entorno (nunca escritas en el código).
    PGHOST (localhost), PGPORT (5432), PGDATABASE (imdb), PGUSER, PGPASSWORD
"""

import datetime
import decimal
import json
import os
import re
import sys

import psycopg2

CARPETA = os.path.dirname(os.path.abspath(__file__))
PLANTILLA = os.path.join(CARPETA, "plantilla_tablero.html")
CONSULTAS = os.path.join(CARPETA, "03_consultas.sql")
SALIDA = os.path.join(CARPETA, "docs", "index.html")


# ------------------------------------------------------------------
# 1. Conexión y consultas (mismo flujo de la guía de la cátedra)
# ------------------------------------------------------------------
def conectar():
    """Abre la conexión leyendo las credenciales de variables de entorno."""
    return psycopg2.connect(
        host=os.environ.get("PGHOST", "localhost"),
        port=int(os.environ.get("PGPORT", 5432)),
        dbname=os.environ.get("PGDATABASE", "imdb"),
        user=os.environ.get("PGUSER", "postgres"),
        password=os.environ.get("PGPASSWORD", ""),
    )


def a_json(valor):
    """Convierte los tipos que devuelve el driver a tipos de JSON."""
    if isinstance(valor, decimal.Decimal):
        return float(valor)
    if isinstance(valor, (datetime.date, datetime.datetime)):
        return valor.isoformat()
    return valor


def consultar(con, sql, params=None):
    """Ejecuta un SELECT (parametrizado) y devuelve columnas y filas."""
    cur = con.cursor()
    try:
        cur.execute(sql, params)  # los valores viajan separados del SQL
        filas = cur.fetchall()
        columnas = [d[0] for d in cur.description]
    finally:
        cur.close()
    return columnas, [[a_json(v) for v in fila] for fila in filas]


def como_diccionarios(con, sql, params=None):
    columnas, filas = consultar(con, sql, params)
    return [dict(zip(columnas, fila)) for fila in filas]


# ------------------------------------------------------------------
# 2. Datos del catálogo (consultas escritas como en la teoría)
# ------------------------------------------------------------------
SQL_PELICULAS = """
SELECT p.id_pelicula, p.titulo_pelicula, p.anio_estreno, p.presupuesto,
       p.recaudacion, c.puntuacion_promedio, c.cantidad_de_votos
FROM Peliculas p, Clasificaciones_En_IMDb c
WHERE p.id_clasificacion = c.id_clasificacion
ORDER BY p.titulo_pelicula
"""

SQL_GENEROS = """
SELECT pg.id_pelicula, g.nombre_genero
FROM Pelicula_Genero pg, Genero g
WHERE pg.id_genero = g.id_genero
"""

SQL_IDIOMAS = "SELECT id_pelicula, nombre_idioma FROM Pelicula_Idioma"

SQL_LUGARES = "SELECT id_pelicula, nombre_lugar_filmacion FROM Pelicula_Lugar_Filmacion"

SQL_PERSONAS = """
SELECT id_persona, nombre_persona, nombre_sexo, nombre_nacionalidad
FROM Persona
ORDER BY nombre_persona
"""

SQL_PARTICIPACIONES = """
SELECT pa.id_pelicula, pa.id_persona, r.nombre_rol
FROM Participacion pa, Rol r
WHERE pa.id_rol = r.id_rol
"""



def agrupar(filas, clave, valor):
    salida = {}
    for f in filas:
        salida.setdefault(f[clave], []).append(f[valor])
    return salida


def leer_catalogo(con):
    peliculas = como_diccionarios(con, SQL_PELICULAS)
    generos = agrupar(como_diccionarios(con, SQL_GENEROS), "id_pelicula", "nombre_genero")
    idiomas = agrupar(como_diccionarios(con, SQL_IDIOMAS), "id_pelicula", "nombre_idioma")
    lugares = agrupar(como_diccionarios(con, SQL_LUGARES), "id_pelicula", "nombre_lugar_filmacion")
    for p in peliculas:
        p["generos"] = sorted(generos.get(p["id_pelicula"], []))
        p["idiomas"] = sorted(idiomas.get(p["id_pelicula"], []))
        p["lugares"] = sorted(lugares.get(p["id_pelicula"], []))
    return {
        "peliculas": peliculas,
        "personas": como_diccionarios(con, SQL_PERSONAS),
        "participaciones": como_diccionarios(con, SQL_PARTICIPACIONES),
    }


# ------------------------------------------------------------------
# 3. Consultas del TP: se leen de 03_consultas.sql y se ejecutan
# ------------------------------------------------------------------
def consultas_del_tp(con):
    texto = open(CONSULTAS, encoding="utf-8").read()
    bloques = re.split(r"\n-- -{20,}\n-- (?=Consulta \d+)", texto)[1:]
    resultado = []
    for bloque in bloques:
        encabezado, _, resto = bloque.partition("\n-- ---")
        lineas = encabezado.split("\n")
        titulo = lineas[0].strip()
        descripcion = " ".join(l.lstrip("- ").strip() for l in lineas[1:])
        sql = resto.split("\n", 1)[1].strip()
        columnas, filas = consultar(con, sql.rstrip(";"))
        resultado.append({"titulo": titulo, "descripcion": descripcion,
                          "sql": sql, "columnas": columnas, "filas": filas})
    return resultado


# ------------------------------------------------------------------
# 4. Armado del tablero
# ------------------------------------------------------------------
def main():
    try:
        con = conectar()
    except psycopg2.OperationalError as e:
        sys.exit(f"No se pudo conectar a la base: {e}")
    try:
        datos = leer_catalogo(con)
        datos["consultas"] = consultas_del_tp(con)
    finally:
        con.close()

    datos["generado"] = datetime.date.today().isoformat()
    js = json.dumps(datos, ensure_ascii=False).replace("</", "<\\/")
    html = open(PLANTILLA, encoding="utf-8").read().replace("/*__DATOS__*/null", js)
    os.makedirs(os.path.dirname(SALIDA), exist_ok=True)
    with open(SALIDA, "w", encoding="utf-8") as f:
        f.write(html)
    print(f"Tablero generado: {SALIDA}")
    print(f"  {len(datos['peliculas'])} películas, {len(datos['personas'])} personas, "
          f"{len(datos['consultas'])} consultas del TP")


if __name__ == "__main__":
    main()
