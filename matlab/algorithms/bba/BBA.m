classdef BBA < BaseAlgorithm
    % BBA 二进制蝙蝠算法 (Binary Bat Algorithm)
    %
    % 一种基于蝙蝠回声定位行为的二进制元启发式算法。使用V型传递函数
    % 将连续速度转换为二进制位置更新的概率。
    %
    % 算法特点:
    %   - 频率调节: 控制搜索步长
    %   - V型传递函数: 将速度转换为翻转概率
    %   - 脉冲率机制: 以一定概率选择当前最优
    %   - 响度机制: 控制是否接受新解
    %
    % 参考文献:
    %   S. Mirjalili, S. M. Mirjalili, X. Yang
    %   "Binary Bat Algorithm"
    %   Neural Computing and Applications, 2014
    %   DOI: 10.1007/s00521-013-1525-5
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 20, 'maxIterations', 500);
    %   bba = algorithms.bba.BBA(config);
    %   problem = struct('evaluate', @myBinaryFitness, 'lb', 0, 'ub', 1, 'dim', 50);
    %   result = bba.run(problem);
    %
    % 原始作者: Seyedali Mirjalili, Xin-She Yang
    % 重构版本: 2.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 二进制位置矩阵 (N x Dim, logical)
        velocities           % 连续速度矩阵 (N x Dim, double)
        frequencies          % 频率向量 (N x 1)
        tempPositions        % 临时位置矩阵 (用于更新)
        bestPosition         % 全局最优位置 (1 x Dim, logical)
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 20, ...
                'min', 5, ...
                'max', 10000, ...
                'description', '蝙蝠种群大小'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'Qmin', struct(...
                'type', 'float', ...
                'default', 0, ...
                'description', '最小频率'), ...
            'Qmax', struct(...
                'type', 'float', ...
                'default', 2, ...
                'description', '最大频率'), ...
            'loudness', struct(...
                'type', 'float', ...
                'default', 0.5, ...
                'min', 0, ...
                'max', 1, ...
                'description', '响度 (A)'), ...
            'pulseRate', struct(...
                'type', 'float', ...
                'default', 0.5, ...
                'min', 0, ...
                'max', 1, ...
                'description', '脉冲率 (r)'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = BBA(configStruct)
            % BBA 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 20)
            %     - maxIterations: 最大迭代次数 (默认: 500)
            %     - Qmin, Qmax: 频率范围 (默认: 0, 2)
            %     - loudness: 响度 (默认: 0.5)
            %     - pulseRate: 脉冲率 (默认: 0.5)
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
            %   problem - 问题对象，需包含 dim, evaluate 字段

            dim = problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;

            % 初始化二进制位置 (随机0/1)
            obj.positions = rand(N, dim) > 0.5;

            % 初始化速度和频率
            obj.velocities = zeros(N, dim);
            obj.frequencies = zeros(N, 1);

            % 初始化临时位置
            obj.tempPositions = obj.positions;

            % 初始化最优
            obj.bestPosition = zeros(1, dim);
            obj.bestFitness = Inf;

            % 评估初始种群
            fitness = obj.evaluatePopulation(obj.positions);

            % 找出最优
            [obj.bestFitness, bestIdx] = min(fitness);
            obj.bestPosition = obj.positions(bestIdx, :);

            % 初始化全局最优
            obj.bestSolution = obj.bestPosition;
            obj.bestFitness = obj.bestFitness;

            % 预分配收敛曲线
            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括频率更新、速度更新、V型传递函数、位置更新

            N = obj.config.populationSize;
            dim = size(obj.positions, 2);
            A = obj.config.loudness;
            r = obj.config.pulseRate;
            Qmin = obj.config.Qmin;
            Qmax = obj.config.Qmax;
            currentIter = obj.currentIteration + 1;

            % 遍历所有蝙蝠
            for i = 1:N
                % 更新频率 (Eq. 3)
                obj.frequencies(i) = Qmin + (Qmax - Qmin) * rand();

                % 更新速度和位置
                for j = 1:dim
                    % 速度更新 (Eq. 1)
                    obj.velocities(i, j) = obj.velocities(i, j) + ...
                        (obj.positions(i, j) - obj.bestPosition(j)) * obj.frequencies(i);

                    % V型传递函数 (Eq. 9)
                    V_shaped = abs((2 / pi) * atan((pi / 2) * obj.velocities(i, j)));

                    % 位置更新 (Eq. 10)
                    if rand < V_shaped
                        obj.tempPositions(i, j) = ~obj.positions(i, j);
                    else
                        obj.tempPositions(i, j) = obj.positions(i, j);
                    end

                    % 脉冲率机制
                    if rand > r
                        obj.tempPositions(i, j) = obj.bestPosition(j);
                    end
                end

                % 评估新解
                newFitness = obj.evaluateSolution(obj.tempPositions(i, :));

                % 接受准则 (Eq. 11)
                if (newFitness <= obj.problem.evaluate(obj.positions(i, :))) && (rand < A)
                    obj.positions(i, :) = obj.tempPositions(i, :);
                end

                % 更新全局最优
                if newFitness <= obj.bestFitness
                    obj.bestPosition = obj.tempPositions(i, :);
                    obj.bestFitness = newFitness;
                end
            end

            % 更新全局最优
            if obj.bestFitness < obj.bestFitness
                obj.bestSolution = obj.bestPosition;
                obj.bestFitness = obj.bestFitness;
            end

            % 记录收敛曲线
            obj.convergenceCurve(currentIter) = obj.bestFitness;

            % 显示进度
            if obj.config.verbose && mod(currentIter, 50) == 0
                obj.displayProgress(sprintf('Best fitness: %.6f, Ones: %d', ...
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
            
            if validatedConfig.loudness < 0 || validatedConfig.loudness > 1
                error('BBA:InvalidConfig', 'loudness must be in [0, 1]');
            end
            if validatedConfig.pulseRate < 0 || validatedConfig.pulseRate > 1
                error('BBA:InvalidConfig', 'pulseRate must be in [0, 1]');
            end
        end
    end

    methods (Static)
        function register()
            % register 将BBA算法注册到算法注册表
            %
            % 示例:
            %   BBA.register();
            %   algClass = AlgorithmRegistry.getAlgorithm('BBA');

            AlgorithmRegistry.register('BBA', '2.0.0', @BBA);
        end
    end
end
