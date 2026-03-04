classdef DE < BaseAlgorithm
    % DE 差分进化算法 (Differential Evolution)
    %
    % 一种基于种群差分变异的进化算法。通过种群个体间的差分向量
    % 进行变异操作，结合交叉和选择实现优化。
    %
    % 算法流程:
    %   1. 变异: v = x_r1 + F * (x_r2 - x_r3)  (DE/rand/1)
    %   2. 交叉: u = 交叉(x, v)  (二项式交叉)
    %   3. 选择: x_new = argmin(f(x), f(u))
    %
    % 变体策略:
    %   - DE/rand/1: v = x_r1 + F*(x_r2 - x_r3)
    %   - DE/best/1: v = x_best + F*(x_r1 - x_r2)
    %   - DE/rand/2: v = x_r1 + F*(x_r2 - x_r3 + x_r4 - x_r5)
    %   - DE/best/2: v = x_best + F*(x_r1 - x_r2 + x_r3 - x_r4)
    %   - DE/current-to-best/1: v = x_i + F*(x_best - x_i) + F*(x_r1 - x_r2)
    %
    % 参考文献:
    %   R. Storn, K. Price
    %   "Differential Evolution - A Simple and Efficient Heuristic
    %    for Global Optimization over Continuous Spaces"
    %   Journal of Global Optimization, 1997
    %   DOI: 10.1023/A:1008202821328
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 50, 'maxIterations', 500);
    %   de = DE(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = de.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Rainer Storn, Kenneth Price
    % 实现版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        population           % 种群矩阵 (N x Dim)
        fitness              % 适应度向量 (N x 1)
        bestIndex            % 最优个体索引
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 50, ...
                'min', 4, ...
                'max', 10000, ...
                'description', '种群大小(建议为5的倍数)'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'F', struct(...
                'type', 'float', ...
                'default', 0.8, ...
                'min', 0, ...
                'max', 2, ...
                'description', '缩放因子(变异步长)'), ...
            'CR', struct(...
                'type', 'float', ...
                'default', 0.9, ...
                'min', 0, ...
                'max', 1, ...
                'description', '交叉概率'), ...
            'strategy', struct(...
                'type', 'enum', ...
                'options', {{'DE/rand/1', 'DE/best/1', 'DE/rand/2', ...
                             'DE/best/2', 'DE/current-to-best/1'}}, ...
                'default', 'DE/rand/1', ...
                'description', '变异策略'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = DE(configStruct)
            % DE 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 50)
            %     - maxIterations: 最大迭代次数 (默认: 500)
            %     - F: 缩放因子 (默认: 0.8)
            %     - CR: 交叉概率 (默认: 0.9)
            %     - strategy: 变异策略 (默认: 'DE/rand/1')
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

            obj.population = Initialization(N, dim, ub, lb);

            obj.fitness = obj.evaluatePopulation(obj.population);

            [obj.bestFitness, obj.bestIndex] = min(obj.fitness);
            obj.bestSolution = obj.population(obj.bestIndex, :);

            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括变异、交叉、选择三个阶段

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            dim = obj.problem.dim;
            N = obj.config.populationSize;
            F = obj.config.F;
            CR = obj.config.CR;
            strategy = obj.config.strategy;

            for i = 1:N
                mutant = obj.mutation(i, strategy, F);

                trial = obj.crossover(obj.population(i, :), mutant, CR, dim);

                trial = obj.clampToBounds(trial, lb, ub);

                trialFitness = obj.evaluateSolution(trial);

                if trialFitness <= obj.fitness(i)
                    obj.population(i, :) = trial;
                    obj.fitness(i) = trialFitness;

                    if trialFitness < obj.bestFitness
                        obj.bestFitness = trialFitness;
                        obj.bestSolution = trial;
                        obj.bestIndex = i;
                    end
                end
            end
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
        function mutant = mutation(obj, targetIdx, strategy, F)
            % mutation 变异操作
            %
            % 输入参数:
            %   targetIdx - 目标个体索引
            %   strategy - 变异策略
            %   F - 缩放因子
            %
            % 输出参数:
            %   mutant - 变异向量

            N = obj.config.populationSize;
            dim = size(obj.population, 2);

            candidates = setdiff(1:N, targetIdx);

            switch strategy
                case 'DE/rand/1'
                    r = candidates(randperm(length(candidates), 3));
                    mutant = obj.population(r(1), :) + ...
                             F * (obj.population(r(2), :) - obj.population(r(3), :));

                case 'DE/best/1'
                    r = candidates(randperm(length(candidates), 2));
                    mutant = obj.bestSolution + ...
                             F * (obj.population(r(1), :) - obj.population(r(2), :));

                case 'DE/rand/2'
                    r = candidates(randperm(length(candidates), 5));
                    mutant = obj.population(r(1), :) + ...
                             F * (obj.population(r(2), :) - obj.population(r(3), :)) + ...
                             F * (obj.population(r(4), :) - obj.population(r(5), :));

                case 'DE/best/2'
                    r = candidates(randperm(length(candidates), 4));
                    mutant = obj.bestSolution + ...
                             F * (obj.population(r(1), :) - obj.population(r(2), :)) + ...
                             F * (obj.population(r(3), :) - obj.population(r(4), :));

                case 'DE/current-to-best/1'
                    r = candidates(randperm(length(candidates), 2));
                    mutant = obj.population(targetIdx, :) + ...
                             F * (obj.bestSolution - obj.population(targetIdx, :)) + ...
                             F * (obj.population(r(1), :) - obj.population(r(2), :));

                otherwise
                    r = candidates(randperm(length(candidates), 3));
                    mutant = obj.population(r(1), :) + ...
                             F * (obj.population(r(2), :) - obj.population(r(3), :));
            end
        end

        function trial = crossover(obj, target, mutant, CR, dim)
            % crossover 二项式交叉操作
            %
            % 输入参数:
            %   target - 目标向量
            %   mutant - 变异向量
            %   CR - 交叉概率
            %   dim - 问题维度
            %
            % 输出参数:
            %   trial - 试验向量

            trial = target;

            jrand = randi(dim);

            for j = 1:dim
                if rand() < CR || j == jrand
                    trial(j) = mutant(j);
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

            if validatedConfig.populationSize < 4
                error('DE:InvalidConfig', ...
                    'Population size must be at least 4 for DE/rand/1 strategy');
            end
        end
    end

    methods (Static)
        function register()
            % register 注册算法到算法注册表
            %
            % 调用此方法后可通过 AlgorithmRegistry.getAlgorithm('DE') 获取

            AlgorithmRegistry.register('DE', @DE);
        end
    end
end
