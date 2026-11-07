-- Instalação inicial completa da versão pssouvr. Execute uma vez no Supabase SQL Editor.
-- As partes podem ser repetidas: produtos/stamps/home sections não sobrescrevem edições existentes.


-- ===== supabase-setup.sql =====
-- DEUS É O JUIZ: Supabase para Auth, catálogo e resumo dos pedidos.
-- Não armazene CPF, telefone, CEP ou endereço nestas tabelas.
-- Execute no SQL Editor do projeto Supabase jioxcxezhgdffsjufejc.

begin;

create table if not exists public.products (
  slug text primary key,
  name text not null,
  category text not null,
  stamp text,
  price numeric(10,2) not null check (price >= 0),
  old_price numeric(10,2) check (old_price is null or old_price >= 0),
  sizes jsonb not null default '[]'::jsonb,
  colors jsonb not null default '[]'::jsonb,
  tag text,
  description text not null default '',
  image text not null default '',
  images jsonb not null default '[]'::jsonb,
  source_url text not null default '',
  active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.products add column if not exists images jsonb not null default '[]'::jsonb;

create table if not exists public.store_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

-- Somente dados operacionais não sensíveis. Os dados pessoais ficam cifrados no Neon.
create table if not exists public.order_summaries (
  order_id uuid primary key,
  request_id uuid not null unique,
  user_id uuid references auth.users(id) on delete set null,
  items jsonb not null default '[]'::jsonb,
  subtotal numeric(10,2) not null check (subtotal >= 0),
  status text not null default 'Aguardando confirmação de frete e pagamento',
  created_at timestamptz not null default now()
);

alter table public.products enable row level security;
alter table public.store_admins enable row level security;
alter table public.order_summaries enable row level security;

grant usage on schema public to anon, authenticated;
grant select on public.products to anon, authenticated;
grant insert, update, delete on public.products to authenticated;
grant select on public.store_admins to authenticated;
grant select on public.order_summaries to authenticated;
revoke all on public.order_summaries from anon;
revoke insert, update, delete on public.order_summaries from anon, authenticated;

insert into storage.buckets (id, name, public, file_size_limit)
values ('product-images', 'product-images', true, 1073741824)
on conflict (id) do update set public = true, file_size_limit = 1073741824;

do $policies$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='store_admins' and policyname='Admins can read their own membership') then
    execute $policy$ create policy "Admins can read their own membership" on public.store_admins for select to authenticated using ((select auth.uid()) = user_id) $policy$;
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='products' and policyname='Anyone can read active products') then
    execute $policy$ create policy "Anyone can read active products" on public.products for select to anon, authenticated using (active is true) $policy$;
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='products' and policyname='Store admins can read all products') then
    execute $policy$ create policy "Store admins can read all products" on public.products for select to authenticated using (exists (select 1 from public.store_admins where user_id = (select auth.uid()))) $policy$;
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='products' and policyname='Store admins can insert products') then
    execute $policy$ create policy "Store admins can insert products" on public.products for insert to authenticated with check (exists (select 1 from public.store_admins where user_id = (select auth.uid()))) $policy$;
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='products' and policyname='Store admins can update products') then
    execute $policy$ create policy "Store admins can update products" on public.products for update to authenticated using (exists (select 1 from public.store_admins where user_id = (select auth.uid()))) with check (exists (select 1 from public.store_admins where user_id = (select auth.uid()))) $policy$;
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='products' and policyname='Store admins can delete products') then
    execute $policy$ create policy "Store admins can delete products" on public.products for delete to authenticated using (exists (select 1 from public.store_admins where user_id = (select auth.uid()))) $policy$;
  end if;
  if not exists (select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='Public can read product images') then
    execute $policy$ create policy "Public can read product images" on storage.objects for select to anon, authenticated using (bucket_id = 'product-images') $policy$;
  end if;
  if not exists (select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='Store admins can upload product images') then
    execute $policy$ create policy "Store admins can upload product images" on storage.objects for insert to authenticated with check (bucket_id = 'product-images' and exists (select 1 from public.store_admins where user_id = (select auth.uid()))) $policy$;
  end if;
  if not exists (select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='Store admins can update product images') then
    execute $policy$ create policy "Store admins can update product images" on storage.objects for update to authenticated using (bucket_id = 'product-images' and exists (select 1 from public.store_admins where user_id = (select auth.uid()))) with check (bucket_id = 'product-images' and exists (select 1 from public.store_admins where user_id = (select auth.uid()))) $policy$;
  end if;
  if not exists (select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='Store admins can delete product images') then
    execute $policy$ create policy "Store admins can delete product images" on storage.objects for delete to authenticated using (bucket_id = 'product-images' and exists (select 1 from public.store_admins where user_id = (select auth.uid()))) $policy$;
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='order_summaries' and policyname='Customers can read their own order summaries') then
    execute $policy$ create policy "Customers can read their own order summaries" on public.order_summaries for select to authenticated using (user_id = (select auth.uid())) $policy$;
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='order_summaries' and policyname='Store admins can read order summaries') then
    execute $policy$ create policy "Store admins can read order summaries" on public.order_summaries for select to authenticated using (exists (select 1 from public.store_admins where user_id = (select auth.uid()))) $policy$;
  end if;
