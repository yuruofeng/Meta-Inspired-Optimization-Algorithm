/**
 * 数字验证和格式化工具函数
 */

/**
 * 检查值是否为有效的有限数字
 */
export function isValidNumber(value: unknown): value is number {
  return typeof value === 'number' && Number.isFinite(value);
}

/**
 * 安全的科学计数法格式化
 * @param value - 要格式化的值
 * @param fractionDigits - 小数位数
 * @param fallback - 回退值
 * @returns 格式化后的字符串
 */
export function safeToExponential(
  value: unknown,
  fractionDigits: number = 6,
  fallback: string = '-'
): string {
  if (!isValidNumber(value)) {
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
 * @returns 格式化后的字符串
 */
export function safeToFixed(
  value: unknown,
  fractionDigits: number = 3,
  fallback: string = '-'
): string {
  if (!isValidNumber(value)) {
    return fallback;
  }
  try {
    return value.toFixed(fractionDigits);
  } catch {
    return fallback;
  }
}

/**
 * 将数字限制在指定范围内
 * @param value - 要限制的值
 * @param min - 最小值
 * @param max - 最大值
 * @returns 限制后的值
 */
export function clamp(value: number, min: number, max: number): number {
  if (!isValidNumber(value)) {
    return min;
  }
  return Math.min(Math.max(value, min), max);
}

/**
 * 安全解析数字
 * @param value - 要解析的值
 * @param defaultValue - 默认值
 * @returns 解析后的数字
 */
export function safeParseNumber(value: unknown, defaultValue: number = 0): number {
  if (typeof value === 'number') {
    return isValidNumber(value) ? value : defaultValue;
  }
  if (typeof value === 'string') {
    const parsed = parseFloat(value);
    return isValidNumber(parsed) ? parsed : defaultValue;
  }
  return defaultValue;
}

/**
 * 安全解析整数
 * @param value - 要解析的值
 * @param defaultValue - 默认值
 * @returns 解析后的整数
 */
export function safeParseInt(value: unknown, defaultValue: number = 0): number {
  if (typeof value === 'number') {
    return Number.isInteger(value) ? value : defaultValue;
  }
  if (typeof value === 'string') {
    const parsed = parseInt(value, 10);
    return Number.isInteger(parsed) ? parsed : defaultValue;
  }
  return defaultValue;
}
