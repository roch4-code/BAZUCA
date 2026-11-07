-- Deus é o Juiz: edição das seções de produtos da página inicial.
-- Execute no SQL Editor do Supabase. A tabela guarda somente configuração
-- pública da vitrine; somente membros de public.store_admins podem alterá-la.

begin;

-- Compatível com instalação parcial: cria a tabela de administradores se
-- o setup principal ainda não tiver sido executado.
create table if not exists public.store_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.store_admins enable row level security;
revoke all on public.store_admins from anon;
grant select on public.store_admins to authenticated;

drop policy if exists "Admins can read their own membership"
  on public.store_admins;
create policy "Admins can read their own membership"
  on public.store_admins for select to authenticated
  using ((select auth.uid()) = user_id);

create table if not exists public.home_sections (
  section_key text primary key
    check (section_key in ('women', 'featured', 'news')),
  title text not null
    check (char_length(title) between 1 and 80),
  description text not null default ''
    check (char_length(description) <= 240),
  product_slugs jsonb not null default '[]'::jsonb
    check (
      jsonb_typeof(product_slugs) = 'array'
      and jsonb_array_length(product_slugs) <= 40
    ),
  updated_at timestamptz not null default now()
);

alter table public.home_sections enable row level security;
grant usage on schema public to anon, authenticated;
grant select on public.home_sections to anon, authenticated;
grant insert, update on public.home_sections to authenticated;

drop policy if exists "Homepage sections are public"
  on public.home_sections;
create policy "Homepage sections are public"
  on public.home_sections for select to anon, authenticated
  using (true);

drop policy if exists "Store admins manage homepage sections"
  on public.home_sections;
create policy "Store admins manage homepage sections"
  on public.home_sections for all to authenticated
  using (exists (
    select 1 from public.store_admins
    where store_admins.user_id = (select auth.uid())
  ))
  with check (exists (
    select 1 from public.store_admins
    where store_admins.user_id = (select auth.uid())
  ));

create or replace function public.set_home_sections_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists home_sections_updated_at
  on public.home_sections;
create trigger home_sections_updated_at
  before update on public.home_sections
  for each row execute function public.set_home_sections_updated_at();

-- Seeds só são aplicados na primeira execução e preservam edições existentes.
insert into public.home_sections
  (section_key, title, description, product_slugs)
values
  ('women', 'SESSÃO DELAS', 'Cropped e peças femininas Deus é o Juiz.',
    '["cropped-so-deus-pode-me-julgar-preto","cropped-deus-e-o-juiz-preto","cropped-deus-e-o-juiz-branco","cropped-so-deus-pode-me-julgar-branco"]'::jsonb),
  ('featured', 'Principais produtos', '',
    '["camisa-oversize-anti-sistem-branca","bala-clava-anti-sistem","camisa-deus-e-o-juiz-preta","cropped-deus-e-o-juiz-branco"]'::jsonb),
  ('news', 'Novidades', '',
    '["camisa-oversize-off-hammer","corta-vento-impermeavel","mochila-gang","bag-slin","mochila-244"]'::jsonb)
on conflict (section_key) do nothing;

-- Vincula a conta admin já existente. Se ainda não existir no Supabase Auth,
-- crie-a em Authentication > Users e execute este bloco novamente.
insert into public.store_admins (user_id)
select id from auth.users
where lower(email) = lower('roch4v4@gmail.com')
on conflict (user_id) do nothing;

commit;

-- Verificação pós-execução:
select section_key, title, product_slugs, updated_at
from public.home_sections
order by section_key;

select u.email, a.user_id, a.created_at
from public.store_admins as a
join auth.users as u on u.id = a.user_id
where lower(u.email) = lower('roch4v4@gmail.com');
