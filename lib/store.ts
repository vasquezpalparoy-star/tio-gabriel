import {createClient} from '@supabase/supabase-js';
export const db=createClient('https://gyvztqpvgtinxoqhyfbw.supabase.co','sb_publishable_m5tDCWoaiu-xP-lezwd3Lg_rlUfq118');
export type Product={id:string;name:string;description:string;category:string;image_url:string;price:number;colors:string[];sizes:string[];active:boolean;position:number};
export type Item={product_id:string;name:string;image_url:string;price:number;color:string;size:string;quantity:number};
export type Content=Record<string,string>;
export type Work={id?:string;code:string;customer_name?:string;phone?:string;delivery_address?:string;customer_notes?:string;items:Item[];estimated_total:number;quoted_total:number|null;status:string;public_note:string;created_at:string;updated_at:string;history?:{status:string;note:string;created_at:string}[]};
export const defaults:Content={headline:'Seu estilo, seu conforto',subtitle:'Calças e moletons de fabricação própria.',eyebrow:'Feitas para acompanhar você',catalog_title:'Encontre seu favorito',catalog_subtitle:'Escolha os seus modelos e solicite um orçamento sem compromisso.',logo_url:'/images/logo.webp',hero_url:'/images/hero.webp',whatsapp:'5511915820111',contact_name:'Gabriel',instagram:'camilamoda68',address:'Rua Carnot, em frente ao número 356',wholesale_note:'Atacado e varejo • Fabricação própria',footer_text:'Conforto em cada detalhe. Estilo em todos os momentos.'};
export const statuses=['Recebido','Em análise','Aguardando aprovação','Em produção','Pronto','Entregue','Cancelado'];
export const money=(v:number)=>new Intl.NumberFormat('pt-BR',{style:'currency',currency:'BRL'}).format(v);
export const date=(v:string)=>new Date(v).toLocaleString('pt-BR');
export function uuid(){const b=new Uint8Array(16);crypto.getRandomValues(b);b[6]=(b[6]&15)|64;b[8]=(b[8]&63)|128;const h=Array.from(b,x=>x.toString(16).padStart(2,'0')).join('');return `${h.slice(0,8)}-${h.slice(8,12)}-${h.slice(12,16)}-${h.slice(16,20)}-${h.slice(20)}`;}
export const safeUrl=(v:string)=>{if(v.startsWith('/')&&!v.startsWith('//')){const base=import.meta.env.BASE_URL||'/';return base!=='/'&&v.startsWith('/images/')?base.replace(/\/$/,'')+v:v;}return /^https:\/\//i.test(v)?v:'';};
export const wa=(phone:string,text:string)=>`https://wa.me/${phone.replace(/\D/g,'')}?text=${encodeURIComponent(text)}`;
