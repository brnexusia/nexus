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

// Slot management per service
const expandedId = ref(null);
const serviceSlots = ref({});
const slotsLoading = ref(false);
const slotForm = ref({ date: '', start_time: '', end_time: '', max_bookings: 1 });
const showSlotForm = ref(false);
const activeSlotServiceId = ref(null);

const today = new Date().toISOString().slice(0, 10);

const fetchServices = async () => {
  isLoading.value = true;
  try {
    const { data } = await servicesAPI.getAll();
    services.value = data;
  } catch { useAlert('Erro ao carregar serviços.'); }
  finally { isLoading.value = false; }
};

const openNew = () => { editing.value = null; form.value = { name: '', description: '', duration_minutes: 60, price: 0, color: '#A9602D' }; showForm.value = true; };
const openEdit = (s) => { editing.value = s; form.value = { ...s }; showForm.value = true; };

const save = async () => {
  try {
    if (editing.value) { await servicesAPI.update(editing.value.id, form.value); useAlert('Serviço atualizado.'); }
    else { await servicesAPI.create(form.value); useAlert('Serviço criado.'); }
    showForm.value = false; fetchServices();
  } catch (e) { useAlert(e.response?.data?.error || 'Erro ao salvar.'); }
};

const archive = async (s) => {
  try { await servicesAPI.update(s.id, { status: 'archived' }); useAlert('Arquivado.'); fetchServices(); }
  catch { useAlert('Erro.'); }
};

const remove = async (s) => {
  if (!confirm(`Excluir "${s.name}"?`)) return;
  try { await servicesAPI.delete(s.id); useAlert('Excluído.'); fetchServices(); }
  catch (e) { useAlert(e.response?.data?.error || 'Erro.'); }
};

// ─── Slot management ───────────────────────────────────────────────────────────

const toggleExpand = async (service) => {
  if (expandedId.value === service.id) { expandedId.value = null; return; }
  expandedId.value = service.id;
  await loadSlotsFor(service.id);
};

const loadSlotsFor = async (serviceId) => {
  slotsLoading.value = true;
  try {
    const from = new Date().toISOString();
    const to = new Date(Date.now() + 60 * 24 * 60 * 60 * 1000).toISOString(); // next 60 days
    const { data } = await servicesAPI.getSlots(serviceId, from, to);
    serviceSlots.value = { ...serviceSlots.value, [serviceId]: data };
  } catch { serviceSlots.value = { ...serviceSlots.value, [serviceId]: [] }; }
  finally { slotsLoading.value = false; }
};

const openSlotForm = (serviceId) => {
  activeSlotServiceId.value = serviceId;
  slotForm.value = { date: today, start_time: '09:00', end_time: '10:00', max_bookings: 1 };
  showSlotForm.value = true;
};

const saveSlot = async () => {
  if (!slotForm.value.date || !slotForm.value.start_time || !slotForm.value.end_time) return useAlert('Preencha data e horários.');
  const start = new Date(`${slotForm.value.date}T${slotForm.value.start_time}:00`);
  const end = new Date(`${slotForm.value.date}T${slotForm.value.end_time}:00`);
  if (end <= start) return useAlert('Horário de término deve ser após o início.');
  try {
    await servicesAPI.createSlot(activeSlotServiceId.value, {
      start_time: start.toISOString(),
      end_time: end.toISOString(),
      max_bookings: slotForm.value.max_bookings
    });
    useAlert('Horário criado!');
    showSlotForm.value = false;
    await loadSlotsFor(activeSlotServiceId.value);
  } catch (e) { useAlert(e.response?.data?.error || 'Erro ao criar horário.'); }
};

const deleteSlot = async (serviceId, slotId) => {
  if (!confirm('Remover este horário?')) return;
  try { await servicesAPI.deleteSlot(serviceId, slotId); await loadSlotsFor(serviceId); useAlert('Horário removido.'); }
  catch { useAlert('Erro.'); }
};

