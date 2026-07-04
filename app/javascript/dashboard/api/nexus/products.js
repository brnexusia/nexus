/* global axios */
import ApiClient from '../ApiClient';

class NexusProductsAPI extends ApiClient {
  constructor() {
    super('nexus/products', { accountScoped: true });
  }

  getAll() {
    return axios.get(this.url);
  }

  create(product) {
    return axios.post(this.url, { product });
  }

  update(id, product) {
    return axios.patch(`${this.url}/${id}`, { product });
  }

  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }

  // Variantes
  getVariants(productId) {
    return axios.get(`${this.url}/${productId}/variants`);
  }

  createVariant(productId, variant) {
    return axios.post(`${this.url}/${productId}/variants`, { variant });
  }

  updateVariant(productId, variantId, variant) {
    return axios.patch(`${this.url}/${productId}/variants/${variantId}`, { variant });
  }

  deleteVariant(productId, variantId) {
    return axios.delete(`${this.url}/${productId}/variants/${variantId}`);
  }
}

export default new NexusProductsAPI();
