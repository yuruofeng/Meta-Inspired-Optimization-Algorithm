classdef GaussianMutation < MutationOperator
    % GaussianMutation 高斯变异算子
    %
    % 使用高斯分布对基因进行扰动。适合连续优化问题。
    %
    % 算法原理:
    %   mutated = original + sigma * randn()
    %   其中 sigma 是标准差，通常与搜索范围成比例
    %
    % 使用示例:
    %   mutator = GaussianMutation(0.01, 0.1);
    %   mutated = mutator.mutate(solution, lb, ub);
    %
    % 版本: 2.0.0
    % 日期: 2025

    properties
        sigma double = 0.1  % 标准差 (相对于搜索范围的比例)
    end

    methods
        function obj = GaussianMutation(mutationRate, sigma)
            % GaussianMutation 构造函数
            %
            % 输入参数:
            %   mutationRate - 变异概率 (默认: 0.01)
            %   sigma - 标准差比例 (默认: 0.1)

            % 调用父类构造函数设置mutationRate
            if nargin > 0
                obj = obj@MutationOperator(mutationRate);
            else
                obj = obj@MutationOperator();
            end

            if nargin > 1
                if sigma <= 0
                    error('GaussianMutation:InvalidParam', ...
                        'sigma must be > 0');
                end
                obj.sigma = sigma;
            end
        end

        function mutated = mutate(obj, solution, lb, ub)
            % mutate 执行高斯变异
            %
            % 输入参数:
            %   solution - 原始解向量 (1 x Dim)
            %   lb - 下界 (标量或向量)
            %   ub - 上界 (标量或向量)
            %
            % 输出参数:
            %   mutated - 变异后的解向量 (1 x Dim)

            dim = length(solution);

            % 计算搜索范围
            if isscalar(lb)
                range = ub - lb;
                std_dev = obj.sigma * range;
            else
                range = ub - lb;
                std_dev = obj.sigma * range;
            end

            % 生成高斯扰动
            perturbation = randn(1, dim) .* std_dev;

            % 应用变异
            mutated = solution + perturbation;

            % 边界处理
            mutated = max(mutated, lb);
            mutated = min(mutated, ub);
        end

        function mutatedGenes = mutateGenes(obj, genes, lb, ub)
            % mutateGenes 对指定基因执行高斯变异
            %
            % 输入参数:
            %   genes - 需要变异的基因
            %   lb - 下界
            %   ub - 上界
            %
            % 输出参数:
            %   mutatedGenes - 变异后的基因

            nGenes = length(genes);

            % 计算标准差
            if isscalar(lb)
                std_dev = obj.sigma * (ub - lb);
            else
                std_dev = obj.sigma * (ub(1:nGenes) - lb(1:nGenes));
            end

            % 高斯扰动
            perturbation = randn(1, nGenes) .* std_dev;
            mutatedGenes = genes + perturbation;

            % 边界处理
            if isscalar(lb)
                mutatedGenes = max(mutatedGenes, lb);
                mutatedGenes = min(mutatedGenes, ub);
            else
                mutatedGenes = max(mutatedGenes, lb(1:nGenes));
                mutatedGenes = min(mutatedGenes, ub(1:nGenes));
            end
        end
    end
end