const fmt = (iso) => new Date(iso).toLocaleString('pt-BR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });

onMounted(fetchServices);
</script>

<template>
  <div class="flex-1 overflow-auto p-6">
    <div class="max-w-4xl mx-auto">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-xl font-medium text-n-slate-12">Serviços</h1>
          <p class="text-sm text-n-slate-11 mt-0.5">Defina os serviços e os horários disponíveis para agendamento.</p>
        </div>
        <Button label="Novo Serviço" size="sm" @click="openNew" />
      </div>

      <!-- Service Form Modal -->
      <div v-if="showForm" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
        <div class="bg-n-background rounded-xl p-6 w-full max-w-md shadow-xl">
          <h2 class="text-lg font-medium mb-4">{{ editing ? 'Editar' : 'Novo' }} Serviço</h2>
          <div class="space-y-3">
            <input v-model="form.name" placeholder="Nome *" class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand" />
            <textarea v-model="form.description" placeholder="Descrição" rows="2" class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand" />
            <div class="grid grid-cols-3 gap-3">
              <div><label class="text-xs text-n-slate-11 block mb-1">Duração (min)</label>
                <input v-model.number="form.duration_minutes" type="number" min="5" step="5" class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none" />
              </div>
              <div><label class="text-xs text-n-slate-11 block mb-1">Preço (R$)</label>
                <input v-model.number="form.price" type="number" min="0" step="0.01" class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none" />
              </div>
              <div><label class="text-xs text-n-slate-11 block mb-1">Cor</label>
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

      <!-- Slot Form Modal -->
      <div v-if="showSlotForm" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
        <div class="bg-n-background rounded-xl p-6 w-full max-w-sm shadow-xl">
          <h2 class="text-lg font-medium mb-4">Novo Horário Disponível</h2>
          <div class="space-y-3">
            <div><label class="text-xs text-n-slate-11 block mb-1">Data</label>
              <input v-model="slotForm.date" type="date" :min="today" class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand" />
            </div>
            <div class="grid grid-cols-2 gap-3">
              <div><label class="text-xs text-n-slate-11 block mb-1">Início</label>
                <input v-model="slotForm.start_time" type="time" class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand" />
              </div>
              <div><label class="text-xs text-n-slate-11 block mb-1">Término</label>
                <input v-model="slotForm.end_time" type="time" class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand" />
              </div>
            </div>
            <div><label class="text-xs text-n-slate-11 block mb-1">Vagas disponíveis</label>
              <input v-model.number="slotForm.max_bookings" type="number" min="1" class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none" />
            </div>
          </div>
          <div class="flex justify-end gap-2 mt-4">
            <Button label="Cancelar" variant="faded" size="sm" @click="showSlotForm = false" />
            <Button label="Criar Horário" size="sm" @click="saveSlot" />
          </div>
        </div>
      </div>

      <!-- Services List -->
      <div v-if="isLoading" class="text-center py-12 text-n-slate-11">Carregando...</div>
      <div v-else-if="services.length === 0" class="text-center py-16 text-n-slate-11">
        <p class="text-4xl mb-3">📅</p>
        <p class="font-medium">Nenhum serviço ainda.</p>
        <p class="text-sm mt-1">Crie um serviço e depois adicione os horários disponíveis.</p>
      </div>
      <div v-else class="space-y-3">
        <div v-for="s in services" :key="s.id" class="rounded-xl outline outline-1 outline-n-container overflow-hidden">
          <!-- Service Header -->
          <div class="flex items-center gap-4 p-4">
            <div :style="{ background: s.color }" class="w-10 h-10 rounded-full flex-shrink-0" />
            <div class="flex-1">
              <p class="font-medium text-n-slate-12">{{ s.name }}</p>
              <p class="text-xs text-n-slate-11">{{ s.duration_minutes }} min · R$ {{ Number(s.price).toFixed(2) }}</p>
            </div>
            <span :class="s.status === 'active' ? 'text-green-600 bg-green-50' : 'text-n-slate-11 bg-n-surface-1'"
                  class="rounded-full px-2 py-0.5 text-xs font-medium">
              {{ s.status === 'active' ? 'Ativo' : 'Arquivado' }}
            </span>
            <Button label="Horários" variant="faded" size="xs" @click="toggleExpand(s)" />
            <Button label="Editar" variant="faded" size="xs" @click="openEdit(s)" />
            <Button v-if="s.status === 'active'" label="Arquivar" variant="faded" size="xs" @click="archive(s)" />
            <Button label="Excluir" color="ruby" variant="faded" size="xs" @click="remove(s)" />
          </div>

          <!-- Slots Panel (expandable) -->
          <div v-if="expandedId === s.id" class="border-t border-n-weak bg-n-surface-1 p-4">
            <div class="flex items-center justify-between mb-3">
              <p class="text-sm font-medium text-n-slate-12">Horários disponíveis (próximos 60 dias)</p>
              <Button label="+ Novo Horário" size="xs" @click="openSlotForm(s.id)" />
            </div>
            <div v-if="slotsLoading" class="text-xs text-n-slate-11">Carregando...</div>
            <div v-else-if="!serviceSlots[s.id] || serviceSlots[s.id].length === 0"
                 class="text-sm text-n-slate-11 py-2">
              Nenhum horário cadastrado. Clique em "+ Novo Horário" para adicionar.
            </div>
            <div v-else class="space-y-1">
              <div v-for="slot in serviceSlots[s.id]" :key="slot.id"
                   class="flex items-center justify-between rounded-lg bg-n-background px-3 py-2 text-xs">
                <span class="text-n-slate-12 font-medium">{{ fmt(slot.start_time) }} – {{ fmt(slot.end_time) }}</span>
                <span class="text-n-slate-11">{{ slot.current_bookings }}/{{ slot.max_bookings }} vagas</span>
                <span :class="slot.available ? 'text-green-600' : 'text-red-500'">
                  {{ slot.available ? 'Disponível' : 'Lotado' }}
                </span>
                <button class="text-red-400 hover:text-red-600 text-xs" @click="deleteSlot(s.id, slot.id)">Remover</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
