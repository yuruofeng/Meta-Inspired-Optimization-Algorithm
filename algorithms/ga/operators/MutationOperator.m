classdef (Abstract) MutationOperator < handle
    % MutationOperator 变异算子抽象基类
    %
    % 定义遗传算法变异算子的统一接口。所有具体变异算子
    % (高斯、均匀、多项式变异等)必须继承此类。
    %
    % 参考规范: metaheuristic_spec.md §3.2
    %
    % 使用示例:
    %   classdef GaussianMutation < MutationOperator
    %       methods
    %           function mutated = mutate(obj, solution, lb, ub)
    %               % 实现具体变异逻辑
    %           end
    %       end
    %   end
    %
    % 版本: 2.0.0
    % 日期: 2025

    properties
        mutationRate double = 0.01  % 变异概率
    end

    methods
        function obj = MutationOperator(mutationRate)
            % MutationOperator 构造函数
            %
            % 输入参数:
            %   mutationRate - 变异概率 (默认: 0.01)

            if nargin > 0
                if mutationRate < 0 || mutationRate > 1
                    error('MutationOperator:InvalidParam', ...
                        'mutationRate must be in [0, 1]');
                end
                obj.mutationRate = mutationRate;
            end
        end
    end

    methods (Abstract)
        mutated = mutate(obj, solution, lb, ub)
        % mutate 执行变异操作
        %
        % 输入参数:
        %   solution - 原始解向量 (1 x Dim)
        %   lb - 下界 (标量或向量)
        %   ub - 上界 (标量或向量)
        %
        % 输出参数:
        %   mutated - 变异后的解向量 (1 x Dim)
    end

    methods
        function mutated = mutateWithRate(obj, solution, lb, ub)
            % mutateWithRate 带变异概率的变异操作
            %
            % 以 mutationRate 的概率对每个基因执行变异
            %
            % 输入参数:
            %   solution - 原始解向量 (1 x Dim)
            %   lb - 下界 (标量或向量)
            %   ub - 上界 (标量或向量)
            %
            % 输出参数:
            %   mutated - 变异后的解向量 (1 x Dim)

            % 确定哪些位置需要变异
            dim = length(solution);
            mutateMask = rand(1, dim) < obj.mutationRate;

            if any(mutateMask)
                mutated = solution;
                mutated(mutateMask) = obj.mutateGenes(solution(mutateMask), lb, ub);
            else
                mutated = solution;
            end
        end

        function newPopulation = mutatePopulation(obj, population, lb, ub)
            % mutatePopulation 对整个种群执行变异
            %
            % 输入参数:
            %   population - 种群矩阵 (N x Dim)
            %   lb - 下界 (标量或向量)
            %   ub - 上界 (标量或向量)
            %
            % 输出参数:
            %   newPopulation - 变异后的新种群 (N x Dim)

            popSize = size(population, 1);
            newPopulation = population;

            for i = 1:popSize
                newPopulation(i, :) = obj.mutateWithRate(population(i, :), lb, ub);
            end
        end

        function mutatedGenes = mutateGenes(obj, genes, lb, ub)
            % mutateGenes 对指定基因执行变异
            %
            % 子类可以覆盖此方法实现具体的基因变异逻辑
            %
            % 输入参数:
            %   genes - 需要变异的基因
            %   lb - 下界
            %   ub - 上界
            %
            % 输出参数:
            %   mutatedGenes - 变异后的基因

            % 默认实现：在边界内均匀随机
            if isscalar(lb)
                mutatedGenes = lb + (ub - lb) * rand(size(genes));
            else
                mutatedGenes = lb(1:length(genes)) + ...
                    (ub(1:length(genes)) - lb(1:length(genes))) .* rand(size(genes));
            end
        end
    end
end
