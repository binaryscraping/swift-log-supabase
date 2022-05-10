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
