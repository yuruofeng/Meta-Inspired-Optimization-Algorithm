/**
 * API 客户端
 * 使用 Axios 封装 HTTP 请求
 */

import axios, { type AxiosInstance, type AxiosRequestConfig, AxiosError } from 'axios';
import type { ApiError } from '../types';

// API 基础配置
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000';
const API_TIMEOUT = 30000; // 30秒超时

class ApiClient {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: API_BASE_URL,
      timeout: API_TIMEOUT,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // 请求拦截器
    this.client.interceptors.request.use(
      (config) => {
        // 可添加认证token
        const token = localStorage.getItem('authToken');
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => Promise.reject(error)
    );

    // 响应拦截器
    this.client.interceptors.response.use(
      (response) => response,
      (error: AxiosError<ApiError>) => {
        // 统一错误处理
        if (error.response) {
          const { status, data } = error.response;

          switch (status) {
            case 401:
              console.error('未授权访问');
              break;
            case 404:
              console.error('资源不存在');
              break;
            case 500:
              console.error('服务器错误:', data?.message);
              break;
            default:
              console.error('请求错误:', data?.message);
          }

          // 返回格式化的错误
          return Promise.reject({
            code: data?.code || `HTTP_${status}`,
            message: data?.message || error.message,
            details: data?.details,
          } as ApiError);
        }

        // 网络错误
        return Promise.reject({
          code: 'NETWORK_ERROR',
          message: '网络连接失败，请检查网络设置',
        } as ApiError);
      }
    );
  }

  /**
   * GET 请求
   */
  async get<T>(url: string, config?: AxiosRequestConfig): Promise<T> {
    const response = await this.client.get<T>(url, config);
    return response.data;
  }

  /**
   * POST 请求
   */
  async post<T>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<T> {
    const response = await this.client.post<T>(url, data, config);
    return response.data;
  }

  /**
   * PUT 请求
   */
  async put<T>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<T> {
    const response = await this.client.put<T>(url, data, config);
    return response.data;
  }

  /**
   * DELETE 请求
   */
  async delete<T>(url: string, config?: AxiosRequestConfig): Promise<T> {
    const response = await this.client.delete<T>(url, config);
    return response.data;
  }

  /**
   * 获取基础URL
   */
  getBaseUrl(): string {
    return API_BASE_URL;
  }
}

// 导出单例实例
export const apiClient = new ApiClient();
