# Plano de execução — Deus é o Juiz

Atualizado em 07/11/2026. O plano segue a ordem pedida: preparação → verificações → funcionalidades → segurança → verificações → funcionalidades → segurança. Pagamentos, cálculo de frete e rastreio ficam para o fim, conforme solicitado. Itens que já existem no código não são repetidos como novas funcionalidades; sua confirmação em produção continua listada quando depende de serviço externo.

## 0. Fazer agora — preparar e corrigir a base

- [x] Corrigir a API para não sobrescrever dados pessoais cifrados quando um pedido repetido reutiliza o mesmo identificador.
- [ ] Guardar uma cópia de recuperação e identificar claramente branch, commit e projeto de cada serviço antes de publicar.
- [ ] Confirmar qual projeto Supabase é o correto. O conector desta sessão só mostra `supabase-bisque-pillow` (`lydowlqlivyifjbxvxnx`), diferente da referência do projeto da loja; não aplicar SQL nesse projeto por engano.
- [ ] Confirmar o deploy Render ligado ao repositório vigente. O serviço visto está ligado a `roch4-code/pssouvr`, branch `main`; conferir se esse continua sendo o repositório ativo antes de qualquer publicação.
- [ ] Confirmar variáveis exigidas em Render, Vercel e Neon pelos nomes, sem exibir valores em logs ou no navegador.
- [ ] Registrar as migrações de banco necessárias em arquivos versionados e aplicar primeiro em ambiente de teste.

## 1. Verificações — estado atual e fluxo de compra sem pagamento

- [ ] Fazer um pedido de teste ponta a ponta: visitante e cliente autenticado; conferir resumo operacional no Supabase e dados pessoais cifrados no Neon.
- [ ] Confirmar consulta de pedido do cliente e consulta administrativa, incluindo tentativa de consultar ID de outra conta.
- [ ] Confirmar edição, inclusão e exclusão de produtos, estampas e seções da página inicial com conta admin; negar as mesmas operações a cliente comum.
- [ ] Confirmar que a planilha dentro do painel admin lista os pedidos e permite marcar “Empacotado”, “Enviado” e “Recebeu”; Google Sheets permanece cancelado.
- [ ] Confirmar que carrinho e favoritos de duas contas permanecem isolados após login, logout e novo login.
- [ ] Confirmar exclusão de conta com reautenticação e verificar remoção/anonimização nos dois bancos.
- [ ] Testar recuperação de senha, confirmação de e-mail, cadastro por SMS, reenvio e expiração dos códigos no projeto correto.
- [ ] Testar páginas principais, 404, imagens, navegação móvel, menu, suporte e acessibilidade básica no domínio publicado.
- [ ] Repetir o teste do endpoint de pedido para identificador repetido e garantir resposta de conflito sem sobrescrever nenhum dado.

## 2. Funcionalidades — fechar o mínimo antes do lançamento

- [ ] Adicionar estoque por variação (tamanho/cor) e validar disponibilidade no servidor; definir a regra de reserva antes de haver pagamento integrado.
- [ ] Validar checkout de visitante e cliente, sem confiar em preços, quantidades ou dados enviados pelo navegador.
- [ ] Revisar política de troca/devolução e publicar prazo e fluxo corretos para a operação da loja.
- [ ] Revisar Termos de Uso e Privacidade; preencher CNPJ e canal de suporte monitorado com informações oficiais fornecidas pela loja.
- [ ] Configurar e-mails transacionais de pedido e atendimento quando o provedor de e-mail estiver conectado. Confirmação de pagamento/envio fica para depois da integração correspondente.
- [ ] Corrigir mensagens de estado para deixar claro que pedido recebido não significa pagamento confirmado.

## 3. Segurança — preparar antes do lançamento

- [ ] Separar credenciais de teste e produção; manter chaves privadas apenas em variáveis secretas do servidor.
- [ ] Confirmar que a conexão Neon usa papel técnico de privilégio mínimo, nunca o proprietário do banco, e que acesso de rede está restrito conforme hospedagem.
- [ ] Confirmar configuração de senha e confirmação de conta no Supabase Auth; não armazenar senha própria na aplicação.
- [ ] Revisar validação e codificação de entradas/saídas; manter SQL parametrizado e impedir XSS/SQL injection.
- [ ] Revisar cookies, sessão, CSRF, CORS e headers de segurança no domínio de produção.
- [ ] Configurar 2FA para a conta administrativa e limite de tentativas de login/checkout.
- [ ] Confirmar respostas genéricas sem stack trace ou segredo e revisar logs para não incluir CPF, telefone, endereço ou tokens.
- [ ] Configurar backup automático do Neon/Supabase e retenção conhecida antes de armazenar dados reais.

## 4. Verificações — autorização e isolamento

- [ ] Usuário A não acessa pedidos, endereços, dados pessoais, sacola ou favoritos do usuário B trocando IDs.
- [ ] Cliente comum não acessa painel nem APIs administrativas; papel admin não pode ser alterado no perfil/cadastro.
- [ ] Cliente não muda preços, descontos ou status por requisição; somente admin autorizado altera catálogo e etapas operacionais.
- [ ] Recuperação de senha expira, é de uso único e fica vinculada à conta correta; sessão antiga não funciona após logout.
- [ ] Alteração de senha/e-mail exige reautenticação adequada.
- [ ] Exclusão de conta elimina ou anonimiza os dados pessoais associados nos serviços conectados, sem apagar registros que precisem ser retidos legalmente.
- [ ] Confirmar política contra uso indevido de cupom quando o sistema de cupons for criado.
- [ ] Repetir teste de pedido concorrente/duplicado, consulta de pedido, exclusão e status com contas distintas.
- [ ] Verificar limites e políticas RLS no projeto Supabase correto, com usuário anônimo, cliente e admin.
- [ ] Confirmar configuração efetiva no Render e Vercel sem copiar valores secretos para relatórios.

