-- Academix Móvil: módulo autónomo de formación verificable.
-- No elimina ni modifica tablas de CursosWeb existentes.
-- Ejecutar en Supabase SQL Editor tras revisar el script.
-- Los nombres se prefijan mobile_ para evitar conflictos de esquema.

create table if not exists public.mobile_courses (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  description text not null default '',
  category text not null default 'General',
  instructor text not null default 'Academix',
  image_url text not null default '',
  price numeric(10,2) not null default 0 check (price >= 0),
  status text not null default 'draft' check (status in ('draft','published','archived')),
  created_at timestamptz not null default now()
);

create table if not exists public.mobile_modules (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.mobile_courses(id) on delete cascade,
  title text not null,
  position integer not null default 0,
  unique(course_id, position)
);

create table if not exists public.mobile_lessons (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.mobile_modules(id) on delete cascade,
  title text not null,
  description text not null default '',
  position integer not null default 0,
  video_asset text not null default '',
  video_url text not null default '',
  video_bucket text not null default '',
  video_path text not null default '',
  duration_minutes integer not null default 0 check (duration_minutes >= 0),
  is_preview boolean not null default false,
  unique(module_id, position)
);

create table if not exists public.mobile_quiz_questions (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references public.mobile_lessons(id) on delete cascade,
  prompt text not null,
  position integer not null default 0,
  unique(lesson_id, position)
);

create table if not exists public.mobile_quiz_options (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.mobile_quiz_questions(id) on delete cascade,
  label text not null,
  is_correct boolean not null default false
);
create unique index if not exists mobile_one_correct_option
  on public.mobile_quiz_options(question_id) where is_correct;

create table if not exists public.mobile_enrollments (
  user_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid not null references public.mobile_courses(id) on delete cascade,
  enrolled_at timestamptz not null default now(),
  primary key(user_id, course_id)
);

create table if not exists public.mobile_quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  lesson_id uuid not null references public.mobile_lessons(id) on delete cascade,
  score integer not null check (score between 0 and 100),
  passed boolean not null,
  created_at timestamptz not null default now()
);
create index if not exists mobile_attempt_user_lesson
  on public.mobile_quiz_attempts(user_id, lesson_id);

create table if not exists public.mobile_certificates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid not null references public.mobile_courses(id) on delete cascade,
  recipient_name text not null,
  verification_code text not null unique,
  issued_at timestamptz not null default now(),
  unique(user_id, course_id)
);

-- RLS. La sesión se comprueba en PostgreSQL y no solo en Flutter.
alter table public.mobile_courses enable row level security;
alter table public.mobile_modules enable row level security;
alter table public.mobile_lessons enable row level security;
alter table public.mobile_quiz_questions enable row level security;
alter table public.mobile_quiz_options enable row level security;
alter table public.mobile_enrollments enable row level security;
alter table public.mobile_quiz_attempts enable row level security;
alter table public.mobile_certificates enable row level security;

-- No otorgar acceso general a preguntas/opciones: respuestas correctas privadas.
revoke all on public.mobile_quiz_questions from anon, authenticated;
revoke all on public.mobile_quiz_options from anon, authenticated;
revoke all on public.mobile_quiz_attempts from anon, authenticated;
revoke all on public.mobile_certificates from anon, authenticated;

grant select on public.mobile_courses, public.mobile_modules, public.mobile_lessons to anon, authenticated;
grant select, insert on public.mobile_enrollments to authenticated;
grant select on public.mobile_certificates to authenticated;

create policy "mobile_public_courses" on public.mobile_courses
  for select to anon, authenticated using (status = 'published');
create policy "mobile_public_modules" on public.mobile_modules
  for select to anon, authenticated using (
    exists(select 1 from public.mobile_courses c
           where c.id=course_id and c.status='published')
  );
create policy "mobile_authorized_lessons" on public.mobile_lessons
  for select to anon, authenticated using (
    exists (
      select 1 from public.mobile_modules m
      join public.mobile_courses c on c.id=m.course_id
      where m.id=module_id and c.status='published'
      and (is_preview or exists (
        select 1 from public.mobile_enrollments e
        where e.course_id=c.id and e.user_id=auth.uid()
      ))
    )
  );
create policy "mobile_own_enrollments_read" on public.mobile_enrollments
  for select to authenticated using (user_id=auth.uid());
