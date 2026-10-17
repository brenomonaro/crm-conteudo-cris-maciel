-- Central de Conteudo, Cris Maciel
-- Schema Supabase (Postgres). Rode este arquivo inteiro no SQL Editor do
-- projeto Supabase (Database > SQL Editor > New query > Run).

create extension if not exists "pgcrypto";

-- ---------- CARDS ----------
create table if not exists public.cards (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  classificacoes text[] not null default '{}',
  corretor text default '',
  codigo text default '',
  data_gravacao date,
  areas jsonb not null default '[]',       -- [{ rede, data }]
  pub_hora text default '',
  link text default '',
  obs text default '',
  checklist jsonb not null default '[]',   -- [{ text, done }]
  stage integer not null default 0,
  archived boolean not null default false,
  created_at timestamptz not null default now(),
  agendado_at timestamptz,
  gravado_at timestamptz,
  data_entrega date,
  entregue_at timestamptz,
  postado_at timestamptz,
  delivery_status text,
  delivery_days integer,
  auto_archive_opt_out boolean not null default false,
  -- Travas de aprovacao. aprov guarda quem liberou o que e quando:
  --   { "pauta": { "breno": {"at": 1700000000000}, "nicole": {...} },
  --     "pub":   { "nicole": {...}, "breno": {...} } }
  -- A chave "legado" dentro de uma trava marca card anterior ao recurso.
  aprov jsonb not null default '{}',
  -- Conversa sobre o conteudo, numa lista so:
  --   gate preenchido -> pedido de ajuste de uma trava, fecha quando a trava
  --                      for refeita
  --   gate nulo       -> pedido de mudanca solto, fecha no botao e carrega
  --                      resolvidoEm/resolvidoPor
  -- [{ gate, por, at, texto, resolvidoEm, resolvidoPor }]
  ajustes jsonb not null default '[]',
  -- Kit de publicacao, o que a Nicole monta antes de mandar para liberacao
  pub_titulo text default '',
  pub_descricao text default '',
  pub_capa text default '',
  -- Material anexado ao card: panfleto, foto, PDF, arte. Arquivo mesmo mora no
  -- Storage (bucket "anexos"), aqui fica a ficha dele.
  -- [{ id, nome, tipo, tamanho, url, path, por, at }]
  anexos jsonb not null default '[]',
  -- Leitura de resultado depois do ar: { nota, texto, at, por }
  resultado jsonb
);

-- Cobre projetos onde a tabela cards ja existia antes destas colunas. Rodar
-- este arquivo de novo num banco que ja existe e seguro: nada aqui apaga
-- dado, so acrescenta o que falta.
alter table public.cards add column if not exists data_entrega date;
alter table public.cards add column if not exists auto_archive_opt_out boolean not null default false;
alter table public.cards add column if not exists aprov jsonb not null default '{}';
alter table public.cards add column if not exists ajustes jsonb not null default '[]';
alter table public.cards add column if not exists pub_titulo text default '';
alter table public.cards add column if not exists pub_descricao text default '';
alter table public.cards add column if not exists pub_capa text default '';
alter table public.cards add column if not exists resultado jsonb;
alter table public.cards add column if not exists anexos jsonb not null default '[]';

-- ---------- IDEIAS ----------
create table if not exists public.ideas (
  id uuid primary key default gen_random_uuid(),
  titulo text not null,
  formato text default '',
  prioridade text default 'Media',
  descricao text default '',
  referencia text default '',
  created_at timestamptz not null default now()
);

-- ---------- STORAGE DOS ANEXOS ----------
-- Bucket publico onde ficam os arquivos que a Nicole anexa no card (panfleto,
-- foto, PDF) e que o Breno abre dentro do site antes de liberar. Publico aqui
-- significa o mesmo que nas tabelas abaixo: quem tem o link le o arquivo. A
-- protecao e a obscuridade da URL, nao autenticacao.
--
-- Se este bloco falhar por falta de permissao, nada mais no arquivo quebra: da
-- para criar o bucket a mao no painel, em Storage > New bucket, com o nome
-- "anexos" e a opcao Public marcada.
do $$
begin
  insert into storage.buckets (id, name, public, file_size_limit)
  values ('anexos', 'anexos', true, 26214400)
  on conflict (id) do update set public = true, file_size_limit = 26214400;

  execute 'drop policy if exists "anexos: leitura publica" on storage.objects';
  execute 'drop policy if exists "anexos: escrita publica" on storage.objects';
  execute 'drop policy if exists "anexos: atualizacao publica" on storage.objects';
  execute 'drop policy if exists "anexos: exclusao publica" on storage.objects';

  execute 'create policy "anexos: leitura publica" on storage.objects
             for select using (bucket_id = ''anexos'')';
  execute 'create policy "anexos: escrita publica" on storage.objects
             for insert with check (bucket_id = ''anexos'')';
  execute 'create policy "anexos: atualizacao publica" on storage.objects
             for update using (bucket_id = ''anexos'') with check (bucket_id = ''anexos'')';
  execute 'create policy "anexos: exclusao publica" on storage.objects
             for delete using (bucket_id = ''anexos'')';
exception when others then
  raise notice 'Bucket de anexos nao configurado automaticamente (%). Crie a mao em Storage > New bucket, nome "anexos", marcando Public.', sqlerrm;
end $$;

-- ---------- REALTIME ----------
-- Habilita a replicacao das duas tabelas para o canal realtime do Supabase,
-- assim as mudancas de um navegador aparecem no outro sem precisar recarregar.
-- Projetos novos do Supabase ja adicionam tabelas recem criadas nesse canal
-- sozinhos, entao o bloco abaixo so age se ainda nao tiver sido feito.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='cards'
  ) then
    alter publication supabase_realtime add table public.cards;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='ideas'
  ) then
    alter publication supabase_realtime add table public.ideas;
  end if;
end $$;

-- ---------- RLS ----------
-- Sem login: qualquer pessoa com a URL e a chave anon do projeto le e
-- escreve nessas tabelas. A protecao aqui e a obscuridade da URL do
-- projeto e da chave anon, nao autenticacao de usuario. Se no futuro
-- quiser exigir login, troque estas policies por regras com auth.uid().
alter table public.cards enable row level security;
alter table public.ideas enable row level security;

drop policy if exists "cards: leitura publica" on public.cards;
drop policy if exists "cards: escrita publica" on public.cards;
drop policy if exists "cards: atualizacao publica" on public.cards;
drop policy if exists "cards: exclusao publica" on public.cards;
drop policy if exists "ideas: leitura publica" on public.ideas;
drop policy if exists "ideas: escrita publica" on public.ideas;
drop policy if exists "ideas: atualizacao publica" on public.ideas;
drop policy if exists "ideas: exclusao publica" on public.ideas;

create policy "cards: leitura publica" on public.cards
  for select using (true);
create policy "cards: escrita publica" on public.cards
  for insert with check (true);
create policy "cards: atualizacao publica" on public.cards
  for update using (true) with check (true);
create policy "cards: exclusao publica" on public.cards
  for delete using (true);

create policy "ideas: leitura publica" on public.ideas
  for select using (true);
create policy "ideas: escrita publica" on public.ideas
  for insert with check (true);
create policy "ideas: atualizacao publica" on public.ideas
  for update using (true) with check (true);
create policy "ideas: exclusao publica" on public.ideas
  for delete using (true);
