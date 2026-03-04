classdef PSO < BaseAlgorithm
    % PSO 粒子群优化算法 (Particle Swarm Optimization)
    %
    % 一种模拟鸟群觅食行为的群体智能算法。粒子通过跟踪个体最优
    % 和全局最优位置来更新自身位置和速度。
    %
    % 算法原理:
    %   1. 每个粒子具有位置和速度两个属性
    %   2. 粒子根据个体历史最优(pbest)和全局最优(gbest)调整速度
    %   3. 速度更新: v = w*v + c1*r1*(pbest-x) + c2*r2*(gbest-x)
    %   4. 位置更新: x = x + v
    %
    % 参考文献:
    %   J. Kennedy, R. Eberhart
    %   "Particle Swarm Optimization"
    %   Proceedings of ICNN'95, 1995
    %   DOI: 10.1109/ICNN.1995.488968
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   pso = PSO(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = pso.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: James Kennedy, Russell Eberhart
    % 实现版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 粒子位置矩阵 (N x Dim)
        velocities           % 粒子速度矩阵 (N x Dim)
        pBestPositions       % 个体最优位置 (N x Dim)
        pBestFitness         % 个体最优适应度 (N x 1)
        gBestPosition        % 全局最优位置 (1 x Dim)
        gBestFitness         % 全局最优适应度
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 5, ...
                'max', 10000, ...
                'description', '粒子种群大小'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'w', struct(...
                'type', 'float', ...
                'default', 0.729, ...
                'min', 0, ...
                'max', 1, ...
                'description', '惯性权重'), ...
            'c1', struct(...
                'type', 'float', ...
                'default', 1.49445, ...
                'min', 0, ...
                'max', 4, ...
                'description', '认知学习因子'), ...
            'c2', struct(...
                'type', 'float', ...
                'default', 1.49445, ...
                'min', 0, ...
                'max', 4, ...
                'description', '社会学习因子'), ...
            'wMin', struct(...
                'type', 'float', ...
                'default', 0.4, ...
                'min', 0, ...
                'max', 1, ...
                'description', '最小惯性权重(线性递减)'), ...
            'wMax', struct(...
                'type', 'float', ...
                'default', 0.9, ...
                'min', 0, ...
                'max', 1, ...
                'description', '最大惯性权重(线性递减)'), ...
            'useLinearW', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否使用线性递减惯性权重'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = PSO(configStruct)
            % PSO 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 30)
            %     - maxIterations: 最大迭代次数 (默认: 500)
            %     - w: 惯性权重 (默认: 0.729)
            %     - c1: 认知学习因子 (默认: 1.49445)
            %     - c2: 社会学习因子 (默认: 1.49445)
            %     - wMin: 最小惯性权重 (默认: 0.4)
            %     - wMax: 最大惯性权重 (默认: 0.9)
            %     - useLinearW: 是否线性递减惯性权重 (默认: true)
            %     - verbose: 是否显示进度 (默认: true)

            if nargin < 1 || isempty(configStruct)
                configStruct = struct();
            end

            obj = obj@BaseAlgorithm(configStruct);
        end

        function initialize(obj, problem)
            % initialize 初始化粒子群
            %
            % 输入参数:
            %   problem - 问题对象，需包含 lb, ub, dim 字段

            lb = problem.lb;
            ub = problem.ub;
            dim = problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;

            obj.positions = Initialization(N, dim, ub, lb);

            vMax = 0.5 * (ub - lb);
            vMin = -vMax;
            obj.velocities = vMin + 2 * vMax .* rand(N, dim);

            obj.pBestPositions = obj.positions;
            obj.pBestFitness = obj.evaluatePopulation(obj.positions);

            [obj.gBestFitness, bestIdx] = min(obj.pBestFitness);
            obj.gBestPosition = obj.positions(bestIdx, :);

            obj.bestFitness = obj.gBestFitness;
            obj.bestSolution = obj.gBestPosition;

            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括速度更新、位置更新、边界处理、适应度评估

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            dim = obj.problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1;

            if obj.config.useLinearW
                w = obj.config.wMax - (obj.config.wMax - obj.config.wMin) * ...
                    (currentIter / MaxIter);
            else
                w = obj.config.w;
            end

            c1 = obj.config.c1;
            c2 = obj.config.c2;

            vMax = 0.5 * (ub - lb);

            for i = 1:N
                r1 = rand(1, dim);
                r2 = rand(1, dim);

                obj.velocities(i, :) = w * obj.velocities(i, :) + ...
                    c1 * r1 .* (obj.pBestPositions(i, :) - obj.positions(i, :)) + ...
                    c2 * r2 .* (obj.gBestPosition - obj.positions(i, :));

                obj.velocities(i, :) = max(obj.velocities(i, :), -vMax);
                obj.velocities(i, :) = min(obj.velocities(i, :), vMax);

                obj.positions(i, :) = obj.positions(i, :) + obj.velocities(i, :);

                obj.positions(i, :) = obj.clampToBounds(obj.positions(i, :), lb, ub);

                fitness = obj.evaluateSolution(obj.positions(i, :));

                if fitness < obj.pBestFitness(i)
                    obj.pBestFitness(i) = fitness;
                    obj.pBestPositions(i, :) = obj.positions(i, :);

                    if fitness < obj.gBestFitness
                        obj.gBestFitness = fitness;
                        obj.gBestPosition = obj.positions(i, :);
                    end
                end
            end

            obj.bestFitness = obj.gBestFitness;
            obj.bestSolution = obj.gBestPosition;
        end

        function tf = shouldStop(obj)
            % shouldStop 判断是否应该停止迭代
            %
            % 输出参数:
            %   tf - true表示停止，false表示继续

            tf = obj.currentIteration >= obj.config.maxIterations;
        end
    end

    methods (Access = protected)
        function validatedConfig = validateConfig(obj, configStruct)
            % validateConfig 验证并规范化配置参数
            %
            % 输入参数:
            %   configStruct - 原始配置结构体
            %
            % 输出参数:
            %   validatedConfig - 验证后的配置结构体

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

            if validatedConfig.wMin > validatedConfig.wMax
                error('PSO:InvalidConfig', ...
                    'wMin (%.2f) must be <= wMax (%.2f)', ...
                    validatedConfig.wMin, validatedConfig.wMax);
            end
        end
    end

    methods (Static)
        function register()
            % register 注册算法到算法注册表
            %
            % 调用此方法后可通过 AlgorithmRegistry.getAlgorithm('PSO') 获取

            AlgorithmRegistry.register('PSO', @PSO);
        end
    end
end
