classdef LevyFlight < handle
    % LevyFlight Levy飞行算子
    %
    % 提供Levy飞行随机游走策略，用于元启发式算法的探索阶段。
    % Levy飞行具有长尾分布特性，允许算法进行大范围跳跃。
    %
    % 参考文献:
    %   Xin-She Yang, Nature-Inspired Optimization Algorithms, Elsevier, 2014
    %
    % 使用示例:
    %   step = LevyFlight.generate(dim);
    %   newPosition = currentPosition + step .* currentPosition;
    %
    % 版本: 2.0.0
    % 日期: 2025

    properties (Constant)
        BETA = 1.5  % Levy指数 (默认1.5, 范围1-2)
    end

    methods (Static)
        function step = generate(dim, beta)
            % generate 生成Levy飞行步长
            %
            % 输入参数:
            %   dim - 维度
            %   beta - Levy指数 (默认: 1.5)
            %
            % 输出参数:
            %   step - Levy飞行步长向量 (1 x dim)

            if nargin < 2
                beta = 1.5;
            end

            % 计算sigma (Eq. 3.10)
            numerator = gamma(1 + beta) * sin(pi * beta / 2);
            denominator = gamma((1 + beta) / 2) * beta * 2^((beta - 1) / 2);
            sigma = (numerator / denominator)^(1 / beta);

            % 生成随机步长
            u = randn(1, dim) * sigma;
            v = randn(1, dim);
            step = u ./ abs(v).^(1 / beta);

            % 缩放因子
            step = 0.01 * step;
        end

        function step = generateWithScale(dim, scale, beta)
            % generateWithScale 生成带缩放因子的Levy飞行步长
            %
            % 输入参数:
            %   dim - 维度
            %   scale - 缩放因子
            %   beta - Levy指数 (默认: 1.5)
            %
            % 输出参数:
            %   step - Levy飞行步长向量

            if nargin < 3
                beta = 1.5;
            end

            rawStep = LevyFlight.generate(dim, beta);
            step = scale * rawStep;
        end
    end
end
