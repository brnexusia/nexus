<script setup>
import { ref, computed, onMounted } from 'vue';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import { servicesAPI, appointmentsAPI } from 'dashboard/api/nexus/scheduling';

const today = new Date();
const currentYear = ref(today.getFullYear());
const currentMonth = ref(today.getMonth()); // 0-based

const appointments = ref([]);
const services = ref([]);
const slots = ref([]);
const isLoading = ref(false);
const showBookForm = ref(false);
const selectedDate = ref(null);
const selectedSlotId = ref('');
const selectedServiceId = ref('');
const bookNotes = ref('');

const MONTHS = ['Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'];
const DAYS = ['Dom','Seg','Ter','Qua','Qui','Sex','Sáb'];
const STATUS_LABELS = { pending: 'Pendente', confirmed: 'Confirmado', cancelled: 'Cancelado', completed: 'Concluído', no_show: 'Não compareceu' };
const STATUS_COLORS = { pending: '#F59E0B', confirmed: '#3B82F6', cancelled: '#EF4444', completed: '#10B981', no_show: '#6B7280' };

const monthStart = computed(() => new Date(currentYear.value, currentMonth.value, 1));
const monthEnd = computed(() => new Date(currentYear.value, currentMonth.value + 1, 0));

// Grid of weeks for the calendar
const calendarDays = computed(() => {
  const days = [];
  const start = new Date(monthStart.value);
  start.setDate(start.getDate() - start.getDay()); // go back to sunday
  for (let i = 0; i < 42; i++) {
    const d = new Date(start);
    d.setDate(d.getDate() + i);
    days.push(d);
  }
  return days;
});

const appointmentsByDate = computed(() => {
  const map = {};
  appointments.value.forEach(a => {
    const key = a.nexus_time_slot?.start_time?.slice(0, 10);
    if (!map[key]) map[key] = [];
    map[key].push(a);
  });
  return map;
});

