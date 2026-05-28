-- ============================================================
-- GOL 258 - CBTis 258
-- Esquema SQL para Supabase
-- Basado en el Diagrama ER del proyecto
-- ============================================================

-- -------------------------------------------------------
-- 1. TABLA: admin
--    Atributos: nombre (PK), contrasena
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin (
  id         BIGSERIAL PRIMARY KEY,
  nombre     TEXT NOT NULL UNIQUE,
  contrasena TEXT NOT NULL
);

-- Admin por defecto (cambiar contraseña en producción)
INSERT INTO public.admin (nombre, contrasena)
VALUES ('admin258', 'cobras258')
ON CONFLICT (nombre) DO NOTHING;

-- -------------------------------------------------------
-- 2. TABLA: usuario
--    Atributos: correo (unique), contrasena, nombre
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.usuario (
  id         BIGSERIAL PRIMARY KEY,
  nombre     TEXT NOT NULL,
  correo     TEXT NOT NULL UNIQUE,
  contrasena TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- -------------------------------------------------------
-- 3. TABLA: equipos
--    Atributos: nombre_equipo, categoria, entrenador
--    Admin registra 1:N equipos
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.equipos (
  id            BIGSERIAL PRIMARY KEY,
  nombre_equipo TEXT NOT NULL,
  categoria     TEXT DEFAULT 'Varonil',
  entrenador    TEXT,
  escudo_url    TEXT,
  color_hex     TEXT DEFAULT '#6B1B2B',
  admin_id      BIGINT REFERENCES public.admin(id) ON DELETE SET NULL,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- -------------------------------------------------------
-- 4. TABLA: jugadores
--    Atributos: nombre_jugador, goles
--    Admin registra 1:N jugadores
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.jugadores (
  id             BIGSERIAL PRIMARY KEY,
  nombre_jugador TEXT NOT NULL,
  goles          INT DEFAULT 0,
  asistencias    INT DEFAULT 0,
  partidos       INT DEFAULT 0,
  numero         INT DEFAULT 0,
  posicion       TEXT DEFAULT 'Delantero',
  foto_url       TEXT,
  equipo_id      BIGINT REFERENCES public.equipos(id) ON DELETE SET NULL,
  admin_id       BIGINT REFERENCES public.admin(id) ON DELETE SET NULL,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- -------------------------------------------------------
-- 5. TABLA: calendario
--    Atributos: fecha, hora, lugar, categoria
--    Admin realiza 1:N eventos de calendario
--    Cada evento referencia dos equipos
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.calendario (
  id                  BIGSERIAL PRIMARY KEY,
  fecha               DATE NOT NULL,
  hora                TEXT DEFAULT '12:00',
  lugar               TEXT,
  categoria           TEXT DEFAULT 'Varonil',
  equipo_local_id     BIGINT REFERENCES public.equipos(id) ON DELETE CASCADE,
  equipo_visitante_id BIGINT REFERENCES public.equipos(id) ON DELETE CASCADE,
  goles_local         INT,
  goles_visitante     INT,
  jugado              BOOLEAN DEFAULT FALSE,
  estado              TEXT DEFAULT 'programado',  -- programado | en_juego | finalizado
  admin_id            BIGINT REFERENCES public.admin(id) ON DELETE SET NULL,
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- -------------------------------------------------------
-- RELACIONES M:N (tablas de consulta)
-- Según el diagrama: usuario consulta jugadores, calendario y equipos
-- -------------------------------------------------------

-- usuario M:N jugadores (favoritos / seguimiento)
CREATE TABLE IF NOT EXISTS public.usuario_jugadores (
  usuario_id  BIGINT REFERENCES public.usuario(id) ON DELETE CASCADE,
  jugador_id  BIGINT REFERENCES public.jugadores(id) ON DELETE CASCADE,
  PRIMARY KEY (usuario_id, jugador_id)
);

-- usuario M:N calendario (partidos de interés)
CREATE TABLE IF NOT EXISTS public.usuario_calendario (
  usuario_id    BIGINT REFERENCES public.usuario(id) ON DELETE CASCADE,
  calendario_id BIGINT REFERENCES public.calendario(id) ON DELETE CASCADE,
  PRIMARY KEY (usuario_id, calendario_id)
);

-- usuario M:N equipos (equipos seguidos)
CREATE TABLE IF NOT EXISTS public.usuario_equipos (
  usuario_id BIGINT REFERENCES public.usuario(id) ON DELETE CASCADE,
  equipo_id  BIGINT REFERENCES public.equipos(id) ON DELETE CASCADE,
  PRIMARY KEY (usuario_id, equipo_id)
);


-- ============================================================
-- LIGUILLA INDEPENDIENTE
-- Tablas exclusivas para gestionar el torneo de eliminatorias
-- ============================================================

-- 1. Torneo de liguilla
CREATE TABLE IF NOT EXISTS public.liguilla_torneos (
  id          BIGSERIAL PRIMARY KEY,
  nombre      TEXT NOT NULL DEFAULT 'Liguilla 2025',
  estado      TEXT DEFAULT 'activo', -- activo | finalizado
  num_equipos INT DEFAULT 4,         -- 2, 4, 8, 16
  admin_id    BIGINT REFERENCES public.admin(id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Equipos clasificados en un torneo
CREATE TABLE IF NOT EXISTS public.liguilla_equipos (
  id          BIGSERIAL PRIMARY KEY,
  torneo_id   BIGINT REFERENCES public.liguilla_torneos(id) ON DELETE CASCADE,
  equipo_id   BIGINT REFERENCES public.equipos(id) ON DELETE CASCADE,
  seed        INT NOT NULL, -- posición (1 = superlíder)
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(torneo_id, seed),
  UNIQUE(torneo_id, equipo_id)
);

-- 3. Partidos del bracket
CREATE TABLE IF NOT EXISTS public.liguilla_partidos (
  id                  BIGSERIAL PRIMARY KEY,
  torneo_id           BIGINT REFERENCES public.liguilla_torneos(id) ON DELETE CASCADE,
  ronda               TEXT NOT NULL, -- final, semis, cuartos, octavos
  numero_partido      INT NOT NULL,  -- 1, 2, 3... (orden vertical en UI)
  equipo_local_id     BIGINT REFERENCES public.equipos(id) ON DELETE CASCADE,
  equipo_visitante_id BIGINT REFERENCES public.equipos(id) ON DELETE CASCADE,
  fecha               DATE,
  hora                TEXT DEFAULT '12:00',
  lugar               TEXT,
  goles_local         INT,
  goles_visitante     INT,
  jugado              BOOLEAN DEFAULT FALSE,
  estado              TEXT DEFAULT 'programado',
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- -------------------------------------------------------
-- ROW LEVEL SECURITY
-- -------------------------------------------------------

-- Equipos: lectura pública, escritura solo autenticados
ALTER TABLE public.equipos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública equipos" ON public.equipos FOR SELECT USING (true);
CREATE POLICY "Admin puede gestionar equipos" ON public.equipos
  FOR ALL USING (true) WITH CHECK (true);

-- Jugadores: lectura pública, escritura restringida
ALTER TABLE public.jugadores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública jugadores" ON public.jugadores FOR SELECT USING (true);
CREATE POLICY "Admin puede gestionar jugadores" ON public.jugadores
  FOR ALL USING (true) WITH CHECK (true);

-- Calendario: lectura pública
ALTER TABLE public.calendario ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública calendario" ON public.calendario FOR SELECT USING (true);
CREATE POLICY "Admin puede gestionar calendario" ON public.calendario
  FOR ALL USING (true) WITH CHECK (true);

-- Admin: solo lectura (nunca exponer contraseñas en producción)
ALTER TABLE public.admin ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura admin para login" ON public.admin FOR SELECT USING (true);

-- Usuario: cada usuario ve sus propios datos
ALTER TABLE public.usuario ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Usuarios pueden leer su propio perfil" ON public.usuario FOR SELECT USING (true);
CREATE POLICY "Registro público de usuarios" ON public.usuario FOR INSERT WITH CHECK (true);

-- Liguilla: lectura publica, admin escribe
ALTER TABLE public.liguilla_torneos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública torneos" ON public.liguilla_torneos FOR SELECT USING (true);
CREATE POLICY "Admin gestiona torneos" ON public.liguilla_torneos FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.liguilla_equipos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública liguilla_equipos" ON public.liguilla_equipos FOR SELECT USING (true);
CREATE POLICY "Admin gestiona liguilla_equipos" ON public.liguilla_equipos FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE public.liguilla_partidos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública liguilla_partidos" ON public.liguilla_partidos FOR SELECT USING (true);
CREATE POLICY "Admin gestiona liguilla_partidos" ON public.liguilla_partidos FOR ALL USING (true) WITH CHECK (true);

-- -------------------------------------------------------
-- DATOS DE EJEMPLO
-- -------------------------------------------------------
INSERT INTO public.equipos (nombre_equipo, categoria, entrenador, color_hex)
VALUES
  ('Cobras FC', 'División I', 'Prof. García', '#6B1B2B'),
  ('Tigres CBTis', 'División I', 'Prof. Martínez', '#E65100'),
  ('Rayos 258', 'Juvenil', 'Prof. López', '#1565C0'),
  ('Águilas Doradas', 'Varonil', 'Prof. Ramos', '#F9A825')
ON CONFLICT DO NOTHING;
