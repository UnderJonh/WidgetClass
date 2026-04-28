create extension if not exists pgcrypto;
create extension if not exists citext;

create table if not exists public.turmas (
  id text primary key,
  nome text not null,
  curso text not null,
  created_at timestamptz not null default now()
);

insert into public.turmas (id, nome, curso) values
  ('eletronica_1a', 'Eletronica 1A', 'Eletronica'),
  ('eletronica_2a', 'Eletronica 2A', 'Eletronica'),
  ('eletronica_3a', 'Eletronica 3A', 'Eletronica'),
  ('meio_ambiente_1a', 'Meio Ambiente 1A', 'Meio Ambiente'),
  ('meio_ambiente_2a', 'Meio Ambiente 2A', 'Meio Ambiente'),
  ('meio_ambiente_3a', 'Meio Ambiente 3A', 'Meio Ambiente')
on conflict (id) do update set
  nome = excluded.nome,
  curso = excluded.curso;

create table if not exists public.usuarios_roles (
  email citext primary key,
  role text not null check (role in ('admin', 'staff')),
  nome text,
  created_at timestamptz not null default now()
);

-- Crie o usuario manualmente em Authentication > Users e depois cadastre
-- o mesmo email como admin ou staff aqui:
-- insert into public.usuarios_roles (email, role, nome)
-- values ('seu.email@gmail.com', 'admin', 'Seu Nome')
-- on conflict (email) do update set role = excluded.role, nome = excluded.nome;

create table if not exists public.aulas (
  id uuid primary key default gen_random_uuid(),
  turma_id text not null default 'eletronica_3a' references public.turmas(id),
  disciplina text not null,
  professor text not null,
  sala text not null default 'F104',
  dia_semana int not null check (dia_semana between 1 and 7),
  horario_inicio time not null,
  horario_fim time,
  icone text not null default '📘',
  cor_hex text not null default '#00B8D9',
  imagem_url text,
  created_at timestamptz not null default now()
);

alter table public.aulas add column if not exists turma_id text not null default 'eletronica_3a' references public.turmas(id);
alter table public.aulas add column if not exists horario_fim time;
alter table public.aulas add column if not exists icone text not null default '📘';
alter table public.aulas add column if not exists cor_hex text not null default '#00B8D9';
alter table public.aulas add column if not exists imagem_url text;
alter table public.aulas add column if not exists created_at timestamptz not null default now();
alter table public.aulas alter column sala set default 'F104';

create unique index if not exists aulas_turma_disciplina_dia_inicio_key
on public.aulas (turma_id, disciplina, dia_semana, horario_inicio);

create or replace function public.current_user_role()
returns text
language sql
security definer
set search_path = public
as $$
  select ur.role
  from public.usuarios_roles ur
  where lower(ur.email::text) = lower(coalesce(auth.email(), ''))
  limit 1
$$;

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select public.current_user_role() = 'admin'
$$;

create or replace function public.is_staff()
returns boolean
language sql
security definer
set search_path = public
as $$
  select public.current_user_role() = 'staff'
$$;

create or replace function public.guard_staff_aula_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if current_user in ('postgres', 'supabase_admin', 'service_role') then
    return new;
  end if;

  if public.is_admin() then
    return new;
  end if;

  if public.is_staff() then
    if new.id is distinct from old.id
      or new.turma_id is distinct from old.turma_id
      or new.disciplina is distinct from old.disciplina
      or new.professor is distinct from old.professor
      or new.dia_semana is distinct from old.dia_semana
      or new.horario_inicio is distinct from old.horario_inicio
      or new.horario_fim is distinct from old.horario_fim
      or new.icone is distinct from old.icone
      or new.cor_hex is distinct from old.cor_hex
      or new.imagem_url is distinct from old.imagem_url
      or new.created_at is distinct from old.created_at then
      raise exception 'Staff pode alterar apenas a sala da aula.';
    end if;

    return new;
  end if;

  raise exception 'Sem permissao para alterar aulas.';
end;
$$;

drop trigger if exists guard_staff_aula_update_trigger on public.aulas;
create trigger guard_staff_aula_update_trigger
before update on public.aulas
for each row
execute function public.guard_staff_aula_update();

alter table public.turmas enable row level security;
alter table public.aulas enable row level security;
alter table public.usuarios_roles enable row level security;

drop policy if exists "Leitura publica de turmas" on public.turmas;
create policy "Leitura publica de turmas"
on public.turmas
for select
using (true);

