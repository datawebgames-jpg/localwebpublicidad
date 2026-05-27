// Edge Function: reporte-semanal
// Cron: cada lunes a las 11:00 UTC (08:00 Argentina)
// supabase/functions/reporte-semanal/index.ts

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL     = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const WA_PHONE         = Deno.env.get('WA_PHONE')!;
const WA_APIKEY        = Deno.env.get('WA_APIKEY')!;

Deno.serve(async () => {
  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE);

  // Clientes de los últimos 7 días
  const desde = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

  const { data: clientes } = await sb
    .from('clientes')
    .select('vendedora_id, interesado, pagina, perfiles(nombre, apellido)')
    .gte('created_at', desde);

  if (!clientes || clientes.length === 0) {
    await sendWA('📊 *Reporte Semanal LocalWeb*\n\nSin actividad esta semana. ¡A salir a vender! 💪');
    return new Response('ok');
  }

  // Agrupar por vendedora
  const porVendedora: Record<string, { nombre: string; total: number; si: number; tc: number; lw: number; dw: number }> = {};

  for (const c of clientes) {
    const id = c.vendedora_id as string;
    const p  = c.perfiles as { nombre: string; apellido: string } | null;
    if (!id) continue;
    if (!porVendedora[id]) {
      porVendedora[id] = {
        nombre: p ? `${p.nombre} ${p.apellido}` : 'Sin nombre',
        total: 0, si: 0, tc: 0, lw: 0, dw: 0
      };
    }
    porVendedora[id].total++;
    if (c.interesado === 'si') porVendedora[id].si++;
    if (c.pagina === 'trabajoscerca') porVendedora[id].tc++;
    if (c.pagina === 'localweb')     porVendedora[id].lw++;
    if (c.pagina === 'dataweb')      porVendedora[id].dw++;
  }

  // Ordenar por total desc
  const ranking = Object.values(porVendedora).sort((a, b) => b.total - a.total);
  const medallas = ['🥇', '🥈', '🥉'];

  let msg = `📊 *Reporte Semanal LocalWeb*\n`;
  msg += `_${new Date().toLocaleDateString('es-AR', { weekday:'long', day:'2-digit', month:'long' })}_\n\n`;
  msg += `*Total de clientes registrados: ${clientes.length}*\n`;
  msg += `Interesados: ${clientes.filter(c => c.interesado === 'si').length} ✅\n\n`;

  ranking.forEach((v, i) => {
    const medal = medallas[i] ?? '▪️';
    msg += `${medal} *${v.nombre}*\n`;
    msg += `   Visitas: ${v.total} | Interesados: ${v.si}\n`;
    const plats = [v.tc && `TC:${v.tc}`, v.lw && `LW:${v.lw}`, v.dw && `DW:${v.dw}`].filter(Boolean).join(' · ');
    if (plats) msg += `   ${plats}\n`;
    msg += '\n';
  });

  msg += `_LocalWeb · Sistema de Vendedoras_`;

  await sendWA(msg);
  return new Response('ok');
});

async function sendWA(text: string) {
  const url = `https://api.callmebot.com/whatsapp.php?phone=${WA_PHONE}&text=${encodeURIComponent(text)}&apikey=${WA_APIKEY}`;
  await fetch(url).catch(() => {});
}
