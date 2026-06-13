classdef NSGAIII < MOBaseAlgorithm
    % NSGA-III 非支配排序遗传算法III (Non-dominated Sorting Genetic Algorithm III)
    %
    % 一种专门针对高维多目标优化问题(k≥3)设计的进化算法。通过参考点引导
    % 种群向Pareto前沿收敛，使用小生境保持操作维护解集的多样性。
    %
    % 核心机制:
    %   1. 参考点生成 - 使用Das and Dennis方法生成均匀分布的参考点
    %   2. 非支配排序 - 将种群分层排序
    %   3. 参考点关联 - 将解与最近的参考点关联
    %   4. 小生境保持 - 在参考点周围保持解的多样性
    %
    % 参考文献:
    %   K. Deb, H. Jain
    %   "An Evolutionary Many-Objective Optimization Algorithm Using 
    %    Reference-Point-Based Nondominated Sorting Approach, Part I: 
    %    Solving Problems With Box Constraints"
    %   IEEE Transactions on Evolutionary Computation, 2014
    %   DOI: 10.1109/TEVC.2013.2281535
    %
    % 时间复杂度: O(MaxIter × N² × M)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 100, 'maxIterations', 200);
    %   nsga3 = NSGAIII(config);
    %   problem.lb = 0; problem.ub = 1; problem.dim = 10;
    %   problem.objCount = 3;
    %   problem.evaluate = @(x) DTLZ1(x, 3);
    %   result = nsga3.run(problem);
    %   result.plot();
    %
    % 原始作者: Kalyanmoy Deb, Himanshu Jain
    % 重构版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 种群位置矩阵 (N x Dim)
        fitness              % 适应度矩阵 (N x objCount)
        referencePoints      % 参考点矩阵 (nRef x objCount)
        nRef                 % 参考点数量
        idealPoint           % 理想点 (1 x objCount)
        nadirPoint           % 端点 (1 x objCount)
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 100, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '种群大小'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 200, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'archiveMaxSize', struct(...
                'type', 'integer', ...
                'default', 100, ...
                'min', 10, ...
                'max', 1000, ...
                'description', 'Pareto存档最大容量'), ...
            'crossoverProb', struct(...
                'type', 'float', ...
                'default', 0.9, ...
                'min', 0, ...
                'max', 1, ...
                'description', '交叉概率'), ...
            'mutationProb', struct(...
                'type', 'float', ...
                'default', 0.1, ...
                'min', 0, ...
                'max', 1, ...
                'description', '变异概率'), ...
            'etaC', struct(...
                'type', 'float', ...
                'default', 30, ...
                'min', 1, ...
                'max', 100, ...
                'description', 'SBX分布指数'), ...
            'etaM', struct(...
                'type', 'float', ...
                'default', 20, ...
                'min', 1, ...
                'max', 100, ...
                'description', '多项式变异分布指数'), ...
            'divisions', struct(...
                'type', 'integer', ...
                'default', 12, ...
                'min', 2, ...
                'max', 50, ...
                'description', '参考点分层参数p'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = NSGAIII(configStruct)
            % NSGAIII 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体

            if nargin < 1 || isempty(configStruct)
                configStruct = struct();
            end

            obj = obj@MOBaseAlgorithm(configStruct);
        end

        function initialize(obj, problem)
            % initialize 初始化种群、参考点和存档

            lb = problem.lb;
            ub = problem.ub;
            dim = problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            obj.archiveMaxSize = int32(obj.config.archiveMaxSize);
            obj.objCount = int32(problem.objCount);

            if isscalar(lb)
                lb = lb * ones(1, dim);
                ub = ub * ones(1, dim);
            end
            obj.problem.lb = lb;
            obj.problem.ub = ub;

            obj.positions = Initialization(N, dim, ub, lb);
            obj.fitness = zeros(N, obj.objCount);

            for i = 1:N
                obj.fitness(i, :) = obj.evaluateSolution(obj.positions(i, :));
            end

            obj.idealPoint = min(obj.fitness, [], 1);
            obj.nadirPoint = max(obj.fitness, [], 1);

            obj.referencePoints = obj.generateReferencePoints(obj.objCount, obj.config.divisions);
            obj.nRef = size(obj.referencePoints, 1);

            obj.archiveX = zeros(obj.archiveMaxSize, dim);
            obj.archiveF = inf(obj.archiveMaxSize, obj.objCount);
            obj.archiveSize = int32(0);

            obj.updateArchive(obj.positions, obj.fitness);

            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括选择、交叉、变异和环境选择

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1;
            dim = size(obj.positions, 2);

            offspringPositions = zeros(N, dim);
            offspringFitness = zeros(N, obj.objCount);

            for i = 1:2:N
                parent1 = obj.tournamentSelection();
                parent2 = obj.tournamentSelection();

                [child1, child2] = obj.sbxCrossover(...
                    obj.positions(parent1, :), obj.positions(parent2, :), ...
                    lb, ub);

                child1 = obj.polynomialMutation(child1, lb, ub);
                child2 = obj.polynomialMutation(child2, lb, ub);

                offspringPositions(i, :) = child1;
                offspringFitness(i, :) = obj.evaluateSolution(child1);

                if i + 1 <= N
                    offspringPositions(i + 1, :) = child2;
                    offspringFitness(i + 1, :) = obj.evaluateSolution(child2);
                end
            end

            combinedPositions = [obj.positions; offspringPositions];
            combinedFitness = [obj.fitness; offspringFitness];

            [obj.positions, obj.fitness] = obj.environmentSelection(...
                combinedPositions, combinedFitness, N);

            obj.updateArchive(obj.positions, obj.fitness);

            obj.idealPoint = min(obj.fitness, [], 1);
            obj.nadirPoint = max(obj.fitness, [], 1);

            igd = obj.calculateIGD();
            obj.convergenceCurve(currentIter) = igd;

            if obj.config.verbose && mod(currentIter, 20) == 0
                obj.displayProgress(sprintf('IGD: %.6e, Archive size: %d', ...
                    igd, obj.archiveSize));
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
                validatedConfig.populationSize = 100;
            end

            if isfield(config, 'maxIterations')
                validatedConfig.maxIterations = max(1, round(config.maxIterations));
            else
                validatedConfig.maxIterations = 200;
            end

            if isfield(config, 'archiveMaxSize')
                validatedConfig.archiveMaxSize = max(10, round(config.archiveMaxSize));
            else
                validatedConfig.archiveMaxSize = 100;
            end

            if isfield(config, 'crossoverProb')
                validatedConfig.crossoverProb = min(1, max(0, config.crossoverProb));
            else
                validatedConfig.crossoverProb = 0.9;
            end

            if isfield(config, 'mutationProb')
                validatedConfig.mutationProb = min(1, max(0, config.mutationProb));
            else
                validatedConfig.mutationProb = 0.1;
            end

            if isfield(config, 'etaC')
                validatedConfig.etaC = max(1, config.etaC);
            else
                validatedConfig.etaC = 30;
            end

            if isfield(config, 'etaM')
                validatedConfig.etaM = max(1, config.etaM);
            else
                validatedConfig.etaM = 20;
            end

            if isfield(config, 'divisions')
                validatedConfig.divisions = max(2, round(config.divisions));
            else
                validatedConfig.divisions = 12;
            end

            if isfield(config, 'verbose')
                validatedConfig.verbose = logical(config.verbose);
            else
                validatedConfig.verbose = true;
            end
        end
    end

    methods (Access = protected)
        function refPoints = generateReferencePoints(obj, M, p)
            % generateReferencePoints 生成参考点 (Das and Dennis方法)
            %
            % 输入参数:
            %   M - 目标数量
            %   p - 分层参数
            %
            % 输出参数:
            %   refPoints - 参考点矩阵 (nRef x M)

            refPoints = obj.simplexLatticeDesign(M, p);
        end

        function Z = simplexLatticeDesign(obj, M, p)
            % simplexLatticeDesign 单纯形格子设计
            %
            % 输入参数:
            %   M - 维度
            %   p - 分层参数
            %
            % 输出参数:
            %   Z - 参考点矩阵

            if M == 1
                Z = [0; 1];
                return;
            end

            n = nchoosek(p + M - 1, M - 1);
            Z = zeros(n, M);

            temp = zeros(1, M);
            idx = 1;
            obj.generateCombinations(p, M, 1, temp, Z, idx);
        end

        function [Z, idx] = generateCombinations(obj, p, M, start, temp, Z, idx)
            % generateCombinations 递归生成组合

            if start == M
                temp(start) = p - sum(temp(1:start-1));
                Z(idx, :) = temp / p;
                idx = idx + 1;
                return;
            end

            for i = 0:p
                temp(start) = i;
                if sum(temp(1:start)) <= p
                    [Z, idx] = obj.generateCombinations(p, M, start + 1, temp, Z, idx);
                end
            end
        end

        function idx = tournamentSelection(obj)
            % tournamentSelection 锦标赛选择
            %
            % 输出参数:
            %   idx - 选中的个体索引

            N = size(obj.positions, 1);
            candidates = randperm(N, 2);

            dominated = obj.dominates(obj.fitness(candidates(1), :), ...
                obj.fitness(candidates(2), :));

            if dominated
                idx = candidates(1);
            else
                dominated = obj.dominates(obj.fitness(candidates(2), :), ...
                    obj.fitness(candidates(1), :));
                if dominated
                    idx = candidates(2);
                else
                    idx = candidates(randi(2));
                end
            end
        end

        function [child1, child2] = sbxCrossover(obj, parent1, parent2, lb, ub)
            % sbxCrossover 模拟二进制交叉 (SBX)
            %
            % 输入参数:
            %   parent1 - 父代1
            %   parent2 - 父代2
            %   lb - 下边界
            %   ub - 上边界
            %
            % 输出参数:
            %   child1 - 子代1
            %   child2 - 子代2

            dim = length(parent1);
            child1 = parent1;
            child2 = parent2;

            if rand() > obj.config.crossoverProb
                return;
            end

            etaC = obj.config.etaC;

            for i = 1:dim
                if rand() < 0.5
                    if abs(parent1(i) - parent2(i)) > eps
                        if parent1(i) < parent2(i)
                            y1 = parent1(i);
                            y2 = parent2(i);
                        else
                            y1 = parent2(i);
                            y2 = parent1(i);
                        end

                        yl = lb(i);
                        yu = ub(i);

                        rand_val = rand();
                        beta = 1 + (2 * (y1 - yl) / (y2 - y1));
                        alpha = 2 - beta^(-(etaC + 1));

                        if rand_val <= (1 / alpha)
                            betaq = (rand_val * alpha)^(1 / (etaC + 1));
                        else
                            betaq = (1 / (2 - rand_val * alpha))^(1 / (etaC + 1));
                        end

                        c1 = 0.5 * ((y1 + y2) - betaq * (y2 - y1));
                        c2 = 0.5 * ((y1 + y2) + betaq * (y2 - y1));

                        child1(i) = min(max(c1, yl), yu);
                        child2(i) = min(max(c2, yl), yu);
                    end
                end
            end
        end

        function mutant = polynomialMutation(obj, individual, lb, ub)
            % polynomialMutation 多项式变异
            %
            % 输入参数:
            %   individual - 待变异个体
            %   lb - 下边界
            %   ub - 上边界
            %
            % 输出参数:
            %   mutant - 变异后的个体

            mutant = individual;
            dim = length(individual);
            etaM = obj.config.etaM;

            for i = 1:dim
                if rand() < obj.config.mutationProb
                    y = individual(i);
                    yl = lb(i);
                    yu = ub(i);

                    delta1 = (y - yl) / (yu - yl);
                    delta2 = (yu - y) / (yu - yl);

                    rand_val = rand();

                    mut_pow = 1 / (etaM + 1);

                    if rand_val < 0.5
                        xy = 1 - delta1;
                        val = 2 * rand_val + (1 - 2 * rand_val) * (xy^(etaM + 1));
                        deltaq = val^mut_pow - 1;
                    else
                        xy = 1 - delta2;
                        val = 2 * (1 - rand_val) + 2 * (rand_val - 0.5) * (xy^(etaM + 1));
                        deltaq = 1 - val^mut_pow;
                    end

                    y = y + deltaq * (yu - yl);
                    mutant(i) = min(max(y, yl), yu);
                end
            end
        end

        function [selectedPos, selectedFit] = environmentSelection(obj, ...
                combinedPos, combinedFit, N)
            % environmentSelection 环境选择
            %
            % 输入参数:
            %   combinedPos - 合并后的位置矩阵
            %   combinedFit - 合并后的适应度矩阵
            %   N - 目标种群大小
            %
            % 输出参数:
            %   selectedPos - 选择的位置矩阵
            %   selectedFit - 选择的适应度矩阵

            totalSize = size(combinedPos, 1);
            fronts = obj.nonDominatedSort(combinedFit);

            selectedPos = [];
            selectedFit = [];
            frontIdx = 1;

            while size(selectedPos, 1) + length(fronts{frontIdx}) <= N
                front = fronts{frontIdx};
                selectedPos = [selectedPos; combinedPos(front, :)];
                selectedFit = [selectedFit; combinedFit(front, :)];
                frontIdx = frontIdx + 1;

                if frontIdx > length(fronts)
                    break;
                end
            end

            if size(selectedPos, 1) < N && frontIdx <= length(fronts)
                remaining = N - size(selectedPos, 1);
                front = fronts{frontIdx};

                normalizedFit = obj.normalizeFitness(combinedFit(front, :));

                nicheCount = obj.calculateNicheCount(normalizedFit);

                [~, sortedIndices] = sort(nicheCount);

                for i = 1:min(remaining, length(sortedIndices))
                    idx = front(sortedIndices(i));
                    selectedPos = [selectedPos; combinedPos(idx, :)];
                    selectedFit = [selectedFit; combinedFit(idx, :)];
                end
            end
        end

        function fronts = nonDominatedSort(obj, fitness)
            % nonDominatedSort 非支配排序
            %
            % 输入参数:
            %   fitness - 适应度矩阵
            %
            % 输出参数:
            %   fronts - 分层前沿 (cell数组)

            N = size(fitness, 1);
            dominationCount = zeros(N, 1);
            dominatedSet = cell(N, 1);

            for i = 1:N
                dominatedSet{i} = [];
                for j = 1:N
                    if i ~= j
                        if obj.dominates(fitness(i, :), fitness(j, :))
                            dominatedSet{i} = [dominatedSet{i}, j];
                        elseif obj.dominates(fitness(j, :), fitness(i, :))
                            dominationCount(i) = dominationCount(i) + 1;
                        end
                    end
                end
            end

            fronts = {};
            currentFront = find(dominationCount == 0);

            while ~isempty(currentFront)
                fronts{end + 1} = currentFront;

                for i = 1:length(currentFront)
                    for j = 1:length(dominatedSet{currentFront(i)})
                        dominationCount(dominatedSet{currentFront(i)}(j)) = ...
                            dominationCount(dominatedSet{currentFront(i)}(j)) - 1;

                        if dominationCount(dominatedSet{currentFront(i)}(j)) == 0
                            nextFront = [nextFront, dominatedSet{currentFront(i)}(j)];
                        end
                    end
                end

                if exist('nextFront', 'var')
                    currentFront = nextFront;
                    clear nextFront;
                else
                    currentFront = [];
                end
            end
        end

        function normalizedFit = normalizeFitness(obj, fitness)
            % normalizeFitness 归一化适应度
            %
            % 输入参数:
            %   fitness - 适应度矩阵
            %
            % 输出参数:
            %   normalizedFit - 归一化后的适应度

            normalizedFit = fitness - obj.idealPoint;
            range = obj.nadirPoint - obj.idealPoint;
            range(range < eps) = 1;
            normalizedFit = normalizedFit ./ range;
        end

        function nicheCount = calculateNicheCount(obj, normalizedFit)
            % calculateNicheCount 计算小生境计数
            %
            % 输入参数:
            %   normalizedFit - 归一化适应度
            %
            % 输出参数:
            %   nicheCount - 小生境计数

            N = size(normalizedFit, 1);
            nicheCount = zeros(N, 1);

            for i = 1:N
                minDist = Inf;
                for j = 1:obj.nRef
                    dist = norm(normalizedFit(i, :) - obj.referencePoints(j, :));
                    if dist < minDist
                        minDist = dist;
                    end
                end
                nicheCount(i) = minDist;
            end
        end

        function igd = calculateIGD(obj)
            % calculateIGD 计算反向世代距离 (IGD)
            %
            % 输出参数:
            %   igd - IGD值

            if obj.archiveSize == 0
                igd = Inf;
                return;
            end

            igd = 0;
            for i = 1:obj.nRef
                minDist = Inf;
                for j = 1:obj.archiveSize
                    dist = norm(obj.referencePoints(i, :) - ...
                        obj.archiveF(j, :));
                    if dist < minDist
                        minDist = dist;
                    end
                end
                igd = igd + minDist;
            end
            igd = igd / obj.nRef;
        end

        function dominated = dominates(obj, f1, f2)
            % dominates 判断f1是否支配f2
            %
            % 输入参数:
            %   f1 - 适应度向量1
            %   f2 - 适应度向量2
            %
            % 输出参数:
            %   dominated - true表示f1支配f2

            dominated = all(f1 <= f2) && any(f1 < f2);
        end
    end

    methods (Static)
        function register()
            % register 将算法注册到AlgorithmRegistry
            %
            % 此方法在系统初始化时调用，将NSGA-III算法注册到全局注册表。

            AlgorithmRegistry.register('NSGAIII', '1.0.0', 'NSGAIII');
        end
    end
end
