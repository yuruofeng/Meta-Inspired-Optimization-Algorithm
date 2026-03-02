import { useMemo } from 'react';
import ReactECharts from 'echarts-for-react';
import type { EChartsOption } from 'echarts';
import { useTheme } from '../../hooks/useTheme';
import { getAlgorithmColor } from '../../constants';

export interface PerformanceData {
  algorithmId: string;
  bestFitness: number;
  meanFitness?: number;
  stdFitness?: number;
  elapsedTime: number;
}

export interface PerformanceBarChartProps {
  data: PerformanceData[];
  metric?: 'bestFitness' | 'elapsedTime' | 'meanFitness';
  title?: string;
  height?: number;
  showStdDev?: boolean;
}

export function PerformanceBarChart({
  data,
  metric = 'bestFitness',
  title,
  height = 350,
  showStdDev = true,
}: PerformanceBarChartProps) {
  const { isDark } = useTheme();

  const option: EChartsOption = useMemo(() => {
    const metricLabels: Record<string, string> = {
      bestFitness: 'Best Fitness',
      meanFitness: 'Mean Fitness',
      elapsedTime: 'Execution Time (s)',
    };
    const sortedData = [...data].sort((a, b) => {
      const aValue = a[metric] ?? 0;
      const bValue = b[metric] ?? 0;
      return metric === 'elapsedTime' ? aValue - bValue : aValue - bValue;
    });

    const xData = sortedData.map((d) => d.algorithmId);
    const yData = sortedData.map((d) => d[metric] ?? 0);
    const stdData = sortedData.map((d) => d.stdFitness ?? 0);

    return {
      title: title
        ? {
            text: title,
            left: 'center',
            textStyle: {
              color: isDark ? 'rgba(255, 255, 255, 0.88)' : '#333',
              fontSize: 14,
            },
          }
        : undefined,
      tooltip: {
        trigger: 'axis',
        axisPointer: {
          type: 'shadow',
        },
        backgroundColor: isDark ? '#1f1f1f' : '#fff',
        borderColor: isDark ? '#333' : '#ddd',
        textStyle: {
          color: isDark ? '#fff' : '#333',
        },
        formatter: (params: unknown) => {
          const items = params as Array<{ name: string; data: number; color: string }>;
          if (!Array.isArray(items) || items.length === 0) return '';
          const item = items[0];
          const algorithm = data.find((d) => d.algorithmId === item.name);
          if (!algorithm) return '';
          
          let html = `<div style="font-weight: bold; margin-bottom: 4px;">${item.name}</div>`;
          
          if (metric === 'bestFitness') {
            html += `<div>Best Fitness: ${algorithm.bestFitness.toExponential(4)}</div>`;
            if (algorithm.meanFitness !== undefined) {
              html += `<div>Mean Fitness: ${algorithm.meanFitness.toExponential(4)}</div>`;
            }
            if (algorithm.stdFitness !== undefined && showStdDev) {
              html += `<div>Std Dev: ${algorithm.stdFitness.toExponential(4)}</div>`;
            }
          } else if (metric === 'elapsedTime') {
            html += `<div>Time: ${algorithm.elapsedTime.toFixed(3)}s</div>`;
          } else {
            const value = item.data;
            html += `<div>${metricLabels[metric]}: ${typeof value === 'number' ? value.toExponential(4) : value}</div>`;
          }
          
          return html;
        },
      },
      grid: {
        left: '3%',
        right: '4%',
        bottom: '3%',
        top: title ? '15%' : '10%',
        containLabel: true,
      },
      xAxis: {
        type: 'category' as const,
        data: xData,
        axisLine: {
          lineStyle: {
            color: isDark ? 'rgba(255, 255, 255, 0.25)' : '#ccc',
          },
        },
        axisLabel: {
          color: isDark ? 'rgba(255, 255, 255, 0.65)' : '#666',
          rotate: xData.length > 6 ? 45 : 0,
        },
      },
      yAxis: {
        type: 'log' as const,
        name: metricLabels[metric],
        nameLocation: 'middle' as const,
        nameGap: 50,
        nameTextStyle: {
          color: isDark ? 'rgba(255, 255, 255, 0.65)' : '#666',
        },
        axisLine: {
          lineStyle: {
            color: isDark ? 'rgba(255, 255, 255, 0.25)' : '#ccc',
          },
        },
        axisLabel: {
          color: isDark ? 'rgba(255, 255, 255, 0.65)' : '#666',
          formatter: (value: number) => {
            if (value >= 1000 || (value < 0.01 && value > 0)) {
              return value.toExponential(1);
            }
            return value.toFixed(2);
          },
        },
        splitLine: {
          lineStyle: {
            color: isDark ? 'rgba(255, 255, 255, 0.08)' : '#eee',
          },
        },
      },
      series: [
        {
          name: metricLabels[metric],
          type: 'bar',
          data: yData.map((value, index) => ({
            value,
            itemStyle: {
              color: getAlgorithmColor(sortedData[index].algorithmId),
              borderRadius: [4, 4, 0, 0],
            },
          })),
          barMaxWidth: 60,
          emphasis: {
            itemStyle: {
              shadowBlur: 10,
              shadowOffsetX: 0,
              shadowColor: 'rgba(0, 0, 0, 0.5)',
            },
          },
          ...(showStdDev && metric === 'bestFitness' && stdData.some((s) => s > 0)
            ? {
                error: {
                  show: true,
                  width: 2,
                  borderWidth: 1,
                },
                data: yData.map((value, index) => ({
                  value,
                  error: stdData[index],
                })),
              }
            : {}),
        },
      ],
    };
  }, [data, metric, title, showStdDev, isDark]);

  return (
    <ReactECharts
      option={option}
      style={{ height, width: '100%' }}
      opts={{ renderer: 'canvas' }}
      notMerge
    />
  );
}
