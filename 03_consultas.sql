-- ============================================================
-- Parte 2 — Consultas complejas sobre la base IMDb
-- Motor: PostgreSQL 16
-- Las reuniones se escriben como en la teoría: tablas en el FROM
-- (producto cartesiano) y condición de igualdad en el WHERE (selección).
-- ============================================================


-- ------------------------------------------------------------
-- Consulta 1 (reunión de 5 tablas + GROUP BY + HAVING)
-- Directores con al menos 3 películas dirigidas: cantidad de películas,
-- puntuación media en IMDb y recaudación total.
-- ------------------------------------------------------------
SELECT pe.nombre_persona,
       COUNT(*)                   AS peliculas,
       AVG(c.puntuacion_promedio) AS puntuacion_media,
       SUM(p.recaudacion)         AS recaudacion_total
FROM Participacion pa, Persona pe, Rol r, Peliculas p, Clasificaciones_En_IMDb c
WHERE pa.id_persona     = pe.id_persona
  AND pa.id_rol         = r.id_rol
  AND pa.id_pelicula    = p.id_pelicula
  AND p.id_clasificacion = c.id_clasificacion
  AND r.nombre_rol      = 'Director'
GROUP BY pe.nombre_persona
HAVING COUNT(*) >= 3
ORDER BY puntuacion_media DESC;


-- ------------------------------------------------------------
-- Consulta 2 (NOT EXISTS)
-- Películas que todavía no tienen ninguna participación cargada.
-- ------------------------------------------------------------
SELECT p.titulo_pelicula, p.anio_estreno
FROM Peliculas p
WHERE NOT EXISTS (SELECT *
                  FROM Participacion pa
                  WHERE pa.id_pelicula = p.id_pelicula);


-- ------------------------------------------------------------
-- Consulta 3 (EXISTS correlacionado)
-- Personas que dirigieron una película y además actuaron en esa
-- misma película.
-- ------------------------------------------------------------
SELECT DISTINCT pe.nombre_persona, p.titulo_pelicula
FROM Participacion d, Rol rd, Persona pe, Peliculas p
WHERE d.id_rol      = rd.id_rol
  AND d.id_persona  = pe.id_persona
  AND d.id_pelicula = p.id_pelicula
  AND rd.nombre_rol = 'Director'
  AND EXISTS (SELECT *
              FROM Participacion a, Rol ra
              WHERE a.id_rol      = ra.id_rol
                AND a.id_persona  = d.id_persona
                AND a.id_pelicula = d.id_pelicula
                AND (ra.nombre_rol = 'Actor Principal' OR ra.nombre_rol = 'Actor Secundario'));


-- ------------------------------------------------------------
-- Consulta 4 (IN con subconsultas anidadas)
-- Películas de Ciencia Ficción en las que trabajó al menos una
-- persona de nacionalidad británica.
-- ------------------------------------------------------------
SELECT p.titulo_pelicula, p.anio_estreno
FROM Peliculas p
WHERE p.id_pelicula IN (SELECT pg.id_pelicula
                        FROM Pelicula_Genero pg, Genero g
                        WHERE pg.id_genero = g.id_genero
                          AND g.nombre_genero = 'Ciencia Ficción')
  AND p.id_pelicula IN (SELECT pa.id_pelicula
                        FROM Participacion pa
                        WHERE pa.id_persona IN (SELECT pe.id_persona
                                                FROM Persona pe
                                                WHERE pe.nombre_nacionalidad = 'Británica'));


-- ------------------------------------------------------------
-- Consulta 5 (consulta "para todos": doble NOT EXISTS)
-- Personas que participaron en TODAS las películas filmadas en
-- Buenos Aires: no existe una película filmada en Buenos Aires
-- en la que esa persona no haya participado.
-- ------------------------------------------------------------
SELECT pe.nombre_persona
FROM Persona pe
WHERE NOT EXISTS (SELECT *
                  FROM Pelicula_Lugar_Filmacion l
                  WHERE l.nombre_lugar_filmacion = 'Buenos Aires, Argentina'
                    AND NOT EXISTS (SELECT *
                                    FROM Participacion pa
                                    WHERE pa.id_persona  = pe.id_persona
                                      AND pa.id_pelicula = l.id_pelicula));


