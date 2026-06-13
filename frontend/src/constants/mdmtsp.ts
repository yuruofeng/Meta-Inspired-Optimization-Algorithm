/**
 * MDMTSP应用问题常量定义
 */

import type { MDMTSPFunction } from '../types';

export const MDMTSP_FUNCTIONS: MDMTSPFunction[] = [
  {
    id: 'MDMTSP-S',
    name: '小规模',
    type: 'application',
    subtype: 'MDMTSP',
    dimension: 10,
    lowerBound: 0,
    upperBound: 2,
    numCities: 10,
    numDepots: 2,
    travelersPerDepot: [1, 1],
    totalTravelers: 2,
    areaSize: 100,
    description: '小规模多仓库多旅行商问题，10城市2仓库',
  },
  {
    id: 'MDMTSP-M',
    name: '中规模',
    type: 'application',
    subtype: 'MDMTSP',
    dimension: 15,
    lowerBound: 0,
    upperBound: 4,
    numCities: 15,
    numDepots: 2,
    travelersPerDepot: [2, 2],
    totalTravelers: 4,
    areaSize: 200,
    description: '中规模多仓库多旅行商问题，15城市2仓库',
  },
  {
    id: 'MDMTSP-L',
    name: '大规模',
    type: 'application',
    subtype: 'MDMTSP',
    dimension: 25,
    lowerBound: 0,
    upperBound: 6,
    numCities: 25,
    numDepots: 3,
    travelersPerDepot: [2, 2, 2],
    totalTravelers: 6,
    areaSize: 300,
    description: '大规模多仓库多旅行商问题，25城市3仓库',
  },
  {
    id: 'MDMTSP-XL',
    name: '超大规模',
    type: 'application',
    subtype: 'MDMTSP',
    dimension: 50,
    lowerBound: 0,
    upperBound: 12,
    numCities: 50,
    numDepots: 4,
    travelersPerDepot: [3, 3, 3, 3],
    totalTravelers: 12,
    areaSize: 500,
    description: '超大规模多仓库多旅行商问题，50城市4仓库',
  },
];

export function getMDMTSPById(id: string): MDMTSPFunction | undefined {
  return MDMTSP_FUNCTIONS.find(f => f.id === id);
}
