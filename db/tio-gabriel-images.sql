insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('tio-gabriel','tio-gabriel',true,8388608,array['image/jpeg','image/png','image/webp']);
create policy tg_images_select on storage.objects for select to authenticated using(bucket_id='tio-gabriel' and (select tg_private.is_admin()));
create policy tg_images_insert on storage.objects for insert to authenticated with check(bucket_id='tio-gabriel' and (select tg_private.is_admin()));
create policy tg_images_update on storage.objects for update to authenticated using(bucket_id='tio-gabriel' and (select tg_private.is_admin())) with check(bucket_id='tio-gabriel' and (select tg_private.is_admin()));
create policy tg_images_delete on storage.objects for delete to authenticated using(bucket_id='tio-gabriel' and (select tg_private.is_admin()));
