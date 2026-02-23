classdef VPSO < BaseAlgorithm
    % VPSO V形/二进制粒子群优化 (V-shaped/Binary Particle Swarm Optimization)
    %
    % 一种用于二进制优化问题的PSO变体。使用传递函数将连续速度
    % 转换为二进制位置更新的概率。支持S形和V形两类共8种传递函数。
    %
    % 算法特点:
    %   - 二进制编码: 位置为0/1
    %   - 传递函数: S1-S4 (S形), V1-V4 (V形)
    %   - S形: 以概率将位置设为1
    %   - V形: 以概率翻转位置
    %
    % 传递函数说明:
    %   - S1: s = 1/(1+exp(-2v))
    %   - S2: s = 1/(1+exp(-v))
    %   - S3: s = 1/(1+exp(-v/2))
    %   - S4: s = 1/(1+exp(-v/3))
    %   - V1: s = |erf(sqrt(pi)/2 * v)|
    %   - V2: s = |tanh(v)|
    %   - V3: s = |v/sqrt(1+v^2)|
    %   - V4: s = |2/pi * atan(pi/2 * v)| (推荐)
    %
    % 参考文献:
    %   S. Mirjalili and A. Lewis
    %   "S-shaped versus V-shaped transfer functions for binary
    %    Particle Swarm Optimization"
    %   Swarm and Evolutionary Computation, 2013
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500, ...
    %                   'transferFunctionType', 'V4');
    %   vpso = VPSO(config);
    %   problem = struct('evaluate', @myBinaryFitness, 'lb', 0, 'ub', 1, 'dim', 100);
    %   result = vpso.run(problem);
    %   fprintf('Best fitness: %.6f\n', result.bestFitness);
    %
    % 原始作者: Seyedali Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 二进制位置矩阵 (N x Dim, logical)
        velocities           % 连续速度矩阵 (N x Dim, double)
        pbestPositions       % 个体最优二进制位置 (N x Dim, logical)
        pbestFitness         % 个体最优适应度 (N x 1)
        gbestPosition        % 全局最优二进制位置 (1 x Dim, logical)
        gbestFitness         % 全局最优适应度
        transferFunction     % 传递函数句柄
        isVshaped            % 是否为V形传递函数
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 5, ...
                'max', 10000, ...
                'description', '粒子群大小'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'transferFunctionType', struct(...
                'type', 'enum', ...
                'options', {{'S1', 'S2', 'S3', 'S4', 'V1', 'V2', 'V3', 'V4'}}, ...
                'default', 'V4', ...
                'description', '传递函数类型 (S形: 1-4, V形: 5-8)'), ...
            'wMax', struct(...
                'type', 'float', ...
                'default', 0.9, ...
                'min', 0, ...
                'max', 1, ...
                'description', '最大惯性权重'), ...
            'wMin', struct(...
                'type', 'float', ...
                'default', 0.4, ...
                'min', 0, ...
                'max', 1, ...
                'description', '最小惯性权重'), ...
            'c1', struct(...
                'type', 'float', ...
                'default', 2, ...
                'min', 0, ...
                'description', '认知系数'), ...
            'c2', struct(...
                'type', 'float', ...
                'default', 2, ...
                'min', 0, ...
                'description', '社会系数'), ...
            'vMax', struct(...
                'type', 'float', ...
                'default', 6, ...
                'min', 0, ...
                'description', '最大速度'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = VPSO(configStruct)
            % VPSO 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 粒子群大小 (默认: 30)
            %     - maxIterations: 最大迭代次数 (默认: 500)
            %     - transferFunctionType: 传递函数类型 (默认: 'V4')
            %     - wMax, wMin: 惯性权重范围 (默认: 0.9, 0.4)
            %     - c1, c2: 学习因子 (默认: 2, 2)
            %     - vMax: 最大速度 (默认: 6)
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

            % 初始化连续速度
            obj.velocities = (rand(N, dim) * 2 - 1) * obj.config.vMax;

            % 初始化个体最优
            obj.pbestPositions = obj.positions;
            obj.pbestFitness = Inf(N, 1);

            % 初始化全局最优
            obj.gbestPosition = zeros(1, dim);
            obj.gbestFitness = Inf;

            % 评估初始种群
            for i = 1:N
                fitness = obj.evaluateSolution(obj.positions(i, :));
                obj.pbestFitness(i) = fitness;

                if fitness < obj.gbestFitness
                    obj.gbestFitness = fitness;
                    obj.gbestPosition = obj.positions(i, :);
                end
            end

            % 初始化全局最优
            obj.bestFitness = obj.gbestFitness;
            obj.bestSolution = obj.gbestPosition;

            % 获取传递函数
            obj.transferFunction = algorithms.vpso.operators.TransferFunctions.getFunction(...
                obj.config.transferFunctionType);
            obj.isVshaped = algorithms.vpso.operators.TransferFunctions.isVType(...
                obj.config.transferFunctionType);

            % 预分配收敛曲线
            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括速度更新、位置更新(通过传递函数)

            dim = size(obj.positions, 2);
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1;

            % 计算线性递减惯性权重
            w = obj.config.wMax - currentIter * ((obj.config.wMax - obj.config.wMin) / MaxIter);

            % 更新速度和位置
            for i = 1:N
                for j = 1:dim
                    % 速度更新 (标准PSO公式)
                    obj.velocities(i, j) = w * obj.velocities(i, j) + ...
                        obj.config.c1 * rand() * (obj.pbestPositions(i, j) - obj.positions(i, j)) + ...
                        obj.config.c2 * rand() * (obj.gbestPosition(j) - obj.positions(i, j));

                    % 速度钳制
                    if obj.velocities(i, j) > obj.config.vMax
                        obj.velocities(i, j) = obj.config.vMax;
                    end
                    if obj.velocities(i, j) < -obj.config.vMax
                        obj.velocities(i, j) = -obj.config.vMax;
                    end

                    % 计算传递函数值
                    s = obj.transferFunction(obj.velocities(i, j));

                    % 应用传递函数更新位置
                    if obj.isVshaped
                        % V形: 以概率s翻转
                        if rand() < s
                            obj.positions(i, j) = ~obj.positions(i, j);
                        end
                    else
                        % S形: 以概率s设为1
                        if rand() < s
                            obj.positions(i, j) = true;
                        else
                            obj.positions(i, j) = false;
                        end
                    end
                end
            end

            % 评估并更新最优
            for i = 1:N
                fitness = obj.evaluateSolution(obj.positions(i, :));

                % 更新个体最优
                if fitness < obj.pbestFitness(i)
                    obj.pbestPositions(i, :) = obj.positions(i, :);
                    obj.pbestFitness(i) = fitness;

                    % 更新全局最优
                    if fitness < obj.gbestFitness
                        obj.gbestFitness = fitness;
                        obj.gbestPosition = obj.positions(i, :);
                    end
                end
            end

            % 更新全局最优
            if obj.gbestFitness < obj.bestFitness
                obj.bestFitness = obj.gbestFitness;
                obj.bestSolution = obj.gbestPosition;
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

            validatedConfig = struct();

            % 种群大小
            if isfield(config, 'populationSize')
                validatedConfig.populationSize = config.populationSize;
            else
                validatedConfig.populationSize = 30;
            end

            if validatedConfig.populationSize < 5
                error('VPSO:InvalidConfig', 'populationSize must be >= 5');
            end

            % 最大迭代次数
            if isfield(config, 'maxIterations')
                validatedConfig.maxIterations = config.maxIterations;
            else
                validatedConfig.maxIterations = 500;
            end

            if validatedConfig.maxIterations < 1
                error('VPSO:InvalidConfig', 'maxIterations must be >= 1');
            end

            % 传递函数类型
            if isfield(config, 'transferFunctionType')
                validatedConfig.transferFunctionType = validatestring(...
                    config.transferFunctionType, ...
                    {'S1', 'S2', 'S3', 'S4', 'V1', 'V2', 'V3', 'V4'});
            else
                validatedConfig.transferFunctionType = 'V4';
            end

            % 惯性权重
            if isfield(config, 'wMax')
                validatedConfig.wMax = config.wMax;
            else
                validatedConfig.wMax = 0.9;
            end

            if isfield(config, 'wMin')
                validatedConfig.wMin = config.wMin;
            else
                validatedConfig.wMin = 0.4;
            end

            if validatedConfig.wMin > validatedConfig.wMax
                error('VPSO:InvalidConfig', 'wMin must be <= wMax');
            end

            % 学习因子
            if isfield(config, 'c1')
                validatedConfig.c1 = config.c1;
            else
                validatedConfig.c1 = 2;
            end

            if isfield(config, 'c2')
                validatedConfig.c2 = config.c2;
            else
                validatedConfig.c2 = 2;
            end

            % 最大速度
            if isfield(config, 'vMax')
                validatedConfig.vMax = config.vMax;
            else
                validatedConfig.vMax = 6;
            end

            if validatedConfig.vMax <= 0
                error('VPSO:InvalidConfig', 'vMax must be > 0');
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
            % register 将VPSO算法注册到算法注册表
            %
            % 示例:
            %   VPSO.register();
            %   algClass = AlgorithmRegistry.getAlgorithm('VPSO');

            AlgorithmRegistry.register('VPSO', '2.0.0', @VPSO);
        end
    end
end
