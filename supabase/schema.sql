create extension if not exists pgcrypto;

create table if not exists public.aulas (
  id uuid primary key default gen_random_uuid(),
  disciplina text not null,
  professor text not null,
  sala text not null,
  dia_semana int not null check (dia_semana between 1 and 7),
  horario_inicio time not null
);

alter table public.aulas enable row level security;

drop policy if exists "Leitura publica de aulas" on public.aulas;
create policy "Leitura publica de aulas"
on public.aulas
for select
using (true);

drop policy if exists "Cadastro publico de aulas" on public.aulas;
create policy "Cadastro publico de aulas"
on public.aulas
for insert
with check (true);

drop policy if exists "Atualizacao publica de aulas" on public.aulas;
create policy "Atualizacao publica de aulas"
on public.aulas
for update
using (true)
with check (true);

drop policy if exists "Exclusao publica de aulas" on public.aulas;
create policy "Exclusao publica de aulas"
on public.aulas
for delete
using (true);