## 5. Funcionalidades — logo após o lançamento

- [ ] Integrar emissão de nota fiscal conforme a operação e o enquadramento da loja.
- [ ] Recuperar carrinho abandonado e criar cupons/fidelidade depois de ter regras comerciais definidas.
- [ ] Criar logística reversa e vale-troca.
- [ ] Adicionar avaliações e aviso de reposição.
- [ ] Configurar SEO, Pixel Meta, GA4, relatórios e dashboard operacional.
- [ ] Separar permissões entre administração, estoque e atendimento.
- [ ] Fazer reserva de estoque no checkout e alerta de estoque baixo quando o pagamento estiver pronto.

## 6. Segurança — endurecimento pós-lançamento

- [ ] Avaliar WAF/DDoS, CSP, X-Frame-Options, Referrer-Policy, CORS restrito, CSRF e XSS no domínio real.
- [ ] Avaliar Turnstile/reCAPTCHA para login, cadastro e cupons.
- [ ] Validar upload por conteúdo/tipo real, tamanho razoável e nome aleatório; rejeitar executáveis disfarçados.
- [ ] Criar auditoria de ações administrativas e alertas de login, sem registrar dados sensíveis.
- [ ] Configurar uptime/alertas, SPF/DKIM/DMARC e npm audit/Dependabot.
- [ ] Testar restauração de backup em ambiente separado.
- [ ] Confirmar criptografia em trânsito, em repouso e nos backups para CPF e outros dados pessoais.

## 7. Verificações pós-lançamento

- [ ] Confirmar que estoque não fica negativo sob compras simultâneas.
- [ ] Confirmar que toda ação administrativa fica no log e usuários sem permissão não mudam estados.
- [ ] Confirmar rejeição de uploads executáveis/disfarçados e bloqueio temporário após tentativas excessivas.
- [ ] Confirmar restauração de backup, rotação de segredo e exclusão/anonimização de conta em ambiente de teste.
- [ ] Varrer histórico Git inteiro por segredos e testar carga antes de campanhas.

## 8. Deixar para o final — pagamento, frete e rastreio

Não implementar até o usuário retomar esta etapa.

- [ ] Integrar cálculo de frete por CEP e mostrar total dos produtos + entrega antes da confirmação.
- [ ] Integrar Melhor Envio exclusivamente no servidor; começar no Sandbox e guardar etiqueta/código/status no pedido.
- [ ] Exibir consulta de rastreio em “Meus pedidos” e manter o formulário de solicitação de informação à loja como alternativa.
- [ ] Integrar Pix/cartão por gateway; preço e total serão recalculados no servidor.
- [ ] Validar assinatura do webhook e só marcar pagamento concluído após confirmação do gateway.
- [ ] Não armazenar número de cartão ou CVV; usar idempotência, limites contra card testing e estorno até o valor pago.
- [ ] Configurar avisos de confirmação de pagamento e envio após as integrações.

## 9. Evolução e governança

- [ ] Programa de indicação/cashback; pré-venda, kits e combos; marketplaces/TikTok Shop/Google Merchant; automações de e-mail/WhatsApp; chat e recomendações.
- [ ] Conciliação financeira, múltiplas transportadoras, retirada em loja, testes A/B e CDN avançado.
- [ ] Pentest periódico, scanner de vulnerabilidades/malware e revisão obrigatória antes de deploy.
- [ ] Gerenciador e rotação de segredos, revisão de acessos, DNSSEC/bloqueio de transferência e plano de resposta a incidentes/DR.
- [ ] Revisar contratos LGPD, retenção/descarte de dados, canal do titular/DPO e treinamento contra phishing.

## Já presente no código local — não contado como novo trabalho

- Página 404 e estrutura responsiva básica.
- Cadastro por celular com chamada de verificação SMS, login por e-mail/celular, recuperação de senha e exclusão de conta com reautenticação.
- Painel administrativo com produtos, estampas, seções da home e pedidos; planilha interna e etapas operacionais.
- Carrinho e favoritos separados por conta no navegador.
- API privada com validação Supabase, criptografia AES-256-GCM dos dados pessoais no Neon, consultas parametrizadas, CORS configurável e headers de segurança.
- Site exibe meios de pagamento informativos; cobrança real ainda não foi integrada.
- Pagamento, frete e rastreio continuam adiados.

## Bloqueios externos atuais

- A conta Supabase conectada não expõe o projeto de produção indicado anteriormente; ela lista apenas `supabase-bisque-pillow`. Não aplicar ou afirmar migração de produção até conectar/identificar o projeto certo.
- O Render conectado mostra o serviço `dej-private-api-rvq7` ligado a `roch4-code/pssouvr`. O repositório vigente deve ser confirmado antes de trocar a origem do deploy.
- Testes reais de SMS, e-mail, pedido, acesso admin e isolamento dependem de credenciais e configuração ativas nos ambientes correspondentes.