-- ------------------------------------------------------------
-- Consulta 6 (GROUP BY + HAVING con subconsulta)
-- Géneros cuya puntuación media supera la media general del catálogo,
-- con el retorno medio (recaudación / presupuesto).
-- ------------------------------------------------------------
SELECT g.nombre_genero,
       COUNT(*)                          AS peliculas,
       AVG(c.puntuacion_promedio)        AS puntuacion_media,
       AVG(p.recaudacion / p.presupuesto) AS retorno_medio
FROM Genero g, Pelicula_Genero pg, Peliculas p, Clasificaciones_En_IMDb c
WHERE g.id_genero        = pg.id_genero
  AND pg.id_pelicula     = p.id_pelicula
  AND p.id_clasificacion = c.id_clasificacion
GROUP BY g.nombre_genero
HAVING AVG(c.puntuacion_promedio) > (SELECT AVG(puntuacion_promedio)
                                     FROM Clasificaciones_En_IMDb)
ORDER BY puntuacion_media DESC;


-- ------------------------------------------------------------
-- Consulta 7 (NOT IN + COUNT DISTINCT + HAVING)
-- Personas que actuaron en 3 o más películas y que nunca dirigieron.
-- ------------------------------------------------------------
SELECT pe.nombre_persona,
       COUNT(DISTINCT pa.id_pelicula) AS peliculas_como_actor
FROM Persona pe, Participacion pa, Rol r
WHERE pe.id_persona = pa.id_persona
  AND pa.id_rol     = r.id_rol
  AND (r.nombre_rol = 'Actor Principal' OR r.nombre_rol = 'Actor Secundario')
  AND pe.id_persona NOT IN (SELECT pa2.id_persona
                            FROM Participacion pa2, Rol r2
                            WHERE pa2.id_rol = r2.id_rol
                              AND r2.nombre_rol = 'Director')
GROUP BY pe.nombre_persona
HAVING COUNT(DISTINCT pa.id_pelicula) >= 3
ORDER BY peliculas_como_actor DESC;


-- ------------------------------------------------------------
-- Consulta 8 (diferencia de conjuntos: EXCEPT)
-- Directores que nunca figuran como guionistas en el catálogo.
-- ------------------------------------------------------------
(SELECT DISTINCT pe.nombre_persona
 FROM Persona pe, Participacion pa, Rol r
 WHERE pe.id_persona = pa.id_persona
   AND pa.id_rol     = r.id_rol
   AND r.nombre_rol  = 'Director')
EXCEPT
(SELECT DISTINCT pe.nombre_persona
 FROM Persona pe, Participacion pa, Rol r
 WHERE pe.id_persona = pa.id_persona
   AND pa.id_rol     = r.id_rol
   AND r.nombre_rol  = 'Guionista');


-- ------------------------------------------------------------
-- Consulta 9 (comparación de conjuntos: > ALL)
-- Películas que recaudaron más que TODAS las películas dirigidas
-- por Christopher Nolan.
-- ------------------------------------------------------------
SELECT p.titulo_pelicula, p.recaudacion
FROM Peliculas p
WHERE p.recaudacion > ALL (SELECT p2.recaudacion
                           FROM Peliculas p2, Participacion pa, Persona pe, Rol r
                           WHERE p2.id_pelicula   = pa.id_pelicula
                             AND pa.id_persona    = pe.id_persona
                             AND pa.id_rol        = r.id_rol
                             AND r.nombre_rol     = 'Director'
                             AND pe.nombre_persona = 'Christopher Nolan')
ORDER BY p.recaudacion DESC;
