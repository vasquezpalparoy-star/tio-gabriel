-- Camila Moda / Tio Gabriel: isolated catalog, quotations and work tracking.
create schema if not exists tg_private;
revoke all on schema tg_private from public;
grant usage on schema tg_private to anon, authenticated;
create table tg_private.admins(user_id uuid primary key references auth.users(id));
insert into tg_private.admins select id from auth.users where lower(email)='grafiplotvasquez@gmail.com';
alter table tg_private.admins enable row level security;
create function tg_private.is_admin() returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and exists(select 1 from tg_private.admins where user_id=auth.uid());
$$;
revoke all on function tg_private.is_admin() from public;
grant execute on function tg_private.is_admin() to anon,authenticated;
create table public.tg_settings(id integer primary key check(id=1), content jsonb not null default '{}');
create table public.tg_products(
 id uuid primary key default gen_random_uuid(), name text not null check(length(name) between 1 and 150),
 description text not null default '', category text not null default 'Calças', image_url text not null default '',
 price numeric(12,2) not null default 0 check(price>=0), colors text[] not null default array['Rosa'],
 sizes text[] not null default array['P','M','G','GG'], active boolean not null default true,
 position integer not null default 0, created_at timestamptz not null default now());
create table public.tg_quotes(
 id uuid primary key default gen_random_uuid(), request_id uuid unique not null,
 code text unique not null default ('CM-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,16))),
 customer_name text not null, phone text not null, delivery_address text not null default '',
 customer_notes text not null default '', items jsonb not null, estimated_total numeric(12,2) not null,
 quoted_total numeric(12,2) check(quoted_total>=0),
 status text not null default 'Recebido' check(status in ('Recebido','Em análise','Aguardando aprovação','Em produção','Pronto','Entregue','Cancelado')),
 public_note text not null default '', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create index tg_quotes_phone_created on public.tg_quotes(phone,created_at desc);
create table public.tg_work_events(id uuid primary key default gen_random_uuid(), quote_id uuid not null references public.tg_quotes(id) on delete cascade,
 status text not null, note text not null default '', created_at timestamptz not null default now());
create index tg_work_events_quote on public.tg_work_events(quote_id,created_at);
alter table public.tg_settings enable row level security;
alter table public.tg_products enable row level security;
alter table public.tg_quotes enable row level security;
alter table public.tg_work_events enable row level security;
grant select on public.tg_settings,public.tg_products to anon,authenticated;
grant insert,update,delete on public.tg_settings,public.tg_products to authenticated;
grant select,update,delete on public.tg_quotes to authenticated;
grant select on public.tg_work_events to authenticated;
create policy tg_settings_read on public.tg_settings for select to anon,authenticated using(true);
create policy tg_settings_manage on public.tg_settings for all to authenticated using((select tg_private.is_admin())) with check((select tg_private.is_admin()));
create policy tg_products_read on public.tg_products for select to anon,authenticated using(active or (select tg_private.is_admin()));
create policy tg_products_manage on public.tg_products for all to authenticated using((select tg_private.is_admin())) with check((select tg_private.is_admin()));
create policy tg_quotes_manage on public.tg_quotes for all to authenticated using((select tg_private.is_admin())) with check((select tg_private.is_admin()));
create policy tg_events_read on public.tg_work_events for select to authenticated using((select tg_private.is_admin()));
create function tg_private.quote_event() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if TG_OP='INSERT' then
  insert into public.tg_work_events(quote_id,status,note) values(new.id,new.status,new.public_note);
 else
  new.updated_at=now();
  if new.status is distinct from old.status or new.public_note is distinct from old.public_note then
   insert into public.tg_work_events(quote_id,status,note) values(new.id,new.status,new.public_note);
  end if;
 end if;
 return new;
end; $$;
revoke all on function tg_private.quote_event() from public;
create trigger tg_quote_history before insert or update on public.tg_quotes for each row execute function tg_private.quote_event();
-- The history FK is deferred so INSERT history can be atomic with the quotation.
alter table public.tg_work_events drop constraint tg_work_events_quote_id_fkey;
alter table public.tg_work_events add constraint tg_work_events_quote_id_fkey foreign key(quote_id) references public.tg_quotes(id) on delete cascade deferrable initially deferred;
create function tg_private.request_quote(p_request_id uuid,p_name text,p_phone text,p_address text,p_notes text,p_items jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare ph text:=regexp_replace(p_phone,'[^0-9]','','g'); row_item jsonb; product public.tg_products; quantity integer; full_items jsonb:='[]'; total numeric:=0; q public.tg_quotes;
begin
 if length(trim(p_name)) not between 2 and 120 or length(ph) not between 10 and 15 or length(coalesce(p_address,''))>500 or length(coalesce(p_notes,''))>2000 then raise exception 'Confira seu nome e WhatsApp.'; end if;
 if jsonb_typeof(p_items) is distinct from 'array' then raise exception 'Selecione os produtos.'; end if;
 if jsonb_array_length(p_items) not between 1 and 30 then raise exception 'Selecione entre 1 e 30 itens.'; end if;
 perform pg_advisory_xact_lock(hashtextextended(ph,0));
 select * into q from public.tg_quotes where request_id=p_request_id;
 if found then
  if q.phone<>ph then raise exception 'Solicitação inválida.'; end if;
  return jsonb_build_object('code',q.code,'estimated_total',q.estimated_total,'status',q.status);
 end if;
 if (select count(*) from public.tg_quotes where phone=ph and created_at>now()-interval '1 hour')>=5 then raise exception 'Aguarde um pouco antes de enviar outra solicitação.'; end if;
 for row_item in select value from jsonb_array_elements(p_items) loop
  select * into product from public.tg_products where id=(row_item->>'product_id')::uuid and active;
  if not found then raise exception 'Um produto não está mais disponível.'; end if;
  quantity=(row_item->>'quantity')::integer;
  if quantity is null or quantity not between 1 and 500 or not coalesce((row_item->>'size')=any(product.sizes),false) or not coalesce((row_item->>'color')=any(product.colors),false) then raise exception 'Confira quantidade, cor e tamanho.'; end if;
  full_items=full_items||jsonb_build_array(jsonb_build_object('product_id',product.id,'name',product.name,'image_url',product.image_url,'price',product.price,'quantity',quantity,'size',row_item->>'size','color',row_item->>'color'));
  total=total+product.price*quantity;
 end loop;
 insert into public.tg_quotes(request_id,customer_name,phone,delivery_address,customer_notes,items,estimated_total)
 values(p_request_id,trim(p_name),ph,coalesce(p_address,''),coalesce(p_notes,''),full_items,total) returning * into q;
 return jsonb_build_object('code',q.code,'estimated_total',q.estimated_total,'status',q.status);
end; $$;
create function tg_private.track_work(p_code text,p_phone text) returns jsonb language plpgsql security definer set search_path='' as $$
declare q public.tg_quotes;
begin
 select * into q from public.tg_quotes where code=upper(trim(p_code)) and phone=regexp_replace(p_phone,'[^0-9]','','g');
 if not found then return null; end if;
 return jsonb_build_object('code',q.code,'status',q.status,'estimated_total',q.estimated_total,'quoted_total',q.quoted_total,'public_note',q.public_note,'created_at',q.created_at,'updated_at',q.updated_at,'items',q.items,
 'history',(select coalesce(jsonb_agg(jsonb_build_object('status',status,'note',note,'created_at',created_at) order by created_at),'[]'::jsonb) from public.tg_work_events where quote_id=q.id));
end; $$;
revoke all on function tg_private.request_quote(uuid,text,text,text,text,jsonb),tg_private.track_work(text,text) from public;
grant execute on function tg_private.request_quote(uuid,text,text,text,text,jsonb),tg_private.track_work(text,text) to anon,authenticated;
create function public.tg_request_quote(p_request_id uuid,p_name text,p_phone text,p_address text,p_notes text,p_items jsonb) returns jsonb language sql security invoker set search_path='' as $$ select tg_private.request_quote(p_request_id,p_name,p_phone,p_address,p_notes,p_items); $$;
create function public.tg_track_work(p_code text,p_phone text) returns jsonb language sql security invoker set search_path='' as $$ select tg_private.track_work(p_code,p_phone); $$;
create function public.tg_am_i_admin() returns boolean language sql stable security invoker set search_path='' as $$ select tg_private.is_admin(); $$;
revoke all on function public.tg_request_quote(uuid,text,text,text,text,jsonb),public.tg_track_work(text,text),public.tg_am_i_admin() from public;
grant execute on function public.tg_request_quote(uuid,text,text,text,text,jsonb),public.tg_track_work(text,text),public.tg_am_i_admin() to anon,authenticated;
insert into public.tg_settings(id,content) values(1,'{"headline":"Seu estilo, seu conforto","subtitle":"Calças e moletons de fabricação própria.","eyebrow":"Feitas para acompanhar você","catalog_title":"Encontre seu favorito","catalog_subtitle":"Escolha os seus modelos e solicite um orçamento sem compromisso.","logo_url":"/images/logo.webp","hero_url":"/images/hero.webp","whatsapp":"5511915820111","contact_name":"Gabriel","instagram":"camilamoda68","address":"Rua Carnot, em frente ao número 356","wholesale_note":"Atacado e varejo • Fabricação própria","footer_text":"Conforto em cada detalhe. Estilo em todos os momentos."}');
insert into public.tg_products(name,description,category,image_url,price,colors,sizes,position) values
('Pantalona Essencial','Cintura elástica, caimento leve e liberdade para todos os momentos.','Calças','/images/product.webp',49.90,array['Rosa','Preto','Verde'],array['P','M','G','GG'],1),
('Moletom Confort','Seu novo favorito para os dias que pedem conforto e estilo.','Moletons','/images/green.webp',49.90,array['Verde','Preto','Cinza'],array['P','M','G','GG'],2),
('Pantalona Clássica','Uma peça versátil para combinar do seu jeito.','Calças','/images/black.webp',49.90,array['Preto','Terracota','Rosa'],array['P','M','G','GG'],3);
