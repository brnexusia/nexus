<script setup>
import { ref, onMounted } from 'vue';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import ordersAPI from 'dashboard/api/nexus/orders';
import productsAPI from 'dashboard/api/nexus/products';

const orders = ref([]);
const products = ref([]);
const isLoading = ref(false);
const showForm = ref(false);
const cartItems = ref([]);
const newOrderContact = ref('');
const selectedProductId = ref('');
const selectedQty = ref(1);

const STATUS_LABELS = { pending: 'Pendente', confirmed: 'Confirmado', cancelled: 'Cancelado', completed: 'Concluído' };
const STATUS_COLORS = { pending: 'bg-yellow-50 text-yellow-700', confirmed: 'bg-blue-50 text-blue-700', cancelled: 'bg-red-50 text-red-600', completed: 'bg-green-50 text-green-700' };

const fetchAll = async () => {
  isLoading.value = true;
  try {
    const [ordersRes, productsRes] = await Promise.all([ordersAPI.getAll(), productsAPI.getAll()]);
    orders.value = ordersRes.data;
    products.value = productsRes.data.filter(p => p.status === 'active');
  } catch {
    useAlert('Erro ao carregar pedidos.');
  } finally {
    isLoading.value = false;
  }
};

const addToCart = () => {
  const product = products.value.find(p => p.id == selectedProductId.value);
  if (!product) return;
  const existing = cartItems.value.find(i => i.product_id == product.id);
  if (existing) {
    existing.quantity += Number(selectedQty.value);
  } else {
    cartItems.value.push({ product_id: product.id, quantity: Number(selectedQty.value), unit_price: Number(product.price), name: product.name });
  }
  selectedProductId.value = '';
  selectedQty.value = 1;
};

const cartTotal = () => cartItems.value.reduce((sum, i) => sum + i.unit_price * i.quantity, 0);

const saveOrder = async () => {
  if (cartItems.value.length === 0) return useAlert('Adicione pelo menos 1 produto.');
  try {
    await ordersAPI.create({ items: cartItems.value });
    useAlert('Pedido criado com sucesso!');
    showForm.value = false;
    cartItems.value = [];
    fetchAll();
  } catch (e) {
    useAlert(e.response?.data?.error || 'Erro ao criar pedido.');
  }
};

const updateStatus = async (order, status) => {
  try {
    await ordersAPI.updateStatus(order.id, status);
    useAlert('Status atualizado.');
    fetchAll();
  } catch {
    useAlert('Erro ao atualizar status.');
  }
};

onMounted(fetchAll);
</script>

<template>
  <div class="flex-1 overflow-auto p-6">
    <div class="max-w-5xl mx-auto">
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-xl font-medium text-n-slate-12">Pedidos</h1>
        <Button label="Novo Pedido" size="sm" @click="showForm = true" />
      </div>

      <!-- New Order Modal -->
      <div v-if="showForm" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
        <div class="bg-n-background rounded-xl p-6 w-full max-w-2xl shadow-xl max-h-[80vh] overflow-y-auto">
          <h2 class="text-lg font-medium mb-4">Novo Pedido</h2>
          <div class="flex gap-2 mb-4">
            <select v-model="selectedProductId" class="flex-1 rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none">
              <option value="">Selecione um produto</option>
              <option v-for="p in products" :key="p.id" :value="p.id">{{ p.name }} — R$ {{ Number(p.price).toFixed(2) }}</option>
            </select>
            <input v-model.number="selectedQty" type="number" min="1" class="w-20 rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none" />
            <Button label="Adicionar" size="sm" @click="addToCart" />
          </div>
          <div v-if="cartItems.length > 0" class="rounded-lg outline outline-1 outline-n-container overflow-hidden mb-4">
            <table class="w-full text-sm">
              <thead class="bg-n-surface-1 text-n-slate-11 text-left">
                <tr><th class="px-3 py-2">Produto</th><th class="px-3 py-2">Qtd</th><th class="px-3 py-2">Preço</th><th class="px-3 py-2">Total</th><th></th></tr>
              </thead>
              <tbody>
                <tr v-for="(item, idx) in cartItems" :key="idx" class="border-t border-n-weak">
                  <td class="px-3 py-2">{{ item.name }}</td>
                  <td class="px-3 py-2">{{ item.quantity }}</td>
                  <td class="px-3 py-2">R$ {{ item.unit_price.toFixed(2) }}</td>
                  <td class="px-3 py-2 font-medium">R$ {{ (item.unit_price * item.quantity).toFixed(2) }}</td>
                  <td class="px-3 py-2"><button class="text-red-500 text-xs" @click="cartItems.splice(idx,1)">Remover</button></td>
                </tr>
                <tr class="bg-n-surface-1 font-medium">
                  <td colspan="3" class="px-3 py-2 text-right">Total:</td>
                  <td class="px-3 py-2">R$ {{ cartTotal().toFixed(2) }}</td>
                  <td></td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="flex justify-end gap-2">
            <Button label="Cancelar" variant="faded" size="sm" @click="showForm=false; cartItems=[]" />
            <Button label="Criar Pedido" size="sm" @click="saveOrder" />
          </div>
        </div>
      </div>

      <!-- Orders Table -->
      <div v-if="isLoading" class="text-center py-12 text-n-slate-11">Carregando...</div>
      <div v-else-if="orders.length === 0" class="text-center py-12 text-n-slate-11">Nenhum pedido ainda.</div>
      <div v-else class="rounded-xl outline outline-1 outline-n-container overflow-hidden">
        <table class="w-full text-sm">
          <thead class="bg-n-surface-1 text-n-slate-11 text-left">
            <tr><th class="px-4 py-3">#</th><th class="px-4 py-3">Contato</th><th class="px-4 py-3">Total</th><th class="px-4 py-3">Status</th><th class="px-4 py-3">Data</th><th class="px-4 py-3"></th></tr>
          </thead>
          <tbody>
            <tr v-for="o in orders" :key="o.id" class="border-t border-n-weak hover:bg-n-surface-1">
              <td class="px-4 py-3 text-n-slate-11">#{{ o.id }}</td>
              <td class="px-4 py-3">{{ o.contact?.name || '—' }}</td>
              <td class="px-4 py-3 font-medium">R$ {{ Number(o.total).toFixed(2) }}</td>
              <td class="px-4 py-3">
                <span :class="STATUS_COLORS[o.status]" class="rounded-full px-2 py-0.5 text-xs font-medium">{{ STATUS_LABELS[o.status] }}</span>
              </td>
              <td class="px-4 py-3 text-n-slate-11 text-xs">{{ new Date(o.created_at).toLocaleDateString('pt-BR') }}</td>
              <td class="px-4 py-3">
                <select class="text-xs rounded border border-n-weak bg-transparent px-2 py-1" :value="o.status" @change="updateStatus(o, $event.target.value)">
                  <option value="pending">Pendente</option>
                  <option value="confirmed">Confirmar</option>
                  <option value="completed">Concluir</option>
                  <option value="cancelled">Cancelar</option>
                </select>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