end
$policies$;

create index if not exists products_active_sort_idx on public.products (active, sort_order);
create index if not exists order_summaries_user_created_idx on public.order_summaries (user_id, created_at desc);

-- Se a conta de admin já existir, ela será associada. Se ainda não existir,
-- execute o INSERT ao final depois de criar a conta em Authentication > Users.
insert into public.store_admins (user_id)
select id from auth.users where lower(email) = lower('roch4v4@gmail.com')
on conflict (user_id) do nothing;

commit;


-- ===== supabase-seed-products.sql =====
-- Catálogo inicial gerado de products.js. Reexecutar não substitui preços alterados no painel.
insert into public.products (slug,name,category,stamp,price,old_price,sizes,colors,tag,description,image,source_url,active,sort_order)
values
('bala-clava-anti-sistem', 'BALA-CLAVA ANTI SISTEM BRANCA', 'Balaclavas', 'anti-sistema-club', 19.99, 34.99, '["Único"]'::jsonb, '["Preto"]'::jsonb, 'Oferta', 'TAMANHO UNICO, TECIDO ELASTANO IDEAL PARA O CONFORTO E RESPIRAÇÃO NO DIA A DIA', 'https://cdn.dooca.store/160956/products/1e6f1619-b5c7-4b95-b2ee-62e3791b2d0b-5zo5s_495x495+fill_ffffff+crop_center.png?v=1786415172', 'https://www.deuseojuiz.com/bala-clava-anti-sistem', true, 1),
('camisa-oversize-anti-sistem-branca', 'CAMISA OVERSIZE / ANTI SISTEM / BRANCA', 'Camisas', 'anti-sistema-club', 99.9, null, '["P","M","G","GG"]'::jsonb, '["Branco"]'::jsonb, null, 'TECIDO 100% ALGODÃO MALHÃO COM MODELAGEM OVERSIZE', 'https://cdn.dooca.store/160956/products/d12061ce-e71b-4ad1-a386-9101162bf561-yk4wu_495x495+fill_ffffff+crop_center.png?v=1786414973', 'https://www.deuseojuiz.com/camisa-oversize-anti-sistem-branca', true, 2),
('camisa-malhao-anti-sistem', 'CAMISA MALHÃO OVERSIZE / ANTI SISTEM', 'Camisas', 'anti-sistema-club', 99.9, null, '["P","M","G","GG"]'::jsonb, '["Preto"]'::jsonb, null, null, 'https://cdn.dooca.store/160956/products/711dba15-6c35-41e4-8024-5ce4edae5d4f-r8df6_495x495+fill_ffffff+crop_center.png?v=1786414004', 'https://www.deuseojuiz.com/camisa-malhao-oversize-anti-sistem', true, 3),
('camisa-so-deus-pode-me-julgar', 'CAMISA PRETA MALHA PREMIUM / SÓ DEUS PODE ME JULGAR', 'Camisas', 'deus', 59.9, null, '["P","M","G","GG"]'::jsonb, '["Preto"]'::jsonb, null, 'TECIDO 30.1 PREMIUM', 'https://cdn.dooca.store/160956/products/16f23e25-61fc-4c44-8242-7ba7fec43f04-nvuic_495x495+fill_ffffff+crop_center.jpg?v=1783523578', 'https://www.deuseojuiz.com/camisa-preta-malha-so-deus-pode-me-julgar', true, 4),
('camisa-offwhite-oversize-malhao', 'CAMISA OFFWHITE OVERSIZE MALHÃO', 'Camisas', null, 99.9, null, '["P","M","G","GG"]'::jsonb, '["Off-white"]'::jsonb, null, 'TECIDO 100% ALGODÃO MALHÃO COM MODELAGEM OVERIZE', 'https://cdn.dooca.store/160956/products/1c8f380b-9b3c-40fd-acb9-96bbff9ed3f8-u8imz_495x495+fill_ffffff+crop_center.jpg?v=1777931337', 'https://www.deuseojuiz.com/camisa-offwhite-oversize-malhao', true, 5),
('camisa-malhao-frente-unica', 'CAMISA MALHÃO OVERSIZE / FRENTE ÚNICA', 'Camisas', 'deus', 99.9, null, '["P","M","G","GG"]'::jsonb, '["Preto"]'::jsonb, null, null, 'https://cdn.dooca.store/160956/products/ba37214a-066c-43ae-936d-00c508142fcb-gbpiu_495x495+fill_ffffff+crop_center.png?v=1785362493', 'https://www.deuseojuiz.com/camisa-malhao-oversize-frente-unica', true, 6),
('moletom-dj-cinza', 'MOLETOM 3 CABOS DEUS É O JUIZ GANG', 'Moletons', 'deus', 119.9, 179.9, '["P","M","G","GG"]'::jsonb, '["Cinza"]'::jsonb, 'Oferta', 'MOLETOM 3 CABOS DEUS É O JUIZ', 'https://cdn.dooca.store/160956/products/e3e8713c-86ba-407a-93b9-6c66bcee46b5-wddoz_495x495+fill_ffffff+crop_center.png?v=1784159253', 'https://www.deuseojuiz.com/moletom-3-cabos-dj-cinza', true, 7),
('casaco-moletom-3-cabos-1', 'CASACO PRETO DEUS É O JUIZ GANG MOLETOM 3 CABOS', 'Moletons', 'deus', 119.9, 179.9, '["P","M","G","GG"]'::jsonb, '["Preto"]'::jsonb, 'Oferta', 'DEUS É O JUIZ GANG', 'https://cdn.dooca.store/160956/products/73f63dee-7b4a-4e8a-ac9d-1e094a86d3a2-2-mdws7_495x495+fill_ffffff+crop_center.jpg?v=1786148945', 'https://www.deuseojuiz.com/casaco-moletom-3-cabos-1', true, 8),
('casaco-moletom-3-cabos', 'CASACO MOLETOM 3 CABOS', 'Moletons', 'deus', 119.9, 179.9, '["P","M","G","GG"]'::jsonb, '["Preto"]'::jsonb, 'Oferta', 'SÓ DEUS PODE ME JULGAR', 'https://cdn.dooca.store/160956/products/b297d735-0630-42e9-8de6-155008ad6ddd-2-953yk_495x495+fill_ffffff+crop_center.jpg?v=1786148791', 'https://www.deuseojuiz.com/casaco-moletom-3-cabos', true, 9),
('camisa-oversize-off-hammer', 'CAMISA OVERSIZE OFF HAMMER', 'Camisas', null, 99.9, null, '["P","M","G","GG"]'::jsonb, '["Off-white"]'::jsonb, 'Novo', 'CAMISA TECIDO MALHÃO 100% ALGODÃO ESTAMPA SEM MARTELO', 'https://cdn.dooca.store/160956/products/14b9b396-5ac9-4fff-b8bf-9bdb4b96a535-4vk8q_495x495+fill_ffffff+crop_center.png?v=1791382388', 'https://www.deuseojuiz.com/camisa-oversize', true, 10),
('corta-vento-impermeavel', 'CORTA VENTO IMPERMEÁVEL', 'Jaquetas', null, 219.9, null, '["P","M","G","GG"]'::jsonb, '["Preto"]'::jsonb, 'Novo', 'CORTA VENTO IMPERMEÁVEL, FORRADO COM CAPUZ REMOVIVEL', 'https://cdn.dooca.store/160956/products/0a3ca825-dfc6-4e56-8e32-ab882f1a551a-kgvbb_495x495+fill_ffffff+crop_center.jpg?v=1788736977', 'https://www.deuseojuiz.com/corta-vento-impermeavel', true, 11),
('moletom-3-cabos-dj-preto', 'MOLETOM 3 CABOS D&J / PRETO', 'Moletons', 'deus', 179.9, null, '["P","M","G","GG"]'::jsonb, '["Preto"]'::jsonb, null, 'MOLETOM 3 CABOS DEUS É O JUIZ', 'https://cdn.dooca.store/160956/products/73499458-99cd-49a0-a352-6b66800da2ca-2-6kcwp_495x495+fill_ffffff+crop_center.jpg?v=1783790569', 'https://www.deuseojuiz.com/moletom-3-cabos-dj-preto-ajuste-interno-de-gorro', true, 12),
('camisa-deus-e-o-juiz-preta', 'CAMISA DEUS É O JUIZ PRETA', 'Camisas', 'deus', 99.9, null, '["P","M","G","GG"]'::jsonb, '["Preto"]'::jsonb, null, 'A MAIS PEDIDA! TECIDO 100% ALGODÃO MALHÃO COM MODELAGEM PADRÃO', 'https://cdn.dooca.store/160956/products/cd36d496-6c09-4097-a6ba-28804bdc0ff3-llqrf_495x495+fill_ffffff+crop_center.jpg?v=1789155563', 'https://www.deuseojuiz.com/camisa-malhao-deus-e-o-juiz-100-algodao', true, 13),
('calca-moletom-street-preta', 'CALÇA DE MOLETOM STREET / PRETA', 'Calças', null, 119.9, null, '["P","M","G","GG"]'::jsonb, '["Preto"]'::jsonb, null, null, 'https://cdn.dooca.store/160956/products/img-3997-n0gyr_495x495+fill_ffffff+crop_center.jpg?v=1787174969', 'https://www.deuseojuiz.com/calca-de-moletom-street-preta', true, 14),
('calca-moletom-street-cinza', 'CALÇA DE MOLETOM STREET / CINZA', 'Calças', null, 119.9, null, '["P","M","G","GG"]'::jsonb, '["Cinza"]'::jsonb, null, 'CALÇA DE MOLETOM MODELO STREET', 'https://cdn.dooca.store/160956/products/img-4018-ra8ce_495x495+fill_ffffff+crop_center.jpg?v=1787176737', 'https://www.deuseojuiz.com/calca-de-moletom-street-cinza', true, 15),
('bala-clava-longa', 'BALA CLAVA LONGA', 'Balaclavas', null, 29.99, null, '["Único"]'::jsonb, '["Preto"]'::jsonb, null, null, 'https://cdn.dooca.store/160956/products/7105a196-990a-47fa-8d6e-08fc351b85f5-of9mu_495x495+fill_ffffff+crop_center.png?v=1784826428', 'https://www.deuseojuiz.com/bala-clava-longa', true, 16),
('bala-clava-anti-sistema-estampa', 'BALA CLAVA ANTI SISTEMA', 'Balaclavas', 'anti-sistema-club', 19.99, 34.99, '["Único"]'::jsonb, '["Preto"]'::jsonb, 'Oferta', null, 'https://cdn.dooca.store/160956/products/5d4c8dc9-22c5-45d7-96d8-5d4b98c330c8-k7els_495x495+fill_ffffff+crop_center.jpg?v=1786413699', 'https://www.deuseojuiz.com/bala-clava-anti-sistema', true, 17),
('bala-clava-deus-e-o-juiz', 'BALA-CLAVA DEUS É O JUIZ', 'Balaclavas', 'deus', 34.99, null, '["Único"]'::jsonb, '["Preto"]'::jsonb, null, null, 'https://cdn.dooca.store/160956/products/a690b594-a334-4ed4-b2f5-847e2cc92b6a-9vfq8_495x495+fill_ffffff+crop_center.jpg?v=1790871970', 'https://www.deuseojuiz.com/bala-clava-deus-e-o-juiz', true, 18),
('mochila-gang', 'MOCHILA GANG', 'Bags', null, 114.9, null, '["Único"]'::jsonb, '["Preto"]'::jsonb, 'Novo', 'MOCHILA COM ACABAMENTO PREMIUM, PADRÃO SEM REFIL', 'https://cdn.dooca.store/160956/products/img-1226-slg5g_495x495+fill_ffffff+crop_center.jpg?v=1789491841', 'https://www.deuseojuiz.com/mochila-gang', true, 19),
('bag-slin', 'BAG SLIN COM ALÇA REMOVÍVEL', 'Bags', null, 59.9, null, '["Único"]'::jsonb, '["Preto"]'::jsonb, 'Novo', null, 'https://cdn.dooca.store/160956/products/img-1241-ndic1_495x495+fill_ffffff+crop_center.jpg?v=1789493342', 'https://www.deuseojuiz.com/bag-de-3-bolsos-com-alca-removivel', true, 20),
('mochila-244', 'MOCHILA 244 COM REFIL PARA LÍQUIDOS', 'Bags', null, 199.9, null, '["Único"]'::jsonb, '["Preto"]'::jsonb, 'Novo', null, 'https://cdn.dooca.store/160956/products/img-1223-wkkam_495x495+fill_ffffff+crop_center.jpg?v=1789491528', 'https://www.deuseojuiz.com/mochila-244-com-refil-de-agua', true, 21),
('jaqueta-deus-e-o-juiz', 'JAQUETA DEUS É O JUIZ', 'Jaquetas', 'deus', 119.9, null, '["P","M","G","GG"]'::jsonb, '["Preto"]'::jsonb, null, 'JAQUETA COM ZIPER', 'https://cdn.dooca.store/160956/products/img-9221-kbchj_495x495+fill_ffffff+crop_center.png?v=1788642416', 'https://www.deuseojuiz.com/casaco-de-camurca-deus-e-o-juiz', true, 22),
('cropped-so-deus-pode-me-julgar-preto', 'CROPPED PRETO SÓ DEUS PODE ME JULGAR', 'Camisas', 'deus', 59.99, null, '["P","M","G","GG"]'::jsonb, '["Preto"]'::jsonb, null, 'TAMANHO ÚNICO, MODELAGEM OVERSIZE, TECIDO MALHÃO 100% ALGODÃO', 'https://cdn.dooca.store/160956/products/b779b54c-af98-4426-81c9-c59eff1fd117-qrif0_495x495+fill_ffffff+crop_center.png?v=1788636898', 'https://www.deuseojuiz.com/cropped-preto-so-deus-pode-me-julgar', true, 23),
('cropped-deus-e-o-juiz-preto', 'CROPPED PRETO DEUS É O JUIZ', 'Camisas', 'deus', 59.99, null, '["P","M","G","GG"]'::jsonb, '["Preto"]'::jsonb, null, 'TAMANHO ÚNICO, MODELAGEM OVERSIZE, TECIDO MALHÃO 100% ALGODÃO', 'https://cdn.dooca.store/160956/products/285fbd08-b6d2-49b3-ab21-87db0c678e07-2-yg0av_495x495+fill_ffffff+crop_center.jpg?v=1788636380', 'https://www.deuseojuiz.com/cropped-deus-e-o-juiz', true, 24),
('cropped-deus-e-o-juiz-branco', 'CROPPED BRANCO DEUS É O JUIZ', 'Camisas', 'deus', 59.99, null, '["P","M","G","GG"]'::jsonb, '["Branco"]'::jsonb, null, 'TAMANHO ÚNICO, MODELAGEM OVERSIZE, TECIDO MALHÃO 100% ALGODÃO', 'https://cdn.dooca.store/160956/products/bb1c3973-beda-44b2-8157-0fb68860c4e0-wqari_495x495+fill_ffffff+crop_center.png?v=1788637648', 'https://www.deuseojuiz.com/cropped-branco-deus-e-o-juiz', true, 25),
('cropped-so-deus-pode-me-julgar-branco', 'CROPPED BRANCO SÓ DEUS PODE ME JULGAR', 'Camisas', 'deus', 59.99, null, '["P","M","G","GG"]'::jsonb, '["Branco"]'::jsonb, null, 'TAMANHO ÚNICO, MODELAGEM OVERSIZE, TECIDO MALHÃO 100% ALGODÃO', 'https://cdn.dooca.store/160956/products/64ccd7a0-8d07-4e9e-b249-033588a04be3-t0wpd_495x495+fill_ffffff+crop_center.jpg?v=1788638314', 'https://www.deuseojuiz.com/cropped-branco-so-deus-pode-me-julgar', true, 26),
('cropped-frente-unica-deus-e-o-juiz', 'CROPPED FRENTE ÚNICA DEUS É O JUIZ', 'Camisas', 'deus', 59.99, null, '["P","M","G","GG"]'::jsonb, '["Preto"]'::jsonb, null, 'TAMANHO ÚNICO, MODELAGEM OVERSIZE, TECIDO MALHÃO 100% ALGODÃO', 'https://cdn.dooca.store/160956/products/6fb18b41-f638-4881-bac1-c47f73b46792-2qohx_495x495+fill_ffffff+crop_center.jpg?v=1788643712', 'https://www.deuseojuiz.com/crepped-frente-unica-deus-e-o-juiz', true, 27),
('copo-termico-350-ml', 'COPO TÉRMICO 350 ML', 'Decoração/Utilitários', null, 24.99, null, '["350 ML"]'::jsonb, '["Preto"]'::jsonb, null, null, 'https://cdn.dooca.store/160956/products/img-3527-byqjl_640x640+fill_ffffff.jpg?v=1786122419', 'https://www.deuseojuiz.com/copo-termico-350-ml', true, 28)
on conflict (slug) do nothing;


