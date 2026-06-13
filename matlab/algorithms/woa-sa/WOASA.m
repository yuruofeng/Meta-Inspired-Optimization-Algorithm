classdef WOASA < BaseAlgorithm
    % WOASA 混合鲸鱼优化算法与模拟退火 (Whale Optimization Algorithm with Simulated Annealing)
    %
    % 一种用于特征选择/二进制优化的混合元启发式算法。在标准WOA基础上
    % 引入锦标赛选择、均匀变异、均匀交叉和模拟退火局部搜索。
    %
    % 算法特点:
    %   - 二进制编码: 位置为0/1向量
    %   - 锦标赛选择: 替代随机选择，提高选择压力
    %   - 均匀变异/交叉: 用于位置更新
    %   - SA局部搜索: 每次迭代后对领导者进行局部搜索
    %
    % 参考文献:
    %   M. Mafarja and S. Mirjalili
    %   "Hybrid Whale Optimization Algorithm with Simulated Annealing
    %    for Feature Selection"
    %   Neurocomputing, 2017
    %   DOI: 10.1016/j.neucom.2017.04.053
    %
    % 时间复杂度: O(MaxIter × N × (Dim + SA_Iterations))
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 100);
    %   woasa = WOASA(config);
    %   problem = struct('evaluate', @myFitness, 'lb', 0, 'ub', 1, 'dim', 100);
    %   result = woasa.run(problem);
    %   fprintf('Best fitness: %.6f\n', result.bestFitness);
    %
    % 原始作者: Majdi Mafarja, Seyedali Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 种群位置矩阵 (N x Dim, logical)
        leaderPosition       % 领导者位置 (最优解, 1 x Dim, logical)
        leaderFitness        % 领导者适应度
        whaleFitness         % 所有鲸鱼的适应度缓存
        % 算子实例
        tournamentSelector
        mutator
        crossover
        saLocalSearch
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 5, ...
                'max', 10000, ...
                'description', '鲸鱼种群个体数量'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 100, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'b', struct(...
                'type', 'float', ...
                'default', 1, ...
                'min', 0, ...
                'max', 10, ...
                'description', '螺旋形状参数'), ...
            'tournamentParameter', struct(...
                'type', 'float', ...
                'default', 0.5, ...
                'min', 0, ...
                'max', 1, ...
                'description', '锦标赛选择参数'), ...
            'saMaxIterations', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 1, ...
                'max', 1000, ...
                'description', 'SA局部搜索最大迭代次数'), ...
            'saMaxSubIterations', struct(...
                'type', 'integer', ...
                'default', 10, ...
                'min', 1, ...
                'max', 100, ...
                'description', 'SA每温度子迭代次数'), ...
            'saInitialTemp', struct(...
                'type', 'float', ...
                'default', 0.1, ...
                'min', 0, ...
                'description', 'SA初始温度'), ...
            'saCoolingRate', struct(...
                'type', 'float', ...
                'default', 0.99, ...
                'min', 0, ...
                'max', 1, ...
                'description', 'SA冷却率'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = WOASA(configStruct)
            % WOASA 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 30)
            %     - maxIterations: 最大迭代次数 (默认: 100)
            %     - b: 螺旋参数 (默认: 1)
            %     - tournamentParameter: 锦标赛参数 (默认: 0.5)
            %     - saMaxIterations: SA最大迭代 (默认: 30)
            %     - saMaxSubIterations: SA子迭代 (默认: 10)
            %     - saInitialTemp: SA初始温度 (默认: 0.1)
            %     - saCoolingRate: SA冷却率 (默认: 0.99)
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
            %   problem - 问题对象，需包含 lb, ub, dim, evaluate 字段

            % 获取问题参数
            lb = problem.lb;
            ub = problem.ub;
            dim = problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;

            % 初始化种群 (二进制)
            continuousPositions = Initialization(N, dim, ub, lb);
            obj.positions = continuousPositions > 0.5;

            % 初始化领导者
            obj.leaderPosition = zeros(1, dim);
            obj.leaderFitness = Inf;
            obj.whaleFitness = zeros(1, N);

            % 初始评估
            for i = 1:N
                obj.whaleFitness(i) = obj.evaluateSolution(obj.positions(i, :));
            end

            % 找出最优作为领导者
            [~, bestIdx] = min(obj.whaleFitness);
            obj.leaderFitness = obj.whaleFitness(bestIdx);
            obj.leaderPosition = obj.positions(bestIdx, :);

            % 初始化全局最优
            obj.bestFitness = obj.leaderFitness;
            obj.bestSolution = obj.leaderPosition;

            % 初始化算子
            obj.tournamentSelector = TournamentSelection(obj.config.tournamentParameter);
            obj.mutator = UniformMutation();
            obj.crossover = UniformCrossover();

            % 初始化SA局部搜索
            obj.saLocalSearch = SALocalSearch(...
                'objectiveFunction', @obj.problem.evaluate, ...
                'maxIterations', obj.config.saMaxIterations, ...
                'maxSubIterations', obj.config.saMaxSubIterations, ...
                'initialTemp', obj.config.saInitialTemp, ...
                'coolingRate', obj.config.saCoolingRate, ...
                'problemDim', dim, ...
                'mainMaxIterations', MaxIter);

            % 预分配收敛曲线
            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括适应度评估、领导者更新、位置更新、SA局部搜索

            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            dim = size(obj.positions, 2);
            currentIter = obj.currentIteration + 1;

            % 评估适应度并更新领导者
            for i = 1:N
                fitness = obj.evaluateSolution(obj.positions(i, :));
                obj.whaleFitness(i) = fitness;

                if fitness < obj.leaderFitness
                    obj.leaderFitness = fitness;
                    obj.leaderPosition = obj.positions(i, :);
                end
            end

            % 计算衰减参数 a (从2线性递减到0)
            a = 2 - currentIter * (2 / MaxIter);
            a2 = -1 + currentIter * ((-1) / MaxIter);

            b = obj.config.b;
            l = (a2 - 1) * rand + 1;
            p = rand();

            % 更新所有个体位置
            for i = 1:N
                if p < 0.5
                    if abs(A) >= 1
                        % 随机搜索阶段 (使用锦标赛选择)
                        randLeaderIdx = obj.tournamentSelector.select(1 ./ obj.whaleFitness);
                        X_rand = obj.positions(randLeaderIdx, :);

                        % 变异和交叉
                        D_X_rand = obj.mutator.mute(X_rand, currentIter, MaxIter);
                        RE = obj.mutator.mute(obj.positions(i, :), currentIter, MaxIter);
                        obj.positions(i, :) = obj.crossover.cross(D_X_rand, RE);

                        % SA局部搜索 (可选，较耗时)
                        % obj.positions(i, :) = obj.saLocalSearch.search(X_rand, obj.whaleFitness(randLeaderIdx), currentIter);
                    else
                        % 包围猎物阶段 (使用变异和交叉)
                        D_Leader = obj.mutator.mute(obj.leaderPosition, currentIter, MaxIter);
                        obj.positions(i, :) = obj.crossover.cross(obj.leaderPosition, D_Leader);
                    end
                else
                    % 螺旋更新阶段 (对二进制问题可能需要特殊处理)
                    distance2Leader = abs(obj.leaderPosition - obj.positions(i, :));
                    % 将连续值转换为二进制
                    continuousPos = double(distance2Leader) * exp(b * l) * cos(l * 2 * pi) + double(obj.leaderPosition);
                    obj.positions(i, :) = continuousPos > 0.5;
                end
            end

            % 更新适应度缓存
            for i = 1:N
                obj.whaleFitness(i) = obj.problem.evaluate(obj.positions(i, :));
            end

            % SA局部搜索对领导者进行优化
            [obj.leaderPosition, obj.leaderFitness] = obj.saLocalSearch.search(...
                obj.leaderPosition, obj.leaderFitness, currentIter);

            % 更新全局最优
            if obj.leaderFitness < obj.bestFitness
                obj.bestFitness = obj.leaderFitness;
                obj.bestSolution = obj.leaderPosition;
            end

            % 记录收敛曲线
            obj.convergenceCurve(currentIter) = obj.bestFitness;

            % 显示进度
            if obj.config.verbose && mod(currentIter, 10) == 0
                obj.displayProgress(sprintf('Best fitness: %.6f, Features: %d', ...
                    obj.bestFitness, sum(obj.bestSolution)));
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

            validatedConfig = BaseAlgorithm.validateFromSchema(config, obj.PARAM_SCHEMA);
            
            if validatedConfig.tournamentParameter < 0 || validatedConfig.tournamentParameter > 1
                error('WOASA:InvalidConfig', 'tournamentParameter must be in [0, 1]');
            end
            if validatedConfig.saCoolingRate <= 0 || validatedConfig.saCoolingRate > 1
                error('WOASA:InvalidConfig', 'saCoolingRate must be in (0, 1]');
            end
        end
    end

    methods (Static)
        function register()
            % register 将WOASA算法注册到算法注册表
            %
            % 示例:
            %   WOASA.register();
            %   algClass = AlgorithmRegistry.getAlgorithm('WOASA');

            AlgorithmRegistry.register('WOASA', '2.0.0', @WOASA);
        end
    end
end
