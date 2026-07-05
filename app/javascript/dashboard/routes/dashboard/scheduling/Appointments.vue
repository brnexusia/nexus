<script setup>
import { ref, computed, onMounted } from 'vue';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import { servicesAPI, appointmentsAPI } from 'dashboard/api/nexus/scheduling';

const today = new Date();
const currentYear = ref(today.getFullYear());
const currentMonth = ref(today.getMonth());

const appointments = ref([]);
const services = ref([]);
const isLoading = ref(false);

// Booking form
const showBookForm = ref(false);
const selectedDate = ref(null);
const selectedServiceId = ref('');
const selectedSlotId = ref('');
const bookNotes = ref('');
const slots = ref([]);
const slotsLoading = ref(false);

const MONTHS = ['Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'];
const DAYS_HEADER = ['Dom','Seg','Ter','Qua','Qui','Sex','Sáb'];
const STATUS_LABELS = { pending: 'Pendente', confirmed: 'Confirmado', cancelled: 'Cancelado', completed: 'Concluído', no_show: 'Não compareceu' };

const monthStart = computed(() => new Date(currentYear.value, currentMonth.value, 1));
const monthEnd = computed(() => new Date(currentYear.value, currentMonth.value + 1, 0));

const calendarDays = computed(() => {
  const days = [];
  const start = new Date(monthStart.value);
  start.setDate(start.getDate() - start.getDay());
  for (let i = 0; i < 42; i++) {
    const d = new Date(start);
    d.setDate(d.getDate() + i);
    days.push(d);
  }
  return days;
});

