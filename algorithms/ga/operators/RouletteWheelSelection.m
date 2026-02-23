classdef RouletteWheelSelection < SelectionOperator
    % RouletteWheelSelection 轮盘赌选择算子
    %
    % 基于适应度比例的选择方法。个体被选中的概率与其
    % 适应度成正比。
    %
    % 算法原理:
    %   1. 计算每个个体的选择概率 (适应度/总适应度)
    %   2. 构建累积概率分布
    %   3. 生成随机数，落在哪个区间就选择对应个体
    %
    % 注意: 最小化问题需要将适应度转换为选择概率
    %       使用 fitnessToProbability 方法转换
    %
    % 使用示例:
    %   selector = RouletteWheelSelection();
    %   indices = selector.select(population, fitness, n);
    %
    % 版本: 2.0.0
    % 日期: 2025

    properties
        scalingFactor double = 1  % 缩放因子
    end

    methods
        function obj = RouletteWheelSelection(scalingFactor)
            % RouletteWheelSelection 构造函数
            %
            % 输入参数:
            %   scalingFactor - 缩放因子 (默认: 1)

            if nargin > 0
                if scalingFactor <= 0
                    error('RouletteWheelSelection:InvalidParam', ...
                        'scalingFactor must be > 0');
                end
                obj.scalingFactor = scalingFactor;
            end
        end

        function indices = select(obj, population, fitness, n)
            % select 执行轮盘赌选择
            %
            % 输入参数:
            %   population - 种群矩阵 (N x Dim)
            %   fitness - 适应度向量 (N x 1)，值越小越优
            %   n - 需要选择的个体数量
            %
            % 输出参数:
            %   indices - 被选中个体的索引数组 (n x 1)

            popSize = size(population, 1);

            % 将最小化适应度转换为选择概率
            prob = obj.fitnessToProbability(fitness);

            % 构建累积概率
            cumProb = cumsum(prob);

            % 执行选择
            indices = zeros(n, 1);
            for i = 1:n
                r = rand();
                % 找到第一个累积概率大于r的索引
                idx = find(cumProb >= r, 1, 'first');
                if isempty(idx)
                    idx = popSize;
                end
                indices(i) = idx;
            end
        end

        function prob = fitnessToProbability(obj, fitness)
            % fitnessToProbability 将适应度转换为选择概率
            %
            % 输入参数:
            %   fitness - 适应度向量 (N x 1)，值越小越优
            %
            % 输出参数:
            %   prob - 选择概率向量 (N x 1)，和为1
            %
            % 转换方法:
            %   对于最小化问题，适应度越小越好
            %   使用倒数变换: value = 1 / (fitness + epsilon)

            epsilon = 1e-10;  % 避免除零

            % 将最小化适应度转换为选择权重
            weights = 1 ./ (fitness + epsilon);

            % 归一化为概率
            prob = weights / sum(weights);
        end
    end
end
