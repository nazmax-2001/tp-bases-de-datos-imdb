-- ============================================================
-- Base de datos de películas (IMDb) — DDL de la Parte 1
-- Motor: PostgreSQL 16
-- ============================================================

-- 1. Tablas sin dependencias

CREATE TABLE Clasificaciones_En_IMDb (
    id_clasificacion     INT PRIMARY KEY,
    cantidad_de_votos    INT,
    puntuacion_promedio  NUMERIC(3,1) CHECK (puntuacion_promedio BETWEEN 0 AND 10)
);

CREATE TABLE Genero (
    id_genero      INT PRIMARY KEY,
    nombre_genero  VARCHAR(50) NOT NULL
);

CREATE TABLE Rol (
    id_rol      INT PRIMARY KEY,
    nombre_rol  VARCHAR(50) NOT NULL
);

CREATE TABLE Persona (
    id_persona           INT PRIMARY KEY,
    nombre_persona       VARCHAR(100) NOT NULL,
    nombre_sexo          VARCHAR(20),
    nombre_nacionalidad  VARCHAR(50)
);

-- 2. Peliculas (depende de Clasificaciones_En_IMDb, relación 1 a 1)

CREATE TABLE Peliculas (
    id_pelicula       INT PRIMARY KEY,
    titulo_pelicula   VARCHAR(200) NOT NULL,
    anio_estreno      SMALLINT,
    presupuesto       NUMERIC(15,2),
    recaudacion       NUMERIC(15,2),
    id_clasificacion  INT NOT NULL UNIQUE,
    FOREIGN KEY (id_clasificacion)
        REFERENCES Clasificaciones_En_IMDb (id_clasificacion)
);

-- 3. Tablas que dependen de Peliculas (relaciones muchos a muchos / multivaluadas)

CREATE TABLE Pelicula_Genero (
    id_pelicula  INT,
    id_genero    INT,
    PRIMARY KEY (id_pelicula, id_genero),
    FOREIGN KEY (id_pelicula) REFERENCES Peliculas (id_pelicula),
    FOREIGN KEY (id_genero)   REFERENCES Genero (id_genero)
);

CREATE TABLE Pelicula_Idioma (
    id_pelicula    INT,
    nombre_idioma  VARCHAR(50),
    PRIMARY KEY (id_pelicula, nombre_idioma),
    FOREIGN KEY (id_pelicula) REFERENCES Peliculas (id_pelicula)
);

CREATE TABLE Pelicula_Lugar_Filmacion (
    id_pelicula             INT,
    nombre_lugar_filmacion  VARCHAR(100),
    PRIMARY KEY (id_pelicula, nombre_lugar_filmacion),
    FOREIGN KEY (id_pelicula) REFERENCES Peliculas (id_pelicula)
);

-- 4. Participacion (depende de Peliculas, Persona y Rol)

CREATE TABLE Participacion (
    id_participacion  INT PRIMARY KEY,
    id_pelicula       INT NOT NULL,
    id_persona        INT NOT NULL,
    id_rol            INT NOT NULL,
    FOREIGN KEY (id_pelicula) REFERENCES Peliculas (id_pelicula),
    FOREIGN KEY (id_persona)  REFERENCES Persona (id_persona),
    FOREIGN KEY (id_rol)      REFERENCES Rol (id_rol),
    UNIQUE (id_pelicula, id_persona, id_rol)
);
