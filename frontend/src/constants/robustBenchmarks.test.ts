import { describe, it, expect } from 'vitest'
import {
  ROBUST_BENCHMARK_FUNCTIONS,
  ROBUST_TYPE_NAMES,
  ROBUST_TYPE_DESCRIPTIONS,
  getRobustBenchmarkById,
  getRobustBenchmarksByType,
  getRobustBenchmarkIds,
} from './robustBenchmarks'
import type { RobustBenchmarkType, RobustBenchmarkFunction } from '../types'

describe('robustBenchmarks', () => {
  describe('ROBUST_BENCHMARK_FUNCTIONS', () => {
    it('should contain 8 robust benchmark functions', () => {
      expect(ROBUST_BENCHMARK_FUNCTIONS).toHaveLength(8)
    })

    it('should have correct function IDs from R1 to R8', () => {
      const ids = ROBUST_BENCHMARK_FUNCTIONS.map((f: RobustBenchmarkFunction) => f.id)
      expect(ids).toEqual(['R1', 'R2', 'R3', 'R4', 'R5', 'R6', 'R7', 'R8'])
    })

    it('should have all required properties for each function', () => {
      ROBUST_BENCHMARK_FUNCTIONS.forEach((func: RobustBenchmarkFunction) => {
        expect(func).toHaveProperty('id')
        expect(func).toHaveProperty('name')
        expect(func).toHaveProperty('type')
        expect(func).toHaveProperty('dimension')
        expect(func).toHaveProperty('lowerBound')
        expect(func).toHaveProperty('upperBound')
        expect(func).toHaveProperty('delta')
        expect(func).toHaveProperty('description')
      })
    })

    it('should have dimension 2 for all functions', () => {
      ROBUST_BENCHMARK_FUNCTIONS.forEach((func: RobustBenchmarkFunction) => {
        expect(func.dimension).toBe(2)
      })
    })
  })

  describe('ROBUST_TYPE_NAMES', () => {
    it('should have Chinese names for all types', () => {
      expect(ROBUST_TYPE_NAMES['Biased']).toBe('偏置函数')
      expect(ROBUST_TYPE_NAMES['Deceptive']).toBe('欺骗函数')
      expect(ROBUST_TYPE_NAMES['Multimodal']).toBe('多模态函数')
      expect(ROBUST_TYPE_NAMES['Flat']).toBe('平坦函数')
    })

    it('should have 4 type names', () => {
      expect(Object.keys(ROBUST_TYPE_NAMES)).toHaveLength(4)
    })
  })

  describe('ROBUST_TYPE_DESCRIPTIONS', () => {
    it('should have descriptions for all types', () => {
      expect(ROBUST_TYPE_DESCRIPTIONS['Biased']).toContain('偏置')
      expect(ROBUST_TYPE_DESCRIPTIONS['Deceptive']).toContain('欺骗')
      expect(ROBUST_TYPE_DESCRIPTIONS['Multimodal']).toContain('局部最优')
      expect(ROBUST_TYPE_DESCRIPTIONS['Flat']).toContain('平坦')
    })
  })

  describe('getRobustBenchmarkById', () => {
    it('should return correct function for valid ID', () => {
      const r1 = getRobustBenchmarkById('R1')
      expect(r1).toBeDefined()
      expect(r1?.name).toBe('TP_Biased1')
      expect(r1?.type).toBe('Biased')
    })

    it('should return undefined for invalid ID', () => {
      const invalid = getRobustBenchmarkById('R99')
      expect(invalid).toBeUndefined()
    })

    it('should return correct function for all valid IDs', () => {
      for (let i = 1; i <= 8; i++) {
        const func = getRobustBenchmarkById(`R${i}`)
        expect(func).toBeDefined()
        expect(func?.id).toBe(`R${i}`)
      }
    })
  })

  describe('getRobustBenchmarksByType', () => {
    it('should return 2 Biased functions', () => {
      const biased = getRobustBenchmarksByType('Biased')
      expect(biased).toHaveLength(2)
      expect(biased.every((f: RobustBenchmarkFunction) => f.type === 'Biased')).toBe(true)
    })

    it('should return 3 Deceptive functions', () => {
      const deceptive = getRobustBenchmarksByType('Deceptive')
      expect(deceptive).toHaveLength(3)
      expect(deceptive.every((f: RobustBenchmarkFunction) => f.type === 'Deceptive')).toBe(true)
    })

    it('should return 2 Multimodal functions', () => {
      const multimodal = getRobustBenchmarksByType('Multimodal')
      expect(multimodal).toHaveLength(2)
      expect(multimodal.every((f: RobustBenchmarkFunction) => f.type === 'Multimodal')).toBe(true)
    })

    it('should return 1 Flat function', () => {
      const flat = getRobustBenchmarksByType('Flat')
      expect(flat).toHaveLength(1)
      expect(flat[0].id).toBe('R8')
    })
  })

  describe('getRobustBenchmarkIds', () => {
    it('should return array of 8 IDs', () => {
      const ids = getRobustBenchmarkIds()
      expect(ids).toHaveLength(8)
      expect(ids).toEqual(['R1', 'R2', 'R3', 'R4', 'R5', 'R6', 'R7', 'R8'])
    })
  })

  describe('function bounds validation', () => {
    it('should have correct bounds for Biased functions (R1, R2)', () => {
      const r1 = getRobustBenchmarkById('R1')
      const r2 = getRobustBenchmarkById('R2')
      
      expect(r1?.lowerBound).toBe(-100)
      expect(r1?.upperBound).toBe(100)
      expect(r2?.lowerBound).toBe(-100)
      expect(r2?.upperBound).toBe(100)
    })

    it('should have correct bounds for Deceptive functions (R3-R5)', () => {
      const r3 = getRobustBenchmarkById('R3')
      const r4 = getRobustBenchmarkById('R4')
      const r5 = getRobustBenchmarkById('R5')
      
      expect(r3?.lowerBound).toBe(0)
      expect(r3?.upperBound).toBe(1)
      expect(r4?.lowerBound).toBe(0)
      expect(r4?.upperBound).toBe(1)
      expect(r5?.lowerBound).toBe(0)
      expect(r5?.upperBound).toBe(2)
    })

    it('should have correct bounds for Multimodal functions (R6, R7)', () => {
      const r6 = getRobustBenchmarkById('R6')
      const r7 = getRobustBenchmarkById('R7')
      
      expect(r6?.lowerBound).toBe(0)
      expect(r6?.upperBound).toBe(1)
      expect(r7?.lowerBound).toBe(0)
      expect(r7?.upperBound).toBe(1)
    })

    it('should have correct bounds for Flat function (R8)', () => {
      const r8 = getRobustBenchmarkById('R8')
      
      expect(r8?.lowerBound).toBe(0)
      expect(r8?.upperBound).toBe(1)
    })
  })

  describe('delta values validation', () => {
    it('should have delta = 1 for Biased functions', () => {
      const biased = getRobustBenchmarksByType('Biased')
      biased.forEach((f: RobustBenchmarkFunction) => {
        expect(f.delta).toBe(1)
      })
    })

    it('should have delta = 0.01 for non-Biased functions', () => {
      const types: RobustBenchmarkType[] = ['Deceptive', 'Multimodal', 'Flat']
      types.forEach((type: RobustBenchmarkType) => {
        const funcs = getRobustBenchmarksByType(type)
        funcs.forEach((f: RobustBenchmarkFunction) => {
          expect(f.delta).toBe(0.01)
        })
      })
    })
  })
})
