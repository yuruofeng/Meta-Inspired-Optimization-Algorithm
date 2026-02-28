classdef DominanceOperator < handle
    % DominanceOperator 支配关系操作符
    %
    % 提供Pareto支配关系的判断和相关操作，是多目标优化的核心组件。
    %
    % 支配关系定义:
    %   解x支配解y (记作 x ≺ y) 当且仅当:
    %   1. x在所有目标上不劣于y (对于最小化: x_i <= y_i for all i)
    %   2. x至少在一个目标上严格优于y (对于最小化: x_j < y_j for some j)
    %
    % 使用示例:
    %   op = DominanceOperator();
    %   if op.dominates(fitness1, fitness2)
    %       disp('Solution 1 dominates Solution 2');
    %   end
    %
    % 作者：RUOFENG YU
    % 版本: 1.0.0
    % 日期: 2025

    properties (Constant)
        minimize = true  % 默认为最小化问题
    end

    methods
        function obj = DominanceOperator()
        end

        function tf = dominates(obj, x, y)
            % dominates 判断解x是否支配解y
            %
            % 输入参数:
            %   x - 解x的目标函数值向量 (1 x m)
            %   y - 解y的目标函数值向量 (1 x m)
            %
            % 输出参数:
            %   tf - true表示x支配y

            if obj.minimize
                tf = all(x <= y) && any(x < y);
            else
                tf = all(x >= y) && any(x > y);
            end
        end

        function relation = compare(obj, x, y)
            % compare 比较两个解的支配关系
            %
            % 输入参数:
            %   x - 解x的目标函数值向量
            %   y - 解y的目标函数值向量
            %
            % 输出参数:
            %   relation - 1表示x支配y, -1表示y支配x, 0表示互不支配

            if obj.dominates(x, y)
                relation = 1;
            elseif obj.dominates(y, x)
                relation = -1;
            else
                relation = 0;
            end
        end

        function ranks = fastNonDominatedSort(obj, population)
            % fastNonDominatedSort 快速非支配排序
            %
            % 实现NSGA-II的快速非支配排序算法
            %
            % 输入参数:
            %   population - 目标函数值矩阵 (N x m)
            %
            % 输出参数:
            %   ranks - 每个解的Pareto等级 (1 x N)

            N = size(population, 1);
            ranks = zeros(1, N);
            dominationCount = zeros(1, N);
            dominatedSet = cell(1, N);

            for i = 1:N
                dominatedSet{i} = [];
                for j = 1:N
                    if i ~= j
                        if obj.dominates(population(i, :), population(j, :))
                            dominatedSet{i} = [dominatedSet{i}, j];
                        elseif obj.dominates(population(j, :), population(i, :))
                            dominationCount(i) = dominationCount(i) + 1;
                        end
                    end
                end
            end

            currentRank = 0;
            front = find(dominationCount == 0);

            while ~isempty(front)
                ranks(front) = currentRank;
                currentRank = currentRank + 1;

                nextFront = [];
                for i = front
                    for j = dominatedSet{i}
                        dominationCount(j) = dominationCount(j) - 1;
                        if dominationCount(j) == 0
                            nextFront = [nextFront, j];
                        end
                    end
                end
                front = nextFront;
            end
        end

        function cd = crowdingDistance(obj, front)
            % crowdingDistance 计算拥挤距离
            %
            % 实现NSGA-II的拥挤距离计算
            %
            % 输入参数:
            %   front - 前沿内解的目标函数值矩阵 (n x m)
            %
            % 输出参数:
            %   cd - 拥挤距离向量 (n x 1)

            n = size(front, 1);
            m = size(front, 2);

            if n <= 2
                cd = inf(n, 1);
                return;
            end

            cd = zeros(n, 1);

            for objIdx = 1:m
                [~, sortIdx] = sort(front(:, objIdx));
                sortedFront = front(sortIdx, objIdx);

                range = sortedFront(end) - sortedFront(1);
                if range == 0
                    range = 1;
                end

                cd(sortIdx(1)) = inf;
                cd(sortIdx(end)) = inf;

                for i = 2:n-1
                    cd(sortIdx(i)) = cd(sortIdx(i)) + ...
                        (sortedFront(i+1) - sortedFront(i-1)) / range;
                end
            end
        end
    end
end
