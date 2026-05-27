-- ============================================================
-- LocalWeb Vendedoras — Supabase PRO setup
-- Ejecutar en: supabase.com > SQL Editor > New query
-- ============================================================

-- 1. Columna last_seen para online indicator
ALTER TABLE public.perfiles ADD COLUMN IF NOT EXISTS last_seen TIMESTAMPTZ;

-- 2. Ampliar constraint de rol para incluir 'admin'
ALTER TABLE public.perfiles DROP CONSTRAINT IF EXISTS perfiles_rol_check;
ALTER TABLE public.perfiles ADD CONSTRAINT perfiles_rol_check
  CHECK (rol IN ('pendiente','vendedora','admin','superadmin'));

-- 3. Storage bucket para fotos de clientes
INSERT INTO storage.buckets (id, name, public)
VALUES ('fotos-clientes', 'fotos-clientes', true)
ON CONFLICT DO NOTHING;

-- Política: cualquier usuario autenticado puede subir fotos
CREATE POLICY "upload_fotos" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'fotos-clientes' AND auth.role() = 'authenticated'
  );

-- Política: lectura pública de fotos
CREATE POLICY "read_fotos" ON storage.objects
  FOR SELECT USING (bucket_id = 'fotos-clientes');

-- 4. Cron semanal via pg_cron (lunes 11:00 UTC = 08:00 Argentina)
--    Requiere extensión pg_cron habilitada en Supabase Pro
SELECT cron.schedule(
  'reporte-semanal-wa',
  '0 11 * * 1',
  $$
    SELECT net.http_post(
      url    := 'https://qzwphmnxirsgqtotnzzq.supabase.co/functions/v1/reporte-semanal',
      body   := '{}'::jsonb,
      headers := '{"Authorization":"Bearer TU_ANON_KEY_AQUI"}'::jsonb
    );
  $$
);

-- ============================================================
-- NOTA: reemplazá 'TU_ANON_KEY_AQUI' por el valor de SUPABASE_ANON_KEY
-- que está en config.js de tu app.
-- ============================================================
