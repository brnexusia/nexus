<script setup>
import { ref, onMounted } from 'vue';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import { servicesAPI } from 'dashboard/api/nexus/scheduling';

const services = ref([]);
const isLoading = ref(false);
const showForm = ref(false);
const editing = ref(null);
const form = ref({ name: '', description: '', duration_minutes: 60, price: 0, color: '#A9602D' });

const fetchServices = async () => {
  isLoading.value = true;
  try {
    const { data } = await servicesAPI.getAll();
    services.value = data;
  } catch {
    useAlert('Erro ao carregar serviços.');
  } finally {
    isLoading.value = false;
  }
};

const openNew = () => {
  editing.value = null;
  form.value = { name: '', description: '', duration_minutes: 60, price: 0, color: '#A9602D' };
  showForm.value = true;
};

const openEdit = (service) => {
  editing.value = service;
  form.value = { ...service };
  showForm.value = true;
};

const save = async () => {
  try {
    if (editing.value) {
      await servicesAPI.update(editing.value.id, form.value);
      useAlert('Serviço atualizado.');
    } else {
      await servicesAPI.create(form.value);
      useAlert('Serviço criado.');
    }
    showForm.value = false;
    fetchServices();
  } catch (e) {
    useAlert(e.response?.data?.error || 'Erro ao salvar.');
  }
};

const archive = async (service) => {
  try {
    await servicesAPI.update(service.id, { status: 'archived' });
    useAlert('Serviço arquivado.');
    fetchServices();
  } catch {
    useAlert('Erro ao arquivar.');
  }
};

const remove = async (service) => {
  if (!confirm(`Excluir "${service.name}"?`)) return;
  try {
    await servicesAPI.delete(service.id);
    useAlert('Serviço excluído.');
    fetchServices();
  } catch (e) {
    useAlert(e.response?.data?.error || 'Erro ao excluir.');
  }
};

onMounted(fetchServices);
</script>

<template>
  <div class="flex-1 overflow-auto p-6">
    <div class="max-w-4xl mx-auto">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-xl font-medium text-n-slate-12">Serviços</h1>
          <p class="text-sm text-n-slate-11 mt-0.5">Defina os tipos de serviço disponíveis para agendamento.</p>
        </div>
        <Button label="Novo Serviço" size="sm" @click="openNew" />
      </div>

      <!-- Form Modal -->
      <div v-if="showForm" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
        <div class="bg-n-background rounded-xl p-6 w-full max-w-md shadow-xl">
          <h2 class="text-lg font-medium mb-4">{{ editing ? 'Editar Serviço' : 'Novo Serviço' }}</h2>
          <div class="space-y-3">
            <input v-model="form.name" placeholder="Nome do serviço *" class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand" />
            <textarea v-model="form.description" placeholder="Descrição" rows="2" class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand" />
            <div class="grid grid-cols-3 gap-3">
              <div>
                <label class="text-xs text-n-slate-11 mb-1 block">Duração (min)</label>
                <input v-model.number="form.duration_minutes" type="number" min="5" step="5" class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand" />
              </div>
              <div>
                <label class="text-xs text-n-slate-11 mb-1 block">Preço (R$)</label>
                <input v-model.number="form.price" type="number" min="0" step="0.01" class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand" />
              </div>
              <div>
                <label class="text-xs text-n-slate-11 mb-1 block">Cor</label>
                <input v-model="form.color" type="color" class="w-full h-10 rounded-lg border border-n-weak cursor-pointer" />
              </div>
            </div>
          </div>
          <div class="flex justify-end gap-2 mt-4">
            <Button label="Cancelar" variant="faded" size="sm" @click="showForm = false" />
            <Button label="Salvar" size="sm" @click="save" />
          </div>
        </div>
      </div>

      <!-- Services List -->
      <div v-if="isLoading" class="text-center py-12 text-n-slate-11">Carregando...</div>
      <div v-else-if="services.length === 0" class="text-center py-12 text-n-slate-11">
        Nenhum serviço cadastrado ainda.
      </div>
      <div v-else class="grid gap-3">
        <div v-for="s in services" :key="s.id"
             class="flex items-center gap-4 p-4 rounded-xl outline outline-1 outline-n-container hover:bg-n-surface-1">
          <div :style="{ background: s.color }" class="w-10 h-10 rounded-full flex-shrink-0" />
          <div class="flex-1">
            <p class="font-medium text-n-slate-12">{{ s.name }}</p>
            <p class="text-xs text-n-slate-11">{{ s.duration_minutes }} min · R$ {{ Number(s.price).toFixed(2) }}</p>
          </div>
          <span :class="s.status === 'active' ? 'text-green-600 bg-green-50' : 'text-n-slate-11 bg-n-surface-1'"
                class="rounded-full px-2 py-0.5 text-xs font-medium">
            {{ s.status === 'active' ? 'Ativo' : 'Arquivado' }}
          </span>
          <div class="flex gap-2">
            <Button label="Editar" variant="faded" size="xs" @click="openEdit(s)" />
            <Button v-if="s.status === 'active'" label="Arquivar" variant="faded" size="xs" @click="archive(s)" />
            <Button label="Excluir" color="ruby" variant="faded" size="xs" @click="remove(s)" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
