<script setup>
import { ref, onMounted } from 'vue';
import { useAlert } from 'dashboard/composables';

// Lazy import to avoid build issues if axios isn't global
const reports = ref(null);
const isLoading = ref(false);

const fetchReports = async () => {
  isLoading.value = true;
  try {
    const accountId = window.chatwootConfig?.accountId
      || document.querySelector('[data-account-id]')?.dataset?.accountId
      || window.location.pathname.match(/accounts\/(\d+)/)?.[1];
    const token = window.authToken || Object.values(window.__vue_store__?.state?.auth || {}).find(v => v?.access_token)?.access_token;

    // Fallback: fetch from API using current page cookies/session
    const res = await fetch(`/api/v1/accounts/${accountId}/nexus/reports/sales`, {
      headers: { 'api_access_token': token || '', 'Content-Type': 'application/json' }
    });
    if (!res.ok) throw new Error(res.status);
    reports.value = await res.json();
  } catch {
    useAlert('Erro ao carregar relatórios. Verifique se o módulo de Vendas está ativo.');
  } finally {
    isLoading.value = false;
  }
};

// Simple bar chart helper - returns array of { label, value, pct }
const barData = (obj, limit = 7) => {
  if (!obj) return [];
  const entries = Object.entries(obj).slice(-limit);
  const max = Math.max(...entries.map(([, v]) => Number(v)), 1);
  return entries.map(([label, value]) => ({
    label: label.slice(5), // strip year from date
    value: Number(value),
    pct: Math.round((Number(value) / max) * 100)
  }));
};

const formatCurrency = (v) => `R$ ${Number(v || 0).toFixed(2)}`;

onMounted(fetchReports);
</script>

<template>
  <div class="flex-1 overflow-auto p-6">
    <div class="max-w-5xl mx-auto">
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-xl font-medium text-n-slate-12">Relatórios de Vendas</h1>
        <button @click="fetchReports" class="text-xs text-n-slate-11 hover:text-n-slate-12 underline">Atualizar</button>
      </div>

      <div v-if="isLoading" class="text-center py-16 text-n-slate-11">Carregando...</div>

      <template v-else-if="reports">
        <!-- Summary cards -->
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
          <div class="rounded-xl outline outline-1 outline-n-container p-4">
            <p class="text-xs text-n-slate-11 mb-1">Total de Pedidos</p>
            <p class="text-2xl font-bold text-n-slate-12">{{ reports.summary.total_orders }}</p>
          </div>
          <div class="rounded-xl outline outline-1 outline-n-container p-4">
            <p class="text-xs text-n-slate-11 mb-1">Receita (concluídos)</p>
            <p class="text-2xl font-bold text-n-brand">{{ formatCurrency(reports.summary.total_revenue) }}</p>
          </div>
          <div class="rounded-xl outline outline-1 outline-n-container p-4">
            <p class="text-xs text-n-slate-11 mb-1">Pendentes</p>
            <p class="text-2xl font-bold text-yellow-600">{{ reports.summary.pending }}</p>
          </div>
          <div class="rounded-xl outline outline-1 outline-n-container p-4">
            <p class="text-xs text-n-slate-11 mb-1">Concluídos</p>
            <p class="text-2xl font-bold text-green-600">{{ reports.summary.completed }}</p>
          </div>
        </div>

        <!-- Revenue chart (last 30 days) -->
        <div class="rounded-xl outline outline-1 outline-n-container p-5 mb-6">
          <h3 class="text-sm font-medium text-n-slate-12 mb-4">Receita por dia (últimos 30 dias)</h3>
          <div class="flex items-end gap-1 h-32">
            <div v-for="item in barData(reports.revenue_by_day)" :key="item.label"
                 class="flex-1 flex flex-col items-center gap-1 group">
              <div class="w-full rounded-t transition-all bg-n-brand opacity-80 hover:opacity-100"
                   :style="{ height: Math.max(item.pct, 2) + '%' }"
                   :title="`${item.label}: ${formatCurrency(item.value)}`" />
              <span class="text-[9px] text-n-slate-11 rotate-45 origin-left mt-1">{{ item.label }}</span>
            </div>
          </div>
          <div v-if="!Object.keys(reports.revenue_by_day).length" class="text-center text-n-slate-11 text-sm py-4">
            Nenhum dado ainda.
          </div>
        </div>

        <!-- Orders chart -->
        <div class="rounded-xl outline outline-1 outline-n-container p-5 mb-6">
          <h3 class="text-sm font-medium text-n-slate-12 mb-4">Pedidos por dia (últimos 30 dias)</h3>
          <div class="flex items-end gap-1 h-24">
            <div v-for="item in barData(reports.orders_by_day)" :key="item.label"
                 class="flex-1 flex flex-col items-center gap-1">
              <div class="w-full rounded-t bg-blue-400 opacity-70 hover:opacity-100"
                   :style="{ height: Math.max(item.pct, 2) + '%' }"
                   :title="`${item.label}: ${item.value} pedidos`" />
              <span class="text-[9px] text-n-slate-11 rotate-45 origin-left mt-1">{{ item.label }}</span>
            </div>
          </div>
        </div>

        <!-- Top products -->
        <div class="rounded-xl outline outline-1 outline-n-container p-5">
          <h3 class="text-sm font-medium text-n-slate-12 mb-4">Produtos mais vendidos</h3>
          <div v-if="!Object.keys(reports.top_products).length" class="text-sm text-n-slate-11">
            Nenhum produto vendido ainda.
          </div>
          <div v-else class="space-y-2">
            <div v-for="[name, qty] in Object.entries(reports.top_products)" :key="name"
                 class="flex items-center justify-between">
              <span class="text-sm text-n-slate-12">{{ name }}</span>
              <span class="text-sm font-medium text-n-slate-12">{{ qty }} unid.</span>
            </div>
          </div>
        </div>
      </template>

      <div v-else class="text-center py-16 text-n-slate-11">
        <p class="text-4xl mb-3">📊</p>
        <p>Nenhum dado disponível.</p>
      </div>
    </div>
  </div>
</template>
