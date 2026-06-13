import { useMemo } from 'react';
import ReactECharts from 'echarts-for-react';
import type { EChartsOption } from 'echarts';
import { useTheme } from '../../hooks/useTheme';
import { getAlgorithmColor } from '../../constants';

export interface ParetoFrontData {
  algorithmId: string;
  solutions: number[][];
  objectives: number;
}

export interface ParetoFrontChartProps {
  data: ParetoFrontData[];
  title?: string;
  height?: number;
  showLegend?: boolean;
  objectiveLabels?: string[];
}

export function ParetoFrontChart({
  data,
  title,
  height = 450,
  showLegend = true,
  objectiveLabels = ['f1', 'f2'],
}: ParetoFrontChartProps) {
  const { isDark } = useTheme();

  const option: EChartsOption = useMemo(() => {
    const series = data.map((item) => ({
      name: item.algorithmId,
      type: 'scatter' as const,
      data: item.solutions.map((sol) => ({
        value: sol.slice(0, 2),
      })),
      symbolSize: 8,
      itemStyle: {
        color: getAlgorithmColor(item.algorithmId),
        opacity: 0.7,
      },
      emphasis: {
        focus: 'series' as const,
        itemStyle: {
          opacity: 1,
          borderColor: '#fff',
          borderWidth: 2,
        },
      },
    }));

    return {
      title: title
        ? {
            text: title,
            left: 'center',
            textStyle: {
              color: isDark ? 'rgba(255, 255, 255, 0.88)' : '#333',
              fontSize: 16,
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
        formatter: (params: unknown) => {
          const item = params as { seriesName: string; data: { value: number[] } };
          const values = item.data.value;
          let html = `<div style="font-weight: bold; margin-bottom: 4px;">${item.seriesName}</div>`;
          values.forEach((v, i) => {
            html += `<div>${objectiveLabels[i] || `f${i + 1}`}: ${v.toExponential(4)}</div>`;
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
        type: 'value',
        name: objectiveLabels[0] || 'f1',
        nameLocation: 'middle',
        nameGap: 30,
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
            if (Math.abs(value) >= 1000 || (Math.abs(value) < 0.01 && value !== 0)) {
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
      yAxis: {
        type: 'value',
        name: objectiveLabels[1] || 'f2',
        nameLocation: 'middle',
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
            if (Math.abs(value) >= 1000 || (Math.abs(value) < 0.01 && value !== 0)) {
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
      toolbox: {
        right: 10,
        feature: {
          dataZoom: {
            title: {
              zoom: 'Zoom',
              back: 'Reset',
            },
          },
          restore: {
            title: 'Restore',
          },
          saveAsImage: {
            title: 'Save as Image',
            pixelRatio: 2,
          },
        },
        iconStyle: {
          borderColor: isDark ? 'rgba(255, 255, 255, 0.65)' : '#666',
        },
      },
      dataZoom: [
        {
          type: 'inside',
          xAxisIndex: 0,
          yAxisIndex: 0,
        },
      ],
      series,
    };
  }, [data, title, showLegend, objectiveLabels, isDark]);

  return (
    <ReactECharts
      option={option}
      style={{ height, width: '100%' }}
      opts={{ renderer: 'canvas' }}
      notMerge
    />
  );
}
