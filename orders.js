(() => {
  const esc = value => String(value ?? '').replace(/[&<>"']/g, ch => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch]));
  const formatDate = value => value ? new Date(value).toLocaleString('pt-BR', { dateStyle: 'medium', timeStyle: 'short' }) : 'Data indisponível';

  function ordersPage(user) {
    if (!user) return `<main class="page page-copy"><span class="eyebrow">Área do cliente</span><h1 class="page-title">Meus pedidos</h1><p class="muted">Entre na sua conta para consultar os pedidos associados a ela.</p><a class="btn" href="/login" data-link>Entrar na conta</a></main>`;
    return `<main class="page page-copy customer-orders-page"><nav class="breadcrumbs" aria-label="Navegação estrutural"><a href="/" data-link>Início</a><span aria-hidden="true"> / </span><span aria-current="page">Pedidos</span></nav><span class="eyebrow">Área do cliente</span><h1 class="page-title">Meus pedidos</h1><p class="muted">Aqui aparecem os pedidos feitos enquanto esta conta estava conectada. Para compra como visitante, fale com o suporte.</p><div class="customer-orders-list" id="customer-orders-list" role="status" aria-live="polite"><div class="notice">Carregando seus pedidos…</div></div><section class="account-support orders-support"><span class="eyebrow">Precisa de ajuda?</span><h2>Suporte sobre um pedido</h2><p class="muted">Peça informações de entrega, confira um pedido ou relate um problema.</p><a class="btn btn-outline" href="/suporte" data-link>Falar com suporte</a></section></main>`;
  }

  function orderCard(order) {
    const itemLines = (order.items || []).map(item => `<li><strong>${esc(item.quantity)} × ${esc(item.name)}</strong><span>${esc(item.size || 'Sem tamanho')} · ${esc(item.color || 'Sem cor')} · ${esc(item.lineTotal == null ? '' : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(item.lineTotal))}</span></li>`).join('');
    const customer = order.customer || {};
    const refund = order.refundRequest;
    const detail = `<dl class="order-details"><div><dt>Status</dt><dd>${esc(order.status || 'Recebido')}</dd></div><div><dt>Data</dt><dd>${esc(formatDate(order.createdAt))}</dd></div><div><dt>Valor dos produtos</dt><dd>${new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(order.subtotal || 0))}</dd></div><div><dt>Pagamento</dt><dd>Ainda não informado pelo sistema da loja</dd></div><div><dt>Rastreio</dt><dd>Ainda não disponível</dd></div></dl><h3>Entrega informada</h3><p>${esc(customer.name || '—')} · ${esc(customer.phone || '—')}<br>${esc(customer.address || '—')}${customer.addressExtra ? `, ${esc(customer.addressExtra)}` : ''}<br>${esc(customer.postalCode || '—')} · ${esc(customer.cityState || '—')}</p>`;
    const refundBlock = refund
      ? `<div class="notice refund-request-status"><strong>Solicitação de reembolso: ${esc(refund.status === 'requested' ? 'recebida para análise' : refund.status)}</strong><p>${esc(refund.reason || '')}</p><small>${esc(formatDate(refund.createdAt))}. O registro da solicitação não confirma nem processa um estorno.</small></div>`
      : `<form class="refund-request-form" data-order-id="${esc(order.orderId)}"><label for="refund-${esc(order.orderId)}">Solicitar análise de reembolso</label><textarea id="refund-${esc(order.orderId)}" name="reason" minlength="10" maxlength="1500" rows="3" required placeholder="Conte o motivo da solicitação (mínimo de 10 caracteres)."></textarea><p class="muted">A solicitação será encaminhada para análise manual. Nenhum estorno financeiro é processado por este formulário.</p><button class="btn btn-outline" type="submit">Enviar solicitação</button><p class="refund-form-status" role="status" aria-live="polite"></p></form>`;
    return `<article class="customer-order-card"><header><div><span class="eyebrow">Pedido</span><h2>${esc(order.orderId)}</h2></div><time>${esc(formatDate(order.createdAt))}</time></header><details><summary>Ver produtos e informações do pedido</summary><ul class="customer-order-items">${itemLines || '<li>Itens indisponíveis</li>'}</ul>${detail}${refundBlock}</details></article>`;
  }

  function supportPage(user) {
    return `<main class="page page-copy support-page"><nav class="breadcrumbs" aria-label="Navegação estrutural"><a href="/" data-link>Início</a><span aria-hidden="true"> / </span><span aria-current="page">Suporte</span></nav><span class="eyebrow">Atendimento</span><h1 class="page-title">Suporte</h1><p class="muted">Preencha os dados e confira a mensagem. Ela só será encaminhada à loja quando você abrir o WhatsApp e tocar em enviar.</p><div class="form-wrap"><form class="support-request-form"><label for="support-name">Nome</label><input id="support-name" name="name" autocomplete="name" value="${esc(user?.user_metadata?.full_name || '')}" required><label for="support-contact">E-mail ou celular</label><input id="support-contact" name="contact" autocomplete="email" value="${esc(user?.email || user?.phone || '')}" required><label for="support-order">Número do pedido (se houver)</label><input id="support-order" name="order" autocomplete="off" placeholder="Cole o número do pedido"><label for="support-topic">Assunto</label><select id="support-topic" name="topic" required><option value="">Escolha um assunto</option><option>Pedido ou entrega</option><option>Solicitação de rastreio</option><option>Troca ou reembolso</option><option>Problema na conta</option><option>Suspeita de acesso indevido</option><option>Outro assunto</option></select><label for="support-message">Como podemos ajudar?</label><textarea id="support-message" name="message" rows="5" minlength="10" maxlength="1500" required></textarea><button class="btn" type="submit">Preparar mensagem</button></form><div class="support-whatsapp-result" id="support-whatsapp-result" hidden><p id="support-preview"></p><a class="btn btn-outline" id="support-whatsapp-link" href="#" target="_blank" rel="noopener noreferrer">Abrir WhatsApp para enviar</a></div><small>Não envie senhas, códigos de confirmação ou número completo do cartão.</small></div></main>`;
  }

  async function loadOrders() {
    const container = document.getElementById('customer-orders-list');
    if (!container) return;
    try {
      const orders = await window.DEJBackend.customerOrders();
      container.innerHTML = orders.length ? orders.map(orderCard).join('') : `<div class="empty"><h2>Nenhum pedido nesta conta</h2><p class="muted">Pedidos feitos sem login não são associados automaticamente. Fale com o suporte para localizar uma compra como visitante.</p><a class="btn btn-outline" href="/suporte" data-link>Falar com suporte</a></div>`;
      bindRefundForms();
      if (typeof bindCards === 'function') bindCards();
    } catch (error) {
      container.innerHTML = `<div class="notice" role="alert">${esc(error.message || 'Não foi possível carregar os pedidos.')}<br><small>Se a área acabou de ser instalada, confirme que a migration de reembolsos foi aplicada no Neon e que a API do Render foi atualizada.</small></div>`;
    }
  }

  function bindRefundForms() {
    document.querySelectorAll('.refund-request-form').forEach(form => form.addEventListener('submit', async event => {
      event.preventDefault();
      const button = form.querySelector('[type="submit"]');
      const status = form.querySelector('.refund-form-status');
      button.disabled = true;
      status.textContent = 'Enviando para análise…';
      try {
        const result = await window.DEJBackend.requestRefund(form.dataset.orderId, new FormData(form).get('reason'));
        status.textContent = result.message || 'Solicitação registrada para análise manual.';
        await loadOrders();
      } catch (error) {
        status.textContent = error.message || 'Não foi possível registrar a solicitação.';
        button.disabled = false;
      }
    }));
  }

  function bindSupport() {
    const form = document.querySelector('.support-request-form');
    form?.addEventListener('submit', event => {
      event.preventDefault();
      const data = new FormData(form);
      const message = `Olá, loja! Meu nome é ${String(data.get('name') || '').trim()}, meu contato é ${String(data.get('contact') || '').trim()}. Assunto: ${String(data.get('topic') || '').trim()}. Pedido: ${String(data.get('order') || '').trim() || 'não informado'}. ${String(data.get('message') || '').trim()}`;
      const result = document.getElementById('support-whatsapp-result');
      document.getElementById('support-preview').textContent = message;
      document.getElementById('support-whatsapp-link').href = `https://api.whatsapp.com/send?phone=5521982579301&text=${encodeURIComponent(message)}`;
      result.hidden = false;
      result.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    });
  }

  window.DEJOrders = { ordersPage, supportPage, bind(path) { if (path === '/meus-pedidos') void loadOrders(); if (path === '/suporte') bindSupport(); } };
})();
