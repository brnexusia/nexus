<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import productsAPI from 'dashboard/api/nexus/products';

const { t } = useI18n();
const products = ref([]);
const isLoading = ref(false);
const showForm = ref(false);
const editingProduct = ref(null);
const form = ref({ name: '', description: '', price: 0, stock_quantity: 0, sku: '' });

const fetchProducts = async () => {
  isLoading.value = true;
  try {
    const { data } = await productsAPI.getAll();
    products.value = data;
  } catch {
    useAlert('Erro ao carregar produtos.');
  } finally {
    isLoading.value = false;
  }
};

const openNew = () => {
  editingProduct.value = null;
  form.value = { name: '', description: '', price: 0, stock_quantity: 0, sku: '' };
  showForm.value = true;
};

const openEdit = (product) => {
  editingProduct.value = product;
  form.value = { ...product };
  showForm.value = true;
};

const save = async () => {
  try {
    if (editingProduct.value) {
      await productsAPI.update(editingProduct.value.id, form.value);
      useAlert('Produto atualizado.');
    } else {
      await productsAPI.create(form.value);
      useAlert('Produto criado.');
    }
    showForm.value = false;
    fetchProducts();
  } catch (e) {
    useAlert(e.response?.data?.error || 'Erro ao salvar produto.');
  }
};

const archive = async (product) => {
  try {
    await productsAPI.update(product.id, { status: 'archived' });
    useAlert('Produto arquivado.');
    fetchProducts();
  } catch {
    useAlert('Erro ao arquivar.');
  }
};

const remove = async (product) => {
  if (!confirm(`Excluir "${product.name}"?`)) return;
  try {
    await productsAPI.delete(product.id);
    useAlert('Produto excluído.');
    fetchProducts();
  } catch (e) {
    useAlert(e.response?.data?.error || 'Erro ao excluir.');
  }
};

onMounted(fetchProducts);
</script>

<template>
  <div class="flex-1 overflow-auto p-6">
    <div class="max-w-5xl mx-auto">
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-xl font-medium text-n-slate-12">Catálogo de Produtos</h1>
        <Button label="Novo Produto" size="sm" @click="openNew" />
      </div>

      <!-- Form Modal -->
      <div v-if="showForm" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
        <div class="bg-n-background rounded-xl p-6 w-full max-w-lg shadow-xl">
          <h2 class="text-lg font-medium mb-4">{{ editingProduct ? 'Editar Produto' : 'Novo Produto' }}</h2>
          <div class="space-y-3">
            <input v-model="form.name" placeholder="Nome do produto *" class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand" />
            <textarea v-model="form.description" placeholder="Descrição" rows="2" class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand" />
            <div class="grid grid-cols-3 gap-3">
              <input v-model.number="form.price" type="number" min="0" step="0.01" placeholder="Preço (R$)" class="rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand" />
              <input v-model.number="form.stock_quantity" type="number" min="0" placeholder="Estoque" class="rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand" />
              <input v-model="form.sku" placeholder="SKU" class="rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand" />
            </div>
          </div>
          <div class="flex justify-end gap-2 mt-4">
            <Button label="Cancelar" variant="faded" size="sm" @click="showForm = false" />
            <Button label="Salvar" size="sm" @click="save" />
          </div>
        </div>
      </div>

      <!-- Product Table -->
      <div v-if="isLoading" class="text-center py-12 text-n-slate-11">Carregando...</div>
      <div v-else-if="products.length === 0" class="text-center py-12 text-n-slate-11">
        Nenhum produto cadastrado ainda.
      </div>
      <div v-else class="rounded-xl outline outline-1 outline-n-container overflow-hidden">
        <table class="w-full text-sm">
          <thead class="bg-n-surface-1 text-n-slate-11 text-left">
            <tr>
              <th class="px-4 py-3">Produto</th>
              <th class="px-4 py-3">SKU</th>
              <th class="px-4 py-3">Preço</th>
              <th class="px-4 py-3">Estoque</th>
              <th class="px-4 py-3">Status</th>
              <th class="px-4 py-3"></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="p in products" :key="p.id" class="border-t border-n-weak hover:bg-n-surface-1">
              <td class="px-4 py-3 font-medium text-n-slate-12">{{ p.name }}</td>
              <td class="px-4 py-3 text-n-slate-11">{{ p.sku || '—' }}</td>
              <td class="px-4 py-3">R$ {{ Number(p.price).toFixed(2) }}</td>
              <td class="px-4 py-3">{{ p.stock_quantity }}</td>
              <td class="px-4 py-3">
                <span :class="p.status === 'active' ? 'text-green-600 bg-green-50' : 'text-n-slate-11 bg-n-surface-1'" class="rounded-full px-2 py-0.5 text-xs font-medium">
                  {{ p.status === 'active' ? 'Ativo' : 'Arquivado' }}
                </span>
              </td>
              <td class="px-4 py-3 flex gap-2 justify-end">
                <Button label="Editar" variant="faded" size="xs" @click="openEdit(p)" />
                <Button v-if="p.status === 'active'" label="Arquivar" variant="faded" size="xs" @click="archive(p)" />
                <Button label="Excluir" color="ruby" variant="faded" size="xs" @click="remove(p)" />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
