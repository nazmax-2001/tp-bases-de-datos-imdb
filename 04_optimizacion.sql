-- ============================================================
-- Parte 2 — Punto 3: consulta sobre tres tablas y su optimización
-- Tablas: Genero, Pelicula_Genero, Peliculas
-- Condición de igualdad: nombre_genero = 'Ciencia Ficción'
-- Condición de rango:    anio_estreno >= 2010
-- Optimización heurística según Elmasri y Navathe, sección 15.7
-- (los árboles dibujados están en figuras/arbol_*.png)
-- ============================================================

-- ------------------------------------------------------------
-- a) Consulta original
-- ------------------------------------------------------------
SELECT p.titulo_pelicula, p.anio_estreno
FROM Genero g, Pelicula_Genero pg, Peliculas p
WHERE g.id_genero     = pg.id_genero
  AND pg.id_pelicula  = p.id_pelicula
  AND g.nombre_genero = 'Ciencia Ficción'
  AND p.anio_estreno >= 2010;

-- Árbol inicial (canónico): FROM = producto cartesiano, WHERE = selección,
-- SELECT = proyección.
--
--   π titulo_pelicula, anio_estreno (
--     σ g.id_genero = pg.id_genero AND pg.id_pelicula = p.id_pelicula
--       AND nombre_genero = 'Ciencia Ficción' AND anio_estreno >= 2010 (
--         (Genero × Pelicula_Genero) × Peliculas ) )
--
-- Pasos del algoritmo de optimización heurística:
--   1. Regla 1: la selección conjuntiva se divide en cuatro selecciones.
--   2. Reglas 2, 4, 6 y 10: cada selección baja lo más posible.
--      σ nombre_genero queda sobre Genero y σ anio_estreno sobre Peliculas.
--   3. Reglas 5 y 9: se ejecuta primero la selección más restrictiva
--      (Genero filtrado: 1 tupla) junto a Pelicula_Genero, con la que tiene
--      condición de reunión. En esta consulta el orden ya era ese.
--   4. Regla 12: cada producto cartesiano seguido de su selección de
--      igualdad se reemplaza por una reunión (⋈).
--   5. Reglas 3, 4, 7 y 11: las proyecciones bajan lo más posible.
--
-- Árbol optimizado:
--
--   π titulo_pelicula, anio_estreno (
--     π pg.id_pelicula (
--         π g.id_genero ( σ nombre_genero = 'Ciencia Ficción' (Genero) )
--           ⋈ g.id_genero = pg.id_genero  Pelicula_Genero )
--     ⋈ pg.id_pelicula = p.id_pelicula
--     π p.id_pelicula, titulo_pelicula, anio_estreno ( σ anio_estreno >= 2010 (Peliculas) ) )

-- ------------------------------------------------------------
-- b) Consulta reescrita a partir del árbol optimizado
--    Cada subconsulta es una rama del árbol y se resuelve de adentro
--    hacia afuera, como el árbol de abajo hacia arriba:
--      - la subconsulta más interna es la rama σ + π sobre Genero,
--      - la siguiente es la primera reunión con Pelicula_Genero,
--        proyectada sobre id_pelicula,
--      - la consulta externa es la rama σ sobre Peliculas y la reunión
--        final, que solo conserva atributos de Peliculas.
-- ------------------------------------------------------------
SELECT p.titulo_pelicula, p.anio_estreno
FROM Peliculas p
WHERE p.anio_estreno >= 2010
  AND p.id_pelicula IN (SELECT pg.id_pelicula
                        FROM Pelicula_Genero pg
                        WHERE pg.id_genero IN (SELECT g.id_genero
                                               FROM Genero g
                                               WHERE g.nombre_genero = 'Ciencia Ficción'));
