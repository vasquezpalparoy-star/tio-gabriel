import {defineConfig} from 'vite';
import react from '@vitejs/plugin-react';
export default defineConfig({root:'github-pages',base:'/tio-gabriel/',publicDir:'../public',plugins:[react()],build:{outDir:'../docs',emptyOutDir:true}});
