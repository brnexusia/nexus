<script setup>
import { ref, onMounted } from 'vue';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import productsAPI from 'dashboard/api/nexus/products';

const products = ref([]);
const isLoading = ref(false);
const showForm = ref(false);
const editingProduct = ref(null);
const form = ref({ name: '', description: '', price: 0, stock_quantity: 0, sku: '', image_url: '' });

const fetchProducts = async () => {
  isLoading.value = true;
  try { const { data } = await productsAPI.getAll(); products.value = data; }
  catch { useAlert('Erro ao carregar produtos.'); }
  finally { isLoading.value = false; }
};

const openNew = () => {
  editingProduct.value = null;
  form.value = { name: '', description: '', price: 0, stock_quantity: 0, sku: '', image_url: '' };
  showForm.value = true;
};

const openEdit = (p) => { editingProduct.value = p; form.value = { ...p }; showForm.value = true; };

const save = async () => {
  if (!form.value.name) return useAlert('Nome é obrigatório.');
  try {
    if (editingProduct.value) { await productsAPI.update(editingProduct.value.id, form.value); useAlert('Produto atualizado.'); }
    else { await productsAPI.create(form.value); useAlert('Produto criado.'); }
    showForm.value = false; fetchProducts();
  } catch (e) { useAlert(e.response?.data?.error || 'Erro ao salvar produto.'); }
};

const archive = async (p) => {
  try { await productsAPI.update(p.id, { status: 'archived' }); useAlert('Arquivado.'); fetchProducts(); }
  catch { useAlert('Erro.'); }
};

const restore = async (p) => {
  try { await productsAPI.update(p.id, { status: 'active' }); useAlert('Restaurado.'); fetchProducts(); }
  catch { useAlert('Erro.'); }
};

const remove = async (p) => {
  if (!confirm(`Excluir "${p.name}"?`)) return;
  try { await productsAPI.delete(p.id); useAlert('Excluído.'); fetchProducts(); }
  catch (e) { useAlert(e.response?.data?.error || 'Não foi possível excluir. Arquive-o.'); }
};

const activeProducts = () => products.value.filter(p => p.status === 'active');
const archivedProducts = () => products.value.filter(p => p.status === 'archived');

onMounted(fetchProducts);
</script>

