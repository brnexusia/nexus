<script setup>
import { ref, computed, onMounted } from 'vue';
import { useAlert } from 'dashboard/composables';

const reports = ref(null);
const isLoading = ref(false);

const fetchReports = async () => {
  isLoading.value = true;
  try {
    const accountId = window.location.pathname.match(/accounts\/(\d+)/)?.[1];
    const res = await fetch(`/api/v1/accounts/${accountId}/nexus/reports/scheduling`);
    if (!res.ok) throw new Error(res.status);
    reports.value = await res.json();
  } catch {
    useAlert('Erro ao carregar relatórios. Verifique se o módulo de Agendamento está ativo.');
  } finally {
    isLoading.value = false;
  }
};

const barData = (obj, limit = 14) => {
  if (!obj) return [];
  const entries = Object.entries(obj).slice(-limit);
  const max = Math.max(...entries.map(([, v]) => Number(v)), 1);
  return entries.map(([label, value]) => ({
    label: label.slice(5),
    value: Number(value),
    pct: Math.round((Number(value) / max) * 100)
  }));
};

const serviceEntries = computed(() => reports.value ? Object.entries(reports.value.by_service) : []);

const STATUS_LABELS = { pending: 'Pendentes', confirmed: 'Confirmados', completed: 'Concluídos', cancelled: 'Cancelados', no_show: 'Não compareceu' };
const STATUS_COLORS = { pending: 'text-yellow-600', confirmed: 'text-blue-600', completed: 'text-green-600', cancelled: 'text-red-600', no_show: 'text-gray-500' };

onMounted(fetchReports);
</script>

<template>
  <div class="flex-1 overflow-auto p-6">
    <div class="max-w-5xl mx-auto">
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-xl font-medium text-n-slate-12">Relatórios de Agendamento</h1>
        <button @click="fetchReports" class="text-xs text-n-slate-11 hover:text-n-slate-12 underline">Atualizar</button>
      </div>

      <div v-if="isLoading" class="text-center py-16 text-n-slate-11">Carregando...</div>

      <template v-else-if="reports">
        <!-- Summary -->
        <div class="grid grid-cols-2 md:grid-cols-3 gap-4 mb-8">
          <div class="rounded-xl outline outline-1 outline-n-container p-4 col-span-2 md:col-span-1">
            <p class="text-xs text-n-slate-11 mb-1">Próximos agendamentos</p>
            <p class="text-3xl font-bold text-n-brand">{{ reports.summary.upcoming }}</p>
          </div>
          <div v-for="[status, label] in Object.entries(STATUS_LABELS)" :key="status"
               class="rounded-xl outline outline-1 outline-n-container p-4">
            <p class="text-xs text-n-slate-11 mb-1">{{ label }}</p>
            <p class="text-2xl font-bold" :class="STATUS_COLORS[status]">
              {{ reports.summary[status] || 0 }}
            </p>
          </div>
        </div>

        <!-- By service -->
        <div class="rounded-xl outline outline-1 outline-n-container p-5 mb-6">
          <h3 class="text-sm font-medium text-n-slate-12 mb-4">Agendamentos por serviço</h3>
          <div v-if="serviceEntries.length === 0" class="text-sm text-n-slate-11">Nenhum dado ainda.</div>
          <div v-else class="space-y-3">
            <div v-for="[name, count] in serviceEntries" :key="name" class="flex items-center gap-3">
              <span class="text-sm text-n-slate-12 w-40 truncate flex-shrink-0">{{ name }}</span>
              <div class="flex-1 bg-n-surface-1 rounded-full h-2 overflow-hidden">
                <div class="h-full bg-n-brand rounded-full"
                     :style="{ width: (count / Math.max(...serviceEntries.map(([,v]) => v)) * 100) + '%' }" />
              </div>
              <span class="text-sm font-medium text-n-slate-12 w-8 text-right">{{ count }}</span>
            </div>
          </div>
        </div>

        <!-- By day -->
        <div class="rounded-xl outline outline-1 outline-n-container p-5">
          <h3 class="text-sm font-medium text-n-slate-12 mb-4">Agendamentos por dia (últimos 30 dias)</h3>
          <div class="flex items-end gap-1 h-28">
            <div v-for="item in barData(reports.appointments_by_day)" :key="item.label"
                 class="flex-1 flex flex-col items-center gap-1">
              <div class="w-full rounded-t bg-n-brand opacity-70 hover:opacity-100"
                   :style="{ height: Math.max(item.pct, 2) + '%' }"
                   :title="`${item.label}: ${item.value}`" />
              <span class="text-[9px] text-n-slate-11 rotate-45 origin-left mt-1">{{ item.label }}</span>
            </div>
          </div>
          <div v-if="!Object.keys(reports.appointments_by_day).length" class="text-center text-n-slate-11 text-sm py-4">
            Nenhum dado ainda.
          </div>
        </div>
      </template>

      <div v-else class="text-center py-16 text-n-slate-11">
        <p class="text-4xl mb-3">📅</p>
        <p>Nenhum dado disponível.</p>
      </div>
    </div>
  </div>
</template>
