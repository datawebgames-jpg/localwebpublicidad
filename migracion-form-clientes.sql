-- ============================================================
-- Migración: formulario completo de clientes
-- Ejecutar en Supabase Dashboard → SQL Editor
-- ============================================================

alter table clientes add column if not exists estado_cliente    text    default 'potencial';
-- potencial / bueno / amargado / desinteresado / activo / no_volver

alter table clientes add column if not exists datos_completos   boolean default false;
alter table clientes add column if not exists proximo_contacto  date;
alter table clientes add column if not exists mejor_momento     text;

-- Presencia digital extra
alter table clientes add column if not exists tiene_toko        boolean default false;
alter table clientes add column if not exists toko_url          text;
alter table clientes add column if not exists tiene_mercadoshops boolean default false;
alter table clientes add column if not exists tiene_tiendanube  boolean default false;

-- Publicidad actual del comercio (lo que ya gastan)
alter table clientes add column if not exists publica_radio     boolean default false;
alter table clientes add column if not exists radio_nombre      text;
alter table clientes add column if not exists radio_precio      numeric(12,2);

alter table clientes add column if not exists publica_tv        boolean default false;
alter table clientes add column if not exists tv_nombre         text;
alter table clientes add column if not exists tv_precio         numeric(12,2);

alter table clientes add column if not exists publica_diario    boolean default false;
alter table clientes add column if not exists diario_nombre     text;
alter table clientes add column if not exists diario_precio     numeric(12,2);

alter table clientes add column if not exists publica_portal    boolean default false;
alter table clientes add column if not exists portal_nombre     text;
alter table clientes add column if not exists portal_precio     numeric(12,2);

alter table clientes add column if not exists presupuesto_total numeric(12,2);
-- suma estimada de lo que gastan en publicidad por mes

-- Relación con nosotros
alter table clientes add column if not exists contratado_con    text    default 'ninguno';
-- ninguno / tc / cw / ambos

-- Auditoría
alter table clientes add column if not exists agregado_por_nombre text;
-- nombre del vendedor que lo cargó (además del vendedora_id)
