-- =============================================
-- IA VIP Creators — Tabela de Alunos + RLS
-- Rode este script inteiro no SQL Editor do Supabase
-- (Dashboard > SQL Editor > New Query > Cole > Run)
-- =============================================

-- 1. Cria a tabela "alunos"
--    Cada linha = 1 aluno. As 3 flags controlam o acesso aos produtos.
create table if not exists public.alunos (
  id                    uuid primary key references auth.users(id) on delete cascade,
  email                 text not null,
  nome                  text not null default '',          -- Nome do Google OAuth
  avatar_url            text not null default '',          -- Foto do Google OAuth
  rota10k_ativo         boolean not null default false,   -- Front-End (R$147)
  fabrica_clones_ativo  boolean not null default false,   -- Upsell VIP (R$197)
  arsenal_antiban_ativo boolean not null default false,   -- Order Bump (Contingência)
  created_at            timestamptz not null default now()
);

-- 2. Índice para buscas rápidas por email (usado pelo webhook da Cakto)
create index if not exists idx_alunos_email on public.alunos(email);

-- 3. Ativa o Row Level Security (RLS)
--    Com RLS ligado, NENHUMA query do front-end acessa dados sem policy.
alter table public.alunos enable row level security;

-- 4. Policy: cada aluno só lê a própria linha
--    auth.uid() retorna o id do usuário logado via Supabase Auth.
create policy "Aluno lê próprio registro"
  on public.alunos
  for select
  using ( auth.uid() = id );

-- 5. Policy: permite insert (para o webhook criar o registro do aluno)
--    Na prática o insert é feito via service_role (server-side), mas
--    esta policy garante que o front não quebre se o fluxo mudar.
create policy "Aluno insere próprio registro"
  on public.alunos
  for insert
  with check ( auth.uid() = id );

-- 6. Policy: permite update da própria linha (ex: webhook ativa novos produtos)
create policy "Aluno atualiza próprio registro"
  on public.alunos
  for update
  using ( auth.uid() = id );

-- =============================================
-- COMO TESTAR:
-- 1. Crie um usuário em Authentication > Users
-- 2. No SQL Editor, insira manualmente:
--
--    insert into public.alunos (id, email, rota10k_ativo)
--    values ('UUID-DO-USUARIO', 'email@exemplo.com', true);
--
-- 3. Ative fabrica_clones_ativo ou arsenal_antiban_ativo pra testar o unlock:
--
--    update public.alunos
--    set fabrica_clones_ativo = true
--    where email = 'email@exemplo.com';
-- =============================================