const dayKey = (d) => `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
const isCurrentMonth = (d) => d.getMonth() === currentMonth.value;
const isToday = (d) => dayKey(d) === dayKey(today);

const prevMonth = () => {
  if (currentMonth.value === 0) { currentMonth.value = 11; currentYear.value--; }
  else currentMonth.value--;
  fetchData();
};

const nextMonth = () => {
  if (currentMonth.value === 11) { currentMonth.value = 0; currentYear.value++; }
  else currentMonth.value++;
  fetchData();
};

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
  } catch {
    useAlert('Erro ao carregar agendamentos.');
  } finally {
    isLoading.value = false;
  }
};

const openBooking = async (day) => {
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
  const from = new Date(selectedDate.value);
  from.setHours(0, 0, 0);
  const to = new Date(selectedDate.value);
  to.setHours(23, 59, 59);
  try {
    const { data } = await servicesAPI.getSlots(selectedServiceId.value, from.toISOString(), to.toISOString());
    slots.value = data.filter(s => s.available);
  } catch {
    slots.value = [];
  }
};

const saveBooking = async () => {
  if (!selectedSlotId.value) return useAlert('Selecione um horário.');
  try {
    await appointmentsAPI.create({
      nexus_time_slot_id: selectedSlotId.value,
      notes: bookNotes.value
    });
    useAlert('Agendamento criado!');
    showBookForm.value = false;
    fetchData();
  } catch (e) {
    useAlert(e.response?.data?.error || 'Erro ao agendar.');
  }
};

const cancelAppointment = async (id) => {
  if (!confirm('Cancelar este agendamento?')) return;
  try {
    await appointmentsAPI.cancel(id);
    useAlert('Agendamento cancelado.');
    fetchData();
  } catch {
    useAlert('Erro ao cancelar.');
  }
};

const formatTime = (iso) => new Date(iso).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });

onMounted(fetchData);
</script>

<template>
  <div class="flex-1 overflow-auto p-6">
    <div class="max-w-6xl mx-auto">
      <!-- Header -->
      <div class="flex items-center justify-between mb-6">
        <div class="flex items-center gap-4">
          <h1 class="text-xl font-medium text-n-slate-12">Agendamentos</h1>
          <div class="flex items-center gap-2">
            <button class="p-1 rounded hover:bg-n-surface-1" @click="prevMonth">‹</button>
            <span class="text-sm font-medium w-36 text-center">{{ MONTHS[currentMonth] }} {{ currentYear }}</span>
            <button class="p-1 rounded hover:bg-n-surface-1" @click="nextMonth">›</button>
          </div>
        </div>
        <Button label="Novo Agendamento" size="sm" @click="openBooking(today)" />
      </div>

      <!-- Booking Modal -->
      <div v-if="showBookForm" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
        <div class="bg-n-background rounded-xl p-6 w-full max-w-md shadow-xl">
          <h2 class="text-lg font-medium mb-4">
            Novo Agendamento — {{ selectedDate ? dayKey(selectedDate) : '' }}
          </h2>
          <div class="space-y-3">
            <div>
              <label class="text-xs text-n-slate-11 mb-1 block">Serviço</label>
              <select v-model="selectedServiceId" @change="loadSlots" class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none">
                <option v-for="s in services" :key="s.id" :value="s.id">{{ s.name }}</option>
              </select>
            </div>
            <div>
              <label class="text-xs text-n-slate-11 mb-1 block">Horário disponível</label>
              <select v-model="selectedSlotId" class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none">
                <option value="">Selecione um horário</option>
                <option v-for="s in slots" :key="s.id" :value="s.id">
                  {{ formatTime(s.start_time) }} – {{ formatTime(s.end_time) }} ({{ s.slots_remaining }} vagas)
                </option>
              </select>
              <p v-if="slots.length === 0" class="text-xs text-n-slate-11 mt-1">
                Nenhum horário disponível. Crie slots em "Serviços".
              </p>
            </div>
            <textarea v-model="bookNotes" placeholder="Observações (opcional)" rows="2"
                      class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand" />
          </div>
          <div class="flex justify-end gap-2 mt-4">
            <Button label="Cancelar" variant="faded" size="sm" @click="showBookForm = false" />
            <Button label="Confirmar" size="sm" @click="saveBooking" />
          </div>
        </div>
      </div>

      <!-- Calendar Grid -->
      <div v-if="isLoading" class="text-center py-16 text-n-slate-11">Carregando...</div>
      <div v-else class="rounded-xl outline outline-1 outline-n-container overflow-hidden">
        <!-- Day headers -->
        <div class="grid grid-cols-7 bg-n-surface-1">
          <div v-for="d in DAYS" :key="d" class="py-2 text-center text-xs font-medium text-n-slate-11">{{ d }}</div>
        </div>
        <!-- Day cells -->
        <div class="grid grid-cols-7">
          <div
            v-for="(day, idx) in calendarDays"
            :key="idx"
            class="min-h-[90px] border-t border-l border-n-weak p-1 relative cursor-pointer hover:bg-n-surface-1 transition-colors"
            :class="{ 'bg-n-surface-1 opacity-40': !isCurrentMonth(day), 'ring-2 ring-inset ring-n-brand': isToday(day) }"
            @click="openBooking(day)"
          >
            <span class="text-xs font-medium" :class="isToday(day) ? 'text-n-brand' : 'text-n-slate-11'">
              {{ day.getDate() }}
            </span>
            <div class="mt-1 space-y-0.5">
              <div
                v-for="apt in (appointmentsByDate[dayKey(day)] || [])"
                :key="apt.id"
                class="text-white text-[10px] rounded px-1 py-0.5 truncate flex items-center justify-between"
                :style="{ background: apt.nexus_service?.color || '#A9602D' }"
                @click.stop
              >
                <span>{{ formatTime(apt.nexus_time_slot?.start_time) }} {{ apt.nexus_service?.name }}</span>
                <button class="ml-1 opacity-70 hover:opacity-100" @click="cancelAppointment(apt.id)">✕</button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Legend -->
      <div class="mt-4 flex gap-4 flex-wrap">
        <div v-for="(color, status) in STATUS_COLORS" :key="status" class="flex items-center gap-1.5 text-xs text-n-slate-11">
          <span class="w-3 h-3 rounded-sm flex-shrink-0" :style="{ background: color }" />
          {{ STATUS_LABELS[status] }}
        </div>
      </div>
    </div>
  </div>
</template>
