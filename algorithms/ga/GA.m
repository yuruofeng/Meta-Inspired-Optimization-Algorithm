classdef GA < BaseAlgorithm
    % GA 遗传算法 (Genetic Algorithm)
    %
    % 一种模拟自然选择和遗传机制的进化算法。通过选择、交叉、变异
    % 操作实现种群的迭代进化。
    %
    % 算法流程:
    %   1. 初始化种群
    %   2. 评估适应度
    %   3. 选择: 优胜劣汰
    %   4. 交叉: 基因重组
    %   5. 变异: 引入多样性
    %   6. 精英保留: 保证最优解不丢失
    %   7. 重复2-6直到终止条件
    %
    % 参考文献:
    %   J. Holland
    %   "Adaptation in Natural and Artificial Systems"
    %   University of Michigan Press, 1975
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 50, 'maxIterations', 500);
    %   ga = GA(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = ga.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 版本: 2.0.0
    % 日期: 2025

    properties (Access = protected)
        population           % 种群矩阵 (N x Dim)
        fitness              % 适应度向量 (N x 1)
        % 可插拔算子
        selectionOperator
        crossoverOperator
        mutationOperator
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 50, ...
                'min', 4, ...
                'max', 10000, ...
                'description', '种群大小'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'mutationRate', struct(...
                'type', 'float', ...
                'default', 0.01, ...
                'min', 0, ...
                'max', 1, ...
                'description', '变异概率'), ...
            'crossoverRate', struct(...
                'type', 'float', ...
                'default', 0.9, ...
                'min', 0, ...
                'max', 1, ...
                'description', '交叉概率'), ...
            'elitismCount', struct(...
                'type', 'integer', ...
                'default', 2, ...
                'min', 0, ...
                'max', 100, ...
                'description', '精英保留数量'), ...
            'selection', struct(...
                'type', 'enum', ...
                'options', {{'tournament', 'roulette'}}, ...
                'default', 'tournament', ...
                'description', '选择算子类型'), ...
            'tournamentSize', struct(...
                'type', 'integer', ...
                'default', 3, ...
                'min', 2, ...
                'max', 20, ...
                'description', '锦标赛大小'), ...
            'crossover', struct(...
                'type', 'enum', ...
                'options', {{'uniform'}}, ...
                'default', 'uniform', ...
                'description', '交叉算子类型'), ...
            'mutation', struct(...
                'type', 'enum', ...
                'options', {{'gaussian'}}, ...
                'default', 'gaussian', ...
                'description', '变异算子类型'), ...
            'sigma', struct(...
                'type', 'float', ...
                'default', 0.1, ...
                'min', 0, ...
                'description', '高斯变异标准差比例'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = GA(configStruct)
            % GA 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 50)
            %     - maxIterations: 最大迭代次数 (默认: 500)
            %     - mutationRate: 变异概率 (默认: 0.01)
            %     - crossoverRate: 交叉概率 (默认: 0.9)
            %     - elitismCount: 精英保留数 (默认: 2)
            %     - selection: 选择类型 (默认: 'tournament')
            %     - tournamentSize: 锦标赛大小 (默认: 3)
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

            % 获取问题参数
            lb = problem.lb;
            ub = problem.ub;
            dim = problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;

            % 初始化种群
            obj.population = Initialization(N, dim, ub, lb);

            % 评估初始种群
            obj.fitness = obj.evaluatePopulation(obj.population);

            % 初始化全局最优
            [obj.bestFitness, bestIdx] = min(obj.fitness);
            obj.bestSolution = obj.population(bestIdx, :);

            % 初始化算子
            obj.initOperators();

            % 预分配收敛曲线
            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括选择、交叉、变异、精英保留

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            N = obj.config.populationSize;
            elitismCount = obj.config.elitismCount;
            currentIter = obj.currentIteration + 1;

            % 创建新种群
            newPopulation = zeros(N, size(obj.population, 2));

            % 精英保留: 直接复制最优的elitismCount个个体
            [~, sortedIndices] = sort(obj.fitness);
            eliteIndices = sortedIndices(1:elitismCount);
            newPopulation(1:elitismCount, :) = obj.population(eliteIndices, :);

            % 选择、交叉、变异生成剩余个体
            for i = (elitismCount + 1):2:N
                % 选择两个父代
                parentIndices = obj.selectionOperator.select(obj.population, obj.fitness, 2);
                parent1 = obj.population(parentIndices(1), :);
                parent2 = obj.population(parentIndices(2), :);

                % 交叉
                [offspring1, offspring2] = obj.crossoverOperator.crossWithRate(parent1, parent2);

                % 变异
                offspring1 = obj.mutationOperator.mutateWithRate(offspring1, lb, ub);
                offspring2 = obj.mutationOperator.mutateWithRate(offspring2, lb, ub);

                % 存储子代
                newPopulation(i, :) = offspring1;
                if i + 1 <= N
                    newPopulation(i + 1, :) = offspring2;
                end
            end

            % 更新种群
            obj.population = newPopulation;

            % 评估新种群
            obj.fitness = obj.evaluatePopulation(obj.population);

            % 更新全局最优
            [currentBestFit, currentBestIdx] = min(obj.fitness);
            if currentBestFit < obj.bestFitness
                obj.bestFitness = currentBestFit;
                obj.bestSolution = obj.population(currentBestIdx, :);
            end

            % 记录收敛曲线
            obj.convergenceCurve(currentIter) = obj.bestFitness;

            % 显示进度
            if obj.config.verbose && mod(currentIter, 50) == 0
                obj.displayProgress(sprintf('Best fitness: %.6e', obj.bestFitness));
            end
        end

        function tf = shouldStop(obj)
            % shouldStop 判断是否停止迭代
            %
            % 输出参数:
            %   tf - true表示停止，false表示继续

            tf = obj.currentIteration >= obj.config.maxIterations;
        end

        function validatedConfig = validateConfig(obj, config)
            % validateConfig 验证并规范化配置参数

            validatedConfig = struct();

            % 种群大小
            if isfield(config, 'populationSize')
                validatedConfig.populationSize = config.populationSize;
            else
                validatedConfig.populationSize = 50;
            end

            if validatedConfig.populationSize < 4
                error('GA:InvalidConfig', 'populationSize must be >= 4');
            end

            % 最大迭代次数
            if isfield(config, 'maxIterations')
                validatedConfig.maxIterations = config.maxIterations;
            else
                validatedConfig.maxIterations = 500;
            end

            if validatedConfig.maxIterations < 1
                error('GA:InvalidConfig', 'maxIterations must be >= 1');
            end

            % 变异概率
            if isfield(config, 'mutationRate')
                validatedConfig.mutationRate = config.mutationRate;
            else
                validatedConfig.mutationRate = 0.01;
            end

            if validatedConfig.mutationRate < 0 || validatedConfig.mutationRate > 1
                error('GA:InvalidConfig', 'mutationRate must be in [0, 1]');
            end

            % 交叉概率
            if isfield(config, 'crossoverRate')
                validatedConfig.crossoverRate = config.crossoverRate;
            else
                validatedConfig.crossoverRate = 0.9;
            end

            if validatedConfig.crossoverRate < 0 || validatedConfig.crossoverRate > 1
                error('GA:InvalidConfig', 'crossoverRate must be in [0, 1]');
            end

            % 精英保留数
            if isfield(config, 'elitismCount')
                validatedConfig.elitismCount = config.elitismCount;
            else
                validatedConfig.elitismCount = 2;
            end

            if validatedConfig.elitismCount < 0
                error('GA:InvalidConfig', 'elitismCount must be >= 0');
            end

            if validatedConfig.elitismCount >= validatedConfig.populationSize
                error('GA:InvalidConfig', 'elitismCount must be < populationSize');
            end

            % 选择类型
            if isfield(config, 'selection')
                validatedConfig.selection = validatestring(config.selection, {'tournament', 'roulette'});
            else
                validatedConfig.selection = 'tournament';
            end

            % 锦标赛大小
            if isfield(config, 'tournamentSize')
                validatedConfig.tournamentSize = config.tournamentSize;
            else
                validatedConfig.tournamentSize = 3;
            end

            % 交叉类型
            if isfield(config, 'crossover')
                validatedConfig.crossover = validatestring(config.crossover, {'uniform'});
            else
                validatedConfig.crossover = 'uniform';
            end

            % 变异类型
            if isfield(config, 'mutation')
                validatedConfig.mutation = validatestring(config.mutation, {'gaussian'});
            else
                validatedConfig.mutation = 'gaussian';
            end

            % 高斯变异参数
            if isfield(config, 'sigma')
                validatedConfig.sigma = config.sigma;
            else
                validatedConfig.sigma = 0.1;
            end

            % 详细输出
            if isfield(config, 'verbose')
                validatedConfig.verbose = config.verbose;
            else
                validatedConfig.verbose = true;
            end
        end
    end

    methods (Access = protected)
        function initOperators(obj)
            % initOperators 初始化算子

            % 选择算子
            switch obj.config.selection
                case 'tournament'
                    obj.selectionOperator = algorithms.ga.operators.TournamentSelection(...
                        obj.config.tournamentSize);
                case 'roulette'
                    obj.selectionOperator = algorithms.ga.operators.RouletteWheelSelection();
                otherwise
                    obj.selectionOperator = algorithms.ga.operators.TournamentSelection(3);
            end

            % 交叉算子
            switch obj.config.crossover
                case 'uniform'
                    obj.crossoverOperator = algorithms.ga.operators.UniformCrossover(...
                        obj.config.crossoverRate);
                otherwise
                    obj.crossoverOperator = algorithms.ga.operators.UniformCrossover();
            end

            % 变异算子
            switch obj.config.mutation
                case 'gaussian'
                    obj.mutationOperator = algorithms.ga.operators.GaussianMutation(...
                        obj.config.mutationRate, obj.config.sigma);
                otherwise
                    obj.mutationOperator = algorithms.ga.operators.GaussianMutation();
            end
        end
    end

    methods (Static)
        function register()
            % register 将GA算法注册到算法注册表
            %
            % 示例:
            %   GA.register();
            %   algClass = AlgorithmRegistry.getAlgorithm('GA');

            AlgorithmRegistry.register('GA', '2.0.0', @GA);
        end
    end
end