const dayKey = (d) => `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
const isCurrentMonth = (d) => d.getMonth() === currentMonth.value;
const isToday = (d) => dayKey(d) === dayKey(today);
const formatTime = (iso) => new Date(iso).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });

const appointmentsByDate = computed(() => {
  const map = {};
  appointments.value.forEach(a => {
    const key = a.nexus_time_slot?.start_time?.slice(0, 10);
    if (key) { if (!map[key]) map[key] = []; map[key].push(a); }
  });
  return map;
});

const selectedService = computed(() => services.value.find(s => s.id == selectedServiceId.value));

const prevMonth = () => { if (currentMonth.value === 0) { currentMonth.value = 11; currentYear.value--; } else currentMonth.value--; fetchData(); };
const nextMonth = () => { if (currentMonth.value === 11) { currentMonth.value = 0; currentYear.value++; } else currentMonth.value++; fetchData(); };

const fetchData = async () => {
  isLoading.value = true;
  try {
    const from = monthStart.value.toISOString();
    const to = monthEnd.value.toISOString();
    const [appRes, svcRes] = await Promise.all([
      appointmentsAPI.getAll(from, to),
      servicesAPI.getAll()
    ]);
    appointments.value = appRes.data;
    services.value = svcRes.data.filter(s => s.status === 'active');
  } catch { useAlert('Erro ao carregar dados.'); }
  finally { isLoading.value = false; }
};

const openBooking = async (day) => {
  if (!services.value.length) return useAlert('Nenhum serviço ativo. Crie um em "Serviços" primeiro.');
  selectedDate.value = day;
  selectedSlotId.value = '';
  selectedServiceId.value = services.value[0]?.id || '';
  bookNotes.value = '';
  slots.value = [];
  showBookForm.value = true;
  await loadSlots();
};

const loadSlots = async () => {
  if (!selectedServiceId.value || !selectedDate.value) return;
  slotsLoading.value = true;
  slots.value = [];
  selectedSlotId.value = '';
  try {
    const d = selectedDate.value;
    const from = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 0, 0, 0);
    const to = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59, 59);
    const { data } = await servicesAPI.getSlots(selectedServiceId.value, from.toISOString(), to.toISOString());
    slots.value = data.filter(s => s.available);
  } catch { slots.value = []; }
  finally { slotsLoading.value = false; }
};

const saveBooking = async () => {
  if (!selectedSlotId.value) return useAlert('Selecione um horário disponível.');
  try {
    await appointmentsAPI.create({ nexus_time_slot_id: selectedSlotId.value, notes: bookNotes.value });
    useAlert('Agendamento confirmado! ✅');
    showBookForm.value = false;
    fetchData();
  } catch (e) { useAlert(e.response?.data?.error || 'Erro ao agendar.'); }
};

const cancelAppointment = async (id) => {
  if (!confirm('Cancelar este agendamento?')) return;
  try { await appointmentsAPI.cancel(id); useAlert('Cancelado.'); fetchData(); }
  catch { useAlert('Erro ao cancelar.'); }
};

onMounted(fetchData);
</script>

<template>
  <div class="flex-1 overflow-auto p-6">
    <div class="max-w-6xl mx-auto">
      <!-- Header -->
      <div class="flex items-center justify-between mb-6">
        <div class="flex items-center gap-4">
          <h1 class="text-xl font-medium text-n-slate-12">Calendário de Agendamentos</h1>
          <div class="flex items-center gap-1">
            <button class="p-1.5 rounded hover:bg-n-surface-1 text-n-slate-11" @click="prevMonth">‹</button>
            <span class="text-sm font-medium w-40 text-center">{{ MONTHS[currentMonth] }} {{ currentYear }}</span>
            <button class="p-1.5 rounded hover:bg-n-surface-1 text-n-slate-11" @click="nextMonth">›</button>
          </div>
        </div>
        <Button label="+ Novo Agendamento" size="sm" @click="openBooking(today)" />
      </div>

      <!-- No services warning -->
      <div v-if="!isLoading && services.length === 0"
           class="mb-4 p-3 rounded-lg bg-n-amber-3 text-n-amber-12 text-sm">
        ⚠️ Nenhum serviço ativo. Vá em <strong>Serviços</strong> para criar um serviço e adicionar horários disponíveis.
      </div>

      <!-- Booking Modal -->
      <div v-if="showBookForm" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
        <div class="bg-n-background rounded-xl p-6 w-full max-w-md shadow-xl">
          <h2 class="text-lg font-medium mb-1">Novo Agendamento</h2>
          <p class="text-sm text-n-slate-11 mb-4">
            📅 {{ selectedDate ? selectedDate.toLocaleDateString('pt-BR', { weekday: 'long', day: '2-digit', month: 'long' }) : '' }}
          </p>

          <div class="space-y-4">
            <!-- Service select -->
            <div>
              <label class="text-xs font-medium text-n-slate-11 block mb-1">Serviço</label>
              <select v-model="selectedServiceId" @change="loadSlots"
                      class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand">
                <option v-for="s in services" :key="s.id" :value="s.id">
                  {{ s.name }} ({{ s.duration_minutes }}min · R$ {{ Number(s.price).toFixed(2) }})
                </option>
              </select>
            </div>

            <!-- Slot select -->
            <div>
              <label class="text-xs font-medium text-n-slate-11 block mb-1">Horário disponível</label>
              <div v-if="slotsLoading" class="text-sm text-n-slate-11 py-2">Buscando horários...</div>
              <div v-else-if="slots.length === 0" class="rounded-lg bg-n-amber-3 text-n-amber-12 text-sm p-3">
                Nenhum horário disponível para este serviço neste dia.<br/>
                Vá em <strong>Serviços → Horários</strong> e adicione horários para esta data.
              </div>
              <select v-else v-model="selectedSlotId"
                      class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand">
                <option value="">Selecione um horário</option>
                <option v-for="sl in slots" :key="sl.id" :value="sl.id">
                  {{ formatTime(sl.start_time) }} – {{ formatTime(sl.end_time) }}
                  ({{ sl.slots_remaining }} vaga{{ sl.slots_remaining !== 1 ? 's' : '' }})
                </option>
              </select>
            </div>

            <!-- Notes -->
            <div>
              <label class="text-xs font-medium text-n-slate-11 block mb-1">Observações (opcional)</label>
              <textarea v-model="bookNotes" rows="2" placeholder="Ex: nome do cliente, motivo..."
                        class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand" />
            </div>
          </div>

          <div class="flex justify-end gap-2 mt-5">
            <Button label="Cancelar" variant="faded" size="sm" @click="showBookForm = false" />
            <Button label="Confirmar Agendamento" size="sm" :disabled="!selectedSlotId" @click="saveBooking" />
          </div>
        </div>
      </div>

      <!-- Calendar Grid -->
      <div v-if="isLoading" class="text-center py-16 text-n-slate-11">Carregando calendário...</div>
      <div v-else class="rounded-xl outline outline-1 outline-n-container overflow-hidden">
        <!-- Day headers -->
        <div class="grid grid-cols-7 bg-n-surface-1">
          <div v-for="d in DAYS_HEADER" :key="d" class="py-2 text-center text-xs font-medium text-n-slate-11">{{ d }}</div>
        </div>
        <!-- Cells -->
        <div class="grid grid-cols-7">
          <div v-for="(day, idx) in calendarDays" :key="idx"
               class="min-h-[96px] border-t border-l border-n-weak p-1.5 relative cursor-pointer hover:bg-n-surface-1 transition-colors"
               :class="{ 'opacity-40': !isCurrentMonth(day), 'ring-2 ring-inset ring-n-brand': isToday(day) }"
               @click="openBooking(day)">
            <span class="text-xs font-medium" :class="isToday(day) ? 'text-n-brand' : 'text-n-slate-11'">
              {{ day.getDate() }}
            </span>
            <div class="mt-1 space-y-0.5">
              <div v-for="apt in (appointmentsByDate[dayKey(day)] || [])" :key="apt.id"
                   class="text-white text-[10px] rounded px-1.5 py-0.5 flex items-center justify-between gap-1 truncate"
                   :style="{ background: apt.nexus_service?.color || '#A9602D' }"
                   @click.stop>
                <span class="truncate">{{ formatTime(apt.nexus_time_slot?.start_time) }} {{ apt.nexus_service?.name }}</span>
                <button class="opacity-70 hover:opacity-100 flex-shrink-0" title="Cancelar" @click="cancelAppointment(apt.id)">✕</button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Legend -->
      <div class="mt-3 flex gap-4 flex-wrap">
        <div v-for="s in services" :key="s.id" class="flex items-center gap-1.5 text-xs text-n-slate-11">
          <span class="w-3 h-3 rounded-sm flex-shrink-0" :style="{ background: s.color }" />
          {{ s.name }}
        </div>
      </div>
    </div>
  </div>
</template>
