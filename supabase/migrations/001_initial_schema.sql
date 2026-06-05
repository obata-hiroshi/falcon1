create type public.document_role as enum ('owner', 'editor', 'viewer');

create schema if not exists private;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now()
);

create table public.documents (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body_markdown text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint documents_title_not_blank check (length(btrim(title)) > 0)
);

create table public.document_members (
  document_id uuid not null references public.documents(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.document_role not null,
  created_at timestamptz not null default now(),
  primary key (document_id, user_id)
);

create index document_members_user_id_idx on public.document_members(user_id);
create index document_members_document_id_idx on public.document_members(document_id);
create index documents_owner_id_idx on public.documents(owner_id);

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', new.email)
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create function public.touch_document_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger documents_touch_updated_at
before update on public.documents
for each row execute function public.touch_document_updated_at();

create function public.prevent_document_owner_change()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.owner_id <> old.owner_id then
    raise exception 'documents.owner_id cannot be changed';
  end if;

  return new;
end;
$$;

create trigger documents_prevent_owner_change
before update on public.documents
for each row execute function public.prevent_document_owner_change();

create function public.add_document_owner_member()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.document_members (document_id, user_id, role)
  values (new.id, new.owner_id, 'owner')
  on conflict (document_id, user_id) do update
    set role = 'owner';

  return new;
end;
$$;

create trigger documents_add_owner_member
after insert on public.documents
for each row execute function public.add_document_owner_member();

create function private.is_document_owner(target_document_id uuid, target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, private
as $$
  select exists (
    select 1
    from public.documents d
    where d.id = target_document_id
      and d.owner_id = target_user_id
  );
$$;

create function private.is_document_member(target_document_id uuid, target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, private
as $$
  select exists (
    select 1
    from public.documents d
    where d.id = target_document_id
      and d.owner_id = target_user_id
  )
  or exists (
    select 1
    from public.document_members dm
    where dm.document_id = target_document_id
      and dm.user_id = target_user_id
  );
$$;

create function private.can_edit_document(target_document_id uuid, target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, private
as $$
  select exists (
    select 1
    from public.documents d
    where d.id = target_document_id
      and d.owner_id = target_user_id
  )
  or exists (
    select 1
    from public.document_members dm
    where dm.document_id = target_document_id
      and dm.user_id = target_user_id
      and dm.role in ('owner', 'editor')
  );
$$;

alter table public.profiles enable row level security;
alter table public.documents enable row level security;
alter table public.document_members enable row level security;

grant usage on schema private to authenticated;
grant execute on function private.is_document_owner(uuid, uuid) to authenticated;
grant execute on function private.is_document_member(uuid, uuid) to authenticated;
grant execute on function private.can_edit_document(uuid, uuid) to authenticated;

create policy "profiles can read own profile"
on public.profiles
for select
to authenticated
using (id = auth.uid());

create policy "profiles can update own profile"
on public.profiles
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

create policy "documents can be read by members"
on public.documents
for select
to authenticated
using (private.is_document_member(id, auth.uid()));

create policy "documents can be created by owner"
on public.documents
for insert
to authenticated
with check (owner_id = auth.uid());

create policy "documents can be updated by owner or editor"
on public.documents
for update
to authenticated
using (private.can_edit_document(id, auth.uid()))
with check (private.can_edit_document(id, auth.uid()));

create policy "documents can be deleted by owner"
on public.documents
for delete
to authenticated
using (owner_id = auth.uid());

create policy "document members can be read by document members"
on public.document_members
for select
to authenticated
using (private.is_document_member(document_id, auth.uid()));

create policy "document members can be created by owner"
on public.document_members
for insert
to authenticated
with check (private.is_document_owner(document_id, auth.uid()));

create policy "document members can be updated by owner"
on public.document_members
for update
to authenticated
using (private.is_document_owner(document_id, auth.uid()))
with check (private.is_document_owner(document_id, auth.uid()));

create policy "document members can be deleted by owner"
on public.document_members
for delete
to authenticated
using (private.is_document_owner(document_id, auth.uid()));
