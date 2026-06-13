classdef RouletteWheelSelection < handle
    % RouletteWheelSelection 轮盘赌选择算子
    %
    % 实现基于适应度的轮盘赌选择机制。权重越大的个体被选中的概率越高。
    %
    % 使用示例:
    %   selector = RouletteWheelSelection();
    %   weights = [1, 5, 3, 15, 8, 1];
    %   selected_idx = selector.select(weights);
    %   % 最可能选中索引4 (权重15)
    %
    % 参考文献:
    %   Algorithm adapted from:
    %   http://playmedusa.com/blog/roulette-wheel-selection-algorithm-in-matlab-2/
    %
    % 原始作者: Seyedali Mirjalili
    % 整合版本: 2.0.0
    % 日期: 2025

    methods
        function obj = RouletteWheelSelection()
            % RouletteWheelSelection 构造函数
            % 无参数
        end

        function chosen_index = select(obj, weights)
            % select 执行轮盘赌选择
            %
            % 输入参数:
            %   weights - 适应度权重向量 (1 x N 或 N x 1)
            %
            % 输出参数:
            %   chosen_index - 被选中个体的索引 (1 到 N)
            %
            % 算法:
            %   1. 计算累积和
            %   2. 生成随机数 p ∈ [0, sum(weights)]
            %   3. 返回第一个累积和 > p 的索引

            % 确保权重是行向量
            weights = weights(:)';

            % 检查权重有效性
            if any(weights < 0)
                error('RouletteWheelSelection:NegativeWeights', ...
                    'Weights must be non-negative');
            end

            if sum(weights) == 0
                error('RouletteWheelSelection:ZeroWeights', ...
                    'Sum of weights cannot be zero');
            end

            % 计算累积和
            accumulation = cumsum(weights);

            % 生成随机数
            p = rand() * accumulation(end);

            % 找到被选中的索引
            chosen_index = -1;
            for index = 1:length(accumulation)
                if accumulation(index) > p
                    chosen_index = index;
                    break;
                end
            end

            % 安全检查（理论上不会发生）
            if chosen_index == -1
                chosen_index = length(weights);
            end
        end
    end
end
