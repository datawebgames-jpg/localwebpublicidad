-- Fix: permitir que vendedores puedan buscar en clientes para el buscador
-- La política anterior solo dejaba ver los propios. Ahora cualquier usuario
-- autenticado puede leer (pero solo admin/propietario puede modificar).

-- Eliminar política vieja de SELECT
drop policy if exists "clientes_select" on clientes;
drop policy if exists "Vendedoras ven sus clientes" on clientes;
drop policy if exists "Admins leen clientes" on clientes;

-- Nueva política: cualquier usuario logueado puede buscar/leer clientes
create policy "clientes_select" on clientes
  for select
  using (auth.role() = 'authenticated');

-- La política de UPDATE/INSERT sigue restringida al propietario o admin
-- (si no existe ya, crearla)
do $$ begin
  if not exists (
    select 1 from pg_policies where tablename='clientes' and policyname='clientes_insert'
  ) then
    execute 'create policy "clientes_insert" on clientes for insert with check (
      vendedora_id = auth.uid() or get_mi_rol() in (''superadmin'',''admin'')
    )';
  end if;
end $$;

do $$ begin
  if not exists (
    select 1 from pg_policies where tablename='clientes' and policyname='clientes_update'
  ) then
    execute 'create policy "clientes_update" on clientes for update using (
      vendedora_id = auth.uid() or asignado_a = auth.uid() or get_mi_rol() in (''superadmin'',''admin'')
    )';
  end if;
end $$;
