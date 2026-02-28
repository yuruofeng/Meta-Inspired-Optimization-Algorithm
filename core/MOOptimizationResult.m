classdef MOOptimizationResult < handle
    % MOOptimizationResult 多目标优化结果统一结构体
    %
    % 封装多目标元启发式算法优化结果的标准格式，包含Pareto前沿、
    % 收敛曲线、性能指标和元数据。符合 metaheuristic_spec.md §2.1 规范。
    %
    % 属性:
    %   paretoSet           - Pareto最优解集 (N x dim)
    %   paretoFront         - Pareto前沿 (N x objCount)
    %   objCount            - 目标函数数量
    %   convergenceCurve    - 收敛指标曲线 (iterations x 1)
    %   totalEvaluations    - 总函数评估次数 (整数)
    %   elapsedTime         - 运行时长，单位秒 (标量)
    %   hypervolume         - 超体积指标
    %   spread              - 分布性指标
    %   metadata            - 元数据结构体
    %
    % 使用示例:
    %   result = MOOptimizationResult(...
    %       'paretoSet', solutions, ...
    %       'paretoFront', front, ...
    %       'objCount', 2, ...
    %       'elapsedTime', 5.2);
    %   disp(result);
    %
    % 作者：RUOFENG YU
    % 版本: 1.0.0
    % 日期: 2025

    properties
        paretoSet double = []            % Pareto最优解集
        paretoFront double = []          % Pareto前沿
        objCount int32 = 2               % 目标函数数量
        convergenceCurve double = []     % 收敛指标曲线
        totalEvaluations int64 = 0       % 总评估次数
        elapsedTime double = 0           % 运行时长（秒）
        hypervolume double = 0           % 超体积指标
        spread double = 0                % 分布性指标
        metadata struct = struct()       % 元数据
    end

    methods
        function obj = MOOptimizationResult(varargin)
            % MOOptimizationResult 构造函数
            %
            % 支持键值对参数输入:
            %   'paretoSet', value
            %   'paretoFront', value
            %   'objCount', value
            %   'convergenceCurve', value
            %   'totalEvaluations', value
            %   'elapsedTime', value
            %   'hypervolume', value
            %   'spread', value
            %   'metadata', struct
            %
            % 示例:
            %   result = MOOptimizationResult('paretoFront', front, 'elapsedTime', 5.2);

            p = inputParser;
            addParameter(p, 'paretoSet', []);
            addParameter(p, 'paretoFront', []);
            addParameter(p, 'objCount', int32(2));
            addParameter(p, 'convergenceCurve', []);
            addParameter(p, 'totalEvaluations', int64(0));
            addParameter(p, 'elapsedTime', 0);
            addParameter(p, 'hypervolume', 0);
            addParameter(p, 'spread', 0);
            addParameter(p, 'metadata', struct());

            parse(p, varargin{:});

            obj.paretoSet = p.Results.paretoSet;
            obj.paretoFront = p.Results.paretoFront;
            obj.objCount = p.Results.objCount;
            obj.convergenceCurve = p.Results.convergenceCurve;
            obj.totalEvaluations = p.Results.totalEvaluations;
            obj.elapsedTime = p.Results.elapsedTime;
            obj.hypervolume = p.Results.hypervolume;
            obj.spread = p.Results.spread;
            obj.metadata = p.Results.metadata;
        end

        function display(obj)
            % display 显示结果摘要
            %
            % 打印多目标优化结果的关键信息，包括Pareto解数量、评估次数和运行时间。

            fprintf('\n========== Multi-Objective Optimization Result ==========\n');
            fprintf('Algorithm: %s\n', obj.getAlgorithmName());
            fprintf('Number of Objectives: %d\n', obj.objCount);

            if ~isempty(obj.paretoFront)
                fprintf('Pareto Front Size: %d solutions\n', size(obj.paretoFront, 1));
                fprintf('Objective Ranges:\n');
                for i = 1:obj.objCount
                    fprintf('  f%d: [%.6e, %.6e]\n', i, ...
                        min(obj.paretoFront(:, i)), ...
                        max(obj.paretoFront(:, i)));
                end
            end

            fprintf('Total Evaluations: %d\n', obj.totalEvaluations);
            fprintf('Elapsed Time: %.3f seconds\n', obj.elapsedTime);

            if obj.hypervolume > 0
                fprintf('Hypervolume: %.6e\n', obj.hypervolume);
            end

            if obj.spread > 0
                fprintf('Spread: %.6e\n', obj.spread);
            end

            if ~isempty(obj.convergenceCurve)
                fprintf('Iterations: %d\n', length(obj.convergenceCurve));
            end

            fprintf('==========================================================\n');
        end

        function name = getAlgorithmName(obj)
            % getAlgorithmName 获取算法名称
            %
            % 输出参数:
            %   name - 算法名称字符串

            if isfield(obj.metadata, 'algorithm')
                name = obj.metadata.algorithm;
            else
                name = 'Unknown';
            end
        end

        function n = getParetoSize(obj)
            % getParetoSize 获取Pareto前沿解的数量
            %
            % 输出参数:
            %   n - Pareto解数量

            n = size(obj.paretoFront, 1);
        end

        function plot(obj, truePf)
            % plot 绘制Pareto前沿
            %
            % 输入参数:
            %   truePf - (可选) 真实Pareto前沿，用于对比

            if isempty(obj.paretoFront)
                warning('MOOptimizationResult:EmptyFront', ...
                    'Pareto front is empty, nothing to plot.');
                return;
            end

            figure;
            hold on;

            if nargin > 1 && ~isempty(truePf)
                if obj.objCount == 2
                    plot(truePf(:, 1), truePf(:, 2), 'b-', 'LineWidth', 1.5, ...
                        'DisplayName', 'True PF');
                elseif obj.objCount == 3
                    plot3(truePf(:, 1), truePf(:, 2), truePf(:, 3), 'b.', ...
                        'DisplayName', 'True PF');
                end
            end

            if obj.objCount == 2
                plot(obj.paretoFront(:, 1), obj.paretoFront(:, 2), ...
                    'ko', 'MarkerSize', 8, 'MarkerFaceColor', 'k', ...
                    'DisplayName', 'Obtained PF');
                xlabel('f_1');
                ylabel('f_2');
            elseif obj.objCount == 3
                plot3(obj.paretoFront(:, 1), obj.paretoFront(:, 2), ...
                    obj.paretoFront(:, 3), 'ko', 'MarkerSize', 8, ...
                    'MarkerFaceColor', 'k', 'DisplayName', 'Obtained PF');
                xlabel('f_1');
                ylabel('f_2');
                zlabel('f_3');
            else
                error('MOOptimizationResult:UnsupportedDimension', ...
                    'Plotting is only supported for 2 or 3 objectives.');
            end

            legend('Location', 'best');
            title(sprintf('Pareto Front - %s', obj.getAlgorithmName()));
            grid on;
            hold off;
        end

        function hv = calculateHypervolume(obj, referencePoint)
            % calculateHypervolume 计算超体积指标
            %
            % 输入参数:
            %   referencePoint - 参考点 (1 x objCount)
            %
            % 输出参数:
            %   hv - 超体积值

            if isempty(obj.paretoFront)
                hv = 0;
                return;
            end

            if nargin < 2
                referencePoint = max(obj.paretoFront) * 1.1;
            end

            hv = obj.computeHypervolumeInternal(obj.paretoFront, referencePoint);
        end

        function spreadVal = calculateSpread(obj)
            % calculateSpread 计算分布性指标
            %
            % 输出参数:
            %   spreadVal - 分布性指标值

            if isempty(obj.paretoFront) || size(obj.paretoFront, 1) < 2
                spreadVal = 0;
                return;
            end

            spreadVal = obj.computeSpreadInternal(obj.paretoFront);
        end
    end

    methods (Access = protected)
        function hv = computeHypervolumeInternal(obj, front, ref)
            % computeHypervolumeInternal 内部超体积计算
            %
            % 使用简单的Monte Carlo方法估计超体积

            n = size(front, 1);
            if n == 0
                hv = 0;
                return;
            end

            hv = 1;
            for i = 1:obj.objCount
                sortedFront = sort(front(:, i));
                hv = hv * (ref(i) - sortedFront(1));
            end

            for i = 1:n-1
                vol = 1;
                for j = 1:obj.objCount
                    vol = vol * max(0, front(i+1, j) - front(i, j));
                end
                hv = hv + vol;
            end
        end

        function spreadVal = computeSpreadInternal(obj, front)
            % computeSpreadInternal 内部分布性计算

            n = size(front, 1);
            if n < 2
                spreadVal = 0;
                return;
            end

            distances = zeros(n-1, 1);
            for i = 1:n-1
                distances(i) = norm(front(i+1, :) - front(i, :));
            end

            dMean = mean(distances);
            if dMean == 0
                spreadVal = 0;
            else
                spreadVal = sum(abs(distances - dMean)) / ((n-1) * dMean);
            end
        end
    end
end
