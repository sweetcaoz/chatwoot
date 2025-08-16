import ApiClient from './ApiClient';

class KanbanAPI extends ApiClient {
  constructor() {
    super('kanban', { accountScoped: true });
  }

  // Stages API
  getStages(boardKey = 'sales') {
    return this.axios.get(`${this.url}/stages`, { params: { board_key: boardKey } });
  }

  getStage(id) {
    return this.axios.get(`${this.url}/stages/${id}`);
  }

  createStage(stageData) {
    return this.axios.post(`${this.url}/stages`, { stage: stageData });
  }

  updateStage(id, stageData) {
    return this.axios.patch(`${this.url}/stages/${id}`, { stage: stageData });
  }

  deleteStage(id) {
    return this.axios.delete(`${this.url}/stages/${id}`);
  }

  reorderStages(stageIds) {
    return this.axios.post(`${this.url}/stages/reorder`, { stage_ids: stageIds });
  }

  // Board API
  getBoard(boardKey = 'sales') {
    return this.axios.get(`${this.url}/board`, { params: { board_key: boardKey } });
  }

  moveConversation(conversationId, stageKey, positionParams) {
    return this.axios.post(`${this.url}/board/move`, {
      conversation_id: conversationId,
      stage_key: stageKey,
      position_params: positionParams,
    });
  }
}

export default new KanbanAPI();