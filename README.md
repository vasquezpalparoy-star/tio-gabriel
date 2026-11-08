# Tio Gabriel · Camila Moda

Catálogo em português para a Camila Moda, com solicitações de **cotação** e acompanhamento de **trabalhos**. Não realiza pagamentos ou pedidos de compra.

## Recursos

- Catálogo com pesquisa, categorias, cores e tamanhos.
- Orçamento com múltiplas peças, quantidades e estimativa calculada novamente no servidor.
- Código individual de acompanhamento; a consulta exige o código e o WhatsApp informado na cotação.
- Histórico de estados e mensagens públicas para o cliente, atualizado a cada 30 segundos enquanto a consulta estiver aberta.
- Administração de produtos, preços, textos, contatos, logo e imagem principal.
- Upload direto de imagens JPG, PNG ou WebP de até 8 MB; links HTTPS também são aceitos.
- WhatsApp: Gabriel, (11) 91582-0111. Instagram: @camilamoda68.
- Layout adaptado para computador e celular, seguindo a proposta branca e fúcsia.

## Administração

Clique em **Administração**, no rodapé, e entre com a conta Supabase existente **grafiplotvasquez@gmail.com** e a senha dessa conta. Nenhuma senha está incluída no projeto.

**Produtos:** adicionar, editar, ocultar ou excluir produtos; subir uma foto diretamente; definir cores e tamanhos separados por vírgula.

**Conteúdo:** editar os textos principais, contatos e imagens. Após subir uma imagem, clique em Salvar para aplicar a alteração.

**Cotações:** consultar os dados enviados pelo cliente, definir o valor cotado, alterar o estado e escrever uma mensagem visível no acompanhamento.

Estados: Recebido → Em análise → Aguardando aprovação → Em produção → Pronto → Entregue. Também é possível marcar Cancelado. A aprovação é combinada pela equipe com o cliente; o site não confirma compras automaticamente.

As imagens iniciais são ilustrativas e os preços de R$ 49,90 são referências editáveis. Substitua-os pelas fotos e valores reais no painel.

## Desenvolvimento

Node.js 22.13 ou superior. Dependências fixadas no `pnpm-lock.yaml`.

```sh
corepack pnpm install --frozen-lockfile
corepack pnpm dev
corepack pnpm exec tsc --noEmit
corepack pnpm build
```

Aplicação React com Vinext/Vite. A saída é um Worker Cloudflare em `dist/server/index.js` com assets em `dist/client`. A configuração de hospedagem da versão Sites está em `.openai/hosting.json`. O GitHub Pages usa a pasta `docs` da branch `main`. Execute `pnpm build:pages` e envie a pasta `docs` para atualizar essa publicação. A hospedagem Sites é independente.

## Supabase

Projeto existente: **Cuentas Claras Negocio**, referência `gyvztqpvgtinxoqhyfbw`. A chave utilizada em `lib/store.ts` é **publishable**, própria para o navegador. Nunca coloque uma chave `service_role` no cliente.

Tabelas independentes: `tg_products`, `tg_settings`, `tg_quotes`, `tg_work_events`. Bucket público de imagens: `tio-gabriel`. Os sistemas anteriores de Grafiplot não são alterados.

`db/tio-gabriel.sql` e `db/tio-gabriel-images.sql` registram o esquema já aplicado. Não execute novamente sobre o mesmo banco. Para instalação em outro projeto, a conta de administrador deve existir primeiro e a chave/URL do cliente devem ser atualizadas.

RLS protege a edição e a leitura dos dados de clientes. Funções públicas limitadas recebem as solicitações e retornam somente o acompanhamento mediante código aleatório e telefone. Funções privilegiadas ficam no esquema privado com permissões específicas, validação de parâmetros e `search_path` fixo. A tabela de administradores não é gravável pela API. As fotos do catálogo são públicas; não suba documentos pessoais nesse bucket.

## Validação realizada

Compilação de produção, TypeScript, envio e consulta de cotação pela interface, idempotência, cálculo de preços no servidor, rejeição de quantidades inválidas, consulta com telefone errado, acesso administrativo, histórico e políticas de acesso. Cotação técnica de teste identificada e cancelada após a validação.
