classdef ASO < BaseAlgorithm
    % ASO 原子搜索优化算法 (Atom Search Optimization)
    %
    % 一种模拟原子运动行为的元启发式算法。基于分子动力学中
    % 原子的相互作用和运动规律实现全局优化。
    %
    % 算法原理:
    %   1. 原子间存在相互作用力(吸引和排斥)
    %   2. 原子速度受力和质量影响
    %   3. 系统通过迭代达到平衡态(最优解)
    %   4. 温度参数控制探索与开发
    %
    % 参考文献:
    %   W. Zhao, L. Wang, Z. Zhang
    %   "Atom search optimization and its application to solve a hydrogeologic parameter estimation problem"
    %   Knowledge-Based Systems, 2019
    %   DOI: 10.1016/j.knosys.2018.09.030
    %
    % 时间复杂度: O(MaxIter × N^2 × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   aso = ASO(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = aso.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Weiguo Zhao, Liying Wang, Zhenxing Zhang
    % 实现版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 原子位置矩阵 (N x Dim)
        velocities           % 原子速度矩阵 (N x Dim)
        acceleration         % 原子加速度矩阵 (N x Dim)
        fitness              % 适应度向量 (N x 1)
        masses               % 原子质量向量 (N x 1)
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
                'description', '原子数量'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'alpha', struct(...
                'type', 'float', ...
                'default', 50, ...
                'min', 1, ...
                'max', 100, ...
                'description', '深度权重'), ...
            'beta', struct(...
                'type', 'float', ...
                'default', 0.2, ...
                'min', 0.01, ...
                'max', 1, ...
                'description', '乘数权重'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = ASO(configStruct)
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

            obj.velocities = zeros(N, dim);
            obj.acceleration = zeros(N, dim);

            obj.fitness = obj.evaluatePopulation(obj.positions);

            [obj.bestFitness, bestIdx] = min(obj.fitness);
            obj.bestPosition = obj.positions(bestIdx, :);

            obj.masses = ones(N, 1);

            obj.bestSolution = obj.bestPosition;
            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            lb = obj.problem.lb;
            ub = problem.ub;
            dim = obj.problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            t = obj.currentIteration + 1;
            alpha = obj.config.alpha;

            obj.updateMasses();

            for i = 1:N
                force = zeros(1, dim);

                for k = 1:N
                    if k ~= i
                        dist = norm(obj.positions(i, :) - obj.positions(k, :));
                        dist = max(dist, 1e-10);

                        if obj.fitness(k) < obj.fitness(i)
                            h = rand();
                            p = (2 + h) * rand() - h;
                            rij = p * (2 - exp(-alpha * t / MaxIter)) * ...
                                  exp(-dist / alpha);
                            force = force + rij * rand(1, dim) .* ...
                                    (obj.positions(k, :) - obj.positions(i, :));
                        else
                            rij = rand();
                            force = force - rij * rand(1, dim) .* ...
                                    (obj.positions(k, :) - obj.positions(i, :));
                        end
                    end
                end

                G = exp(-t / MaxIter);
                obj.acceleration(i, :) = G * force / obj.masses(i);
            end

            for i = 1:N
                lambda = rand(1, dim);

                obj.velocities(i, :) = obj.velocities(i, :) .* ...
                    lambda + obj.acceleration(i, :);

                obj.positions(i, :) = obj.positions(i, :) + obj.velocities(i, :);

                obj.positions(i, :) = obj.clampToBounds(obj.positions(i, :), lb, ub);
            end

            obj.fitness = obj.evaluatePopulation(obj.positions);

            [currentBestFit, currentBestIdx] = min(obj.fitness);
            if currentBestFit < obj.bestFitness
                obj.bestFitness = currentBestFit;
                obj.bestPosition = obj.positions(currentBestIdx, :);
            end

            obj.bestSolution = obj.bestPosition;
        end

        function tf = shouldStop(obj)
            tf = obj.currentIteration >= obj.config.maxIterations;
        end
    end

    methods (Access = protected)
        function updateMasses(obj)
            N = obj.config.populationSize;

            fitBest = min(obj.fitness);
            fitWorst = max(obj.fitness);

            if fitWorst == fitBest
                obj.masses = ones(N, 1);
            else
                obj.masses = exp((obj.fitness - fitBest) / (fitWorst - fitBest));
                obj.masses = obj.masses / sum(obj.masses);
            end

            obj.masses = max(obj.masses, 0.01);
        end

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
            AlgorithmRegistry.register('ASO', @ASO);
        end
    end
end
