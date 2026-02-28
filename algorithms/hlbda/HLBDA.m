classdef HLBDA < BaseAlgorithm
    % HLBDA 超学习二进制蜻蜓算法 (Hyper Learning Binary Dragonfly Algorithm)
    %
    % 一种改进的二进制蜻蜓算法，专门用于特征选择问题。通过引入
    % 超学习机制增强算法的搜索能力，结合个人学习和全局学习策略。
    %
    % 算法特点:
    %   - 二进制编码：适用于离散优化和特征选择
    %   - 五种行为模式：分离、对齐、内聚、吸引、躲避
    %   - 超学习机制：融合个人最优和全局最优学习
    %   - 传递函数：将连续速度转换为二进制位置更新
    %
    % 参考文献:
    %   改进的二进制蜻蜓算法用于特征选择
    %
    % 时间复杂度: O(MaxIter × N^2 × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 100);
    %   hlbda = HLBDA(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = hlbda.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: 特征选择算法研究者
    % 重构版本: 2.0.0
    % 日期: 2026

    properties (Access = protected)
        positions            % 位置矩阵 (N x Dim) - 二进制
        deltaPositions       % 速度/位移向量 (N x Dim)
        pBestPositions       % 个人最优位置 (N x Dim)
        pBestFitness         % 个人最优适应度 (N x 1)
        gBestPosition        % 全局最优位置 (1 x Dim)
        gBestFitness         % 全局最优适应度
        worstPosition        % 最差位置 (1 x Dim)
        worstFitness         % 最差适应度
        Dmax                 % 最大位移
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 10, ...
                'min', 5, ...
                'max', 10000, ...
                'description', '蜻蜓种群个体数量'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 100, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'pp', struct(...
                'type', 'double', ...
                'default', 0.4, ...
                'min', 0, ...
                'max', 1, ...
                'description', '个人学习概率'), ...
            'pg', struct(...
                'type', 'double', ...
                'default', 0.7, ...
                'min', 0, ...
                'max', 1, ...
                'description', '全局学习概率'), ...
            'Dmax', struct(...
                'type', 'double', ...
                'default', 6, ...
                'min', 1, ...
                'max', 20, ...
                'description', '最大位移'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = HLBDA(configStruct)
            % HLBDA 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 10)
            %     - maxIterations: 最大迭代次数 (默认: 100)
            %     - pp: 个人学习概率 (默认: 0.4)
            %     - pg: 全局学习概率 (默认: 0.7)
            %     - Dmax: 最大位移 (默认: 6)
            %     - verbose: 是否显示进度 (默认: true)

            if nargin < 1 || isempty(configStruct)
                configStruct = struct();
            end

            obj = obj@BaseAlgorithm(configStruct);
            obj.Dmax = obj.config.Dmax;
        end

        function initialize(obj, problem)
            % initialize 初始化种群
            %
            % 输入参数:
            %   problem - 问题对象，需包含 lb, ub, dim 字段

            dim = problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;

            obj.positions = round(rand(N, dim));

            obj.deltaPositions = zeros(N, dim);

            obj.pBestPositions = obj.positions;
            obj.pBestFitness = Inf * ones(N, 1);

            obj.gBestPosition = zeros(1, dim);
            obj.gBestFitness = Inf;

            obj.worstPosition = zeros(1, dim);
            obj.worstFitness = -Inf;

            fitness = obj.evaluatePopulation(obj.positions);

            for i = 1:N
                obj.pBestFitness(i) = fitness(i);
                obj.pBestPositions(i, :) = obj.positions(i, :);

                if fitness(i) < obj.gBestFitness
                    obj.gBestFitness = fitness(i);
                    obj.gBestPosition = obj.positions(i, :);
                end

                if fitness(i) > obj.worstFitness
                    obj.worstFitness = fitness(i);
                    obj.worstPosition = obj.positions(i, :);
                end
            end

            obj.bestFitness = obj.gBestFitness;
            obj.bestSolution = obj.gBestPosition;

            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括行为计算、速度更新、二进制位置更新

            N = obj.config.populationSize;
            dim = size(obj.positions, 2);
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1;

            fitness = obj.evaluatePopulation(obj.positions);

            for i = 1:N
                if fitness(i) < obj.pBestFitness(i)
                    obj.pBestFitness(i) = fitness(i);
                    obj.pBestPositions(i, :) = obj.positions(i, :);
                end

                if fitness(i) < obj.gBestFitness
                    obj.gBestFitness = fitness(i);
                    obj.gBestPosition = obj.positions(i, :);
                end

                if fitness(i) > obj.worstFitness
                    obj.worstFitness = fitness(i);
                    obj.worstPosition = obj.positions(i, :);
                end
            end

            w = 0.9 - currentIter * ((0.9 - 0.4) / MaxIter);
            rate = 0.1 - currentIter * (0.1 / (MaxIter / 2));
            if rate < 0
                rate = 0;
            end

            s = 2 * rand() * rate;
            a = 2 * rand() * rate;
            c = 2 * rand() * rate;
            f = 2 * rand();
            e = rate;

            positionsNew = zeros(N, dim);

            for i = 1:N
                S = zeros(1, dim);
                A = zeros(1, dim);
                C = zeros(1, dim);

                neighborCount = 0;
                for j = 1:N
                    if i ~= j
                        neighborCount = neighborCount + 1;
                        S = S - (obj.positions(i, :) - obj.positions(j, :));
                        A = A + obj.deltaPositions(j, :);
                        C = C + obj.positions(j, :);
                    end
                end

                if neighborCount > 0
                    A = A / neighborCount;
                    C = C / neighborCount - obj.positions(i, :);
                end

                F = ((obj.pBestPositions(i, :) - obj.positions(i, :)) + ...
                     (obj.gBestPosition - obj.positions(i, :))) / 2;
                E = ((obj.worstPosition + obj.positions(i, :)) + ...
                     (obj.worstPosition + obj.positions(i, :))) / 2;

                for d = 1:dim
                    dDelta = s * S(d) + a * A(d) + c * C(d) + f * F(d) + e * E(d) + w * obj.deltaPositions(i, d);

                    if dDelta > obj.Dmax
                        dDelta = obj.Dmax;
                    end
                    if dDelta < -obj.Dmax
                        dDelta = -obj.Dmax;
                    end

                    obj.deltaPositions(i, d) = dDelta;

                    TF = abs(dDelta / sqrt(dDelta^2 + 1));

                    r1 = rand();
                    if r1 < obj.config.pp
                        if rand() < TF
                            positionsNew(i, d) = 1 - obj.positions(i, d);
                        else
                            positionsNew(i, d) = obj.positions(i, d);
                        end
                    elseif r1 < obj.config.pg
                        positionsNew(i, d) = obj.pBestPositions(i, d);
                    else
                        positionsNew(i, d) = obj.gBestPosition(d);
                    end
                end
            end

            obj.positions = positionsNew;

            if obj.gBestFitness < obj.bestFitness
                obj.bestFitness = obj.gBestFitness;
                obj.bestSolution = obj.gBestPosition;
            end

            obj.convergenceCurve(currentIter) = obj.bestFitness;

            if obj.config.verbose && mod(currentIter, 10) == 0
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
                validatedConfig.populationSize = 10;
            end

            if validatedConfig.populationSize < 5
                error('HLBDA:InvalidConfig', 'populationSize must be >= 5');
            end

            if isfield(config, 'maxIterations')
                validatedConfig.maxIterations = config.maxIterations;
            else
                validatedConfig.maxIterations = 100;
            end

            if validatedConfig.maxIterations < 1
                error('HLBDA:InvalidConfig', 'maxIterations must be >= 1');
            end

            if isfield(config, 'pp')
                validatedConfig.pp = config.pp;
            else
                validatedConfig.pp = 0.4;
            end

            if isfield(config, 'pg')
                validatedConfig.pg = config.pg;
            else
                validatedConfig.pg = 0.7;
            end

            if isfield(config, 'Dmax')
                validatedConfig.Dmax = config.Dmax;
            else
                validatedConfig.Dmax = 6;
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
            % register 将HLBDA算法注册到算法注册表
            %
            % 示例:
            %   HLBDA.register();
            %   algClass = AlgorithmRegistry.getAlgorithm('HLBDA');

            AlgorithmRegistry.register('HLBDA', '2.0.0', @HLBDA);
        end
    end
end
