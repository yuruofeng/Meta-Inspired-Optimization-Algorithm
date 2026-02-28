classdef (Abstract) MOBaseAlgorithm < handle
    % MOBaseAlgorithm 多目标元启发式算法抽象基类
    %
    % 定义了多目标元启发式算法的基本框架和生命周期方法。所有具体
    % 多目标算法(如MOALO, MODA, MOGOA, MOGWO, MSSA等)必须继承此类
    % 并实现抽象方法。
    %
    % 与单目标算法的主要区别:
    %   - 维护一个Pareto前沿存档(Archive)而非单一最优解
    %   - 使用支配关系(dominance)比较解的质量
    %   - 支持多个目标函数同时优化
    %
    % 参考规范: metaheuristic_spec.md §2.1
    %
    % 使用示例:
    %   classdef MyMOAlgorithm < MOBaseAlgorithm
    %       methods
    %           function obj = MyMOAlgorithm(config)
    %               obj = obj@MOBaseAlgorithm(config);
    %           end
    %           % 实现抽象方法...
    %       end
    %   end
    %
    % 作者：RUOFENG YU
    % 版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        config struct          % 算法配置参数
        currentIteration int64 % 当前迭代次数
        startTime double       % 开始时间
        problem                % 问题对象
    end

    properties (Access = protected)
        archiveX double        % 存档解集 (ArchiveSize x dim)
        archiveF double        % 存档目标值 (ArchiveSize x objCount)
        archiveSize int32      % 当前存档大小
        archiveMaxSize int32   % 存档最大容量
        archiveRanks double    % 存档拥挤度排名
        objCount int32         % 目标函数数量
    end

    properties (Access = protected, Transient)
        convergenceCurve double  % 收敛曲线 (IGD等指标)
        totalEvaluations int64   % 总评估次数
    end

    properties (Constant)
        PARAM_SCHEMA struct = struct()
    end

    methods
        function obj = MOBaseAlgorithm(configStruct)
            % MOBaseAlgorithm 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，包含算法参数
            %
            % 异常:
            %   InvalidParamError - 参数不合法时抛出

            if nargin < 1 || isempty(configStruct)
                configStruct = struct();
            end

            obj.config = obj.validateConfig(configStruct);
            obj.currentIteration = 0;
            obj.totalEvaluations = 0;
            obj.archiveSize = 0;
        end

        function result = run(obj, problem)
            % run 执行多目标优化过程的主入口 (模板方法)
            %
            % 此方法定义了多目标优化的标准流程，不可被子类覆盖。
            % 子类应实现 initialize(), iterate(), shouldStop() 方法。
            %
            % 输入参数:
            %   problem - 问题对象，必须包含:
            %     - evaluate: 多目标评估函数，返回 (1 x objCount) 向量
            %     - lb: 下边界
            %     - ub: 上边界
            %     - dim: 维度
            %     - objCount: 目标函数数量
            %
            % 输出参数:
            %   result - MOOptimizationResult 对象，包含优化结果
            %
            % 示例:
            %   algorithm = MOGWO(config);
            %   result = algorithm.run(problem);
            %   result.plot();

            obj.startTime = tic;
            obj.problem = problem;
            obj.objCount = int32(problem.objCount);

            obj.initialize(problem);

            while ~obj.shouldStop()
                obj.iterate();
                obj.currentIteration = obj.currentIteration + 1;
                obj.recordConvergence();
            end

            result = obj.collectResult();
        end
    end

    methods (Abstract)
        initialize(obj, problem)
        % initialize 初始化算法
        %
        % 输入参数:
        %   problem - 问题对象

        iterate(obj)
        % iterate 执行一次迭代
        %
        % 在此方法中更新种群，评估适应度，更新存档

        tf = shouldStop(obj)
        % shouldStop 判断是否应该停止迭代
        %
        % 输出参数:
        %   tf - true表示停止，false表示继续

        validatedConfig = validateConfig(obj, config)
        % validatedConfig 验证并规范化配置参数
    end

    methods (Access = protected)
        function result = collectResult(obj)
            % collectResult 收集多目标优化结果
            %
            % 此方法在优化完成后调用，构造 MOOptimizationResult 对象。

            elapsedTime = toc(obj.startTime);

            result = MOOptimizationResult(...
                'paretoSet', obj.archiveX(1:obj.archiveSize, :), ...
                'paretoFront', obj.archiveF(1:obj.archiveSize, :), ...
                'objCount', obj.objCount, ...
                'convergenceCurve', obj.convergenceCurve, ...
                'totalEvaluations', obj.totalEvaluations, ...
                'elapsedTime', elapsedTime, ...
                'metadata', struct(...
                    'algorithm', class(obj), ...
                    'iterations', obj.currentIteration, ...
                    'config', obj.config, ...
                    'archiveSize', obj.archiveSize ...
                ) ...
            );
        end

        function fitness = evaluateSolution(obj, solution)
            % evaluateSolution 评估单个解的多目标适应度
            %
            % 输入参数:
            %   solution - 待评估的解向量 (1 x dim)
            %
            % 输出参数:
            %   fitness - 目标函数值向量 (1 x objCount)

            fitness = obj.problem.evaluate(solution);
            obj.totalEvaluations = obj.totalEvaluations + 1;
        end

        function fitness = evaluatePopulation(obj, population)
            % evaluatePopulation 批量评估种群
            %
            % 输入参数:
            %   population - 种群矩阵 (N x dim)
            %
            % 输出参数:
            %   fitness - 目标函数值矩阵 (N x objCount)

            popSize = size(population, 1);
            fitness = zeros(popSize, obj.objCount);

            for i = 1:popSize
                fitness(i, :) = obj.evaluateSolution(population(i, :));
            end
        end

        function tf = dominates(obj, x, y)
            % dominates 判断解x是否支配解y (Pareto支配)
            %
            % 支配关系定义: x支配y当且仅当:
            %   1. x在所有目标上不劣于y (x_i <= y_i for all i)
            %   2. x至少在一个目标上严格优于y (x_j < y_j for some j)
            %
            % 输入参数:
            %   x - 解x的目标函数值 (1 x objCount)
            %   y - 解y的目标函数值 (1 x objCount)
            %
            % 输出参数:
            %   tf - true表示x支配y

            tf = all(x <= y) && any(x < y);
        end

        function updateArchive(obj, newSolutions, newFitness)
            % updateArchive 更新Pareto存档
            %
            % 将新解加入存档，并移除被支配的解
            %
            % 输入参数:
            %   newSolutions - 新解矩阵 (M x dim)
            %   newFitness - 新解目标值矩阵 (M x objCount)

            nNew = size(newSolutions, 1);

            combinedX = [obj.archiveX(1:obj.archiveSize, :); newSolutions];
            combinedF = [obj.archiveF(1:obj.archiveSize, :); newFitness];

            nCombined = size(combinedF, 1);
            isDominated = false(1, nCombined);

            for i = 1:nCombined
                for j = 1:nCombined
                    if i ~= j && obj.dominates(combinedF(j, :), combinedF(i, :))
                        isDominated(i) = true;
                        break;
                    end
                end
            end

            nonDominatedIdx = find(~isDominated);
            obj.archiveX(1:length(nonDominatedIdx), :) = combinedX(nonDominatedIdx, :);
            obj.archiveF(1:length(nonDominatedIdx), :) = combinedF(nonDominatedIdx, :);
            obj.archiveSize = int32(length(nonDominatedIdx));

            if obj.archiveSize > obj.archiveMaxSize
                obj.handleFullArchive();
            end
        end

        function handleFullArchive(obj)
            % handleFullArchive 处理存档溢出
            %
            % 当存档大小超过最大容量时，根据拥挤度移除多余的解

            obj.archiveRanks = obj.rankingProcess(obj.archiveF(1:obj.archiveSize, :));

            while obj.archiveSize > obj.archiveMaxSize
                ranks = obj.archiveRanks(1:obj.archiveSize);
                [~, maxIdx] = max(ranks);
                obj.archiveX(maxIdx:obj.archiveSize-1, :) = obj.archiveX(maxIdx+1:obj.archiveSize, :);
                obj.archiveF(maxIdx:obj.archiveSize-1, :) = obj.archiveF(maxIdx+1:obj.archiveSize, :);
                obj.archiveRanks(maxIdx:obj.archiveSize-1) = obj.archiveRanks(maxIdx+1:obj.archiveSize);
                obj.archiveSize = obj.archiveSize - 1;
            end
        end

        function ranks = rankingProcess(obj, archiveF)
            % rankingProcess 计算拥挤度排名
            %
            % 基于网格方法计算每个解的拥挤程度
            %
            % 输入参数:
            %   archiveF - 存档目标值矩阵 (N x objCount)
            %
            % 输出参数:
            %   ranks - 拥挤度排名向量 (1 x N)

            n = size(archiveF, 1);
            if n == 0
                ranks = [];
                return;
            end

            fMin = min(archiveF, [], 1);
            fMax = max(archiveF, [], 1);
            range = (fMax - fMin) / 20;
            range(range == 0) = 1;

            ranks = zeros(1, n);
            for i = 1:n
                for j = 1:n
                    if i ~= j
                        inNeighborhood = all(abs(archiveF(j, :) - archiveF(i, :)) < range);
                        if inNeighborhood
                            ranks(i) = ranks(i) + 1;
                        end
                    end
                end
            end
        end

        function idx = selectFromArchive(obj, useInverse)
            % selectFromArchive 从存档中选择一个解 (轮盘赌选择)
            %
            % 输入参数:
            %   useInverse - true表示选择稀疏区域(1/rank)，false表示选择拥挤区域
            %
            % 输出参数:
            %   idx - 被选中的解索引

            if obj.archiveSize == 0
                idx = 0;
                return;
            end

            if obj.archiveSize == 1
                idx = 1;
                return;
            end

            ranks = obj.archiveRanks(1:obj.archiveSize);

            if nargin < 2
                useInverse = true;
            end

            if useInverse
                probs = 1 ./ (ranks + 1);
            else
                probs = ranks + 1;
            end

            probs = probs / sum(probs);
            idx = obj.rouletteWheelSelection(probs);
        end

        function idx = rouletteWheelSelection(obj, probs)
            % rouletteWheelSelection 轮盘赌选择
            %
            % 输入参数:
            %   probs - 概率向量 (和为1)
            %
            % 输出参数:
            %   idx - 被选中的索引

            cumProbs = cumsum(probs);
            r = rand();
            idx = find(r <= cumProbs, 1, 'first');

            if isempty(idx)
                idx = length(probs);
            end
        end

        function recordConvergence(obj)
            % recordConvergence 记录收敛指标
            %
            % 可被子类覆盖以实现特定的收敛指标

            if isempty(obj.convergenceCurve)
                obj.convergenceCurve = zeros(obj.config.maxIterations, 1);
            end

            if obj.archiveSize > 0
                obj.convergenceCurve(obj.currentIteration) = obj.archiveSize;
            end
        end

        function displayProgress(obj, message)
            % displayProgress 显示进度信息
            %
            % 输入参数:
            %   message - 进度消息

            if isfield(obj.config, 'verbose') && obj.config.verbose
                fprintf('[%s] Iteration %d/%d: %s (Archive: %d solutions)\n', ...
                    class(obj), obj.currentIteration, ...
                    obj.config.maxIterations, message, obj.archiveSize);
            end
        end
    end

    methods (Static)
        function schema = getParamSchema()
            schema = struct();
        end

        function register()
            warning('MOBaseAlgorithm:NotImplemented', ...
                'Subclasses should implement their own register method.');
        end
    end
end
