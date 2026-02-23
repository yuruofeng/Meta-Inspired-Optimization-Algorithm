classdef OptimizationResult < handle
    % OptimizationResult 优化结果统一结构体
    %
    % 封装元启发式算法优化结果的标准格式，包含最优解、收敛曲线、
    % 性能指标和元数据。符合 metaheuristic_spec.md §2.1 规范。
    %
    % 属性:
    %   bestSolution      - 最优解向量 (1 x dim)
    %   bestFitness       - 最优适应度值 (标量)
    %   convergenceCurve  - 收敛曲线 (iterations x 1)
    %   totalEvaluations  - 总函数评估次数 (整数)
    %   elapsedTime       - 运行时长，单位秒 (标量)
    %   metadata          - 元数据结构体
    %
    % 使用示例:
    %   result = OptimizationResult(...
    %       'bestSolution', [1.2, -3.4, 0.5], ...
    %       'bestFitness', 0.00142, ...
    %       'convergenceCurve', [128.4, 56.2, 12.1], ...
    %       'totalEvaluations', 25000, ...
    %       'elapsedTime', 3.72);
    %   disp(result);
    %
    % 作者：RUOFENG YU
    % 版本: 1.0.0
    % 日期: 2025

    properties
        bestSolution double = []           % 最优解
        bestFitness double = Inf           % 最优适应度值
        convergenceCurve double = []       % 每代最优值列表
        totalEvaluations int64 = 0         % 总评估次数
        elapsedTime double = 0             % 运行时长（秒）
        metadata struct = struct()         % 元数据
    end

    methods
        function obj = OptimizationResult(varargin)
            % OptimizationResult 构造函数
            %
            % 支持键值对参数输入:
            %   'bestSolution', value
            %   'bestFitness', value
            %   'convergenceCurve', value
            %   'totalEvaluations', value
            %   'elapsedTime', value
            %   'metadata', struct
            %
            % 示例:
            %   result = OptimizationResult('bestFitness', 0.001, 'elapsedTime', 5.2);

            p = inputParser;
            addParameter(p, 'bestSolution', []);
            addParameter(p, 'bestFitness', Inf);
            addParameter(p, 'convergenceCurve', []);
            addParameter(p, 'totalEvaluations', int64(0));
            addParameter(p, 'elapsedTime', 0);
            addParameter(p, 'metadata', struct());

            parse(p, varargin{:});

            obj.bestSolution = p.Results.bestSolution;
            obj.bestFitness = p.Results.bestFitness;
            obj.convergenceCurve = p.Results.convergenceCurve;
            obj.totalEvaluations = p.Results.totalEvaluations;
            obj.elapsedTime = p.Results.elapsedTime;
            obj.metadata = p.Results.metadata;
        end

        function display(obj)
            % display 显示结果摘要
            %
            % 打印优化结果的关键信息，包括最优适应度、评估次数和运行时间。

            fprintf('\n========== Optimization Result ==========\n');
            fprintf('Algorithm: %s\n', obj.getAlgorithmName());
            fprintf('Best Fitness: %.6e\n', obj.bestFitness);
            fprintf('Total Evaluations: %d\n', obj.totalEvaluations);
            fprintf('Elapsed Time: %.3f seconds\n', obj.elapsedTime);

            if ~isempty(obj.bestSolution)
                fprintf('Solution Dimension: %d\n', length(obj.bestSolution));
                fprintf('Best Solution (first 5 dims): ');
                nShow = min(5, length(obj.bestSolution));
                fprintf('%.4f ', obj.bestSolution(1:nShow));
                if length(obj.bestSolution) > 5
                    fprintf('...');
                end
                fprintf('\n');
            end

            if ~isempty(obj.convergenceCurve)
                fprintf('Iterations: %d\n', length(obj.convergenceCurve));
                fprintf('Initial Fitness: %.6e\n', obj.convergenceCurve(1));
                fprintf('Final Fitness: %.6e\n', obj.convergenceCurve(end));
                fprintf('Improvement: %.2f%%\n', ...
                    (obj.convergenceCurve(1) - obj.convergenceCurve(end)) / ...
                    obj.convergenceCurve(1) * 100);
            end

            fprintf('==========================================\n\n');
        end

        function plotConvergence(obj, varargin)
            % plotConvergence 绘制收敛曲线
            %
            % 输入参数:
            %   varargin - 可选参数对:
            %     'Title' - 图表标题 (默认: 'Convergence Curve')
            %     'XLabel' - X轴标签 (默认: 'Iteration')
            %     'YLabel' - Y轴标签 (默认: 'Best Fitness')
            %     'Scale' - 'linear' 或 'log' (默认: 'log')
            %
            % 示例:
            %   result.plotConvergence('Scale', 'log', 'Title', 'GWO Convergence');

            if isempty(obj.convergenceCurve)
                warning('No convergence curve data available');
                return;
            end

            p = inputParser;
            addParameter(p, 'Title', 'Convergence Curve');
            addParameter(p, 'XLabel', 'Iteration');
            addParameter(p, 'YLabel', 'Best Fitness');
            addParameter(p, 'Scale', 'log');
            parse(p, varargin{:});

            figure;
            iterations = 1:length(obj.convergenceCurve);

            if strcmp(p.Results.Scale, 'log')
                semilogy(iterations, obj.convergenceCurve, 'b-', 'LineWidth', 2);
            else
                plot(iterations, obj.convergenceCurve, 'b-', 'LineWidth', 2);
            end

            grid on;
            xlabel(p.Results.XLabel, 'FontSize', 12);
            ylabel(p.Results.YLabel, 'FontSize', 12);
            title(p.Results.Title, 'FontSize', 14, 'FontWeight', 'bold');

            % 添加算法名称图例
            legend(obj.getAlgorithmName(), 'Location', 'best');
        end

        function saveToFile(obj, filename)
            % saveToFile 保存结果到文件
            %
            % 输入参数:
            %   filename - 文件名 (.mat 格式)
            %
            % 示例:
            %   result.saveToFile('gwo_result_F1.mat');

            if ~endsWith(filename, '.mat')
                filename = [filename '.mat'];
            end

            result = obj.toStruct();
            save(filename, 'result');
            fprintf('Result saved to: %s\n', filename);
        end

        function s = toStruct(obj)
            % toStruct 将结果转换为结构体
            %
            % 输出参数:
            %   s - 包含所有结果数据的结构体

            s.bestSolution = obj.bestSolution;
            s.bestFitness = obj.bestFitness;
            s.convergenceCurve = obj.convergenceCurve;
            s.totalEvaluations = obj.totalEvaluations;
            s.elapsedTime = obj.elapsedTime;
            s.metadata = obj.metadata;
        end

        function compare(obj, otherResult)
            % compare 对比两个优化结果
            %
            % 输入参数:
            %   otherResult - 另一个 OptimizationResult 对象
            %
            % 示例:
            %   result1.compare(result2);

            fprintf('\n========== Result Comparison ==========\n');
            fprintf('%-20s %15s %15s\n', 'Metric', 'This', 'Other');
            fprintf('%-20s %15.6e %15.6e\n', 'Best Fitness', ...
                obj.bestFitness, otherResult.bestFitness);
            fprintf('%-20s %15d %15d\n', 'Total Evaluations', ...
                obj.totalEvaluations, otherResult.totalEvaluations);
            fprintf('%-20s %15.3f %15.3f\n', 'Elapsed Time (s)', ...
                obj.elapsedTime, otherResult.elapsedTime);

            if ~isempty(obj.convergenceCurve) && ~isempty(otherResult.convergenceCurve)
                fprintf('%-20s %15d %15d\n', 'Iterations', ...
                    length(obj.convergenceCurve), length(otherResult.convergenceCurve));
            end

            fprintf('========================================\n\n');
        end
    end

    methods (Access = private)
        function name = getAlgorithmName(obj)
            % getAlgorithmName 从元数据中提取算法名称

            if isfield(obj.metadata, 'algorithm')
                name = obj.metadata.algorithm;
            else
                name = 'Unknown';
            end
        end

        function tf = endsWith(str, suffix)
            % endsWith 检查字符串是否以指定后缀结尾

            tf = length(str) >= length(suffix) && ...
                 strcmp(str(end-length(suffix)+1:end), suffix);
        end
    end

    methods (Static)
        function result = loadFromFile(filename)
            % loadFromFile 从文件加载结果
            %
            % 输入参数:
            %   filename - 文件名 (.mat 格式)
            %
            % 输出参数:
            %   result - OptimizationResult 对象
            %
            % 示例:
            %   result = OptimizationResult.loadFromFile('gwo_result.mat');

            if ~exist(filename, 'file')
                error('File not found: %s', filename);
            end

            data = load(filename, 'result');
            s = data.result;

            result = OptimizationResult(...
                'bestSolution', s.bestSolution, ...
                'bestFitness', s.bestFitness, ...
                'convergenceCurve', s.convergenceCurve, ...
                'totalEvaluations', s.totalEvaluations, ...
                'elapsedTime', s.elapsedTime, ...
                'metadata', s.metadata ...
            );
        end
    end
end
