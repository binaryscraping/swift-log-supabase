create table logs (
    id uuid default uuid_generate_v4() not null primary key,
    level text not null,
    message text,
    logged_at timestamp with time zone not null,
    received_at timestamp with time zone default timezone('utc'::text, now()) not null,
    metadata jsonb not null
);
