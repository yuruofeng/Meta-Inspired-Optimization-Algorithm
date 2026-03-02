import { useMemo } from 'react';
import ReactECharts from 'echarts-for-react';
import type { EChartsOption } from 'echarts';
import { useTheme } from '../../hooks/useTheme';
import { getAlgorithmColor } from '../../constants';

export interface RadarMetricData {
  algorithmId: string;
  hypervolume: number;
  igd: number;
  spread: number;
  gd?: number;
  elapsedTime?: number;
}

export interface MetricsRadarChartProps {
  data: RadarMetricData[];
  title?: string;
  height?: number;
  showLegend?: boolean;
}

export function MetricsRadarChart({
  data,
  title,
  height = 400,
  showLegend = true,
}: MetricsRadarChartProps) {
  const { isDark } = useTheme();

  const option: EChartsOption = useMemo(() => {
    const indicators = [
      { name: 'Hypervolume', max: 1 },
      { name: 'IGD (inv)', max: 1 },
      { name: 'Spread (inv)', max: 1 },
      { name: 'GD (inv)', max: 1 },
      { name: 'Speed (inv)', max: 1 },
    ];

    const maxTime = Math.max(...data.map((d) => d.elapsedTime ?? 1));
    const maxIgd = Math.max(...data.map((d) => d.igd || 0.001));
    const maxSpread = Math.max(...data.map((d) => d.spread || 0.001));
    const maxGd = Math.max(...data.map((d) => d.gd || 0.001));

    const seriesData = data.map((item) => ({
      name: item.algorithmId,
      value: [
        item.hypervolume,
        1 - (item.igd / maxIgd),
        1 - (item.spread / maxSpread),
        item.gd !== undefined ? 1 - (item.gd / maxGd) : 0.5,
        item.elapsedTime !== undefined ? 1 - (item.elapsedTime / maxTime) : 0.5,
      ],
      itemStyle: {
        color: getAlgorithmColor(item.algorithmId),
      },
      areaStyle: {
        opacity: 0.1,
      },
      lineStyle: {
        width: 2,
      },
    }));

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
        trigger: 'item',
        backgroundColor: isDark ? '#1f1f1f' : '#fff',
        borderColor: isDark ? '#333' : '#ddd',
        textStyle: {
          color: isDark ? '#fff' : '#333',
        },
      },
      legend: showLegend
        ? {
            type: 'scroll',
            bottom: 0,
            textStyle: {
              color: isDark ? 'rgba(255, 255, 255, 0.65)' : '#666',
            },
          }
        : undefined,
      radar: {
        indicator: indicators,
        shape: 'polygon' as const,
        splitNumber: 5,
        axisName: {
          color: isDark ? 'rgba(255, 255, 255, 0.65)' : '#666',
          fontSize: 11,
        },
        splitLine: {
          lineStyle: {
            color: isDark ? 'rgba(255, 255, 255, 0.15)' : '#ddd',
          },
        },
        splitArea: {
          show: true,
          areaStyle: {
            color: isDark
              ? ['rgba(255, 255, 255, 0.02)', 'rgba(255, 255, 255, 0.05)']
              : ['rgba(0, 0, 0, 0.02)', 'rgba(0, 0, 0, 0.05)'],
          },
        },
        axisLine: {
          lineStyle: {
            color: isDark ? 'rgba(255, 255, 255, 0.2)' : '#ccc',
          },
        },
      },
      series: [
        {
          name: 'Performance Metrics',
          type: 'radar',
          data: seriesData,
          emphasis: {
            lineStyle: {
              width: 3,
            },
          },
        },
      ],
    };
  }, [data, title, showLegend, isDark]);

  return (
    <ReactECharts
      option={option}
      style={{ height, width: '100%' }}
      opts={{ renderer: 'canvas' }}
      notMerge
    />
  );
}
