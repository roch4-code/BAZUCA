-- Execute uma vez no Neon SQL Editor depois de instalar a tabela
-- private.customer_sensitive_orders. Motivos ficam cifrados pelo serviço Render.
begin;

create schema if not exists private;
revoke all on schema private from public;

create table if not exists private.customer_refund_requests (
  request_id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references private.customer_sensitive_orders(order_id) on delete cascade,
  user_id uuid not null,
  reason_ciphertext bytea not null,
  reason_iv bytea not null,
  reason_auth_tag bytea not null,
  status text not null default 'requested'
    check (status in ('requested', 'under_review', 'approved_for_manual_refund', 'rejected', 'closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists customer_refund_requests_user_created_idx
  on private.customer_refund_requests (user_id, created_at desc);
create index if not exists customer_refund_requests_status_created_idx
  on private.customer_refund_requests (status, created_at desc);

comment on table private.customer_refund_requests is
  'Solicitações de análise de reembolso. Motivo cifrado com AES-256-GCM pela API do Render; registrar solicitação não processa transferência financeira.';
revoke all on all tables in schema private from public;
revoke all on all sequences in schema private from public;

do $$
begin
  if exists (select 1 from pg_roles where rolname = 'dej_render_app') then
    execute 'grant usage on schema private to dej_render_app';
    execute 'grant select, insert, update, delete on private.customer_refund_requests to dej_render_app';
  end if;
end
$$;

commit;
