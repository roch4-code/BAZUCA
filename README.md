# Deus é o Juiz — loja online

Site estático para GitHub Pages e API privada no Render. A aplicação usa Supabase Auth, Supabase para catálogo e resumo de pedidos, e Neon para os campos pessoais cifrados antes da gravação.

## Publicação

1. No GitHub, publique os arquivos deste repositório na raiz da branch `main`.
2. Em **Settings → Pages**, selecione `Deploy from a branch`, branch `main` e pasta `/ (root)`.
3. Crie o serviço Render pela Blueprint `render.yaml`. Configure as variáveis secretas listadas em `ORDERS-SETUP.md`.
4. Confirme o domínio real do Render e ajuste `privateApiUrl` em `backend-config.js`.
5. Publique `supabase-setup.sql` no Supabase e `neon-sensitive-setup.sql` no Neon novo. Siga também `ADMIN-SETUP.md` e `ORDERS-SETUP.md`.

Não suba `.env`, connection strings, service role keys ou chave de cifra. A página de checkout não cobra pagamento nem calcula frete nesta versão.

## Exclusão de conta

A exclusão da conta exige que a pessoa informe o identificador vinculado ao login, a senha atual e digite `EXCLUIR`. A tela pede o e-mail/celular da conta, a senha e a confirmação `EXCLUIR`. O cliente refaz a autenticação e a API do Render exige sessão renovada nos últimos cinco minutos. Em seguida apaga os dados pessoais cifrados no Neon, remove os resumos de pedidos no Supabase e só então exclui o usuário do Supabase Auth.

Antes de publicar esta versão:

1. Aplique `render-api/NEON-ACCOUNT-DELETE.sql` no Neon para permitir que o papel técnico do Render apague linhas cifradas.
2. Faça deploy do serviço Render com o `render.yaml` atualizado. Configure `DATABASE_URL`, `DATA_ENCRYPTION_KEY`, `SUPABASE_SERVICE_ROLE_KEY` e `ALLOWED_ORIGINS` como variáveis/segredos no Render.
3. Publique os arquivos estáticos atualizados do pacote.

A sacola e os favoritos desta versão ficam no armazenamento local do navegador, não no servidor. Sacola e favoritos são separados por conta neste navegador. Ao excluir a conta, as chaves locais dessa conta são apagadas neste dispositivo; dados locais que estejam em outro dispositivo não podem ser removidos remotamente.

## Planilha de pedidos no painel admin

Depois do login administrador, a aba **Planilha** carrega pedidos sob demanda pela API privada. O endpoint valida a sessão Supabase e a associação de admin antes de consultar o Neon; CPF e endereço não são expostos por uma consulta pública do navegador. Os status são gravados no resumo Supabase. Pagamento e rastreio ainda são exibidos como não informados enquanto não estiverem integrados. Os pedidos podem ser excluídos individualmente ou em lote, sempre após confirmação; o lembrete mensal destaca pedidos com mais de 90 dias e não apaga nada automaticamente.

Para publicar, faça deploy dos arquivos do repositório e do Render. O HTML principal (`index.html`) já contém as bandeiras como SVGs embutidos em `data:` URLs, sem depender de HTML extra.

### Estampas editáveis
O cabeçalho não exibe mais a logo; a busca ocupa o espaço disponível. A seção Estampas tem edição apenas para administradores e grava imagens, nomes e associações de produtos em `public.store_stamps` e na coluna `products.stamp`. Para ativar o editor, execute `supabase-stamps-setup.sql` uma vez no SQL Editor do Supabase. RLS permite leitura pública de estampas ativas e restringe alterações a membros de `store_admins`.

O acesso por celular usa Phone Auth do Supabase com senha e confirmação por SMS. Antes de publicar o fluxo, habilite Phone Auth e configure um provedor SMS em Authentication > Providers. O cadastro coleta nome, celular e e-mail; se o usuário escolher cadastro por celular, o celular será o identificador de autenticação e o e-mail ficará como contato no metadata. Login Apple e Google foram removidos da interface.

### Movimento no carrossel mobile
A sessão de estampas usa transição curta nos cards e snap por proximidade, evitando paradas forçadas em cada produto. O ícone da sacola mantém o desenho preto sobre fundo claro nos dois temas.

### Edição das seções de produtos da página inicial
A conta administradora pode editar **Sessão Delas**, **Principais produtos** e **Novidades** pelo ícone de lápis ao lado do título. O painel permite trocar nome e descrição, selecionar produtos e reordená-los; as alterações são salvas no Supabase e ficam públicas na página inicial. A seção de estampas logo abaixo do hero e o hero não recebem esse controle. O arquivo `supabase-home-sections-setup.sql` cria a tabela com RLS, carrega as listas iniciais somente se ainda não houver configuração e restringe gravação aos membros de `store_admins`.

Para uma instalação Supabase do zero, use o script único `supabase-install-all.sql` no SQL Editor. Ele aplica, em ordem, schema base, catálogo inicial, estampas e seções editáveis da página inicial. As inserções iniciais usam `ON CONFLICT DO NOTHING`, preservando alterações existentes quando reexecutadas. Se o projeto já estiver configurado, revise e aplique apenas a migração de que estiver faltando.
# Nova área de pedidos, suporte e solicitações de reembolso

Esta versão adiciona `/meus-pedidos` para clientes autenticados e `/suporte` com formulário que prepara uma mensagem para o WhatsApp da loja. O cliente precisa confirmar o envio no WhatsApp. O painel administrativo mostra os pedidos de análise de reembolso.

Antes de publicar o fluxo de reembolso, execute `neon-refund-requests.sql` no Neon usado pela API Render. O script concede permissões automaticamente se o papel `dej_render_app` já existir. Se o papel for criado depois, rode `render-api/NEON-APP-ROLE.sql` novamente.

Depois publique a pasta `render-api` no serviço Render que já está conectado, usando as mesmas variáveis e segredos existentes. A interface usa o `privateApiUrl` já presente em `backend-config.js`; não é necessário alterar a conexão do Supabase nem as chaves. A solicitação é para análise manual: nenhum pagamento ou estorno é processado por este site.
