classdef FA < BaseAlgorithm
    % FA 萤火虫算法 (Firefly Algorithm)
    %
    % 一种模拟萤火虫闪烁行为的群体智能算法。基于光强吸引
    % 机制实现全局优化，特别适合多模态问题。
    %
    % 算法原理:
    %   1. 萤火虫亮度与目标函数值相关
    %   2. 亮度高的萤火虫吸引亮度低的萤火虫
    %   3. 光强随距离指数衰减
    %   4. 没有萤火虫时，萤火虫随机移动
    %
    % 参考文献:
    %   X.-S. Yang
    %   "Firefly Algorithms for Multimodal Optimization"
    %   Stochastic Algorithms: Foundations and Applications, 2009
    %   DOI: 10.1007/978-3-642-04944-6_14
    %
    % 时间复杂度: O(MaxIter × N^2 × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   fa = FA(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = fa.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Xin-She Yang
    % 实现版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 萤火虫位置矩阵 (N x Dim)
        lightIntensity       % 光强度向量 (N x 1)
        bestPosition         % 最优位置 (1 x Dim)
        bestFitness          % 最优适应度
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 5, ...
                'max', 10000, ...
                'description', '萤火虫种群大小'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'alpha', struct(...
                'type', 'float', ...
                'default', 0.2, ...
                'min', 0, ...
                'max', 1, ...
                'description', '随机化参数'), ...
            'beta0', struct(...
                'type', 'float', ...
                'default', 1.0, ...
                'min', 0, ...
                'max', 10, ...
                'description', '基础吸引度'), ...
            'gamma', struct(...
                'type', 'float', ...
                'default', 1.0, ...
                'min', 0.01, ...
                'max', 10, ...
                'description', '光吸收系数'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = FA(configStruct)
            if nargin < 1 || isempty(configStruct)
                configStruct = struct();
            end
            obj = obj@BaseAlgorithm(configStruct);
        end

        function initialize(obj, problem)
            lb = problem.lb;
            ub = problem.ub;
            dim = problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;

            obj.positions = Initialization(N, dim, ub, lb);

            obj.lightIntensity = obj.evaluatePopulation(obj.positions);

            [obj.bestFitness, bestIdx] = min(obj.lightIntensity);
            obj.bestPosition = obj.positions(bestIdx, :);

            obj.bestSolution = obj.bestPosition;
            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            lb = obj.problem.lb;
            ub = problem.ub;
            dim = obj.problem.dim;
            N = obj.config.populationSize;
            alpha = obj.config.alpha;
            beta0 = obj.config.beta0;
            gamma = obj.config.gamma;

            for i = 1:N
                for j = 1:N
                    if obj.lightIntensity(j) < obj.lightIntensity(i)
                        r = norm(obj.positions(i, :) - obj.positions(j, :));

                        beta = beta0 * exp(-gamma * r^2);

                        epsilon = (rand(1, dim) - 0.5) .* alpha;

                        obj.positions(i, :) = obj.positions(i, :) + ...
                            beta * (obj.positions(j, :) - obj.positions(i, :)) + epsilon;

                        obj.positions(i, :) = obj.clampToBounds(obj.positions(i, :), lb, ub);

                        obj.lightIntensity(i) = obj.evaluateSolution(obj.positions(i, :));

                        if obj.lightIntensity(i) < obj.bestFitness
                            obj.bestFitness = obj.lightIntensity(i);
                            obj.bestPosition = obj.positions(i, :);
                        end
                    end
                end
            end

            j = randi(N);
            epsilon = (rand(1, dim) - 0.5) .* alpha;
            obj.positions(j, :) = obj.positions(j, :) + epsilon;
            obj.positions(j, :) = obj.clampToBounds(obj.positions(j, :), lb, ub);
            obj.lightIntensity(j) = obj.evaluateSolution(obj.positions(j, :));

            if obj.lightIntensity(j) < obj.bestFitness
                obj.bestFitness = obj.lightIntensity(j);
                obj.bestPosition = obj.positions(j, :);
            end

            obj.bestSolution = obj.bestPosition;
        end

        function tf = shouldStop(obj)
            tf = obj.currentIteration >= obj.config.maxIterations;
        end
    end

    methods (Access = protected)
        function validatedConfig = validateConfig(obj, configStruct)
            validatedConfig = struct();
            
            fields = fieldnames(obj.PARAM_SCHEMA);
            for i = 1:length(fields)
                field = fields{i};
                schema = obj.PARAM_SCHEMA.(field);
                
                if isfield(configStruct, field)
                    validatedConfig.(field) = configStruct.(field);
                else
                    validatedConfig.(field) = schema.default;
                end
            end
        end
    end

    methods (Static)
        function register()
            AlgorithmRegistry.register('FA', @FA);
        end
    end
end
