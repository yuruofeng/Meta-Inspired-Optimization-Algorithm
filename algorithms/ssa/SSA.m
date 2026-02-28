classdef SSA < BaseAlgorithm
    % SSA 樽海鞘群算法 (Salp Swarm Algorithm)
    %
    % 一种模拟樽海鞘群体行为的元启发式算法。樽海鞘在海洋中形成链状群体，
    % 通过领导-追随者模式进行移动。算法将种群分为领导者和追随者，
    % 领导者负责搜索食物源，追随者跟随前一个个体移动。
    %
    % 算法机制:
    %   - 领导者更新: 使用c1参数控制探索和开发
    %     X(j) = Food(j) + c1*((ub(j)-lb(j))*c2+lb(j)) 或
    %     X(j) = Food(j) - c1*((ub(j)-lb(j))*c2+lb(j))
    %   - 追随者更新: X(i,j) = (X(i,j) + X(i-1,j)) / 2
    %   - c1: 控制参数，随迭代指数递减，平衡探索和开发
    %   - c2, c3: [0,1]随机数，决定移动方向和步长
    %
    % 参考文献:
    %   S. Mirjalili, A.H. Gandomi, S.Z. Mirjalili, S. Saremi, H. Faris, S.M. Mirjalili
    %   "Salp Swarm Algorithm: A bio-inspired optimizer for engineering design problems"
    %   Advances in Engineering Software, 2017
    %   DOI: http://dx.doi.org/10.1016/j.advengsoft.2017.07.002
    %
    % 时间复杂度: O(MaxIter x N x Dim)
    % 空间复杂度: O(N x Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   ssa = SSA(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = ssa.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Seyedali Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2026

    properties (Access = protected)
        salpPositions       % 樽海鞘位置矩阵 (N x Dim)
        foodPosition        % 食物位置（最优解） (1 x Dim)
        foodFitness         % 食物适应度
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '樽海鞘种群数量'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = SSA(configStruct)
            % SSA 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 30)
            %     - maxIterations: 最大迭代次数 (默认: 500)
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

            obj.salpPositions = Initialization(N, dim, ub, lb);

            obj.foodPosition = zeros(1, dim);
            obj.foodFitness = Inf;

            fitness = obj.evaluatePopulation(obj.salpPositions);

            [sortedFitness, sortedIndices] = sort(fitness);
            obj.foodFitness = sortedFitness(1);
            obj.foodPosition = obj.salpPositions(sortedIndices(1), :);

            obj.bestFitness = obj.foodFitness;
            obj.bestSolution = obj.foodPosition;

            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括领导者更新、追随者更新、适应度评估

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1;
            dim = size(obj.salpPositions, 2);

            c1 = 2 * exp(-((4 * currentIter / MaxIter) ^ 2));

            for i = 1:N
                for j = 1:dim
                    c2 = rand();
                    c3 = rand();

                    if i <= N / 2
                        if c3 < 0.5
                            obj.salpPositions(i, j) = obj.foodPosition(j) + ...
                                c1 * ((ub(j) - lb(j)) * c2 + lb(j));
                        else
                            obj.salpPositions(i, j) = obj.foodPosition(j) - ...
                                c1 * ((ub(j) - lb(j)) * c2 + lb(j));
                        end
                    else
                        obj.salpPositions(i, j) = (obj.salpPositions(i, j) + ...
                            obj.salpPositions(i - 1, j)) / 2;
                    end
                end

                obj.salpPositions(i, :) = shared.utils.BoundaryHandler.quickClip(...
                    obj.salpPositions(i, :), lb, ub);
            end

            for i = 1:N
                fitness = obj.evaluateSolution(obj.salpPositions(i, :));

                if fitness < obj.foodFitness
                    obj.foodFitness = fitness;
                    obj.foodPosition = obj.salpPositions(i, :);
                end
            end

            if obj.foodFitness < obj.bestFitness
                obj.bestFitness = obj.foodFitness;
                obj.bestSolution = obj.foodPosition;
            end

            obj.convergenceCurve(currentIter) = obj.bestFitness;

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
            %
            % 输入参数:
            %   config - 原始配置结构体
            %
            % 输出参数:
            %   validatedConfig - 验证后的配置结构体

            validatedConfig = struct();

            if isfield(config, 'populationSize')
                validatedConfig.populationSize = config.populationSize;
            else
                validatedConfig.populationSize = 30;
            end

            if validatedConfig.populationSize < 10
                error('SSA:InvalidConfig', 'populationSize must be >= 10');
            end

            if isfield(config, 'maxIterations')
                validatedConfig.maxIterations = config.maxIterations;
            else
                validatedConfig.maxIterations = 500;
            end

            if validatedConfig.maxIterations < 1
                error('SSA:InvalidConfig', 'maxIterations must be >= 1');
            end

            if isfield(config, 'verbose')
                validatedConfig.verbose = config.verbose;
            else
                validatedConfig.verbose = true;
            end
        end
    end

    methods (Static)
        function register()
            % register 将SSA算法注册到算法注册表
            %
            % 示例:
            %   SSA.register();
            %   algClass = AlgorithmRegistry.getAlgorithm('SSA');

            AlgorithmRegistry.register('SSA', '2.0.0', @SSA);
        end
    end
end
