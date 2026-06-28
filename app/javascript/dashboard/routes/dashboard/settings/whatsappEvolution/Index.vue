<script setup>
import { ref, onMounted, onUnmounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import Button from 'dashboard/components-next/button/Button.vue';
import evolutionConnectionAPI from 'dashboard/api/evolutionConnection';

const { t } = useI18n();
const { isAdmin } = useAdmin();

const status = ref('loading'); // loading | not_connected | qr | connected | disconnected
const qrCode = ref('');
const phoneNumber = ref('');
const isCreating = ref(false);
const errorMessage = ref('');

let pollTimer = null;

const startPolling = () => {
  stopPolling();
  pollTimer = setInterval(fetchStatus, 4000);
};

const stopPolling = () => {
  if (pollTimer) {
    clearInterval(pollTimer);
    pollTimer = null;
  }
};

const fetchStatus = async () => {
  try {
    const { data } = await evolutionConnectionAPI.get();
    status.value = data.status || 'not_connected';
    qrCode.value = data.qrcode || qrCode.value;
    phoneNumber.value = data.phone_number || '';

    if (status.value === 'connected') {
      stopPolling();
    }
  } catch (error) {
    // se ainda não existe conexão, a API retorna not_connected, não erro
    status.value = 'not_connected';
  }
};

const connectWhatsApp = async () => {
  isCreating.value = true;
  errorMessage.value = '';
  try {
    const { data } = await evolutionConnectionAPI.create();
    status.value = data.status;
    qrCode.value = data.qrcode || '';
    startPolling();
  } catch (error) {
    errorMessage.value =
      error?.response?.data?.error ||
      t('EVOLUTION_WHATSAPP.CONNECT.ERROR');
  } finally {
    isCreating.value = false;
  }
};

const disconnectWhatsApp = async () => {
  try {
    await evolutionConnectionAPI.delete();
    useAlert(t('EVOLUTION_WHATSAPP.DISCONNECT.SUCCESS'));
    status.value = 'disconnected';
    qrCode.value = '';
    stopPolling();
  } catch (error) {
    useAlert(t('EVOLUTION_WHATSAPP.DISCONNECT.ERROR'));
  }
};

const reconnect = async () => {
  await connectWhatsApp();
};

onMounted(async () => {
  await fetchStatus();
  if (status.value === 'qr' || status.value === 'connecting') {
    startPolling();
  }
});

onUnmounted(() => {
  stopPolling();
});
</script>

<template>
  <div class="flex-1 overflow-auto">
    <div class="max-w-2xl mx-auto p-6">
      <h1 class="text-xl font-medium text-n-slate-12 mb-1">
        {{ t('EVOLUTION_WHATSAPP.TITLE') }}
      </h1>
      <p class="text-sm text-n-slate-11 mb-6">
        {{ t('EVOLUTION_WHATSAPP.DESCRIPTION') }}
      </p>

      <div
        v-if="!isAdmin"
        class="p-4 rounded-lg bg-n-amber-3 text-n-amber-12 text-sm"
      >
        {{ t('EVOLUTION_WHATSAPP.ADMIN_ONLY') }}
      </div>

      <template v-else>
        <div
          v-if="status === 'loading'"
          class="text-sm text-n-slate-11"
        >
          {{ t('EVOLUTION_WHATSAPP.LOADING') }}
        </div>

        <div
          v-else-if="status === 'connected'"
          class="flex flex-col items-center gap-4 p-8 rounded-xl outline outline-1 outline-n-container"
        >
          <span
            class="w-12 h-12 rounded-full bg-n-teal-3 text-n-teal-11 flex items-center justify-center text-2xl"
          >
            ✓
          </span>
          <p class="text-base font-medium text-n-slate-12">
            {{ t('EVOLUTION_WHATSAPP.CONNECTED.TITLE') }}
          </p>
          <p v-if="phoneNumber" class="text-sm text-n-slate-11">
            {{ phoneNumber }}
          </p>
          <Button
            :label="t('EVOLUTION_WHATSAPP.DISCONNECT.BUTTON')"
            color="ruby"
            variant="faded"
            size="sm"
            @click="disconnectWhatsApp"
          />
        </div>

        <div
          v-else-if="status === 'qr'"
          class="flex flex-col items-center gap-4 p-8 rounded-xl outline outline-1 outline-n-container"
        >
          <p class="text-sm text-n-slate-11 text-center max-w-sm">
            {{ t('EVOLUTION_WHATSAPP.QR.INSTRUCTIONS') }}
          </p>
          <img
            v-if="qrCode"
            :src="qrCode"
            :alt="t('EVOLUTION_WHATSAPP.QR.ALT')"
            class="w-56 h-56 rounded-md outline outline-1 outline-n-container"
          />
          <div v-else class="w-56 h-56 flex items-center justify-center text-sm text-n-slate-11">
            {{ t('EVOLUTION_WHATSAPP.QR.GENERATING') }}
          </div>
          <Button
            :label="t('EVOLUTION_WHATSAPP.QR.REFRESH')"
            variant="faded"
            size="sm"
            :is-loading="isCreating"
            @click="reconnect"
          />
        </div>

        <div
          v-else
          class="flex flex-col items-center gap-4 p-8 rounded-xl outline outline-1 outline-n-container"
        >
          <p class="text-sm text-n-slate-11 text-center max-w-sm">
            {{ t('EVOLUTION_WHATSAPP.NOT_CONNECTED.DESCRIPTION') }}
          </p>
          <Button
            :label="t('EVOLUTION_WHATSAPP.CONNECT.BUTTON')"
            size="sm"
            :is-loading="isCreating"
            @click="connectWhatsApp"
          />
          <p v-if="errorMessage" class="text-sm text-n-ruby-11">
            {{ errorMessage }}
          </p>
        </div>
      </template>
    </div>
  </div>
</template>