drop policy if exists "Leitura publica de aulas" on public.aulas;
create policy "Leitura publica de aulas"
on public.aulas
for select
using (true);

drop policy if exists "Admin cadastra aulas" on public.aulas;
create policy "Admin cadastra aulas"
on public.aulas
for insert
with check (public.is_admin());

drop policy if exists "Admin ou staff atualiza aulas" on public.aulas;
create policy "Admin ou staff atualiza aulas"
on public.aulas
for update
using (public.is_admin() or public.is_staff())
with check (public.is_admin() or public.is_staff());

drop policy if exists "Admin exclui aulas" on public.aulas;
create policy "Admin exclui aulas"
on public.aulas
for delete
using (public.is_admin());

drop policy if exists "Usuario ve proprio role ou admin ve todos" on public.usuarios_roles;
create policy "Usuario ve proprio role ou admin ve todos"
on public.usuarios_roles
for select
using (lower(email::text) = lower(coalesce(auth.email(), '')) or public.is_admin());

drop policy if exists "Admin gerencia roles" on public.usuarios_roles;
create policy "Admin gerencia roles"
on public.usuarios_roles
for all
using (public.is_admin())
with check (public.is_admin());

insert into public.aulas (
  turma_id,
  disciplina,
  professor,
  sala,
  dia_semana,
  horario_inicio,
  horario_fim,
  icone,
  cor_hex,
  imagem_url
) values
  ('eletronica_3a', 'Mecanica Naval', 'Igor Casciano', 'F104', 1, '07:00', '08:40', '⚙️', '#F15BB5', null),
  ('eletronica_3a', 'Sist. de Tele.', 'Tiago Tadeu', 'F104', 1, '09:00', '10:40', '📡', '#F15BB5', null),
  ('eletronica_3a', 'Fisica', 'Christiano Leal', 'F104', 1, '10:40', '12:20', '⚛️', '#FFF56D', null),
  ('eletronica_3a', 'HP', 'Igor Casciano', 'F104', 2, '07:00', '08:40', '🛠️', '#F15BB5', null),
  ('eletronica_3a', 'Automacao e Controle', 'Alcemir Gama', 'F104', 2, '09:00', '12:20', '🤖', '#B9DDF4', null),
  ('eletronica_3a', 'Matematica', 'Ladeisa Moreira', 'F104', 2, '14:10', '15:50', '➗', '#F15BB5', null),
  ('eletronica_3a', 'Projeto ENEM - Redacao', 'Elaine Junger', 'F104', 2, '16:10', '17:50', '✍️', '#00D7DF', null),
  ('eletronica_3a', 'Ingles', 'Leticia Beutzer', 'F104', 3, '07:00', '08:40', '🌎', '#D2B900', null),
  ('eletronica_3a', 'Microcontroladores e Microprocessadores', 'Leonardo Francisco', 'F104', 3, '09:00', '10:40', '🔌', '#B9DDF4', null),
  ('eletronica_3a', 'Redes de Computadores', 'Thiago Nunes', 'F104', 3, '10:40', '12:20', '🌐', '#A78BFA', null),
  ('eletronica_3a', 'Portugues', 'Elaine Junger', 'F104', 4, '07:00', '08:40', '📚', '#00D7DF', null),
  ('eletronica_3a', 'Eletronica Analogica II', 'Luiz Mauricio Lopes', 'F104', 4, '09:00', '10:40', '🧲', '#FBFF3E', null),
  ('eletronica_3a', 'Portugues', 'Elaine Junger', 'F104', 4, '10:40', '12:20', '📚', '#00D7DF', null),
  ('eletronica_3a', 'Dependencia em Quimica', 'Profa. Poliana', 'F104', 4, '14:10', '15:50', '🧪', '#FDBA74', null),
  ('eletronica_3a', 'Educacao Fisica', 'Pedro Sarmat', 'F104', 5, '07:00', '08:40', '🏃', '#CFE7F8', null),
  ('eletronica_3a', 'Sociologia', 'Andreia Abad', 'F104', 5, '09:00', '10:40', '👥', '#C084FC', null),
  ('eletronica_3a', 'Organizacao e Normas', 'William Itabo', 'F104', 5, '10:40', '12:20', '📋', '#A7C7FF', null)
on conflict (turma_id, disciplina, dia_semana, horario_inicio) do update set
  professor = excluded.professor,
  sala = excluded.sala,
  horario_fim = excluded.horario_fim,
  icone = excluded.icone,
  cor_hex = excluded.cor_hex,
  imagem_url = excluded.imagem_url;
