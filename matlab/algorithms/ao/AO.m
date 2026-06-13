classdef AO < BaseAlgorithm
    % AO 天鹰优化器 (Aquila Optimizer)
    %
    % 一种模拟天鹰捕猎行为的元启发式优化算法，灵感来源于天鹰在自然界中的
    % 四种捕猎策略。通过平衡探索和开发能力，实现对搜索空间的有效搜索。
    %
    % 核心机制:
    %   1. 高空飞行(扩展探索) - 种群随机搜索
    %   2. 俯视攻击(集中探索) - 围绕最优解搜索
    %   3. 低空飞行(扩展开发) - 向最优解靠近
    %   4. 突袭攻击(集中开发) - 精确位置更新
    %
    % 参考文献:
    %   L. Abualigah, A. Diabat, S. Mirjalili, M. Abd Elaziz, A. H. Gandomi
    %   "The Aquila Optimizer: A novel meta-heuristic optimization algorithm"
    %   Computers & Industrial Engineering, 2021
    %   DOI: 10.1016/j.cie.2021.107250
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   ao = AO(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = ao.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Laith Abualigah, et al.
    % 重构版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 种群位置矩阵 (N x Dim)
        bestPosition         % 全局最优位置 (1 x Dim)
        meanPosition         % 平均位置 (1 x Dim)
        allFitness           % 所有个体适应度 (N x 1)
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '天鹰种群个体数量'), ...
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
        function obj = AO(configStruct)
            % AO 构造函数
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

            obj.positions = Initialization(N, dim, ub, lb);

            obj.bestPosition = zeros(1, dim);
            obj.bestFitness = Inf;
            obj.meanPosition = zeros(1, dim);

            obj.allFitness = obj.evaluatePopulation(obj.positions);

            [sortedFitness, sortedIndices] = sort(obj.allFitness);
            obj.bestFitness = sortedFitness(1);
            obj.bestPosition = obj.positions(sortedIndices(1), :);

            obj.meanPosition = mean(obj.positions, 1);

            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 根据迭代阶段选择不同的捕猎策略

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1;
            dim = size(obj.positions, 2);

            obj.allFitness = obj.evaluatePopulation(obj.positions);

            [minFitness, minIdx] = min(obj.allFitness);
            if minFitness < obj.bestFitness
                obj.bestFitness = minFitness;
                obj.bestPosition = obj.positions(minIdx, :);
            end

            obj.meanPosition = mean(obj.positions, 1);

            a = 2 - currentIter * (2 / MaxIter);

            for i = 1:N
                if currentIter <= (2 * MaxIter / 3)
                    if rand < 0.5
                        obj.positions(i, :) = obj.highFlight(...
                            obj.positions(i, :), obj.bestPosition, ...
                            obj.meanPosition, i, N, currentIter, MaxIter, lb, ub);
                    else
                        obj.positions(i, :) = obj.divingAttack(...
                            obj.positions(i, :), obj.bestPosition, ...
                            obj.allFitness, obj.allFitness(i), i, N, lb, ub);
                    end
                else
                    if rand < 0.5
                        obj.positions(i, :) = obj.lowFlight(...
                            obj.positions(i, :), obj.bestPosition, ...
                            obj.positions, i, a, dim, lb, ub);
                    else
                        obj.positions(i, :) = obj.swoopAttack(...
                            obj.positions(i, :), obj.bestPosition, ...
                            currentIter, MaxIter, dim, lb, ub);
                    end
                end

                obj.positions(i, :) = obj.clampToBounds(obj.positions(i, :), lb, ub);
            end

            obj.allFitness = obj.evaluatePopulation(obj.positions);
            [minFitness, minIdx] = min(obj.allFitness);
            if minFitness < obj.bestFitness
                obj.bestFitness = minFitness;
                obj.bestPosition = obj.positions(minIdx, :);
            end

            obj.convergenceCurve(currentIter) = obj.bestFitness;

            if obj.config.verbose && mod(currentIter, 50) == 0
                obj.displayProgress(sprintf('Best fitness: %.6e', obj.bestFitness));
            end
        end

        function tf = shouldStop(obj)
            % shouldStop 判断是否应该停止迭代
            %
            % 输出参数:
            %   tf - true表示停止，false表示继续

            tf = obj.currentIteration >= obj.config.maxIterations;
        end

        function validatedConfig = validateConfig(obj, config)
            % validateConfig 验证并规范化配置参数
            %
            % 输入参数:
            %   config - 配置结构体
            %
            % 输出参数:
            %   validatedConfig - 验证后的配置

            validatedConfig = struct();

            if isfield(config, 'populationSize')
                validatedConfig.populationSize = max(10, round(config.populationSize));
            else
                validatedConfig.populationSize = 30;
            end

            if isfield(config, 'maxIterations')
                validatedConfig.maxIterations = max(1, round(config.maxIterations));
            else
                validatedConfig.maxIterations = 500;
            end

            if isfield(config, 'verbose')
                validatedConfig.verbose = logical(config.verbose);
            else
                validatedConfig.verbose = true;
            end
        end
    end

    methods (Access = protected)
        function newPosition = highFlight(obj, currentPos, bestPos, meanPos, ...
                                          ~, ~, currentIter, MaxIter, ~, ~)
            % highFlight 高空飞行策略 (扩展探索)
            %
            % 模拟天鹰在高空寻找猎物的行为，进行全局搜索
            %
            % 输入参数:
            %   currentPos - 当前个体位置
            %   bestPos - 全局最优位置
            %   meanPos - 平均位置
            %   ~ - (未使用) 当前个体索引
            %   ~ - (未使用) 种群大小
            %   currentIter - 当前迭代次数
            %   MaxIter - 最大迭代次数
            %   ~ - (未使用) 下边界
            %   ~ - (未使用) 上边界
            %
            % 输出参数:
            %   newPosition - 更新后的位置

            dim = length(currentPos);

            x1 = bestPos(1) * ones(1, dim);

            r1 = rand(1, dim);
            for d = 1:dim
                if r1(d) < 0.5
                    x1(d) = bestPos(d) * (1 - currentIter / MaxIter) + ...
                        (meanPos(d) - bestPos(d)) * rand;
                else
                    x1(d) = bestPos(d) * (1 - currentIter / MaxIter) - ...
                        (meanPos(d) - bestPos(d)) * rand;
                end
            end

            newPosition = x1;
        end

        function newPosition = divingAttack(obj, currentPos, bestPos, ...
                                            allFitness, currentFitness, index, ~, ~, ~)
            % divingAttack 俯视攻击策略 (集中探索)
            %
            % 模拟天鹰从高处俯冲攻击猎物的行为
            %
            % 输入参数:
            %   currentPos - 当前个体位置
            %   bestPos - 全局最优位置
            %   allFitness - 所有个体适应度
            %   currentFitness - 当前个体适应度
            %   index - 当前个体索引
            %   ~ - (未使用) 种群大小
            %   ~ - (未使用) 下边界
            %   ~ - (未使用) 上边界
            %
            % 输出参数:
            %   newPosition - 更新后的位置

            dim = length(currentPos);
            N = length(allFitness);

            [~, sortedIndices] = sort(allFitness);
            if N >= 2
                secondBestIdx = sortedIndices(2);
                if secondBestIdx == index
                    if N >= 3
                        secondBestIdx = sortedIndices(3);
                    else
                        secondBestIdx = sortedIndices(1);
                    end
                end
            else
                secondBestIdx = 1;
            end

            if allFitness(secondBestIdx) < currentFitness
                newPosition = bestPos + LevyFlight(dim) .* (currentPos - bestPos) + ...
                    (rand - 0.5) .* 2 .* (currentPos - currentPos(secondBestIdx));
            else
                newPosition = bestPos + LevyFlight(dim) .* (currentPos - bestPos) + ...
                    (rand - 0.5) .* 2 .* (bestPos - currentPos);
            end
        end

        function newPosition = lowFlight(obj, currentPos, bestPos, ...
                                         allPositions, index, a, dim, ~, ~)
            % lowFlight 低空飞行策略 (扩展开发)
            %
            % 模拟天鹰在低空追逐猎物的行为
            %
            % 输入参数:
            %   currentPos - 当前个体位置
            %   bestPos - 全局最优位置
            %   allPositions - 所有个体位置矩阵
            %   index - 当前个体索引
            %   a - 收敛因子
            %   dim - 维度
            %   ~ - (未使用) 下边界
            %   ~ - (未使用) 上边界
            %
            % 输出参数:
            %   newPosition - 更新后的位置

            N = size(allPositions, 1);

            r = rand();
            theta = rand() * 2 * pi;
            x = r * sin(theta);
            sigma = (rand() * 10) / 10;
            u = rand() * sigma * 2 - sigma;
            v = rand() * sigma * 2 - sigma;
            XF = x * u;
            YF = v;

            r2 = rand(1, dim);
            A = 2 * a .* r2 - a;

            for d = 1:dim
                if A(d) >= 0
                    A(d) = 1;
                else
                    A(d) = -1;
                end
            end

            newPosition = bestPos + XF .* (currentPos - bestPos) + YF .* ...
                (currentPos - allPositions(index, :));
        end

        function newPosition = swoopAttack(obj, currentPos, bestPos, ...
                                           currentIter, MaxIter, dim, ~, ~)
            % swoopAttack 突袭攻击策略 (集中开发)
            %
            % 模拟天鹰最后阶段精确捕获猎物的行为
            %
            % 输入参数:
            %   currentPos - 当前个体位置
            %   bestPos - 全局最优位置
            %   currentIter - 当前迭代次数
            %   MaxIter - 最大迭代次数
            %   dim - 维度
            %   ~ - (未使用) 下边界
            %   ~ - (未使用) 上边界
            %
            % 输出参数:
            %   newPosition - 更新后的位置

            alpha = (1 - currentIter / MaxIter) * 0.5;
            delta = (1 - currentIter / MaxIter) * 0.5;

            r = rand();
            theta = rand() * 2 * pi;
            x = r * sin(theta);
            y = r * cos(theta);
            sigma = (rand() * 10) / 10;
            u = rand() * sigma * 2 - sigma;
            v = rand() * sigma * 2 - sigma;
            XF = x * u;
            YF = y * v;

            QF = currentIter^((2*rand()-1) / (1 - MaxIter)^2);

            newPosition = QF .* bestPos - (XF + YF) .* currentPos - ...
                alpha .* (rand(1, dim) - 0.5) .* ...
                (currentPos - bestPos) + delta .* (currentPos - bestPos);
        end
    end

    methods (Static)
        function register()
            % register 将算法注册到AlgorithmRegistry
            %
            % 此方法在系统初始化时调用，将AO算法注册到全局注册表。

            AlgorithmRegistry.register('AO', '1.0.0', 'AO');
        end
    end
end
