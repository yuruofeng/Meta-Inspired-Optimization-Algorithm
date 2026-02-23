classdef MVO < BaseAlgorithm
    % MVO 多元宇宙优化算法 (Multi-Verse Optimizer)
    %
    % 一种基于多元宇宙理论的元启发式算法。模拟宇宙中的白洞、黑洞和虫洞机制，
    % 通过宇宙间的物质交换和信息传递实现全局搜索和局部开发。
    %
    % 算法机制:
    %   - 白洞: 优秀宇宙向其他宇宙发送物质（探索）
    %   - 黑洞: 劣质宇宙接收来自其他宇宙的物质（开发）
    %   - 虫洞: 所有宇宙通过虫洞与最优宇宙建立连接（局部搜索）
    %
    % 核心概念:
    %   - 膨胀率(Inflation Rate): 宇宙的适应度值
    %   - 虫洞存在概率(WEP): 随迭代线性增加
    %   - 旅行距离率(TDR): 随迭代非线性递减
    %
    % 参考文献:
    %   S. Mirjalili, S. M. Mirjalili, A. Hatamlou
    %   "Multi-Verse Optimizer: a nature-inspired algorithm for global optimization"
    %   Neural Computing and Applications, 2016
    %   DOI: http://dx.doi.org/10.1007/s00521-015-1870-7
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   mvo = MVO(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = mvo.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Seyedali Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2026

    properties (Access = protected)
        universePositions      % 宇宙位置矩阵 (N x Dim)
        bestUniverse           % 最优宇宙位置 (1 x Dim)
        bestUniverseInflationRate  % 最优宇宙膨胀率（适应度）
        WEP_Min                % 最小虫洞存在概率
        WEP_Max                % 最大虫洞存在概率
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '宇宙（种群）个体数量'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'WEP_Min', struct(...
                'type', 'double', ...
                'default', 0.2, ...
                'min', 0, ...
                'max', 1, ...
                'description', '最小虫洞存在概率'), ...
            'WEP_Max', struct(...
                'type', 'double', ...
                'default', 1.0, ...
                'min', 0, ...
                'max', 1, ...
                'description', '最大虫洞存在概率'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = MVO(configStruct)
            % MVO 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 30)
            %     - maxIterations: 最大迭代次数 (默认: 500)
            %     - WEP_Min: 最小虫洞存在概率 (默认: 0.2)
            %     - WEP_Max: 最大虫洞存在概率 (默认: 1.0)
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

            % 初始化宇宙位置
            obj.universePositions = Initialization(N, dim, ub, lb);

            % 初始化最优宇宙
            obj.bestUniverse = zeros(1, dim);
            obj.bestUniverseInflationRate = Inf;

            % 设置虫洞存在概率参数
            obj.WEP_Min = obj.config.WEP_Min;
            obj.WEP_Max = obj.config.WEP_Max;

            % 初始评估
            for i = 1:N
                inflationRate = obj.evaluateSolution(obj.universePositions(i, :));
                if inflationRate < obj.bestUniverseInflationRate
                    obj.bestUniverseInflationRate = inflationRate;
                    obj.bestUniverse = obj.universePositions(i, :);
                end
            end

            % 初始化全局最优
            obj.bestFitness = obj.bestUniverseInflationRate;
            obj.bestSolution = obj.bestUniverse;

            % 预分配收敛曲线
            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括白洞/黑洞交换、虫洞传输、适应度评估

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1;

            % 计算虫洞存在概率 (WEP) - Equation 3.3
            WEP = obj.WEP_Min + currentIter * ((obj.WEP_Max - obj.WEP_Min) / MaxIter);

            % 计算旅行距离率 (TDR) - Equation 3.4
            TDR = 1 - ((currentIter)^(1/6) / (MaxIter)^(1/6));

            % 评估宇宙膨胀率（适应度）并更新最优
            inflationRates = zeros(1, N);
            for i = 1:N
                % 边界约束（使用统一的BoundaryHandler）
                obj.universePositions(i, :) = shared.utils.BoundaryHandler.quickClip(obj.universePositions(i, :), lb, ub);

                % 评估膨胀率
                inflationRates(i) = obj.evaluateSolution(obj.universePositions(i, :));

                % 精英策略：更新最优宇宙
                if inflationRates(i) < obj.bestUniverseInflationRate
                    obj.bestUniverseInflationRate = inflationRates(i);
                    obj.bestUniverse = obj.universePositions(i, :);
                end
            end

            % 排序宇宙
            [sortedInflationRates, sortedIndexes] = sort(inflationRates);
            sortedUniverses = obj.universePositions(sortedIndexes, :);

            % 归一化膨胀率 (NI) - Equation 3.1
            normalizedInflationRates = normr(sortedInflationRates);

            % 保留最优宇宙（精英）
            obj.universePositions(1, :) = sortedUniverses(1, :);

            % 更新宇宙位置
            for i = 2:N  % 从2开始，因为第1个是精英
                blackColorIndex = i;  % 当前宇宙作为黑洞

                for j = 1:size(obj.universePositions, 2)
                    r1 = rand();

                    % 白洞/黑洞机制
                    if r1 < normalizedInflationRates(i)
                        % 轮盘赌选择白洞（发送物质的宇宙）
                        % 注意：对于最小化问题，使用负值进行选择
                        whiteHoleIndex = shared.operators.selection.RouletteWheelSelection.quickSelect(-sortedInflationRates);

                        % 如果选择失败，使用最优宇宙
                        if whiteHoleIndex == -1
                            whiteHoleIndex = 1;
                        end

                        % Equation 3.1: 通过白洞交换物质
                        obj.universePositions(blackColorIndex, j) = sortedUniverses(whiteHoleIndex, j);
                    end

                    % 虫洞机制 - Equation 3.2
                    r2 = rand();
                    if r2 < WEP
                        r3 = rand();
                        if r3 < 0.5
                            % 向最优宇宙的正方向移动
                            if length(lb) == 1
                                % 标量边界
                                obj.universePositions(i, j) = obj.bestUniverse(j) + ...
                                    TDR * ((ub - lb) * rand + lb);
                            else
                                % 向量边界
                                obj.universePositions(i, j) = obj.bestUniverse(j) + ...
                                    TDR * ((ub(j) - lb(j)) * rand + lb(j));
                            end
                        else
                            % 向最优宇宙的负方向移动
                            if length(lb) == 1
                                % 标量边界
                                obj.universePositions(i, j) = obj.bestUniverse(j) - ...
                                    TDR * ((ub - lb) * rand + lb);
                            else
                                % 向量边界
                                obj.universePositions(i, j) = obj.bestUniverse(j) - ...
                                    TDR * ((ub(j) - lb(j)) * rand + lb(j));
                            end
                        end
                    end
                end
            end

            % 更新全局最优
            if obj.bestUniverseInflationRate < obj.bestFitness
                obj.bestFitness = obj.bestUniverseInflationRate;
                obj.bestSolution = obj.bestUniverse;
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
            %
            % 输入参数:
            %   config - 原始配置结构体
            %
            % 输出参数:
            %   validatedConfig - 验证后的配置结构体

            validatedConfig = struct();

            % 种群大小
            if isfield(config, 'populationSize')
                validatedConfig.populationSize = config.populationSize;
            else
                validatedConfig.populationSize = 30;
            end

            if validatedConfig.populationSize < 10
                error('MVO:InvalidConfig', 'populationSize must be >= 10');
            end

            % 最大迭代次数
            if isfield(config, 'maxIterations')
                validatedConfig.maxIterations = config.maxIterations;
            else
                validatedConfig.maxIterations = 500;
            end

            if validatedConfig.maxIterations < 1
                error('MVO:InvalidConfig', 'maxIterations must be >= 1');
            end

            % 最小虫洞存在概率
            if isfield(config, 'WEP_Min')
                validatedConfig.WEP_Min = config.WEP_Min;
            else
                validatedConfig.WEP_Min = 0.2;
            end

            if validatedConfig.WEP_Min < 0 || validatedConfig.WEP_Min > 1
                error('MVO:InvalidConfig', 'WEP_Min must be in [0, 1]');
            end

            % 最大虫洞存在概率
            if isfield(config, 'WEP_Max')
                validatedConfig.WEP_Max = config.WEP_Max;
            else
                validatedConfig.WEP_Max = 1.0;
            end

            if validatedConfig.WEP_Max < 0 || validatedConfig.WEP_Max > 1
                error('MVO:InvalidConfig', 'WEP_Max must be in [0, 1]');
            end

            if validatedConfig.WEP_Max < validatedConfig.WEP_Min
                error('MVO:InvalidConfig', 'WEP_Max must be >= WEP_Min');
            end

            % 详细输出
            if isfield(config, 'verbose')
                validatedConfig.verbose = config.verbose;
            else
                validatedConfig.verbose = true;
            end
        end
    end

    methods (Static)
        function register()
            % register 将MVO算法注册到算法注册表
            %
            % 示例:
            %   MVO.register();
            %   algClass = AlgorithmRegistry.getAlgorithm('MVO');

            AlgorithmRegistry.register('MVO', '2.0.0', @MVO);
        end
    end
end
