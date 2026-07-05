<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store.js';

const currentAccount = useMapGetter('getCurrentAccount');
const currentUser = useMapGetter('getCurrentUser');

const baseUrl = computed(() => window.location.origin);
const accountId = computed(() => currentAccount.value?.id);
const apiToken = computed(() => currentUser.value?.access_token || '(obtenha em Configurações → Perfil → Token de Acesso)');

const stockEndpoint = computed(() =>
  `${baseUrl.value}/api/v1/accounts/${accountId.value}/nexus/products?api_access_token=SEU_TOKEN`
);

const slotsEndpoint = computed(() =>
  `${baseUrl.value}/api/v1/accounts/${accountId.value}/nexus/services/ID_SERVICO/time_slots?from=DATA_INICIO&to=DATA_FIM&api_access_token=SEU_TOKEN`
);

const appointmentEndpoint = computed(() =>
  `${baseUrl.value}/api/v1/accounts/${accountId.value}/nexus/appointments`
);

const appointmentBody = `{
  "appointment": {
    "nexus_time_slot_id": 123,
    "contact_id": 456,
    "notes": "Agendado via n8n"
  }
}`;

const stockN8nNode = computed(() => JSON.stringify({
  "parameters": {
    "method": "GET",
    "url": `${baseUrl.value}/api/v1/accounts/${accountId.value}/nexus/products`,
    "authentication": "genericCredentialType",
    "genericAuthType": "queryAuth",
    "queryParameters": {
      "parameters": [{ "name": "api_access_token", "value": "={{ $credentials.token }}" }]
    },
    "options": {}
  },
  "name": "Verificar Estoque Nexus",
  "type": "n8n-nodes-base.httpRequest"
}, null, 2));

const copy = (text) => {
  navigator.clipboard.writeText(text).then(() => alert('Copiado!'));
};
</script>

