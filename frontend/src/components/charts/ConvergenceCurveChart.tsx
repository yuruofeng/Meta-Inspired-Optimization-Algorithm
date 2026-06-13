import { useMemo } from 'react';
import ReactECharts from 'echarts-for-react';
import type { EChartsOption } from 'echarts';
import { useTheme } from '../../hooks/useTheme';
import { getAlgorithmColor } from '../../constants';

export interface ConvergenceCurveData {
  algorithmId: string;
  data: number[];
}

export interface ConvergenceCurveChartProps {
  curves: ConvergenceCurveData[];
  title?: string;
  height?: number;
  showLegend?: boolean;
  logScale?: boolean;
}

export function ConvergenceCurveChart({
  curves,
  title,
  height = 400,
  showLegend = true,
  logScale = true,
}: ConvergenceCurveChartProps) {
  const { isDark } = useTheme();

  const option: EChartsOption = useMemo(() => {
    const series = curves.map((curve) => ({
      name: curve.algorithmId,
      type: 'line' as const,
      data: curve.data,
      smooth: false,
      symbol: 'none',
      lineStyle: {
        width: 2,
      },
      itemStyle: {
        color: getAlgorithmColor(curve.algorithmId),
      },
      emphasis: {
        focus: 'series' as const,
      },
      animationDuration: 1000,
      animationEasing: 'cubicOut' as const,
    }));

    const xAxisData = curves[0]
      ? Array.from({ length: curves[0].data.length }, (_, i) => i + 1)
      : [];

    return {
      title: title
        ? {
            text: title,
            left: 'center' as const,
            textStyle: {
              color: isDark ? 'rgba(255, 255, 255, 0.88)' : '#333',
              fontSize: 16,
            },
          }
        : undefined,
      tooltip: {
        trigger: 'axis',
        backgroundColor: isDark ? '#1f1f1f' : '#fff',
        borderColor: isDark ? '#333' : '#ddd',
        textStyle: {
          color: isDark ? '#fff' : '#333',
        },
        formatter: (params: unknown) => {
          const items = params as Array<{ seriesName: string; data: number; marker: string }>;
          if (!Array.isArray(items) || items.length === 0) return '';
          let html = '<div style="font-weight: bold; margin-bottom: 4px;">Convergence Data</div>';
          items.forEach((item) => {
            const value = typeof item.data === 'number' ? item.data.toExponential(4) : item.data;
            html += `<div>${item.marker} ${item.seriesName}: ${value}</div>`;
          });
          return html;
        },
      },
      legend: showLegend
        ? {
            type: 'scroll',
            bottom: 0,
            textStyle: {
              color: isDark ? 'rgba(255, 255, 255, 0.65)' : '#666',
            },
            pageTextStyle: {
              color: isDark ? 'rgba(255, 255, 255, 0.65)' : '#666',
            },
          }
        : undefined,
      grid: {
        left: '3%',
        right: '4%',
        bottom: showLegend ? '15%' : '10%',
        top: title ? '15%' : '10%',
        containLabel: true,
      },
      xAxis: {
        type: 'category' as const,
        name: 'Iteration',
        nameLocation: 'middle' as const,
        nameGap: 30,
        nameTextStyle: {
          color: isDark ? 'rgba(255, 255, 255, 0.65)' : '#666',
        },
        data: xAxisData,
        axisLine: {
          lineStyle: {
            color: isDark ? 'rgba(255, 255, 255, 0.25)' : '#ccc',
          },
        },
        axisLabel: {
          color: isDark ? 'rgba(255, 255, 255, 0.65)' : '#666',
          formatter: (value: string) => {
            const numValue = parseInt(value, 10);
            if (xAxisData.length > 100) {
              return numValue % Math.ceil(xAxisData.length / 10) === 0 ? value : '';
            }
            return value;
          },
        },
        splitLine: {
          show: false,
        },
      },
      yAxis: {
        type: logScale ? 'log' as const : 'value' as const,
        name: 'Fitness',
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
      dataZoom: curves[0] && curves[0].data.length > 100
        ? [
            {
              type: 'inside',
              start: 0,
              end: 100,
            },
            {
              start: 0,
              end: 100,
              height: 20,
              bottom: showLegend ? '18%' : '3%',
              borderColor: isDark ? '#333' : '#ddd',
              textStyle: {
                color: isDark ? 'rgba(255, 255, 255, 0.65)' : '#666',
              },
              handleStyle: {
                color: isDark ? '#555' : '#999',
              },
            },
          ]
        : undefined,
      series,
    };
  }, [curves, title, showLegend, logScale, isDark]);

  return (
    <ReactECharts
      option={option}
      style={{ height, width: '100%' }}
      opts={{ renderer: 'canvas' }}
      notMerge
    />
  );
}
