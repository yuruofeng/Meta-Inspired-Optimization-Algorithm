classdef GOA < BaseAlgorithm
    % GOA 蚱蜢优化算法 (Grasshopper Optimization Algorithm)
    %
    % 一种模拟蚱蜢群体行为的元启发式算法。蚱蜢群体在幼虫阶段
    % 表现出缓慢移动和逐步跳跃的行为，在成年阶段则展现出长距离
    % 和突然移动的能力。GOA算法模拟这种群体行为进行全局优化。
    %
    % 算法特点:
    %   - 社会相互作用机制：蚱蜢间的吸引和排斥力
    %   - 自适应衰减参数：平衡全局搜索和局部开发
    %   - 舒适区、排斥区和吸引区的三区域社会力模型
    %
    % 参考文献:
    %   S. Saremi, S. Mirjalili, A. Lewis
    %   "Grasshopper Optimisation Algorithm: Theory and Application"
    %   Advances in Engineering Software, 2017
    %   DOI: http://dx.doi.org/10.1016/j.advengsoft.2017.01.004
    %
    % 时间复杂度: O(MaxIter × N^2 × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   goa = GOA(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub': ub, 'dim', dim);
    %   result = goa.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Seyedali Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2026

    properties (Access = protected)
        positions            % 蚱蜢位置矩阵 (N x Dim)
        targetPosition       % 目标位置 (最优, 1 x Dim)
        targetFitness         % 目标适应度
        cMax                  % 最大衰减系数
        cMin                  % 最小衰减系数
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '蚱蜢种群个体数量'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'cMax', struct(...
                'type', 'double', ...
                'default', 1, ...
                'min', 0.1, ...
                'max', 10, ...
                'description', '最大衰减系数'), ...
            'cMin', struct(...
                'type', 'double', ...
                'default', 0.00004, ...
                'min', 0, ...
                'max', 1, ...
                'description', '最小衰减系数'), ...
            'f', struct(...
                'type', 'double', ...
                'default', 0.5, ...
                'min', 0, ...
                'max', 2, ...
                'description', '吸引力强度参数'), ...
            'l', struct(...
                'type', 'double', ...
                'default', 1.5, ...
                'min', 0.1, ...
                'max', 5, ...
                'description', '吸引力尺度参数'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = GOA(configStruct)
            % GOA 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 30)
            %     - maxIterations: 最大迭代次数 (默认: 500)
            %     - cMax: 最大衰减系数 (默认: 1)
            %     - cMin: 最小衰减系数 (默认: 0.00004)
            %     - f: 吸引力强度参数 (默认: 0.5)
            %     - l: 吸引力尺度参数 (默认: 1.5)
            %     - verbose: 是否显示进度 (默认: true)

            if nargin < 1 || isempty(configStruct)
                configStruct = struct();
            end

            obj = obj@BaseAlgorithm(configStruct);
            obj.cMax = obj.config.cMax;
            obj.cMin = obj.config.cMin;
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

            obj.targetPosition = zeros(1, dim);
            obj.targetFitness = Inf;

            fitness = obj.evaluatePopulation(obj.positions);

            [sortedFitness, sortedIndices] = sort(fitness);
            obj.targetFitness = sortedFitness(1);
            obj.targetPosition = obj.positions(sortedIndices(1), :);

            obj.bestFitness = obj.targetFitness;
            obj.bestSolution = obj.targetPosition;

            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括社会力计算、位置更新、边界处理和适应度评估

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            dim = size(obj.positions, 2);
            currentIter = obj.currentIteration + 1;

            c = obj.cMax - currentIter * ((obj.cMax - obj.cMin) / MaxIter);

            positionsTemp = zeros(N, dim);

            for i = 1:N
                sTotal = zeros(1, dim);
                
                for j = 1:N
                    if i ~= j
                        dist = norm(obj.positions(i, :) - obj.positions(j, :));
                        
                        if dist > 0
                            r_ij_vec = (obj.positions(j, :) - obj.positions(i, :)) / dist;
                            
                            xj_xi = 2 + rem(dist, 2);
                            
                            s_ij = ((ub - lb) * c / 2) * obj.s_func(xj_xi) .* r_ij_vec;
                            sTotal = sTotal + s_ij;
                        end
                    end
                end
                
                xNew = c * sTotal + obj.targetPosition;
                positionsTemp(i, :) = xNew;
            end

            obj.positions = positionsTemp;

            for i = 1:N
                obj.positions(i, :) = shared.utils.BoundaryHandler.quickClip(obj.positions(i, :), lb, ub);

                fitness = obj.evaluateSolution(obj.positions(i, :));

                if fitness < obj.targetFitness
                    obj.targetFitness = fitness;
                    obj.targetPosition = obj.positions(i, :);
                end
            end

            if obj.targetFitness < obj.bestFitness
                obj.bestFitness = obj.targetFitness;
                obj.bestSolution = obj.targetPosition;
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
                error('GOA:InvalidConfig', 'populationSize must be >= 10');
            end

            if isfield(config, 'maxIterations')
                validatedConfig.maxIterations = config.maxIterations;
            else
                validatedConfig.maxIterations = 500;
            end

            if validatedConfig.maxIterations < 1
                error('GOA:InvalidConfig', 'maxIterations must be >= 1');
            end

            if isfield(config, 'cMax')
                validatedConfig.cMax = config.cMax;
            else
                validatedConfig.cMax = 1;
            end

            if isfield(config, 'cMin')
                validatedConfig.cMin = config.cMin;
            else
                validatedConfig.cMin = 0.00004;
            end

            if isfield(config, 'f')
                validatedConfig.f = config.f;
            else
                validatedConfig.f = 0.5;
            end

            if isfield(config, 'l')
                validatedConfig.l = config.l;
            else
                validatedConfig.l = 1.5;
            end

            if isfield(config, 'verbose')
                validatedConfig.verbose = config.verbose;
            else
                validatedConfig.verbose = true;
            end
        end
    end

    methods (Access = protected)
        function o = s_func(obj, r)
            % s_func 社会力函数 (Equation 2.3)
            %
            % 输入参数:
            %   r - 距离
            %
            % 输出参数:
            %   o - 社会力值
            %
            % 该函数定义了舒适区、排斥区和吸引区的社会力

            f = obj.config.f;
            l = obj.config.l;
            o = f * exp(-r / l) - exp(-r);
        end
    end

    methods (Static)
        function register()
            % register 将GOA算法注册到算法注册表
            %
            % 示例:
            %   GOA.register();
            %   algClass = AlgorithmRegistry.getAlgorithm('GOA');

            AlgorithmRegistry.register('GOA', '2.0.0', @GOA);
        end
    end
end
