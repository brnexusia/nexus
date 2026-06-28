/* global axios */
import ApiClient from './ApiClient';

class EvolutionConnection extends ApiClient {
  constructor() {
    super('evolution_connection', { accountScoped: true });
  }

  get() {
    return axios.get(this.url);
  }

  create() {
    return axios.post(this.url);
  }

  delete() {
    return axios.delete(this.url);
  }
}

export default new EvolutionConnection();