create policy "mobile_free_enrollment" on public.mobile_enrollments
  for insert to authenticated with check (
    user_id=auth.uid() and exists(
      select 1 from public.mobile_courses c
      where c.id=course_id and c.status='published' and c.price=0
    )
  );
create policy "mobile_own_certificates" on public.mobile_certificates
  for select to authenticated using (user_id=auth.uid());

-- Preguntas sin soluciones: RPC protegida, jamás expone is_correct.
create or replace function public.mobile_get_quiz(p_lesson_id uuid)
returns jsonb language plpgsql stable security definer
set search_path=public,pg_temp as $$
declare v_course uuid; v_result jsonb;
begin
  if auth.uid() is null then raise exception 'Se requiere iniciar sesión'; end if;
  select m.course_id into v_course
    from public.mobile_lessons l join public.mobile_modules m on m.id=l.module_id
    where l.id=p_lesson_id;
  if v_course is null or not exists (
    select 1 from public.mobile_courses c where c.id=v_course and c.status='published'
  ) or not exists (
    select 1 from public.mobile_enrollments
    where course_id=v_course and user_id=auth.uid()) then
    raise exception 'No tienes acceso al examen';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', q.id,'prompt',q.prompt,
    'options',(
      select coalesce(jsonb_agg(jsonb_build_object('id',o.id,'label',o.label)
        order by o.id), '[]'::jsonb)
      from public.mobile_quiz_options o where o.question_id=q.id
    )) order by q.position), '[]'::jsonb)
  into v_result from public.mobile_quiz_questions q
  where q.lesson_id=p_lesson_id;
  return v_result;
end $$;

-- Corrección en servidor y emisión condicionada por TODOS los exámenes aprobados.
-- No se puede fabricar una nota ni certificado desde un INSERT del móvil.
create or replace function public.mobile_submit_quiz(p_lesson_id uuid, p_answers jsonb)
returns jsonb language plpgsql volatile security definer
set search_path=public,pg_temp as $$
declare
  v_course uuid; v_total integer; v_valid integer; v_correct integer;
  v_score integer; v_passed boolean; v_certificate public.mobile_certificates%rowtype;
  v_name text;
begin
  if auth.uid() is null then raise exception 'Se requiere iniciar sesión'; end if;
  if p_answers is null or jsonb_typeof(p_answers) <> 'array' then
    raise exception 'Respuestas inválidas';
  end if;
  select m.course_id into v_course
    from public.mobile_lessons l join public.mobile_modules m on m.id=l.module_id
    join public.mobile_courses c on c.id=m.course_id and c.status='published'
    where l.id=p_lesson_id;
  if v_course is null or not exists (
    select 1 from public.mobile_enrollments
    where course_id=v_course and user_id=auth.uid()) then
    raise exception 'Inscripción requerida para evaluar';
  end if;
  select count(*) into v_total from public.mobile_quiz_questions where lesson_id=p_lesson_id;
  if v_total=0 or jsonb_array_length(p_answers) <> v_total then
    raise exception 'Contesta todas las preguntas';
  end if;
  with answers as (
    select answer->>'question_id' as qid, answer->>'option_id' as oid
    from jsonb_array_elements(p_answers) answer
  )
  select count(distinct q.id), count(*) filter (where o.is_correct)
    into v_valid, v_correct
  from answers a
  join public.mobile_quiz_questions q
    on q.id::text=a.qid and q.lesson_id=p_lesson_id
  left join public.mobile_quiz_options o
    on o.id::text=a.oid and o.question_id=q.id;
  if v_valid<>v_total then raise exception 'Respuestas incompletas o repetidas'; end if;
  v_score := round(v_correct*100.0/v_total)::integer;
  v_passed := v_score >= 80;
  insert into public.mobile_quiz_attempts(user_id,lesson_id,score,passed)
    values(auth.uid(),p_lesson_id,v_score,v_passed);

  if v_passed and not exists (
    select 1 from public.mobile_modules m
    join public.mobile_lessons l on l.module_id=m.id
    where m.course_id=v_course
      and not exists (
        select 1 from public.mobile_quiz_attempts a
        where a.lesson_id=l.id and a.user_id=auth.uid() and a.passed
      )
  ) and exists(
    select 1 from public.mobile_modules m
    join public.mobile_lessons l on l.module_id=m.id
    where m.course_id=v_course
  ) then
    v_name := trim(concat_ws(' ',
      nullif(auth.jwt()->'user_metadata'->>'nombres',''),
      nullif(auth.jwt()->'user_metadata'->>'apellido_paterno',''),
      nullif(auth.jwt()->'user_metadata'->>'apellido_materno','')));
    if v_name='' then v_name:=split_part(coalesce(auth.jwt()->>'email','Estudiante'),'@',1); end if;
    insert into public.mobile_certificates(user_id,course_id,recipient_name,verification_code)
      values(auth.uid(),v_course,v_name,upper(substr(replace(gen_random_uuid()::text,'-',''),1,16)))
      on conflict(user_id,course_id) do nothing;
  end if;

  select * into v_certificate from public.mobile_certificates
    where user_id=auth.uid() and course_id=v_course;
  return jsonb_build_object('score',v_score,'passed',v_passed,
    'certificate_code',v_certificate.verification_code);
