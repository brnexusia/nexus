/* global axios */
import ApiClient from '../ApiClient';

class NexusServicesAPI extends ApiClient {
  constructor() {
    super('nexus/services', { accountScoped: true });
  }

  getAll() {
    return axios.get(this.url);
  }

  create(service) {
    return axios.post(this.url, { service });
  }

  update(id, service) {
    return axios.patch(`${this.url}/${id}`, { service });
  }

  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }

  // Slots de um serviço
  getSlots(serviceId, from, to) {
    return axios.get(`${this.url}/${serviceId}/time_slots`, { params: { from, to } });
  }

  createSlot(serviceId, slot) {
    return axios.post(`${this.url}/${serviceId}/time_slots`, { time_slot: slot });
  }

  deleteSlot(serviceId, slotId) {
    return axios.delete(`${this.url}/${serviceId}/time_slots/${slotId}`);
  }
}

class NexusAppointmentsAPI extends ApiClient {
  constructor() {
    super('nexus/appointments', { accountScoped: true });
  }

  getAll(from, to) {
    return axios.get(this.url, { params: { from, to } });
  }

  create(appointment) {
    return axios.post(this.url, { appointment });
  }

  updateStatus(id, status, notes) {
    return axios.patch(`${this.url}/${id}`, { appointment: { status, notes } });
  }

  cancel(id) {
    return axios.delete(`${this.url}/${id}`);
  }
}

export const servicesAPI = new NexusServicesAPI();
export const appointmentsAPI = new NexusAppointmentsAPI();
