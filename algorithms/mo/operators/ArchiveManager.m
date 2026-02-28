classdef ArchiveManager < handle
    % ArchiveManager Pareto存档管理器
    %
    % 管理多目标优化算法中的Pareto前沿存档，提供存档更新、
    % 溢出处理和选择操作。
    %
    % 功能:
    %   - 维护非支配解集
    %   - 存档溢出时基于拥挤度移除解
    %   - 提供基于轮盘赌的选择机制
    %
    % 使用示例:
    %   archive = ArchiveManager(maxSize, dim, objCount);
    %   archive.update(newSolutions, newFitness);
    %   [x, f] = archive.selectFromSparseRegion();
    %
    % 作者：RUOFENG YU
    % 版本: 1.0.0
    % 日期: 2025

    properties
        maxSize int32           % 存档最大容量
        dim int32               % 决策变量维度
        objCount int32          % 目标函数数量
    end

    properties (Access = private)
        solutions double        % 解集 (maxSize x dim)
        fitness double          % 目标值 (maxSize x objCount)
        currentSize int32       % 当前大小
        ranks double            % 拥挤度排名
        dominanceOp             % 支配关系操作符
    end

    methods
        function obj = ArchiveManager(maxSize, dim, objCount)
            % ArchiveManager 构造函数
            %
            % 输入参数:
            %   maxSize - 存档最大容量
            %   dim - 决策变量维度
            %   objCount - 目标函数数量

            if nargin < 3
                objCount = 2;
            end

            obj.maxSize = int32(maxSize);
            obj.dim = int32(dim);
            obj.objCount = int32(objCount);
            obj.solutions = zeros(maxSize, dim);
            obj.fitness = inf(maxSize, objCount);
            obj.currentSize = int32(0);
            obj.ranks = zeros(1, maxSize);
            obj.dominanceOp = algorithms.mo.operators.DominanceOperator();
        end

        function size = getSize(obj)
            % getSize 获取当前存档大小
            %
            % 输出参数:
            %   size - 当前存档中非支配解的数量

            size = obj.currentSize;
        end

        function [sols, fits] = getAll(obj)
            % getAll 获取所有存档解
            %
            % 输出参数:
            %   sols - 解矩阵 (currentSize x dim)
            %   fits - 目标值矩阵 (currentSize x objCount)

            if obj.currentSize == 0
                sols = [];
                fits = [];
            else
                sols = obj.solutions(1:obj.currentSize, :);
                fits = obj.fitness(1:obj.currentSize, :);
            end
        end

        function update(obj, newSolutions, newFitness)
            % update 更新存档
            %
            % 将新解加入存档，移除被支配的解，必要时处理溢出
            %
            % 输入参数:
            %   newSolutions - 新解矩阵 (n x dim)
            %   newFitness - 新解目标值矩阵 (n x objCount)

            nNew = size(newSolutions, 1);

            if obj.currentSize == 0
                combinedX = newSolutions;
                combinedF = newFitness;
            else
                combinedX = [obj.solutions(1:obj.currentSize, :); newSolutions];
                combinedF = [obj.fitness(1:obj.currentSize, :); newFitness];
            end

            nCombined = size(combinedF, 1);
            isDominated = false(1, nCombined);

            for i = 1:nCombined
                for j = 1:nCombined
                    if i ~= j
                        if obj.dominanceOp.dominates(combinedF(j, :), combinedF(i, :))
                            isDominated(i) = true;
                            break;
                        end
                    end
                end
            end

            nonDominatedIdx = find(~isDominated);
            obj.currentSize = int32(length(nonDominatedIdx));

            if obj.currentSize > 0
                obj.solutions(1:obj.currentSize, :) = combinedX(nonDominatedIdx, :);
                obj.fitness(1:obj.currentSize, :) = combinedF(nonDominatedIdx, :);
            end

            obj.ranks = obj.computeRanks();

            if obj.currentSize > obj.maxSize
                obj.handleOverflow();
            end
        end

        function ranks = computeRanks(obj)
            % computeRanks 计算拥挤度排名
            %
            % 输出参数:
            %   ranks - 拥挤度排名向量

            if obj.currentSize == 0
                ranks = [];
                return;
            end

            archiveF = obj.fitness(1:obj.currentSize, :);
            n = obj.currentSize;

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

            obj.ranks = ranks;
        end

        function handleOverflow(obj)
            % handleOverflow 处理存档溢出
            %
            % 当存档大小超过最大容量时，根据拥挤度移除多余的解

            while obj.currentSize > obj.maxSize
                ranks = obj.ranks(1:obj.currentSize);
                [~, maxIdx] = max(ranks);

                obj.solutions(maxIdx:obj.currentSize-1, :) = ...
                    obj.solutions(maxIdx+1:obj.currentSize, :);
                obj.fitness(maxIdx:obj.currentSize-1, :) = ...
                    obj.fitness(maxIdx+1:obj.currentSize, :);
                obj.ranks(maxIdx:obj.currentSize-1) = ...
                    obj.ranks(maxIdx+1:obj.currentSize);

                obj.currentSize = obj.currentSize - 1;
            end
        end

        function [sol, fit] = selectFromSparseRegion(obj)
            % selectFromSparseRegion 从稀疏区域选择解
            %
            % 使用轮盘赌选择，倾向于选择拥挤度低的解
            %
            % 输出参数:
            %   sol - 被选中的解
            %   fit - 被选中的解的目标值

            idx = obj.selectIndex(true);
            if idx == 0
                sol = [];
                fit = [];
            else
                sol = obj.solutions(idx, :);
                fit = obj.fitness(idx, :);
            end
        end

        function [sol, fit] = selectFromCrowdedRegion(obj)
            % selectFromCrowdedRegion 从拥挤区域选择解
            %
            % 使用轮盘赌选择，倾向于选择拥挤度高的解
            %
            % 输出参数:
            %   sol - 被选中的解
            %   fit - 被选中的解的目标值

            idx = obj.selectIndex(false);
            if idx == 0
                sol = [];
                fit = [];
            else
                sol = obj.solutions(idx, :);
                fit = obj.fitness(idx, :);
            end
        end

        function idx = selectIndex(obj, useInverse)
            % selectIndex 选择解索引
            %
            % 输入参数:
            %   useInverse - true选择稀疏区域，false选择拥挤区域
            %
            % 输出参数:
            %   idx - 被选中的索引

            if obj.currentSize == 0
                idx = 0;
                return;
            end

            if obj.currentSize == 1
                idx = 1;
                return;
            end

            ranks = obj.ranks(1:obj.currentSize);

            if useInverse
                probs = 1 ./ (ranks + 1);
            else
                probs = ranks + 1;
            end

            probs = probs / sum(probs);
            cumProbs = cumsum(probs);
            r = rand();
            idx = find(r <= cumProbs, 1, 'first');

            if isempty(idx)
                idx = int32(obj.currentSize);
            end
        end

        function reset(obj)
            % reset 重置存档

            obj.currentSize = int32(0);
            obj.solutions = zeros(obj.maxSize, obj.dim);
            obj.fitness = inf(obj.maxSize, obj.objCount);
            obj.ranks = zeros(1, obj.maxSize);
        end
    end
end