<template>
  <div class="flex-1 overflow-auto p-6">
    <div class="max-w-5xl mx-auto">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-xl font-medium text-n-slate-12">Catálogo de Produtos</h1>
          <p class="text-sm text-n-slate-11 mt-0.5">Gerencie produtos e controle o estoque.</p>
        </div>
        <Button label="+ Novo Produto" size="sm" @click="openNew" />
      </div>

      <!-- Form Modal -->
      <div v-if="showForm" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
        <div class="bg-n-background rounded-xl p-6 w-full max-w-lg shadow-xl max-h-[90vh] overflow-y-auto">
          <h2 class="text-lg font-medium mb-4">{{ editingProduct ? 'Editar Produto' : 'Novo Produto' }}</h2>

          <!-- Image preview -->
          <div v-if="form.image_url" class="mb-4">
            <img :src="form.image_url" alt="preview" class="w-full max-h-40 object-contain rounded-lg border border-n-weak" @error="form.image_url = ''" />
          </div>

          <div class="space-y-3">
            <input v-model="form.name" placeholder="Nome do produto *"
                   class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand" />
            <textarea v-model="form.description" placeholder="Descrição do produto" rows="2"
                      class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand" />
            <div>
              <label class="text-xs text-n-slate-11 block mb-1">URL da imagem (cole o link da foto)</label>
              <input v-model="form.image_url" placeholder="https://exemplo.com/foto.jpg"
                     class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand" />
            </div>
            <div class="grid grid-cols-3 gap-3">
              <div>
                <label class="text-xs text-n-slate-11 block mb-1">Preço (R$)</label>
                <input v-model.number="form.price" type="number" min="0" step="0.01"
                       class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand" />
              </div>
              <div>
                <label class="text-xs text-n-slate-11 block mb-1">Estoque</label>
                <input v-model.number="form.stock_quantity" type="number" min="0"
                       class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand" />
              </div>
              <div>
                <label class="text-xs text-n-slate-11 block mb-1">SKU</label>
                <input v-model="form.sku" placeholder="Ex: PROD-001"
                       class="w-full rounded-lg border border-n-weak bg-transparent px-3 py-2 text-sm text-n-slate-12 outline-none focus:ring-2 focus:ring-n-brand" />
              </div>
            </div>
          </div>

          <div class="flex justify-end gap-2 mt-4">
            <Button label="Cancelar" variant="faded" size="sm" @click="showForm = false" />
            <Button label="Salvar Produto" size="sm" @click="save" />
          </div>
        </div>
      </div>

      <!-- Loading -->
      <div v-if="isLoading" class="text-center py-12 text-n-slate-11">Carregando...</div>

      <!-- Active Products -->
      <div v-else-if="products.length === 0" class="text-center py-16 text-n-slate-11">
        <p class="text-4xl mb-3">📦</p>
        <p class="font-medium">Nenhum produto cadastrado ainda.</p>
      </div>

      <template v-else>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
          <div v-for="p in activeProducts()" :key="p.id"
               class="rounded-xl outline outline-1 outline-n-container overflow-hidden flex flex-col">
            <!-- Image -->
            <div class="h-36 bg-n-surface-1 flex items-center justify-center overflow-hidden">
              <img v-if="p.image_url" :src="p.image_url" :alt="p.name" class="w-full h-full object-cover" />
              <span v-else class="text-4xl opacity-20">📦</span>
            </div>
            <!-- Info -->
            <div class="p-4 flex-1 flex flex-col">
              <p class="font-medium text-n-slate-12 truncate">{{ p.name }}</p>
              <p v-if="p.description" class="text-xs text-n-slate-11 mt-0.5 line-clamp-2">{{ p.description }}</p>
              <div class="flex items-center justify-between mt-3">
                <span class="text-lg font-bold text-n-brand">R$ {{ Number(p.price).toFixed(2) }}</span>
                <span :class="p.stock_quantity > 0 ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-600'"
                      class="text-xs rounded-full px-2 py-0.5 font-medium">
                  {{ p.stock_quantity > 0 ? `${p.stock_quantity} em estoque` : 'Sem estoque' }}
                </span>
              </div>
              <p v-if="p.sku" class="text-xs text-n-slate-11 mt-1">SKU: {{ p.sku }}</p>
              <div class="flex gap-2 mt-3 pt-3 border-t border-n-weak">
                <Button label="Editar" variant="faded" size="xs" class="flex-1" @click="openEdit(p)" />
                <Button label="Arquivar" variant="faded" size="xs" @click="archive(p)" />
                <Button label="Excluir" color="ruby" variant="faded" size="xs" @click="remove(p)" />
              </div>
            </div>
          </div>
        </div>

        <!-- Archived -->
        <div v-if="archivedProducts().length > 0">
          <p class="text-sm font-medium text-n-slate-11 mb-3">Arquivados ({{ archivedProducts().length }})</p>
          <div class="rounded-xl outline outline-1 outline-n-container overflow-hidden">
            <div v-for="p in archivedProducts()" :key="p.id"
                 class="flex items-center gap-3 px-4 py-2.5 border-b border-n-weak last:border-0 opacity-60">
              <div class="w-8 h-8 bg-n-surface-1 rounded flex items-center justify-center overflow-hidden flex-shrink-0">
                <img v-if="p.image_url" :src="p.image_url" :alt="p.name" class="w-full h-full object-cover" />
                <span v-else class="text-xs">📦</span>
              </div>
              <span class="flex-1 text-sm text-n-slate-12">{{ p.name }}</span>
              <span class="text-sm text-n-slate-11">R$ {{ Number(p.price).toFixed(2) }}</span>
              <Button label="Restaurar" variant="faded" size="xs" @click="restore(p)" />
              <Button label="Excluir" color="ruby" variant="faded" size="xs" @click="remove(p)" />
            </div>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>
