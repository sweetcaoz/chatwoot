import kanbanAPI from '../../api/kanban';
import { createAsyncMutation } from '../utils/api';

const state = {
  stages: [],
  conversations: {},
  boardKey: 'sales',
  isLoading: false,
  isMoving: false,
  error: null,
};

export const getters = {
  getStages: state => state.stages,
  getActiveStages: state => state.stages.filter(stage => stage.active),
  getConversationsByStage: state => stageKey => {
    return state.conversations[stageKey] || [];
  },
  getAllConversations: state => {
    return Object.values(state.conversations).flat();
  },
  getBoardKey: state => state.boardKey,
  isLoading: state => state.isLoading,
  isMoving: state => state.isMoving,
};

export const actions = {
  async fetchStages({ commit }, boardKey = 'sales') {
    commit('setLoading', true);
    try {
      const response = await kanbanAPI.getStages(boardKey);
      commit('setStages', response.data);
    } catch (error) {
      commit('setError', error.message);
    } finally {
      commit('setLoading', false);
    }
  },

  async fetchBoard({ commit }, boardKey = 'sales') {
    commit('setLoading', true);
    try {
      const response = await kanbanAPI.getBoard(boardKey);
      commit('setBoardKey', response.data.board_key);
      commit('setStages', response.data.stages);
      commit('setConversations', response.data.conversations);
    } catch (error) {
      commit('setError', error.message);
    } finally {
      commit('setLoading', false);
    }
  },

  async createStage({ dispatch }, stageData) {
    try {
      await kanbanAPI.createStage(stageData);
      await dispatch('fetchStages', stageData.board_key);
    } catch (error) {
      throw error;
    }
  },

  async updateStage({ dispatch }, { id, ...stageData }) {
    try {
      await kanbanAPI.updateStage(id, stageData);
      await dispatch('fetchStages', stageData.board_key);
    } catch (error) {
      throw error;
    }
  },

  async deleteStage({ dispatch, state }, id) {
    try {
      await kanbanAPI.deleteStage(id);
      await dispatch('fetchStages', state.boardKey);
    } catch (error) {
      throw error;
    }
  },

  async reorderStages({ commit }, stageIds) {
    try {
      await kanbanAPI.reorderStages(stageIds);
      commit('reorderStages', stageIds);
    } catch (error) {
      throw error;
    }
  },

  async moveConversation({ commit, dispatch, state }, { conversationId, fromStage, toStage, position }) {
    commit('setMoving', true);
    
    // Store original state for potential rollback
    const originalState = { conversationId, fromStage, toStage, position };
    
    // Optimistically update the UI for immediate feedback
    commit('moveConversationOptimistic', { conversationId, fromStage, toStage, position });
    
    try {
      const positionParams = {};
      if (position.afterId) positionParams.after_id = position.afterId;
      if (position.beforeId) positionParams.before_id = position.beforeId;
      if (position.absolutePosition) positionParams.absolute_position = position.absolutePosition;
      
      // Make API call
      const response = await kanbanAPI.moveConversation(conversationId, toStage, positionParams);
      
      // Success: Let the optimistic update stand, just force a reactivity refresh
      // This ensures Vue detects the changes and re-renders the UI
      commit('triggerReactivityUpdate');
      
    } catch (error) {
      // Revert optimistic update on error
      commit('moveConversationOptimistic', { 
        conversationId, 
        fromStage: toStage, 
        toStage: fromStage, 
        position: originalState.position 
      });
      throw error;
    } finally {
      commit('setMoving', false);
    }
  },

  // WebSocket event handlers called by ActionCable
  updateStageFromSocket({ commit }, data) {
    commit('updateStage', data);
  },

  updateConversationPositionFromSocket({ commit }, data) {
    commit('updateConversationPosition', {
      conversationId: data.conversation_id,
      stageKey: data.stage_key,
      position: data.position,
    });
  },

  updateConversationFromSocket({ commit, state }, data) {
    // Update conversation data if it exists in our current board
    if (data.custom_attributes?.kanban_stage) {
      commit('updateConversationData', data);
    }
  },

  addConversationFromSocket({ commit, state }, data) {
    // Add new conversation to appropriate stage if it has kanban data
    if (data.custom_attributes?.kanban_stage) {
      commit('addConversation', data);
    }
  },

  cleanup({ commit }) {
    // Clear any subscriptions or timers
    commit('resetState');
  },
};

