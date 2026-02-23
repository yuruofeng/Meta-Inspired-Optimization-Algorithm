/**
 * 算法选择状态管理
 */

import { create } from 'zustand';
import type { Algorithm, AlgorithmConfig } from '../types';
import { ALGORITHMS, DEFAULT_CONFIG } from '../constants';

interface AlgorithmState {
  // 可用算法列表
  algorithms: Algorithm[];

  // 当前选中的算法ID列表
  selectedIds: string[];

  // 当前配置
  configs: Record<string, AlgorithmConfig>;

  // Actions
  setSelectedIds: (ids: string[]) => void;
  toggleAlgorithm: (id: string) => void;
  selectAll: () => void;
  clearSelection: () => void;
  updateConfig: (id: string, config: Partial<AlgorithmConfig>) => void;
  resetConfig: (id: string) => void;

  // Getters
  getSelectedAlgorithms: () => Algorithm[];
  getConfig: (id: string) => AlgorithmConfig;
}

export const useAlgorithmStore = create<AlgorithmState>((set, get) => ({
  algorithms: ALGORITHMS,
  selectedIds: [],
  configs: {},

  setSelectedIds: (ids) => set({ selectedIds: ids }),

  toggleAlgorithm: (id) => {
    const { selectedIds } = get();
    const newIds = selectedIds.includes(id)
      ? selectedIds.filter((i) => i !== id)
      : [...selectedIds, id];
    set({ selectedIds: newIds });
  },

  selectAll: () => {
    set({ selectedIds: get().algorithms.map((a) => a.id) });
  },

  clearSelection: () => {
    set({ selectedIds: [] });
  },

  updateConfig: (id, config) => {
    const { configs } = get();
    set({
      configs: {
        ...configs,
        [id]: { ...get().getConfig(id), ...config },
      },
    });
  },

  resetConfig: (id) => {
    const { configs } = get();
    const { [id]: _, ...rest } = configs;
    set({ configs: rest });
  },

  getSelectedAlgorithms: () => {
    const { algorithms, selectedIds } = get();
    return algorithms.filter((a) => selectedIds.includes(a.id));
  },

  getConfig: (id) => {
    const { configs } = get();
    const algorithm = get().algorithms.find((a) => a.id === id);
    if (!algorithm) return DEFAULT_CONFIG;

    const savedConfig = configs[id] || {};
    const schemaDefaults: Record<string, number | boolean | string> = {};

    for (const [key, schema] of Object.entries(algorithm.paramSchema)) {
      savedConfig[key as keyof AlgorithmConfig];
      schemaDefaults[key] = schema.default;
    }

    return { ...DEFAULT_CONFIG, ...schemaDefaults, ...savedConfig };
  },
}));
