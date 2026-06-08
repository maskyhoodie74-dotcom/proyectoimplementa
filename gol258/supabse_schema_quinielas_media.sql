-- ============================================================
-- SCRIPT DE ACTUALIZACIÓN: QUINIELAS Y HIGHLIGHTS
-- ============================================================

-- -------------------------------------------------------
-- 1. TABLA: quinielas
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.quinielas (
  id                 BIGSERIAL PRIMARY KEY,
  usuario_id         BIGINT REFERENCES public.usuario(id) ON DELETE CASCADE,
  partido_id         BIGINT REFERENCES public.calendario(id) ON DELETE CASCADE,
  goles_local_pred   INT NOT NULL,
  goles_visit_pred   INT NOT NULL,
  puntos_obtenidos   INT DEFAULT 0,
  created_at         TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(usuario_id, partido_id) -- Solo una predicción por partido por usuario
);

ALTER TABLE public.quinielas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública quinielas" ON public.quinielas FOR SELECT USING (true);
CREATE POLICY "Usuarios crean sus quinielas" ON public.quinielas FOR INSERT WITH CHECK (true);
CREATE POLICY "Usuarios actualizan sus quinielas" ON public.quinielas FOR UPDATE USING (true);

-- -------------------------------------------------------
-- 2. TABLA: highlights
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.highlights (
  id          BIGSERIAL PRIMARY KEY,
  partido_id  BIGINT REFERENCES public.calendario(id) ON DELETE CASCADE,
  equipo_id   BIGINT REFERENCES public.equipos(id) ON DELETE CASCADE,
  url_media   TEXT NOT NULL,
  tipo        TEXT DEFAULT 'foto', -- foto | video
  descripcion TEXT,
  admin_id    BIGINT REFERENCES public.admin(id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.highlights ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura pública highlights" ON public.highlights FOR SELECT USING (true);
CREATE POLICY "Admin gestiona highlights" ON public.highlights FOR ALL USING (true) WITH CHECK (true);

-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================

-- ============================================================
-- 5. BUCKET DE ALMACENAMIENTO (media)
-- ============================================================
-- Nota: En algunos casos, la creación de buckets desde SQL directo requiere permisos especiales.
-- Si esto falla, crea el bucket "media" manualmente en la consola de Supabase y ponlo como público.

INSERT INTO storage.buckets (id, name, public) 
VALUES ('media', 'media', true)
ON CONFLICT (id) DO NOTHING;

-- Políticas para el bucket "media" (Permitir lectura a todos, permitir subida a usuarios autenticados)
CREATE POLICY "Public Access" 
ON storage.objects FOR SELECT 
USING ( bucket_id = 'media' );

CREATE POLICY "Authenticated users can upload media" 
ON storage.objects FOR INSERT 
WITH CHECK ( bucket_id = 'media' AND auth.role() = 'authenticated' );

CREATE POLICY "Authenticated users can update media" 
ON storage.objects FOR UPDATE 
WITH CHECK ( bucket_id = 'media' AND auth.role() = 'authenticated' );

CREATE POLICY "Authenticated users can delete media" 
ON storage.objects FOR DELETE 
USING ( bucket_id = 'media' AND auth.role() = 'authenticated' );