-- ===== supabase-stamps-setup.sql =====
begin;

create table if not exists public.store_stamps (
  slug text primary key check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  name text not null,
  image text not null,
  sort_order integer not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.store_stamps enable row level security;
grant select on public.store_stamps to anon, authenticated;
grant insert, update, delete on public.store_stamps to authenticated;
create index if not exists store_stamps_active_sort_idx on public.store_stamps (active, sort_order);

do $policies$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='store_stamps' and policyname='Anyone can read active stamps') then
    execute $policy$ create policy "Anyone can read active stamps" on public.store_stamps for select to anon, authenticated using (active is true) $policy$;
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='store_stamps' and policyname='Admins can read all stamps') then
    execute $policy$ create policy "Admins can read all stamps" on public.store_stamps for select to authenticated using (exists (select 1 from public.store_admins where user_id = (select auth.uid()))) $policy$;
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='store_stamps' and policyname='Admins can add stamps') then
    execute $policy$ create policy "Admins can add stamps" on public.store_stamps for insert to authenticated with check (exists (select 1 from public.store_admins where user_id = (select auth.uid()))) $policy$;
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='store_stamps' and policyname='Admins can update stamps') then
    execute $policy$ create policy "Admins can update stamps" on public.store_stamps for update to authenticated using (exists (select 1 from public.store_admins where user_id = (select auth.uid()))) with check (exists (select 1 from public.store_admins where user_id = (select auth.uid()))) $policy$;
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='store_stamps' and policyname='Admins can delete stamps') then
    execute $policy$ create policy "Admins can delete stamps" on public.store_stamps for delete to authenticated using (exists (select 1 from public.store_admins where user_id = (select auth.uid()))) $policy$;
  end if;