<template>
  <div class="flex-1 overflow-auto p-6">
    <div class="max-w-4xl mx-auto">
      <h1 class="text-xl font-medium text-n-slate-12 mb-1">Integração com n8n</h1>
      <p class="text-sm text-n-slate-11 mb-8">Configure seu n8n para consultar estoque, listar horários disponíveis e criar agendamentos automaticamente.</p>

      <!-- Auth -->
      <div class="rounded-xl outline outline-1 outline-n-container p-5 mb-6">
        <h3 class="text-sm font-medium text-n-slate-12 mb-3">🔑 Autenticação</h3>
        <p class="text-sm text-n-slate-11 mb-3">Todas as requisições precisam do seu token de acesso. No n8n, crie uma credencial do tipo <strong>Query Auth</strong> com o parâmetro <code class="bg-n-surface-1 px-1 rounded text-xs">api_access_token</code>.</p>
        <div class="grid grid-cols-2 gap-4 text-sm">
          <div>
            <p class="text-xs text-n-slate-11 mb-1">URL base</p>
            <div class="flex items-center gap-2">
              <code class="flex-1 bg-n-surface-1 px-3 py-2 rounded text-xs font-mono break-all">{{ baseUrl }}</code>
              <button class="text-xs text-n-brand" @click="copy(baseUrl)">Copiar</button>
            </div>
          </div>
          <div>
            <p class="text-xs text-n-slate-11 mb-1">ID da conta</p>
            <div class="flex items-center gap-2">
              <code class="flex-1 bg-n-surface-1 px-3 py-2 rounded text-xs font-mono">{{ accountId }}</code>
              <button class="text-xs text-n-brand" @click="copy(String(accountId))">Copiar</button>
            </div>
          </div>
        </div>
        <div class="mt-3 p-3 bg-n-amber-3 text-n-amber-12 rounded-lg text-xs">
          ⚠️ Seu token de acesso fica em <strong>Configurações → Perfil → Token de Acesso</strong>. Nunca compartilhe-o.
        </div>
      </div>

      <!-- Stock check -->
      <div class="rounded-xl outline outline-1 outline-n-container p-5 mb-6">
        <h3 class="text-sm font-medium text-n-slate-12 mb-2">📦 Verificar Estoque</h3>
        <p class="text-xs text-n-slate-11 mb-3">Retorna todos os produtos com nome, preço, SKU e <code class="bg-n-surface-1 px-1 rounded">stock_quantity</code>.</p>
        <div class="flex items-start gap-2 mb-3">
          <code class="flex-1 bg-n-surface-1 px-3 py-2 rounded text-xs font-mono break-all">GET {{ stockEndpoint }}</code>
          <button class="text-xs text-n-brand flex-shrink-0 mt-1" @click="copy(stockEndpoint)">Copiar</button>
        </div>
        <details class="text-xs">
          <summary class="cursor-pointer text-n-brand">Ver configuração do nó n8n (JSON)</summary>
          <div class="relative mt-2">
            <pre class="bg-n-surface-1 p-3 rounded text-xs overflow-auto max-h-48">{{ stockN8nNode }}</pre>
            <button class="absolute top-2 right-2 text-n-brand" @click="copy(stockN8nNode)">Copiar</button>
          </div>
        </details>
      </div>

      <!-- Available slots -->
      <div class="rounded-xl outline outline-1 outline-n-container p-5 mb-6">
        <h3 class="text-sm font-medium text-n-slate-12 mb-2">📅 Horários Disponíveis</h3>
        <p class="text-xs text-n-slate-11 mb-3">Retorna os slots de um serviço num intervalo de datas. Use o campo <code class="bg-n-surface-1 px-1 rounded">available</code> para filtrar.</p>
        <div class="flex items-start gap-2 mb-3">
          <code class="flex-1 bg-n-surface-1 px-3 py-2 rounded text-xs font-mono break-all">GET {{ slotsEndpoint }}</code>
          <button class="text-xs text-n-brand flex-shrink-0 mt-1" @click="copy(slotsEndpoint)">Copiar</button>
        </div>
        <p class="text-xs text-n-slate-11">Substitua <code class="bg-n-surface-1 px-1 rounded">ID_SERVICO</code> pelo ID do serviço (visível na URL ao abrir o serviço). Datas no formato ISO: <code class="bg-n-surface-1 px-1 rounded">2026-07-01T00:00:00Z</code></p>
      </div>

      <!-- Create appointment -->
      <div class="rounded-xl outline outline-1 outline-n-container p-5 mb-6">
        <h3 class="text-sm font-medium text-n-slate-12 mb-2">✅ Criar Agendamento</h3>
        <p class="text-xs text-n-slate-11 mb-3">Cria um agendamento para um slot específico. O <code class="bg-n-surface-1 px-1 rounded">contact_id</code> é opcional (ID do contato no Chatwoot).</p>
        <div class="grid md:grid-cols-2 gap-4">
          <div>
            <p class="text-xs text-n-slate-11 mb-1">Endpoint (POST)</p>
            <div class="flex items-start gap-2">
              <code class="flex-1 bg-n-surface-1 px-3 py-2 rounded text-xs font-mono break-all">POST {{ appointmentEndpoint }}</code>
              <button class="text-xs text-n-brand flex-shrink-0 mt-1" @click="copy(appointmentEndpoint)">Copiar</button>
            </div>
          </div>
          <div>
            <p class="text-xs text-n-slate-11 mb-1">Body (JSON)</p>
            <div class="flex items-start gap-2">
              <pre class="flex-1 bg-n-surface-1 px-3 py-2 rounded text-xs font-mono overflow-auto">{{ appointmentBody }}</pre>
              <button class="text-xs text-n-brand flex-shrink-0 mt-1" @click="copy(appointmentBody)">Copiar</button>
            </div>
          </div>
        </div>
      </div>

      <!-- Workflow tip -->
      <div class="rounded-xl outline outline-1 outline-n-container p-5">
        <h3 class="text-sm font-medium text-n-slate-12 mb-3">💡 Fluxo sugerido no n8n</h3>
        <ol class="text-sm text-n-slate-11 space-y-2 list-decimal list-inside">
          <li>Webhook recebe mensagem do cliente pelo WhatsApp (Evolution API trigger)</li>
          <li>HTTP Request <strong>GET</strong> → listar horários disponíveis do serviço desejado</li>
          <li>Código JS → filtrar slots com <code class="bg-n-surface-1 px-1 rounded text-xs">available = true</code> e formatar para o cliente</li>
          <li>Enviar lista de horários para o cliente via WhatsApp</li>
          <li>Aguardar resposta → identificar o slot escolhido</li>
          <li>HTTP Request <strong>POST</strong> → criar o agendamento com o <code class="bg-n-surface-1 px-1 rounded text-xs">nexus_time_slot_id</code></li>
          <li>Confirmar agendamento para o cliente com os detalhes</li>
        </ol>
      </div>
    </div>
  </div>
</template>
