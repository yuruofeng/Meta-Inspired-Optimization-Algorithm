import { describe, it, expect } from 'vitest'
import {
  BENCHMARK_FUNCTIONS,
  BENCHMARK_TYPE_NAMES,
  getBenchmarkById,
  getBenchmarksByType,
} from './benchmarks'
import type { BenchmarkFunction } from '../types'

describe('benchmarks', () => {
  describe('BENCHMARK_FUNCTIONS', () => {
    it('should contain 23 benchmark functions', () => {
      expect(BENCHMARK_FUNCTIONS).toHaveLength(23)
    })

    it('should have correct function IDs from F1 to F23', () => {
      const ids = BENCHMARK_FUNCTIONS.map((f: BenchmarkFunction) => f.id)
      expect(ids[0]).toBe('F1')
      expect(ids[22]).toBe('F23')
    })

    it('should have all required properties for each function', () => {
      BENCHMARK_FUNCTIONS.forEach((func: BenchmarkFunction) => {
        expect(func).toHaveProperty('id')
        expect(func).toHaveProperty('name')
        expect(func).toHaveProperty('type')
        expect(func).toHaveProperty('dimension')
        expect(func).toHaveProperty('lowerBound')
        expect(func).toHaveProperty('upperBound')
        expect(func).toHaveProperty('optimalValue')
      })
    })
  })

  describe('BENCHMARK_TYPE_NAMES', () => {
    it('should have Chinese names for all types', () => {
      expect(BENCHMARK_TYPE_NAMES['Unimodal']).toBe('单峰函数')
      expect(BENCHMARK_TYPE_NAMES['Multimodal']).toBe('多峰函数')
      expect(BENCHMARK_TYPE_NAMES['Fixed-dimension Multimodal']).toBe('固定维度多峰函数')
    })
  })

  describe('getBenchmarkById', () => {
    it('should return correct function for valid ID', () => {
      const f1 = getBenchmarkById('F1')
      expect(f1).toBeDefined()
      expect(f1?.name).toBe('Sphere')
      expect(f1?.type).toBe('Unimodal')
    })

    it('should return undefined for invalid ID', () => {
      const invalid = getBenchmarkById('F99')
      expect(invalid).toBeUndefined()
    })
  })

  describe('getBenchmarksByType', () => {
    it('should return 7 Unimodal functions (F1-F7)', () => {
      const unimodal = getBenchmarksByType('Unimodal')
      expect(unimodal).toHaveLength(7)
    })

    it('should return 6 Multimodal functions (F8-F13)', () => {
      const multimodal = getBenchmarksByType('Multimodal')
      expect(multimodal).toHaveLength(6)
    })

    it('should return 10 Fixed-dimension Multimodal functions (F14-F23)', () => {
      const fixed = getBenchmarksByType('Fixed-dimension Multimodal')
      expect(fixed).toHaveLength(10)
    })
  })
})