end
$policies$;

insert into public.store_stamps (slug,name,image,sort_order,active) values
  ('anti-sistema-club','Anti Sistema Club','estampa-anti-sistema-club.png',0,true),
  ('deus','Deus é o Juiz','estampa-deus-e-o-juiz.png',1,true)
on conflict (slug) do nothing;

commit;


-- ===== supabase-home-sections-setup.sql =====
-- Configuração pública da página inicial.
-- Visitantes podem ler os títulos e listas de produtos; somente membros de
-- public.store_admins podem criar ou alterar as seções editáveis.

begin;

create table if not exists public.home_sections (
  section_key text primary key check (section_key in ('women', 'featured', 'news')),
  title text not null check (char_length(title) between 1 and 80),
  description text not null default '' check (char_length(description) <= 240),
  product_slugs jsonb not null default '[]'::jsonb check (jsonb_typeof(product_slugs) = 'array'),
  updated_at timestamptz not null default now()
);

-- Defaults entram apenas quando ainda não existe configuração; repetir a migração
-- não sobrescreve títulos, descrições ou ordem já editados pela administração.
insert into public.home_sections (section_key, title, description, product_slugs)
values
  ('women', 'SESSÃO DELAS', 'Cropped e peças femininas Deus é o Juiz.', '["cropped-so-deus-pode-me-julgar-preto","cropped-deus-e-o-juiz-preto","cropped-deus-e-o-juiz-branco","cropped-so-deus-pode-me-julgar-branco"]'::jsonb),
  ('featured', 'Principais produtos', '', '["camisa-oversize-anti-sistem-branca","bala-clava-anti-sistem","camisa-deus-e-o-juiz-preta","cropped-deus-e-o-juiz-branco"]'::jsonb),
  ('news', 'Novidades', '', '["camisa-oversize-off-hammer","corta-vento-impermeavel","mochila-gang","bag-slin","mochila-244"]'::jsonb)
on conflict (section_key) do nothing;

alter table public.home_sections enable row level security;

grant select on public.home_sections to anon, authenticated;
grant insert, update on public.home_sections to authenticated;

drop policy if exists "Homepage sections are public" on public.home_sections;
create policy "Homepage sections are public"
  on public.home_sections for select
  to anon, authenticated
  using (true);

drop policy if exists "Store admins manage homepage sections" on public.home_sections;
create policy "Store admins manage homepage sections"
  on public.home_sections for all
  to authenticated
  using (exists (
    select 1 from public.store_admins
    where store_admins.user_id = (select auth.uid())
  ))
  with check (exists (
    select 1 from public.store_admins
    where store_admins.user_id = (select auth.uid())
  ));

commit;

