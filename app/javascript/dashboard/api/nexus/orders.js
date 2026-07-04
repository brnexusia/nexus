/* global axios */
import ApiClient from '../ApiClient';

class NexusOrdersAPI extends ApiClient {
  constructor() {
    super('nexus/orders', { accountScoped: true });
  }

  getAll() {
    return axios.get(this.url);
  }

  get(id) {
    return axios.get(`${this.url}/${id}`);
  }

  create(order) {
    return axios.post(this.url, order);
  }

  updateStatus(id, status) {
    return axios.patch(`${this.url}/${id}`, { order: { status } });
  }

  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }
}

export default new NexusOrdersAPI();
