classdef ABC < BaseAlgorithm
    % ABC 人工蜂群算法 (Artificial Bee Colony)
    %
    % 一种模拟蜜蜂采蜜行为的群体智能算法。蜜蜂分为雇佣蜂、观察蜂
    % 和侦查蜂三类，通过协作完成最优蜜源（最优解）的搜索。
    %
    % 算法阶段:
    %   1. 雇佣蜂阶段: 在当前蜜源附近搜索新蜜源
    %   2. 观察蜂阶段: 根据蜜源质量概率选择蜜源进行搜索
    %   3. 侦查蜂阶段: 放弃搜索次数超限的蜜源，随机生成新蜜源
    %
    % 位置更新公式:
    %   v_ij = x_ij + phi_ij * (x_ij - x_kj)
    %   其中 phi_ij ∈ [-1, 1], k ≠ i
    %
    % 参考文献:
    %   D. Karaboga
    %   "An Idea Based on Honey Bee Swarm for Numerical Optimization"
    %   Technical Report-TR06, Erciyes University, 2005
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   abc = ABC(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = abc.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Dervis Karaboga
    % 实现版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        foods               % 蜜源位置矩阵 (N x Dim)
        fitness             % 蜜源适应度向量 (N x 1)
        trial               % 搜索失败计数器 (N x 1)
        prob                % 选择概率 (N x 1)
        bestFood            % 最优蜜源位置 (1 x Dim)
        bestFitness         % 最优蜜源适应度
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 5, ...
                'max', 10000, ...
                'description', '蜜源数量(雇佣蜂数量)'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'limit', struct(...
                'type', 'integer', ...
                'default', 100, ...
                'min', 1, ...
                'max', 10000, ...
                'description', '放弃蜜源阈值'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = ABC(configStruct)
            % ABC 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 30)
            %     - maxIterations: 最大迭代次数 (默认: 500)
            %     - limit: 放弃蜜源阈值 (默认: 100)
            %     - verbose: 是否显示进度 (默认: true)

            if nargin < 1 || isempty(configStruct)
                configStruct = struct();
            end

            obj = obj@BaseAlgorithm(configStruct);
        end

        function initialize(obj, problem)
            % initialize 初始化种群
            %
            % 输入参数:
            %   problem - 问题对象，需包含 lb, ub, dim 字段

            lb = problem.lb;
            ub = problem.ub;
            dim = problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;

            obj.foods = Initialization(N, dim, ub, lb);

            obj.fitness = obj.evaluatePopulation(obj.foods);

            obj.trial = zeros(N, 1);

            obj.prob = zeros(N, 1);

            [obj.bestFitness, bestIdx] = min(obj.fitness);
            obj.bestFood = obj.foods(bestIdx, :);

            obj.bestSolution = obj.bestFood;
            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括雇佣蜂阶段、观察蜂阶段和侦查蜂阶段

            N = obj.config.populationSize;
            dim = size(obj.foods, 2);
            lb = obj.problem.lb;
            ub = obj.problem.ub;

            obj.employedBeePhase(N, dim, lb, ub);

            obj.calculateProbabilities(N);

            obj.onlookerBeePhase(N, dim, lb, ub);

            obj.scoutBeePhase(N, dim, lb, ub);

            obj.bestSolution = obj.bestFood;
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
        function employedBeePhase(obj, N, dim, lb, ub)
            % employedBeePhase 雇佣蜂阶段
            %
            % 每只雇佣蜂在对应蜜源附近搜索新蜜源
            %
            % 输入参数:
            %   N - 蜜源数量
            %   dim - 问题维度
            %   lb - 下界
            %   ub - 上界

            for i = 1:N
                k = randi(N);
                while k == i
                    k = randi(N);
                end

                phi = -1 + 2 * rand(1, dim);

                newFood = obj.foods(i, :) + phi .* (obj.foods(i, :) - obj.foods(k, :));

                newFood = obj.clampToBounds(newFood, lb, ub);

                newFitness = obj.evaluateSolution(newFood);

                if newFitness < obj.fitness(i)
                    obj.foods(i, :) = newFood;
                    obj.fitness(i) = newFitness;
                    obj.trial(i) = 0;

                    if newFitness < obj.bestFitness
                        obj.bestFitness = newFitness;
                        obj.bestFood = newFood;
                    end
                else
                    obj.trial(i) = obj.trial(i) + 1;
                end
            end
        end

        function calculateProbabilities(obj, ~)
            % calculateProbabilities 计算蜜源选择概率
            %
            % 基于适应度值计算各蜜源被观察蜂选择的概率

            fitValues = obj.fitness;
            fitValues(fitValues < 0) = 1 + abs(fitValues(fitValues < 0));
            fitValues(fitValues >= 0) = 1 ./ (1 + fitValues(fitValues >= 0));

            obj.prob = fitValues / sum(fitValues);
        end

        function onlookerBeePhase(obj, N, dim, lb, ub)
            % onlookerBeePhase 观察蜂阶段
            %
            % 观察蜂根据概率选择蜜源进行搜索
            %
            % 输入参数:
            %   N - 蜜源数量
            %   dim - 问题维度
            %   lb - 下界
            %   ub - 上界

            i = 1;
            t = 0;

            while t < N
                if rand() < obj.prob(i)
                    t = t + 1;

                    k = randi(N);
                    while k == i
                        k = randi(N);
                    end

                    phi = -1 + 2 * rand(1, dim);

                    newFood = obj.foods(i, :) + phi .* (obj.foods(i, :) - obj.foods(k, :));

                    newFood = obj.clampToBounds(newFood, lb, ub);

                    newFitness = obj.evaluateSolution(newFood);

                    if newFitness < obj.fitness(i)
                        obj.foods(i, :) = newFood;
                        obj.fitness(i) = newFitness;
                        obj.trial(i) = 0;

                        if newFitness < obj.bestFitness
                            obj.bestFitness = newFitness;
                            obj.bestFood = newFood;
                        end
                    else
                        obj.trial(i) = obj.trial(i) + 1;
                    end
                end

                i = i + 1;
                if i > N
                    i = 1;
                end
            end
        end

        function scoutBeePhase(obj, ~, dim, lb, ub)
            % scoutBeePhase 侦查蜂阶段
            %
            % 放弃搜索次数超限的蜜源，随机生成新蜜源
            %
            % 输入参数:
            %   dim - 问题维度
            %   lb - 下界
            %   ub - 上界

            limit = obj.config.limit;

            [~, maxTrialIdx] = max(obj.trial);

            if obj.trial(maxTrialIdx) >= limit
                obj.foods(maxTrialIdx, :) = lb + rand(1, dim) .* (ub - lb);
                obj.fitness(maxTrialIdx) = obj.evaluateSolution(obj.foods(maxTrialIdx, :));
                obj.trial(maxTrialIdx) = 0;

                if obj.fitness(maxTrialIdx) < obj.bestFitness
                    obj.bestFitness = obj.fitness(maxTrialIdx);
                    obj.bestFood = obj.foods(maxTrialIdx, :);
                end
            end
        end

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

            if validatedConfig.limit < 1
                error('ABC:InvalidConfig', ...
                    'Limit must be at least 1');
            end
        end
    end

    methods (Static)
        function register()
            % register 注册算法到算法注册表
            %
            % 调用此方法后可通过 AlgorithmRegistry.getAlgorithm('ABC') 获取

            AlgorithmRegistry.register('ABC', @ABC);
        end
    end
end
