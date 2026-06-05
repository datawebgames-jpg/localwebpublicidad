-- ============================================================
-- Publicidades LocalWeb — ejecutar en Supabase SQL Editor
-- ============================================================

-- Tabla principal de planes de publicidad
create table if not exists publicidades (
  id           uuid default gen_random_uuid() primary key,
  nombre       text not null,
  ubicacion    text not null default 'banner_inicio',
  -- ubicacion: 'banner_inicio' | 'banner_buscador' | 'banner_perfil' | 'banner_popup'
  formato      text not null default 'fijo',
  -- formato: 'fijo' | 'rotativo' | 'gif'
  con_link     boolean default false,
  con_popup    boolean default false,
  imagen_data  text,
  precio       numeric(12,2) not null default 0,
  comision_1   numeric(5,2)  not null default 0,
  comision_2   numeric(5,2)  not null default 0,
  activo       boolean default true,
  created_at   timestamptz default now()
);

alter table publicidades enable row level security;

create policy "Lectura pública publicidades"
  on publicidades for select using (true);

create policy "Admins gestionan publicidades"
  on publicidades for all
  using (exists (
    select 1 from perfiles
    where id = auth.uid() and rol in ('admin','superadmin')
  ));

-- Vendedoras asignadas a cada publicidad (muchos a muchos)
create table if not exists pub_vendedoras (
  publicidad_id uuid references publicidades(id) on delete cascade,
  vendedora_id  uuid references perfiles(id)     on delete cascade,
  primary key (publicidad_id, vendedora_id)
);

alter table pub_vendedoras enable row level security;

create policy "Lectura pública pub_vendedoras"
  on pub_vendedoras for select using (true);

create policy "Admins gestionan pub_vendedoras"
  on pub_vendedoras for all
  using (exists (
    select 1 from perfiles
    where id = auth.uid() and rol in ('admin','superadmin')
  ));

-- Precios sugeridos por vendedoras (precios de competencia en su zona)
create table if not exists precios_sugeridos (
  id           uuid default gen_random_uuid() primary key,
  vendedora_id uuid references perfiles(id) on delete cascade,
  ciudad       text not null,
  items        jsonb not null default '[]',
  -- cada item: { medio, descripcion, precio }
  -- medio: 'radio' | 'diario' | 'web' | 'tv' | 'revista' | 'otro'
  notas        text,
  created_at   timestamptz default now()
);

alter table precios_sugeridos enable row level security;

create policy "Vendedoras insertan sus precios"
  on precios_sugeridos for insert
  with check (vendedora_id = auth.uid());

create policy "Admins leen todos los precios"
  on precios_sugeridos for select
  using (exists (
    select 1 from perfiles
    where id = auth.uid() and rol in ('admin','superadmin')
  ));

create policy "Vendedoras leen sus propios precios"
  on precios_sugeridos for select
  using (vendedora_id = auth.uid());

-- Vincular clientes con la publicidad vendida
alter table clientes
  add column if not exists publicidad_id uuid references publicidades(id);

-- Columna ciudad en perfiles (para autocompletar en el form de precios)
alter table perfiles
  add column if not exists ciudad text;
