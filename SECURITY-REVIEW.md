# Revisão de segurança da versão local

Data: 07/11/2026

Escopo: cópia local do site, SQL do Supabase, API Render e schema privado Neon. Esta revisão não acessou nem alterou contas ou bancos remotos.

## O que foi verificado

- Sintaxe JavaScript com `node --check` em `app.js`, `backend.js`, `orders.js`, `admin.js` e `render-api/server.mjs`.
- `npm run check:api`.
- Referências de assets locais e inclusão das imagens no pacote.
- Políticas RLS presentes nos scripts locais para catálogo, membros admin, resumos de pedidos, estampas e seções da página inicial.
- Fluxos de pedido, consulta do próprio cliente, solicitação manual de reembolso, ações administrativas e exclusão de conta no código local.
- Padrões conhecidos de chaves privadas nos arquivos de texto de publicação. Nenhuma chave privada de servidor foi identificada na cópia verificada. A chave `sb_publishable_...` é publicável por desenho; não equivale a `service_role` ou `sb_secret_...`.

## Controles presentes no código

- Login/identidade via Supabase Auth. O servidor exige e-mail administrador configurado **e** associação do UUID em `public.store_admins` para as rotas administrativas.
- Os pedidos consultados por cliente são filtrados pelo UUID autenticado no Supabase e novamente pelo UUID na tabela privada do Neon. A rota de solicitação de reembolso também confirma a titularidade antes de gravar.
- CPF, telefone, endereço e outros dados enviados no pedido são cifrados no servidor com AES-256-GCM antes de serem persistidos no Neon. SQL usa parâmetros na API.
- O total do pedido é recalculado no servidor usando preço, tamanho e cor do catálogo Supabase, em vez de confiar no valor enviado pelo navegador.
- O motivo de solicitação de reembolso é cifrado e o banco impede mais de uma solicitação por pedido. O fluxo registra pedido de análise manual; **não efetua estorno nem confirma pagamento**.
- Os scripts Supabase habilitam RLS e restringem gravação de produtos, estampas e seções da página inicial aos membros de `store_admins`. Os resumos de pedido não aceitam escrita direta por `anon`/`authenticated`.
- A API tem limite de tamanho do corpo, validação básica de campos/CPF/UUID, resposta `no-store`, alguns headers de segurança, allowlist CORS configurável e rate limit local por processo.
- As falhas inesperadas das rotas administrativas agora retornam mensagens genéricas; detalhes de exceções internas não são enviados nessas respostas.
- `.gitignore` exclui `.env*` (exceto `.env.example`), `node_modules`, arquivos ZIP e pasta de build local.

## Problemas e lacunas que impedem afirmar “tudo seguro”

1. **Não há prova de produção:** não conferi as variáveis configuradas no Render, o papel usado na conexão Neon, o conteúdo efetivo de RLS no projeto Supabase, nem se a migration `neon-refund-requests.sql` foi aplicada. Arquivos SQL locais não configuram serviços por si só.
2. **Rate limit frágil para escala:** é armazenado em memória e depende de `X-Forwarded-For`. Reinicia com o processo, não compartilha contagem entre instâncias e a confiança no cabeçalho depende do proxy. Use proteção distribuída/gateway antes de tráfego real relevante.
3. **MFA do administrador não comprovado:** não encontrei evidência de que 2FA seja exigido. A verificação de e-mail não substitui MFA.
4. **Headers do site estático:** os headers listados são enviados pela API Render. HTTPS/HSTS, CSP, `X-Frame-Options` e política de referrer do host estático precisam ser definidos e conferidos na hospedagem; não são garantidos pelo JavaScript do site.
5. **Sem verificação prática de isolamento:** a leitura do código indica checagens de titularidade, mas não executei testes com duas contas para provar IDOR em produção, nem tentativas de alterar status, preço ou papel via chamadas manipuladas.
6. **Exclusão não é transação entre serviços:** o fluxo apaga Neon, depois resumo Supabase e então usuário Auth. Uma falha intermediária pode deixar exclusão parcial; precisa de reconciliação/log e teste integrado.
7. **Dados de pedido:** checkout ainda não processa pagamento, frete ou rastreio. Não exiba um pedido registrado como pago. O pacote não inclui gateway, webhook de pagamento, antifraude, cálculo de frete nem e-mail transacional completo.
8. **Operação:** backup/restauração, alertas, auditoria de ações admin, rotação de segredos, SPF/DKIM/DMARC e política de retenção não foram comprovados.
9. **Uploads:** o SQL pede limite de até 1 GB, mas o limite real é definido pelo plano e configuração do Supabase Storage. Validar tamanho/tipo no cliente e servidor e confirmar o limite no Dashboard.
10. **Cobertura de segurança:** não foi executado pentest, Strix, DAST, análise completa do histórico Git ou scanner de dependências. A checagem de padrões não substitui essas atividades.

## Checklist antes de produção

- Aplicar somente as migrations necessárias no projeto correto e confirmar RLS/permissões no Dashboard.
- Publicar esta API no Render, restringir `ALLOWED_ORIGINS` ao domínio real, e confirmar secretamente que `DATABASE_URL` usa `dej_render_app` de privilégio mínimo. Nunca colar ou versionar valores de segredo.
- Confirmar `DATA_ENCRYPTION_KEY` com 32 bytes, guardar backup seguro da chave e planejar rotação; sem ela os dados existentes podem ficar irrecuperáveis.
- Exigir MFA para administração e revisar lista de membros de `store_admins`.
- Fazer testes integrados de dois clientes, admin vs cliente, sessão expirada/logout, exclusão, pedido e tentativa de acesso a UUID alheio.
- Configurar headers na hospedagem, backup e restauração, monitoramento e canal oficial de suporte.
- Só habilitar pagamento depois de gateway real, webhook assinado, idempotência e validação server-side.

## Resultado

**Há controles importantes implementados no código local, mas esta versão não está certificada como segura ou pronta para produção.** As checagens locais de sintaxe passaram; faltam aplicação/verificação de configurações remotas e testes integrados. Nenhuma publicação ou alteração remota foi feita nesta revisão.