end $$;

-- Verificación pública mediante código. El nombre del titular se muestra
-- solo cuando alguien conoce el código de credencial compartido.
create or replace function public.mobile_verify_certificate(p_code text)
returns jsonb language plpgsql stable security definer
set search_path=public,pg_temp as $$
declare v_result jsonb;
begin
  if p_code is null or length(trim(p_code))<>16 then return null; end if;
  select jsonb_build_object(
    'code',c.verification_code,'recipient',c.recipient_name,
    'course',co.title,'issued_at',c.issued_at)
  into v_result
  from public.mobile_certificates c
  join public.mobile_courses co on co.id=c.course_id
  where c.verification_code=upper(trim(p_code));
  return v_result;
end $$;

-- Para 'Mis cursos' y constancias del propio usuario.
create or replace function public.mobile_course_progress(p_course_id uuid)
returns jsonb language plpgsql stable security definer
set search_path=public,pg_temp as $$
declare v_result jsonb;
begin
  if auth.uid() is null then raise exception 'Inicia sesión'; end if;
  if not exists(select 1 from public.mobile_enrollments
    where user_id=auth.uid() and course_id=p_course_id) then
    raise exception 'Curso no inscrito';
  end if;
  select jsonb_build_object(
    'passed_lessons', coalesce((
      select jsonb_agg(distinct a.lesson_id) from public.mobile_quiz_attempts a
      join public.mobile_lessons l on l.id=a.lesson_id
      join public.mobile_modules m on m.id=l.module_id
      where m.course_id=p_course_id and a.user_id=auth.uid() and a.passed
    ),'[]'::jsonb),
    'certificate_code',(
      select c.verification_code from public.mobile_certificates c
      where c.user_id=auth.uid() and c.course_id=p_course_id
    )) into v_result;
  return v_result;
end $$;

revoke all on function public.mobile_get_quiz(uuid) from public, anon, authenticated;
revoke all on function public.mobile_submit_quiz(uuid,jsonb) from public, anon, authenticated;
revoke all on function public.mobile_course_progress(uuid) from public, anon, authenticated;
revoke all on function public.mobile_verify_certificate(text) from public, anon, authenticated;
grant execute on function public.mobile_get_quiz(uuid) to authenticated;
grant execute on function public.mobile_submit_quiz(uuid,jsonb) to authenticated;
grant execute on function public.mobile_course_progress(uuid) to authenticated;
grant execute on function public.mobile_verify_certificate(text) to anon, authenticated;

-- Temario PUBLICO sin exponer video, rutas de Storage ni respuestas de exámenes.
-- El acceso a la lección completa se decide en mobile_lessons mediante RLS.
create or replace function public.mobile_course_outline(p_course_id uuid)
returns jsonb language plpgsql stable security definer
set search_path=public,pg_temp as $$
declare v_outline jsonb;
begin
  if not exists(select 1 from public.mobile_courses
    where id=p_course_id and status='published') then
    raise exception 'Curso no disponible';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
      'id',m.id, 'title',m.title,
      'lessons',coalesce((
        select jsonb_agg(jsonb_build_object(
          'id',l.id, 'title',l.title,
          'duration_minutes',l.duration_minutes, 'is_preview',l.is_preview)
          order by l.position)
        from public.mobile_lessons l where l.module_id=m.id
      ),'[]'::jsonb)) order by m.position),'[]'::jsonb)
  into v_outline from public.mobile_modules m where m.course_id=p_course_id;
  return v_outline;
end $$;
revoke all on function public.mobile_course_outline(uuid) from public,anon,authenticated;
grant execute on function public.mobile_course_outline(uuid) to anon,authenticated;
