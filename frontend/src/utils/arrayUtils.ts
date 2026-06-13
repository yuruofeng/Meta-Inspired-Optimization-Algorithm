/**
 * 数组安全操作工具函数
 * 提供边界检查和空值处理
 */

/**
 * 安全获取数组最后一个元素
 * @param arr - 数组
 * @returns 最后一个元素，如果数组为空则返回 undefined
 */
export function getLastElement<T>(arr: T[] | undefined | null): T | undefined {
  if (!arr || arr.length === 0) {
    return undefined;
  }
  return arr[arr.length - 1];
}

/**
 * 安全格式化数字
 * @param value - 要格式化的值
 * @param fallback - 回退值（当值无效时）
 * @returns 格式化后的字符串或回退值
 */
export function formatNumber(
  value: number | undefined | null,
  fallback: string = '-'
): string {
  if (value === undefined || value === null || !Number.isFinite(value)) {
    return fallback;
  }
  return value.toString();
}

/**
 * 安全的科学计数法格式化
 * @param value - 要格式化的值
 * @param fractionDigits - 小数位数
 * @param fallback - 回退值
 * @returns 格式化后的字符串或回退值
 */
export function toExponentialSafe(
  value: number | undefined | null,
  fractionDigits: number = 6,
  fallback: string = '-'
): string {
  if (value === undefined || value === null || !Number.isFinite(value)) {
    return fallback;
  }
  try {
    return value.toExponential(fractionDigits);
  } catch {
    return fallback;
  }
}

/**
 * 安全的定点格式化
 * @param value - 要格式化的值
 * @param fractionDigits - 小数位数
 * @param fallback - 回退值
 * @returns 格式化后的字符串或回退值
 */
export function toFixedSafe(
  value: number | undefined | null,
  fractionDigits: number = 3,
  fallback: string = '-'
): string {
  if (value === undefined || value === null || !Number.isFinite(value)) {
    return fallback;
  }
  try {
    return value.toFixed(fractionDigits);
  } catch {
    return fallback;
  }
}

/**
 * 检查数组是否非空
 * @param arr - 数组
 * @returns 是否非空
 */
export function isNonEmptyArray<T>(arr: T[] | undefined | null): arr is T[] {
  return Array.isArray(arr) && arr.length > 0;
}