export const mutations = {
  setLoading(state, isLoading) {
    state.isLoading = isLoading;
  },

  setMoving(state, isMoving) {
    state.isMoving = isMoving;
  },

  setError(state, error) {
    state.error = error;
  },

  setStages(state, stages) {
    state.stages = stages;
  },

  setBoardKey(state, boardKey) {
    state.boardKey = boardKey;
  },

  setConversations(state, conversations) {
    state.conversations = conversations;
  },

  reorderStages(state, stageIds) {
    const stagesMap = {};
    state.stages.forEach(stage => {
      stagesMap[stage.id] = stage;
    });
    
    state.stages = stageIds.map((id, index) => ({
      ...stagesMap[id],
      position: index,
    }));
  },

  moveConversationOptimistic(state, { conversationId, fromStage, toStage, position }) {
    // Remove from source stage
    if (fromStage && state.conversations[fromStage]) {
      const fromIndex = state.conversations[fromStage].findIndex(c => c.id === conversationId);
      if (fromIndex > -1) {
        const [conversation] = state.conversations[fromStage].splice(fromIndex, 1);
        
        // Add to target stage
        if (!state.conversations[toStage]) {
          state.conversations[toStage] = [];
        }
        
        // Find insertion position
        let insertIndex = 0;
        if (position.afterId) {
          const afterIndex = state.conversations[toStage].findIndex(c => c.id === position.afterId);
          insertIndex = afterIndex + 1;
        } else if (position.beforeId) {
          insertIndex = state.conversations[toStage].findIndex(c => c.id === position.beforeId);
        } else {
          insertIndex = state.conversations[toStage].length;
        }
        
        state.conversations[toStage].splice(insertIndex, 0, conversation);
      }
    }
  },

  updateConversationPosition(state, { conversationId, stageKey, position }) {
    // Find and update conversation across all stages
    Object.keys(state.conversations).forEach(key => {
      const index = state.conversations[key].findIndex(c => c.id === conversationId);
      if (index > -1) {
        if (key === stageKey) {
          // Update position in same stage
          state.conversations[key][index].kanban_position = position;
        } else {
          // Move to different stage
          const [conversation] = state.conversations[key].splice(index, 1);
          conversation.kanban_position = position;
          
          if (!state.conversations[stageKey]) {
            state.conversations[stageKey] = [];
          }
          state.conversations[stageKey].push(conversation);
        }
      }
    });
    
    // Sort by position
    if (state.conversations[stageKey]) {
      state.conversations[stageKey].sort((a, b) => {
        // Unread first
        if (a.unread_count > 0 && b.unread_count === 0) return -1;
        if (b.unread_count > 0 && a.unread_count === 0) return 1;
        // Then by position
        return a.kanban_position - b.kanban_position;
      });
    }
  },

  updateStage(state, stageData) {
    const index = state.stages.findIndex(stage => stage.id === stageData.id);
    if (index > -1) {
      state.stages.splice(index, 1, stageData);
    }
  },

  updateConversationData(state, conversationData) {
    // Find and update conversation across all stages
    Object.keys(state.conversations).forEach(stageKey => {
      const index = state.conversations[stageKey].findIndex(c => c.id === conversationData.id);
      if (index > -1) {
        state.conversations[stageKey][index] = { ...state.conversations[stageKey][index], ...conversationData };
      }
    });
  },

  addConversation(state, conversation) {
    const stageKey = conversation.custom_attributes?.kanban_stage;
    if (stageKey && !state.conversations[stageKey]) {
      state.conversations[stageKey] = [];
    }
    if (stageKey) {
      // Check if conversation already exists
      const exists = state.conversations[stageKey].some(c => c.id === conversation.id);
      if (!exists) {
        state.conversations[stageKey].push(conversation);
      }
    }
  },

  updateConversationFromMove(state, { conversation, targetStage }) {
    // After optimistic update, conversation is already in target stage
    // Find and update it there with the latest server data
    if (state.conversations[targetStage]) {
      const index = state.conversations[targetStage].findIndex(c => c.id === conversation.id);
      if (index > -1) {
        // Update with latest server data (position, custom_attributes, etc.)
        state.conversations[targetStage][index] = { 
          ...state.conversations[targetStage][index], 
          ...conversation,
          // Ensure stage consistency
          custom_attributes: {
            ...state.conversations[targetStage][index].custom_attributes,
            ...conversation.custom_attributes,
            kanban_stage: targetStage
          }
        };
      }
    }
  },

  syncStageConversations(state, { stageKey, conversations }) {
    // Replace conversations in specific stage with server-ordered data
    // This handles position corrections without full board reload
    if (state.conversations[stageKey] && conversations) {
      state.conversations[stageKey] = conversations;
    }
  },

  triggerReactivityUpdate(state) {
    // Force Vue reactivity by creating new object references
    // This ensures UI updates even when deep nested properties change
    const newConversations = {};
    Object.keys(state.conversations).forEach(stageKey => {
      newConversations[stageKey] = [...state.conversations[stageKey]];
    });
    state.conversations = newConversations;
  },

  resetState(state) {
    state.stages = [];
    state.conversations = {};
    state.isLoading = false;
    state.isMoving = false;
    state.error = null;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};