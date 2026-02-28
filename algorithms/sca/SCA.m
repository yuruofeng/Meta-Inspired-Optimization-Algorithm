classdef SCA < BaseAlgorithm
    % SCA 正弦余弦算法 (Sine Cosine Algorithm)
    %
    % 一种基于正弦和余弦函数的元启发式算法。通过正弦和余弦函数的
    % 数学模型实现解空间的探索和开发，利用参数自适应机制平衡
    % 全局搜索和局部开发能力。
    %
    % 算法机制:
    %   - 正弦更新: X(i,j) = X(i,j) + r1*sin(r2)*|r3*Dest(j)-X(i,j)|
    %   - 余弦更新: X(i,j) = X(i,j) + r1*cos(r2)*|r3*Dest(j)-X(i,j)|
    %   - r1: 从a线性递减到0，控制探索/开发平衡
    %   - r2: [0,2pi]随机数，决定移动方向和距离
    %   - r3: [0,2]随机数，强调/弱化目标影响
    %   - r4: [0,1]随机数，选择正弦或余弦更新
    %
    % 参考文献:
    %   S. Mirjalili, "SCA: A Sine Cosine Algorithm for solving optimization problems"
    %   Knowledge-Based Systems, 2016
    %   DOI: http://dx.doi.org/10.1016/j.knosys.2015.12.022
    %
    % 时间复杂度: O(MaxIter x N x Dim)
    % 空间复杂度: O(N x Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   sca = SCA(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = sca.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Seyedali Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2026

    properties (Access = protected)
        positions             % 搜索代理位置矩阵 (N x Dim)
        destinationPosition   % 目标位置（最优解） (1 x Dim)
        destinationFitness    % 目标适应度
        a                     % 控制参数a（控制探索/开发）
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '搜索代理数量'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'a', struct(...
                'type', 'double', ...
                'default', 2, ...
                'min', 0, ...
                'max', 10, ...
                'description', '控制探索/开发平衡的参数'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = SCA(configStruct)
            % SCA 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 30)
            %     - maxIterations: 最大迭代次数 (默认: 500)
            %     - a: 控制参数 (默认: 2)
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

            obj.positions = Initialization(N, dim, ub, lb);

            obj.destinationPosition = zeros(1, dim);
            obj.destinationFitness = Inf;

            obj.a = obj.config.a;

            fitness = obj.evaluatePopulation(obj.positions);

            [sortedFitness, sortedIndices] = sort(fitness);
            obj.destinationFitness = sortedFitness(1);
            obj.destinationPosition = obj.positions(sortedIndices(1), :);

            obj.bestFitness = obj.destinationFitness;
            obj.bestSolution = obj.destinationPosition;

            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括正弦/余弦位置更新、适应度评估、目标更新

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1;

            r1 = obj.a - currentIter * (obj.a / MaxIter);

            for i = 1:N
                for j = 1:size(obj.positions, 2)
                    r2 = (2 * pi) * rand();
                    r3 = 2 * rand();
                    r4 = rand();

                    if r4 < 0.5
                        obj.positions(i, j) = obj.positions(i, j) + ...
                            r1 * sin(r2) * abs(r3 * obj.destinationPosition(j) - obj.positions(i, j));
                    else
                        obj.positions(i, j) = obj.positions(i, j) + ...
                            r1 * cos(r2) * abs(r3 * obj.destinationPosition(j) - obj.positions(i, j));
                    end
                end

                obj.positions(i, :) = shared.utils.BoundaryHandler.quickClip(obj.positions(i, :), lb, ub);
            end

            for i = 1:N
                fitness = obj.evaluateSolution(obj.positions(i, :));

                if fitness < obj.destinationFitness
                    obj.destinationFitness = fitness;
                    obj.destinationPosition = obj.positions(i, :);
                end
            end

            if obj.destinationFitness < obj.bestFitness
                obj.bestFitness = obj.destinationFitness;
                obj.bestSolution = obj.destinationPosition;
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
                error('SCA:InvalidConfig', 'populationSize must be >= 10');
            end

            if isfield(config, 'maxIterations')
                validatedConfig.maxIterations = config.maxIterations;
            else
                validatedConfig.maxIterations = 500;
            end

            if validatedConfig.maxIterations < 1
                error('SCA:InvalidConfig', 'maxIterations must be >= 1');
            end

            if isfield(config, 'a')
                validatedConfig.a = config.a;
            else
                validatedConfig.a = 2;
            end

            if validatedConfig.a < 0
                error('SCA:InvalidConfig', 'a must be >= 0');
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
            % register 将SCA算法注册到算法注册表
            %
            % 示例:
            %   SCA.register();
            %   algClass = AlgorithmRegistry.getAlgorithm('SCA');

            AlgorithmRegistry.register('SCA', '2.0.0', @SCA);
        end
    end
end
