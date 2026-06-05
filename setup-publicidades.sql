-- ============================================================
-- Publicidades LocalWeb — ejecutar en Supabase SQL Editor
-- ============================================================

-- Tabla de planes de publicidad
create table if not exists publicidades (
  id           uuid default gen_random_uuid() primary key,
  nombre       text not null,
  tipo         text not null default 'banner_inicio',
  -- tipos: 'banner_inicio' | 'rotativo' | 'fijo'
  con_link     boolean default false,
  con_popup    boolean default false,
  imagen_data  text,   -- base64 de la imagen de ubicación en la página
  precio       numeric(12,2) not null default 0,
  comision_1   numeric(5,2)  not null default 0,  -- % comisión 1er pago
  comision_2   numeric(5,2)  not null default 0,  -- % comisión desde 2da cuota
  activo       boolean default true,
  created_at   timestamptz default now()
);

-- RLS
alter table publicidades enable row level security;

create policy "Lectura pública publicidades"
  on publicidades for select using (true);

create policy "Admins gestionan publicidades"
  on publicidades for all
  using (
    exists (
      select 1 from perfiles
      where id = auth.uid()
      and rol in ('admin', 'superadmin')
    )
  );

-- Vincular clientes con la publicidad vendida (opcional pero recomendado)
alter table clientes
  add column if not exists publicidad_id uuid references publicidades(id);
