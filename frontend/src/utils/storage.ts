/**
 * 安全的 localStorage 封装
 * 处理 localStorage 不可用的情况（如隐私模式、禁用存储等）
 */

type StorageValue = string | number | boolean | object | null;

interface SafeStorage {
  getItem: (key: string) => string | null;
  setItem: (key: string, value: StorageValue) => boolean;
  removeItem: (key: string) => boolean;
  clear: () => boolean;
  getJSON: <T>(key: string) => T | null;
  setJSON: <T>(key: string, value: T) => boolean;
}

// 检查 localStorage 是否可用
function isLocalStorageAvailable(): boolean {
  try {
    const testKey = '__storage_test__';
    localStorage.setItem(testKey, testKey);
    localStorage.removeItem(testKey);
    return true;
  } catch {
    return false;
  }
}

const storageAvailable = isLocalStorageAvailable();

// 内存缓存（当 localStorage 不可用时使用）
const memoryCache = new Map<string, string>();

export const safeStorage: SafeStorage = {
  /**
   * 获取存储项
   */
  getItem(key: string): string | null {
    try {
      if (storageAvailable) {
        return localStorage.getItem(key);
      }
      return memoryCache.get(key) ?? null;
    } catch (e) {
      console.warn(`[SafeStorage] 无法读取 ${key}:`, e);
      return null;
    }
  },

  /**
   * 设置存储项
   */
  setItem(key: string, value: StorageValue): boolean {
    try {
      const stringValue = typeof value === 'string' ? value : JSON.stringify(value);
      if (storageAvailable) {
        localStorage.setItem(key, stringValue);
      } else {
        memoryCache.set(key, stringValue);
      }
      return true;
    } catch (e) {
      console.warn(`[SafeStorage] 无法写入 ${key}:`, e);
      return false;
    }
  },

  /**
   * 删除存储项
   */
  removeItem(key: string): boolean {
    try {
      if (storageAvailable) {
        localStorage.removeItem(key);
      } else {
        memoryCache.delete(key);
      }
      return true;
    } catch (e) {
      console.warn(`[SafeStorage] 无法删除 ${key}:`, e);
      return false;
    }
  },

  /**
   * 清除所有存储
   */
  clear(): boolean {
    try {
      if (storageAvailable) {
        localStorage.clear();
      } else {
        memoryCache.clear();
      }
      return true;
    } catch (e) {
      console.warn('[SafeStorage] 无法清除存储:', e);
      return false;
    }
  },

  /**
   * 获取 JSON 对象
   */
  getJSON<T>(key: string): T | null {
    try {
      const value = this.getItem(key);
      if (value === null) return null;
      return JSON.parse(value) as T;
    } catch (e) {
      console.warn(`[SafeStorage] 无法解析 JSON ${key}:`, e);
      return null;
    }
  },

  /**
   * 设置 JSON 对象
   */
  setJSON<T>(key: string, value: T): boolean {
    try {
      return this.setItem(key, JSON.stringify(value));
    } catch (e) {
      console.warn(`[SafeStorage] 无法存储 JSON ${key}:`, e);
      return false;
    }
  },
};

/**
 * 检查存储是否可用
 */
export function isStorageAvailable(): boolean {
  return storageAvailable;
}
