classdef MOGWO < MOBaseAlgorithm
    % MOGWO 多目标灰狼优化器 (Multi-Objective Grey Wolf Optimizer)
    %
    % 一种模拟灰狼社会等级和狩猎行为的多目标元启发式算法。通过Alpha、
    % Beta、Delta三层领导机制引导种群搜索Pareto前沿。
    %
    % 算法特点:
    %   - 社会等级: Alpha、Beta、Delta三层领导
    %   - 狩猎机制: 包围、追捕、攻击三个阶段
    %   - 超立方体网格: 用于存档管理和领导选择
    %   - 拥挤度选择: 倾向于选择稀疏区域的解作为领导
    %
    % 参考文献:
    %   S. Mirjalili, S. Saremi, S. M. Mirjalili, L. Coelho
    %   "Multi-objective grey wolf optimizer: A novel algorithm for
    %    multi-criterion optimization"
    %   Expert Systems with Applications, 2016
    %   DOI: 10.1016/j.eswa.2015.10.039
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(ArchiveSize × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 100, 'maxIterations', 100);
    %   mogwo = MOGWO(config);
    %   problem.lb = 0; problem.ub = 1; problem.dim = 5;
    %   problem.objCount = 2;
    %   problem.evaluate = @(x) ZDT1(x);
    %   result = mogwo.run(problem);
    %   result.plot();
    %
    % 原始作者: Seyedali Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2025

    properties (Access = protected)
        positions            % 灰狼位置矩阵 (N x Dim)
        fitness              % 适应度矩阵 (N x objCount)
        alphaPosition        % Alpha狼位置
        betaPosition         % Beta狼位置
        deltaPosition        % Delta狼位置
        alphaFitness         % Alpha狼适应度
        betaFitness          % Beta狼适应度
        deltaFitness         % Delta狼适应度
        grid                 % 超立方体网格结构
        nGrid                % 每维网格数
        alpha                % 网格膨胀参数
        beta                 % 领导选择压力
        gamma                % 删除选择压力
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 100, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '灰狼种群大小'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 100, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'archiveMaxSize', struct(...
                'type', 'integer', ...
                'default', 100, ...
                'min', 10, ...
                'max', 1000, ...
                'description', 'Pareto存档最大容量'), ...
            'nGrid', struct(...
                'type', 'integer', ...
                'default', 10, ...
                'min', 5, ...
                'max', 50, ...
                'description', '每维网格数'), ...
            'alpha', struct(...
                'type', 'float', ...
                'default', 0.1, ...
                'min', 0, ...
                'max', 1, ...
                'description', '网格膨胀参数'), ...
            'beta', struct(...
                'type', 'float', ...
                'default', 4, ...
                'min', 1, ...
                'max', 10, ...
                'description', '领导选择压力'), ...
            'gamma', struct(...
                'type', 'float', ...
                'default', 2, ...
                'min', 1, ...
                'max', 10, ...
                'description', '删除选择压力'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = MOGWO(configStruct)
            % MOGWO 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体

            if nargin < 1 || isempty(configStruct)
                configStruct = struct();
            end

            obj = obj@MOBaseAlgorithm(configStruct);
        end

        function initialize(obj, problem)
            % initialize 初始化种群和存档

            lb = problem.lb;
            ub = problem.ub;
            dim = problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            obj.archiveMaxSize = int32(obj.config.archiveMaxSize);

            obj.nGrid = obj.config.nGrid;
            obj.alpha = obj.config.alpha;
            obj.beta = obj.config.beta;
            obj.gamma = obj.config.gamma;

            if isscalar(lb)
                lb = lb * ones(1, dim);
                ub = ub * ones(1, dim);
            end
            obj.problem.lb = lb;
            obj.problem.ub = ub;

            obj.positions = Initialization(N, dim, ub, lb);
            obj.fitness = zeros(N, obj.objCount);

            obj.alphaPosition = zeros(1, dim);
            obj.betaPosition = zeros(1, dim);
            obj.deltaPosition = zeros(1, dim);
            obj.alphaFitness = inf(1, obj.objCount);
            obj.betaFitness = inf(1, obj.objCount);
            obj.deltaFitness = inf(1, obj.objCount);

            obj.archiveX = zeros(obj.archiveMaxSize, dim);
            obj.archiveF = inf(obj.archiveMaxSize, obj.objCount);
            obj.archiveSize = int32(0);

            for i = 1:N
                obj.fitness(i, :) = obj.evaluateSolution(obj.positions(i, :));
            end

            obj.updateArchive(obj.positions, obj.fitness);
            obj.grid = obj.createHypercubes();

            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            N = obj.config.populationSize;
            dim = size(obj.positions, 2);
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1;

            a = 2 - currentIter * (2 / MaxIter);

            [alphaIdx, betaIdx, deltaIdx] = obj.selectLeaders();

            if alphaIdx > 0 && alphaIdx <= obj.archiveSize
                obj.alphaPosition = obj.archiveX(alphaIdx, :);
                obj.alphaFitness = obj.archiveF(alphaIdx, :);
            end

            if betaIdx > 0 && betaIdx <= obj.archiveSize
                obj.betaPosition = obj.archiveX(betaIdx, :);
                obj.betaFitness = obj.archiveF(betaIdx, :);
            end

            if deltaIdx > 0 && deltaIdx <= obj.archiveSize
                obj.deltaPosition = obj.archiveX(deltaIdx, :);
                obj.deltaFitness = obj.archiveF(deltaIdx, :);
            end

            for i = 1:N
                for j = 1:dim
                    r1 = rand();
                    r2 = rand();

                    A1 = 2 * a * r1 - a;
                    C1 = 2 * r2;
                    D_alpha = abs(C1 * obj.alphaPosition(j) - obj.positions(i, j));
                    X1 = obj.alphaPosition(j) - A1 * D_alpha;

                    r1 = rand();
                    r2 = rand();
                    A2 = 2 * a * r1 - a;
                    C2 = 2 * r2;
                    D_beta = abs(C2 * obj.betaPosition(j) - obj.positions(i, j));
                    X2 = obj.betaPosition(j) - A2 * D_beta;

                    r1 = rand();
                    r2 = rand();
                    A3 = 2 * a * r1 - a;
                    C3 = 2 * r2;
                    D_delta = abs(C3 * obj.deltaPosition(j) - obj.positions(i, j));
                    X3 = obj.deltaPosition(j) - A3 * D_delta;

                    obj.positions(i, j) = (X1 + X2 + X3) / 3;
                end

                obj.positions(i, :) = min(max(obj.positions(i, :), lb), ub);
                obj.fitness(i, :) = obj.evaluateSolution(obj.positions(i, :));
            end

            obj.updateArchive(obj.positions, obj.fitness);
            obj.grid = obj.createHypercubes();

            obj.convergenceCurve(currentIter) = obj.archiveSize;

            if obj.config.verbose && mod(currentIter, 10) == 0
                obj.displayProgress(sprintf('Archive size: %d', obj.archiveSize));
            end
        end

        function tf = shouldStop(obj)
            tf = obj.currentIteration >= obj.config.maxIterations;
        end

        function validated = validateConfig(obj, config)
            validated = config;

            defaults = struct(...
                'populationSize', 100, ...
                'maxIterations', 100, ...
                'archiveMaxSize', 100, ...
                'nGrid', 10, ...
                'alpha', 0.1, ...
                'beta', 4, ...
                'gamma', 2, ...
                'verbose', true ...
            );

            fields = fieldnames(defaults);
            for i = 1:length(fields)
                if ~isfield(validated, fields{i})
                    validated.(fields{i}) = defaults.(fields{i});
                end
            end

            validated.populationSize = max(10, round(validated.populationSize));
            validated.maxIterations = max(1, round(validated.maxIterations));
            validated.archiveMaxSize = max(10, round(validated.archiveMaxSize));
        end
    end

    methods (Access = protected)
        function [alphaIdx, betaIdx, deltaIdx] = selectLeaders(obj)
            % selectLeaders 选择三个领导
            %
            % 基于超立方体网格的拥挤度选择Alpha、Beta、Delta
            %
            % 输出参数:
            %   alphaIdx, betaIdx, deltaIdx - 三个领导的索引

            if obj.archiveSize == 0
                alphaIdx = 0;
                betaIdx = 0;
                deltaIdx = 0;
                return;
            end

            if obj.archiveSize == 1
                alphaIdx = 1;
                betaIdx = 1;
                deltaIdx = 1;
                return;
            end

            if obj.archiveSize == 2
                alphaIdx = 1;
                betaIdx = 2;
                deltaIdx = 2;
                return;
            end

            alphaIdx = obj.selectLeaderIndex();
            betaIdx = obj.selectLeaderIndex();
            while betaIdx == alphaIdx
                betaIdx = obj.selectLeaderIndex();
            end

            deltaIdx = obj.selectLeaderIndex();
            while deltaIdx == alphaIdx || deltaIdx == betaIdx
                deltaIdx = obj.selectLeaderIndex();
            end
        end

        function idx = selectLeaderIndex(obj)
            % selectLeaderIndex 基于轮盘赌选择领导索引
            %
            % 输出参数:
            %   idx - 选中的领导索引

            if obj.archiveSize == 0
                idx = 0;
                return;
            end

            cellCounts = ones(1, obj.archiveSize);
            for i = 1:obj.archiveSize
                for j = 1:obj.archiveSize
                    if i ~= j
                        if obj.isInSameCell(obj.archiveF(i, :), obj.archiveF(j, :))
                            cellCounts(i) = cellCounts(i) + 1;
                        end
                    end
                end
            end

            probs = cellCounts .^ (-obj.beta);
            probs = probs / sum(probs);

            idx = obj.rouletteWheelSelection(probs);
        end

        function tf = isInSameCell(obj, f1, f2)
            % isInSameCell 判断两个解是否在同一网格单元
            %
            % 输入参数:
            %   f1, f2 - 两个解的目标值
            %
            % 输出参数:
            %   tf - 是否在同一单元

            tf = true;
            for k = 1:obj.objCount
                cell1 = obj.getGridIndex(f1(k), k);
                cell2 = obj.getGridIndex(f2(k), k);
                if cell1 ~= cell2
                    tf = false;
                    return;
                end
            end
        end

        function idx = getGridIndex(obj, value, objIdx)
            % getGridIndex 获取值在网格中的索引
            %
            % 输入参数:
            %   value - 目标值
            %   objIdx - 目标函数索引
            %
            % 输出参数:
            %   idx - 网格索引

            if obj.archiveSize == 0
                idx = 1;
                return;
            end

            fMin = min(obj.archiveF(1:obj.archiveSize, objIdx));
            fMax = max(obj.archiveF(1:obj.archiveSize, objIdx));
            range = fMax - fMin;

            if range == 0
                idx = 1;
                return;
            end

            inflatedRange = range * (1 + obj.alpha);
            offset = range * obj.alpha / 2;

            idx = floor((value - fMin + offset) / inflatedRange * obj.nGrid) + 1;
            idx = max(1, min(obj.nGrid, idx));
        end

        function grid = createHypercubes(obj)
            % createHypercubes 创建超立方体网格
            %
            % 输出参数:
            %   grid - 网格结构体

            if obj.archiveSize == 0
                grid = struct('ranges', []);
                return;
            end

            grid = struct();
            grid.ranges = cell(1, obj.objCount);

            for k = 1:obj.objCount
                fMin = min(obj.archiveF(1:obj.archiveSize, k));
                fMax = max(obj.archiveF(1:obj.archiveSize, k));
                range = fMax - fMin;

                if range == 0
                    range = 1;
                end

                inflatedRange = range * (1 + obj.alpha);
                offset = range * obj.alpha / 2;

                grid.ranges{k} = [fMin - offset, fMin - offset + inflatedRange];
            end
        end
    end

    methods (Static)
        function register()
            AlgorithmRegistry.register('MOGWO', '1.0.0', @MOGWO);
        end
    end
end
