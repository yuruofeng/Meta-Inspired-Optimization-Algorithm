import { useEffect, useState } from 'react';

import { getAlgorithms, getBenchmarks, getRobustBenchmarks } from '../api/endpoints';
import { ALGORITHMS, BENCHMARK_FUNCTIONS } from '../constants';
import { ROBUST_BENCHMARK_FUNCTIONS } from '../constants/robustBenchmarks';
import type { Algorithm, BenchmarkFunction, RobustBenchmarkFunction } from '../types';
import { errorLogger } from '../utils/errorLogger';

interface CatalogData {
  algorithms: Algorithm[];
  benchmarks: BenchmarkFunction[];
  robustBenchmarks: RobustBenchmarkFunction[];
  isLoading: boolean;
  source: 'api' | 'fallback';
}

export function useCatalogData(): CatalogData {
  const [algorithms, setAlgorithms] = useState<Algorithm[]>(ALGORITHMS);
  const [benchmarks, setBenchmarks] = useState<BenchmarkFunction[]>(BENCHMARK_FUNCTIONS);
  const [robustBenchmarks, setRobustBenchmarks] = useState<RobustBenchmarkFunction[]>(ROBUST_BENCHMARK_FUNCTIONS);
  const [isLoading, setIsLoading] = useState(true);
  const [source, setSource] = useState<'api' | 'fallback'>('fallback');

  useEffect(() => {
    let active = true;

    async function loadCatalog() {
      try {
        const [apiAlgorithms, apiBenchmarks, apiRobustBenchmarks] = await Promise.all([
          getAlgorithms(),
          getBenchmarks(),
          getRobustBenchmarks(),
        ]);

        if (!active) return;

        setAlgorithms(apiAlgorithms.length > 0 ? apiAlgorithms : ALGORITHMS);
        setBenchmarks(apiBenchmarks.length > 0 ? apiBenchmarks : BENCHMARK_FUNCTIONS);
        setRobustBenchmarks(
          apiRobustBenchmarks.length > 0 ? apiRobustBenchmarks : ROBUST_BENCHMARK_FUNCTIONS
        );
        setSource('api');
      } catch (error) {
        if (active) {
          errorLogger.warn('目录数据加载失败，使用前端fallback数据', error);
          setSource('fallback');
        }
      } finally {
        if (active) {
          setIsLoading(false);
        }
      }
    }

    loadCatalog();

    return () => {
      active = false;
    };
  }, []);

  return { algorithms, benchmarks, robustBenchmarks, isLoading, source };
}
