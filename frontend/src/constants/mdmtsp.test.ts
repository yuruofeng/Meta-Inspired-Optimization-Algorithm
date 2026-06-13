/**
 * MDMTSP常量测试
 */

import { describe, it, expect } from 'vitest';
import { MDMTSP_FUNCTIONS, getMDMTSPById } from './mdmtsp';

describe('MDMTSP Functions', () => {
  it('should have 4 problem configurations', () => {
    expect(MDMTSP_FUNCTIONS).toHaveLength(4);
  });

  it('should have correct problem IDs', () => {
    const ids = MDMTSP_FUNCTIONS.map(f => f.id);
    expect(ids).toContain('MDMTSP-S');
    expect(ids).toContain('MDMTSP-M');
    expect(ids).toContain('MDMTSP-L');
    expect(ids).toContain('MDMTSP-XL');
  });

  it('should have correct problem types', () => {
    MDMTSP_FUNCTIONS.forEach(f => {
      expect(f.type).toBe('application');
      expect(f.subtype).toBe('MDMTSP');
    });
  });

  it('should have correct dimensions', () => {
    const small = MDMTSP_FUNCTIONS.find(f => f.id === 'MDMTSP-S');
    expect(small?.dimension).toBe(10);

    const medium = MDMTSP_FUNCTIONS.find(f => f.id === 'MDMTSP-M');
    expect(medium?.dimension).toBe(15);

    const large = MDMTSP_FUNCTIONS.find(f => f.id === 'MDMTSP-L');
    expect(large?.dimension).toBe(25);

    const xlarge = MDMTSP_FUNCTIONS.find(f => f.id === 'MDMTSP-XL');
    expect(xlarge?.dimension).toBe(50);
  });

  it('should have correct travelers configuration', () => {
    const small = MDMTSP_FUNCTIONS.find(f => f.id === 'MDMTSP-S');
    expect(small?.numDepots).toBe(2);
    expect(small?.travelersPerDepot).toEqual([1, 1]);
    expect(small?.totalTravelers).toBe(2);

    const medium = MDMTSP_FUNCTIONS.find(f => f.id === 'MDMTSP-M');
    expect(medium?.totalTravelers).toBe(4);

    const large = MDMTSP_FUNCTIONS.find(f => f.id === 'MDMTSP-L');
    expect(large?.numDepots).toBe(3);
    expect(large?.totalTravelers).toBe(6);
  });

  it('should have correct bounds', () => {
    MDMTSP_FUNCTIONS.forEach(f => {
      expect(f.lowerBound).toBeLessThan(f.upperBound);
      expect(f.numCities).toBe(f.dimension);
    });
  });

  it('should get problem by ID', () => {
    const problem = getMDMTSPById('MDMTSP-M');
    expect(problem).toBeDefined();
    expect(problem?.id).toBe('MDMTSP-M');
    expect(problem?.name).toBe('中规模');
  });

  it('should return undefined for unknown ID', () => {
    const problem = getMDMTSPById('UNKNOWN');
    expect(problem).toBeUndefined();
  });

  it('should have valid descriptions', () => {
    MDMTSP_FUNCTIONS.forEach(f => {
      expect(f.description).toBeDefined();
      expect(f.description!.length).toBeGreaterThan(0);
    });
  });
});
