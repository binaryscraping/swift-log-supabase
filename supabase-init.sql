create table logs (
    id uuid default uuid_generate_v4() not null primary key,
    label text not null,
    file text not null,
    line text not null,
    source text not null,
    function text not null,
    level text not null,
    message text not null,
    logged_at timestamp with time zone not null,
    received_at timestamp with time zone default timezone('utc'::text, now()) not null,
    metadata jsonb
);

alter table logs enable row level security;

create policy "Logs can be public inserted." on public.logs for insert with check (true);
create policy "Logs can't be public read." on public.logs for select using (false);
create policy "Logs can't be public updated." ON public.logs for update with check (false);
create policy "Logs can't be public deleted." ON public.logs for delete using (false);
