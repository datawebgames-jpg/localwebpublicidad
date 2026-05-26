-- ============================================================
-- LocalWeb Vendedoras — Setup Supabase
-- Ejecutar en: supabase.com > tu proyecto > SQL Editor > New query
-- ============================================================

-- 1. Tabla de perfiles (primero, antes que la función)
CREATE TABLE IF NOT EXISTS public.perfiles (
  id         UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nombre     TEXT NOT NULL,
  apellido   TEXT NOT NULL,
  telefono   TEXT,
  avatar_url TEXT,
  rol        TEXT NOT NULL DEFAULT 'pendiente'
             CHECK (rol IN ('pendiente','vendedora','superadmin')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Función auxiliar (ahora que perfiles ya existe)
CREATE OR REPLACE FUNCTION public.get_mi_rol()
RETURNS TEXT LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public AS $$
  SELECT rol FROM perfiles WHERE id = auth.uid();
$$;

-- 3. RLS en perfiles
ALTER TABLE public.perfiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "perfiles_select" ON public.perfiles
  FOR SELECT USING (auth.uid() = id OR get_mi_rol() = 'superadmin');
CREATE POLICY "perfiles_insert" ON public.perfiles
  FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "perfiles_update" ON public.perfiles
  FOR UPDATE USING (auth.uid() = id OR get_mi_rol() = 'superadmin');

-- 4. Tabla de clientes
CREATE TABLE IF NOT EXISTS public.clientes (
  id             UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  vendedora_id   UUID REFERENCES public.perfiles(id) ON DELETE SET NULL,
  nombre_negocio TEXT NOT NULL,
  propietario    TEXT,
  telefono       TEXT,
  email          TEXT,
  direccion      TEXT,
  rubro          TEXT,
  interesado     TEXT DEFAULT 'indeciso'
                 CHECK (interesado IN ('si','no','indeciso')),
  pagina         TEXT CHECK (pagina IN ('trabajoscerca','localweb','dataweb','ninguna')),
  plan           TEXT,
  observaciones  TEXT,
  fotos          TEXT[],
  created_at     TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "clientes_select" ON public.clientes
  FOR SELECT USING (vendedora_id = auth.uid() OR get_mi_rol() = 'superadmin');
CREATE POLICY "clientes_insert" ON public.clientes
  FOR INSERT WITH CHECK (vendedora_id = auth.uid());
CREATE POLICY "clientes_update" ON public.clientes
  FOR UPDATE USING (vendedora_id = auth.uid() OR get_mi_rol() = 'superadmin');

-- 5. Tabla de actividad (logins)
CREATE TABLE IF NOT EXISTS public.actividad_login (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  vendedora_id UUID REFERENCES public.perfiles(id) ON DELETE SET NULL,
  nombre       TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.actividad_login ENABLE ROW LEVEL SECURITY;
CREATE POLICY "actividad_insert" ON public.actividad_login
  FOR INSERT WITH CHECK (vendedora_id = auth.uid());
CREATE POLICY "actividad_select" ON public.actividad_login
  FOR SELECT USING (get_mi_rol() = 'superadmin');

-- ============================================================
-- PASO FINAL: hacerte superadmin (después de registrarte en login.html)
-- Reemplazá con tu email real y ejecutá esta línea por separado:
-- ============================================================
-- UPDATE perfiles SET rol = 'superadmin'
-- WHERE id = (SELECT id FROM auth.users WHERE email = 'TU@EMAIL.COM');
